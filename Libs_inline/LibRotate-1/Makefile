LUA=lua5.1

all: test docs

clean: 
	rm -R docs

install-dependencies:
	sudo luarocks install busted

test:
	busted --exclude-tags=ignore

test-only:
	busted -t only

docs: LibColor.lua
	luadoc -d docs LibRotate-1.lua

.PHONY: all clean test test-only install-dependencies
