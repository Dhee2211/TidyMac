import SwiftUI

// MARK: - What we clean (all safe, regenerable stuff)

struct Row: Identifiable {
    let id: String
    let name: String
    let detail: String
    var bytes: Int64 = 0
    var selected: Bool
    var items: [URL] = []
}

enum Kind: String, CaseIterable {
    case caches, logs, trash, xcode, devCaches, oldDownloads

    var name: String {
        switch self {
        case .caches: return "App caches"
        case .logs: return "Logs"
        case .trash: return "Trash"
        case .xcode: return "Xcode build junk"
        case .devCaches: return "Developer caches"
        case .oldDownloads: return "Old downloads"
        }
    }
    var detail: String {
        switch self {
        case .caches: return "Temporary files apps rebuild on their own"
        case .logs: return "Old diagnostic logs"
        case .trash: return "Files already in your Trash"
        case .xcode: return "DerivedData and simulator caches"
        case .devCaches: return "npm, yarn, pnpm, pip, Homebrew"
        case .oldDownloads: return "Untouched for 90+ days — moved to Trash"
        }
    }
    var defaultOn: Bool { self != .oldDownloads }

    /// Top-level items this category would remove.
    func items() -> [URL] {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        func children(_ rel: String) -> [URL] {
            let dir = home.appendingPathComponent(rel)
            return (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: [])) ?? []
        }
        switch self {
        case .caches:
            return children("Library/Caches").filter { $0.lastPathComponent != "Homebrew" && $0.lastPathComponent != "pip" }
        case .logs:
            return children("Library/Logs")
        case .trash:
            return children(".Trash")
        case .xcode:
            return children("Library/Developer/Xcode/DerivedData") + children("Library/Developer/CoreSimulator/Caches")
        case .devCaches:
            return ["Library/Caches/Homebrew", "Library/Caches/pip", ".npm/_cacache", ".cache", "Library/Caches/Yarn",
                    "Library/pnpm/store", ".gradle/caches"]
                .map { home.appendingPathComponent($0) }
                .filter { fm.fileExists(atPath: $0.path) }
        case .oldDownloads:
            let cutoff = Date().addingTimeInterval(-90 * 86_400)
            return children("Downloads").filter {
                let d = (try? $0.resourceValues(forKeys: [.contentModificationDateKey, .contentAccessDateKey]))
                let newest = max(d?.contentModificationDate ?? .distantPast, d?.contentAccessDate ?? .distantPast)
                return newest < cutoff && !$0.lastPathComponent.hasPrefix(".")
            }
        }
    }
}

// MARK: - Fast size calculation

func size(of url: URL) -> Int64 {
    let fm = FileManager.default
    let keys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey, .isRegularFileKey]
    var isDir: ObjCBool = false
    guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }
    if !isDir.boolValue {
        return Int64((try? url.resourceValues(forKeys: keys).totalFileAllocatedSize) ?? 0)
    }
    guard let en = fm.enumerator(at: url, includingPropertiesForKeys: Array(keys), options: [],
                                 errorHandler: { _, _ in true }) else { return 0 }
    var total: Int64 = 0
    for case let u as URL in en {
        if let v = try? u.resourceValues(forKeys: keys), v.isRegularFile == true {
            total += Int64(v.totalFileAllocatedSize ?? 0)
        }
    }
    return total
}

func fmt(_ b: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: b, countStyle: .file)
}

func freeSpace() -> Int64 {
    let v = try? URL(fileURLWithPath: NSHomeDirectory())
        .resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
    return v?.volumeAvailableCapacityForImportantUsage ?? 0
}

func totalSpace() -> Int64 {
    let v = try? URL(fileURLWithPath: NSHomeDirectory()).resourceValues(forKeys: [.volumeTotalCapacityKey])
    return Int64(v?.volumeTotalCapacity ?? 0)
}

// MARK: - Model

@MainActor
final class Model: ObservableObject {
    @Published var rows: [Row] = Kind.allCases.map { Row(id: $0.rawValue, name: $0.name, detail: $0.detail, selected: $0.defaultOn) }
    @Published var scanning = false
    @Published var cleaning = false
    @Published var freed: Int64? = nil
    @Published var free: Int64 = freeSpace()
    let total = totalSpace()

