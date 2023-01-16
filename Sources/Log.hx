package;

class Log {
	public static final Colour = {
		NORMAL: "",
		RESET: "\033[m",
		BOLD: "\033[1m",
		RED: "\033[31m",
		GREEN: "\033[32m",
		YELLOW: "\033[33m",
		BLUE: "\033[34m",
		MAGENTA: "\033[35m",
		CYAN: "\033[36m",
		BOLD_RED: "\033[1;31m",
		BOLD_GREEN: "\033[1;32m",
		BOLD_YELLOW: "\033[1;33m",
		BOLD_BLUE: "\033[1;34m",
		BOLD_MAGENTA: "\033[1;35m",
		BOLD_CYAN: "\033[1;36m",
		BG_RED: "\033[41m",
		BG_GREEN: "\033[42m",
		BG_YELLOW: "\033[43m",
		BG_BLUE: "\033[44m",
		BG_MAGENTA: "\033[45m",
		BG_CYAN: "\033[46m"
	};

	public static var enabled = true;

	public static function init() {
		// Set console encoding to show colours and ASCII on Windows.
		if (Sys.systemName() == "Windows") {
			Sys.command("@ECHO OFF >NUL");
			Sys.command("@chcp 65001>NUL");
		}
	}

	public static function logAsciiArt() {
		Log.log('${Colour.BOLD + Colour.GREEN}
	 █████╗ ███████╗███████╗███████╗████████╗
	██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝
	███████║███████╗███████╗█████╗     ██║
	██╔══██║╚════██║╚════██║██╔══╝     ██║
	██║  ██║███████║███████║███████╗   ██║
	╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝
		███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗ 
		████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
		██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
		██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
		██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
		╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝\n');
	}

	public static function log(str:String) {
		if (enabled) {
			Sys.println(str + Colour.RESET);
		}
	}
}
