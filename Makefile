.PHONY: all run install clean

all:
	./build.sh

run: all
	open TidyMac.app

install: all
	rm -rf /Applications/TidyMac.app
	cp -R TidyMac.app /Applications/

clean:
	rm -rf TidyMac.app
