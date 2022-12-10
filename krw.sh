#!/bin/sh -e

log() { printf '\033[1;95m%s %b%s\033[m %s\n' "${3:-->}" "\033[m${2:+\033[1;35m}" "$1" "$2" >&2 ; } 
die() { log "$1" "$2" ERROR ; exit "${3:-1}" ; }

install() {
	curl -L https://roblox.com/download/client -o /tmp/roblox.exe || \
		die 'fetching failed'
	
	wine /tmp/roblox.exe
	wineserver -k
}

launch() {
	[ ! -f "$exe" ] && install
	wine "$exe" "$@"
	fpsu
}

dxvk() {
	[ ! -f "$exe" ] && install
	[ ! -d "$thirdparty" ] && mkdir -p "$thirdparty"
	ver=2.0
	file=dxvk-$ver.tar.gz

	curl -L https://github.com/doitsujin/dxvk/releases/download/v$ver/$file -o "$thirdparty"/"$file"
	tar xvf "$thirdparty"/$file -C "$thirdparty"
	
	cp -f "$thirdparty"/dxvk-$ver/x64/*.dll "$WINEPREFIX/drive_c/windows/system32"
	cp -f "$thirdparty"/dxvk-$ver/x32/*.dll "$WINEPREFIX/drive_c/windows/syswow64"
	rm -rfv "$thirdparty"/"$file"
}

fpsu() {
	[ ! -f "$exe" ] && install
	[ ! -d "$thirdparty" ] && mkdir -p "$thirdparty"
	ver=4.4.4
	file=rbxfpsunlocker-x64.zip
	
	# TODO: switch from unzip to gzip
	curl -L https://github.com/axstin/rbxfpsunlocker/releases/download/v$ver/$file -o "$thirdparty"/"$file"
	unzip -o "$thirdparty"/"$file" -d "$thirdparty"
	rm -rfv "$thirdparty"/"$file"
	cd "$cachedir"
	wine "$thirdparty"/rbxfpsunlocker.exe "$@"
}

main() {
	cachedir=$HOME/.cache/krw

	export WINEPREFIX=$HOME/.local/share/krw/wineprefix
	export WINEDLLOVERRIDES='dxdiagn=;winemenubuilder.exe=;d3d10core=n;d3d11=n;d3d9=n;dxgi=n'
	export DXVK_LOG_LEVEL=warn
    export DXVK_LOG_PATH=none
	export DXVK_STATE_CACHE_PATH="$cachedir"

	[ ! -d $dir ] && mkdir -p $dir
	[ ! -d $WINEPREFIX ] && mkdir -p $WINEPREFIX

	exe=$(find $WINEPREFIX -name RobloxPlayerLauncher.exe)
	dir="$HOME/.local/share/krw"
	thirdparty="$dir"/thirdparty

	action=$1
    shift "$(($# != 0))"
	
	case $action in
		d|dxvk) dxvk "$@" ;;
		f|fpsu) fpsu "$@" ;;
		i|install) install "$@" ;;
		k|kill) wineserver -k "$@" ;;
		l|launch) launch "$@" ;;
		r|rm) rm -rfv $dir ;;
		'')
			log 'krw [d|f|i|k|l|r]...'
			log 'dxvk    Install dxvk'
			log 'fpsu    Install rbpxfpsunlocker'
			log 'install Install Roblox'
			log 'kill    Kill wineprefix'
			log 'launch  Launch Roblox'
			log 'rm      Delete wineprefix'
		;;
	esac
}

main "$@"