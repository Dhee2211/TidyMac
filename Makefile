.PHONY: all run install clean screenshot

all:
	./build.sh

run: all
	open TidyMac.app

install: all
	rm -rf /Applications/TidyMac.app
	cp -R TidyMac.app /Applications/

screenshot: all
	./TidyMac.app/Contents/MacOS/TidyMac --screenshot docs/screenshot.png

clean:
	rm -rf TidyMac.app