    var selectedBytes: Int64 { rows.filter(\.selected).reduce(0) { $0 + $1.bytes } }

    func scan() {
        guard !scanning else { return }
        scanning = true
        Task {
            let results: [String: (Int64, [URL])] = await withTaskGroup(of: (String, Int64, [URL]).self) { group in
                for k in Kind.allCases {
                    group.addTask {
                        let items = k.items()
                        // Size each top-level item in parallel-friendly chunks
                        let bytes = items.reduce(Int64(0)) { $0 + size(of: $1) }
                        return (k.rawValue, bytes, items)
                    }
                }
                var out: [String: (Int64, [URL])] = [:]
                for await (id, b, i) in group { out[id] = (b, i) }
                return out
            }
            for idx in rows.indices {
                if let r = results[rows[idx].id] { rows[idx].bytes = r.0; rows[idx].items = r.1 }
            }
            free = freeSpace()
            scanning = false
        }
    }

    func clean() {
        let chosen = rows.filter { $0.selected && $0.bytes > 0 }
        let before = chosen.reduce(Int64(0)) { $0 + $1.bytes }
        let startFree = freeSpace()
        cleaning = true
        Task {
            await Task.detached {
                let fm = FileManager.default
                for row in chosen {
                    if row.id == Kind.trash.rawValue {
                        for u in row.items { try? fm.removeItem(at: u) }
                        // Fallback for protected Trash: ask Finder
                        if !((try? fm.contentsOfDirectory(atPath: NSHomeDirectory() + "/.Trash"))?.isEmpty ?? true) {
                            var err: NSDictionary?
                            NSAppleScript(source: "tell application \"Finder\" to empty the trash")?.executeAndReturnError(&err)
                        }
                    } else if row.id == Kind.oldDownloads.rawValue {
                        for u in row.items { try? fm.trashItem(at: u, resultingItemURL: nil) }
                    } else {
                        for u in row.items { try? fm.removeItem(at: u) }
                    }
                }
            }.value
            cleaning = false
            scanning = false
            scan()
            // wait for rescan to finish, then report
            while scanning { try? await Task.sleep(nanoseconds: 100_000_000) }
            let gained = freeSpace() - startFree
            freed = max(gained, 0) > 0 ? gained : before
        }
    }
}

// MARK: - UI

struct ContentView: View {
    @StateObject var m = Model()
    @State private var confirm = false

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text(fmt(m.free)).font(.system(size: 34, weight: .semibold, design: .rounded))
                Text("free of \(fmt(m.total))").font(.callout).foregroundStyle(.secondary)
                ProgressView(value: Double(m.total - m.free), total: Double(max(m.total, 1)))
                    .padding(.horizontal, 40)
            }
            .padding(.top, 8)

            VStack(spacing: 0) {
                ForEach($m.rows) { $row in
                    HStack {
                        Toggle("", isOn: $row.selected).labelsHidden().disabled(row.bytes == 0)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(row.name).fontWeight(.medium)
                            Text(row.detail).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if m.scanning { ProgressView().controlSize(.small) }
                        else { Text(fmt(row.bytes)).monospacedDigit().foregroundStyle(row.bytes == 0 ? .tertiary : .primary) }
                    }
                    .padding(.vertical, 8).padding(.horizontal, 12)
                    if row.id != m.rows.last?.id { Divider() }
                }
            }
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))

            if let f = m.freed {
                Label("Freed \(fmt(f))", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green).font(.headline)
            }

            Button {
                m.freed = nil
                confirm = true
            } label: {
                Text(m.cleaning ? "Cleaning…" : "Clean \(fmt(m.selectedBytes))").frame(maxWidth: .infinity)
            }
            .controlSize(.large).buttonStyle(.borderedProminent)
            .disabled(m.scanning || m.cleaning || m.selectedBytes == 0)
            .confirmationDialog("Clean \(fmt(m.selectedBytes))?", isPresented: $confirm) {
                Button("Clean", role: .destructive) { m.clean() }
            } message: {
                Text("Selected items will be removed. Trash is emptied permanently; old downloads go to Trash.")
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear { m.scan() }
    }
}

@main
struct TidyMacApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
            .windowResizability(.contentSize)
    }
}
