all: docs

clean:
	rm -r .target Docs

docs:
	luadoc -d Docs Libs_inline/ArcBar/ArcBar.lua

package: Elementary.zip
	release-wowaddon -d -r ./.target

.PHONY: clean docs
