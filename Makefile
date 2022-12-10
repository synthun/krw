.POSIX:

install:
	mkdir -p /usr/bin
	cp -f krw.sh /usr/bin/krw

mime:
	mkdir -p $(HOME)/.local/share/applications
	cp -f krw.desktop $(HOME)/.local/share/applications
	xdg-mime default krw.desktop x-scheme-handler/roblox-player
