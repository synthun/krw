#!/bin/sh -e

log() { printf '\033[1;95m%s %b%s\033[m %s\n' "${3:-->}" "\033[m${2:+\033[1;35m}" "$1" "$2" >&2 ; } 
die() { log "$1" "$2" ERROR ; exit "${3:-1}" ; }

install() {
	log install 'fetching install executable'
	curl -L https://roblox.com/download/client -o /tmp/roblox.exe || \
		die install 'fetching failed'
	
	log install 'running install executable' ; wine /tmp/roblox.exe
	log install 'killing wineserver' ; wineserver -k
}

launch() {
	[ ! -f "$exe" ] && die launch 'roblox is not installed'
	log launch 'launching'
	wine "$exe" "$@"
	fpsu
}

dxvk() {
	[ ! -f "$exe" ] && install
	[ ! -d "$thirdparty" ] && mkdir -p "$thirdparty"
	ver=2.0
	file=dxvk-$ver.tar.gz

	log dxvk 'fetching dlls'
	curl -L https://github.com/doitsujin/dxvk/releases/download/v$ver/$file -o "$thirdparty"/"$file" || \
		die dxvk 'fetching failed'
	log dxvk 'extracting dlls'
	tar xvf "$thirdparty"/$file -C "$thirdparty"
	
	log dxvk 'copying dlls'
	cp -vf "$thirdparty"/dxvk-$ver/x64/*.dll "$WINEPREFIX/drive_c/windows/system32"
	cp -vf "$thirdparty"/dxvk-$ver/x32/*.dll "$WINEPREFIX/drive_c/windows/syswow64"
	rm -rf "$thirdparty"/"$file" 
}

fpsu() {
	[ ! -f "$exe" ] && install
	[ ! -d "$thirdparty" ] && mkdir -p "$thirdparty"
	ver=4.4.4
	file=rbxfpsunlocker-x64.zip
	
	# TODO: switch from unzip to gzip
	log fpsu 'fetching rbxfpsunlocker'
	curl -L https://github.com/axstin/rbxfpsunlocker/releases/download/v$ver/$file -o "$thirdparty"/"$file" || \
		die 'fetching failed'
	log fpsu 'unzipping' ; unzip -o "$thirdparty"/"$file" -d "$thirdparty"
	rm -rfv "$thirdparty"/"$file"
	cd "$cachedir"
	log fpsu 'launching rbxfpsunlocker'
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
		k|kill) 
			log 'killing wineserver'
			wineserver -k "$@"
		;;
		l|launch) launch "$@" ;;
		r|rm) rm -rfv $dir ;;
		'')
			log 'krw [d|f|i|k|l|r]...'
			log 'dxvk    Install dxvk'
			log 'fpsu    Install and run rbxfpsunlocker'
			log 'install Install Roblox'
			log 'kill    Kill wineprefix'
			log 'launch  Launch Roblox'
			log 'rm      Delete wineprefix'
		;;
	esac
}

main "$@"