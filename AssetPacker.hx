package;

import binpacking.GuillotinePacker;
import binpacking.MaxRectsPacker;
import binpacking.NaiveShelfPacker;
import binpacking.SimplifiedMaxRectsPacker;
import binpacking.Rect;
import binpacking.ShelfPacker;
import binpacking.SkylinePacker;

typedef PlacedImage = {
	var x:Int;
	var y:Int;
	var width:Int;
	var height:Int;
	var bytes:haxe.io.Bytes;
}

class Colour {
	public static var NORMAL = "";
	public static var RESET = "\033[m";
	public static var BOLD = "\033[1m";
	public static var RED = "\033[31m";
	public static var GREEN = "\033[32m";
	public static var YELLOW = "\033[33m";
	public static var BLUE = "\033[34m";
	public static var MAGENTA = "\033[35m";
	public static var CYAN = "\033[36m";
	public static var BOLD_RED = "\033[1;31m";
	public static var BOLD_GREEN = "\033[1;32m";
	public static var BOLD_YELLOW = "\033[1;33m";
	public static var BOLD_BLUE = "\033[1;34m";
	public static var BOLD_MAGENTA = "\033[1;35m";
	public static var BOLD_CYAN = "\033[1;36m";
	public static var BG_RED = "\033[41m";
	public static var BG_GREEN = "\033[42m";
	public static var BG_YELLOW = "\033[43m";
	public static var BG_BLUE = "\033[44m";
	public static var BG_MAGENTA = "\033[45m";
	public static var BG_CYAN = "\033[46m";
}

class AssetPacker {
	public function new() {
		// Set console encoding to show colours and ASCII on Windows.
		if (Sys.systemName() == "Windows") {
			Sys.command("@ECHO OFF >NUL");
			Sys.command("@chcp 65001>NUL");
		}
		Sys.println(Colour.BOLD
			+ Colour.GREEN
			+ "
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
		╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝\n"
			+ Colour.RESET);
		Sys.println("Building assets.\n");

		var dirname = "assets";
		var deepSearch = true;
		var log = true;
		var watch = true;
		var watchTime = .2;
		var maxWidth = 5000;
		var maxHeight = 10000;

		var files:Array<String> = [];
		var folderContents = findAllPngsIn(dirname, deepSearch);
		files = folderContents.pngs;

		if (log) {
			Sys.println("Found " + files.length + " assets.");
		}
		if (folderContents.nonPngs > 0) {
			if (log) {
				Sys.println("Ignoring " + folderContents.nonPngs + " non .png file(s).");
			}
		}
		Sys.println("");

		packImages(files, log, maxWidth, maxHeight);

		var lastWatchCheck = Sys.time();
		var lastFolderStructure = folderContents;

		if (watch) {
			while (true) {
				if ((Sys.time()) - lastWatchCheck > watchTime) {
					var folderContents = findAllPngsIn(dirname, deepSearch);
					if (lastFolderStructure.pngs.length != folderContents.pngs.length) {
						trace("File added/removed, repacking!");
						packImages(folderContents.pngs, false, maxWidth, maxHeight);
						lastWatchCheck = Sys.time();
						lastFolderStructure = folderContents;
						continue;
					} else {
						for (file in folderContents.pngs) {
							if (!sys.FileSystem.exists(file)) {
								Sys.println("File " + file + " removed, skipping.");
								continue;
							}
							if (sys.FileSystem.stat(file).mtime.getTime() / 1000 > lastWatchCheck) {
								Sys.println(Colour.BOLD_CYAN + "Filesystem change at " + file + ", repacking!" + Colour.RESET);
								packImages(folderContents.pngs, false, maxWidth, maxHeight);

								lastWatchCheck = Sys.time();
								lastFolderStructure = folderContents;
							}
						}
					}
				}
			}
		}
	}

	public function packImages(files:Array<String>, log = true, maxWidth:Int, maxHeight:Int) {
		// Packing algorithm packs on a canvas this big.
		var binWidth:Int = maxWidth;
		var binHeight:Int = maxHeight;

		// To crop off unused image space.
		var rightMostPixel = 0;
		var lowestPixel = 0;

		// Packer and output data
		var packer = new SimplifiedMaxRectsPacker(binWidth, binHeight);
		var images = new Array<PlacedImage>();
		var outputData:Array<{
			path:String,
			x:Int,
			y:Int,
			w:Int,
			h:Int
		}> = [];

		var index = 0;
		for (ff in files) {
			index++;
			var path = ff;
			if (log)
				Sys.println(Colour.BOLD_CYAN + "Processing: " + path + Colour.RESET);

			if (!sys.FileSystem.exists(path)) {
				Sys.println("File removed.");
				continue;
			}

			var file:sys.io.FileInput = null;
			var data:format.png.Data = null;
			try {
				file = sys.io.File.read(path, true);
				data = new format.png.Reader(file).read();
			} catch (e:Dynamic) {
				if (file != null)
					file.close();
				Sys.println("Problem reading file " + ff + ", perhaps it is a corrupt png? Error: " + e);
			}
			if (file == null || data == null)
				continue;
			var headerData = format.png.Tools.getHeader(data);
			var bytes = format.png.Tools.extract32(data);
			file.close();

			// Start packing rectangles
			var rectWidth:Int = headerData.width;
			var rectHeight:Int = headerData.height;
			var heuristic:LevelChoiceHeuristic = LevelChoiceHeuristic.MinWasteFit;
			var rect:Rect = packer.insert(rectWidth, rectHeight);
			if (rect == null) {
				if (log)
					Sys.println(Colour.RED + "Failed to pack!" + Colour.RESET);
				continue;
			}
			if (log)
				Sys.println("Placed " + rectWidth + "x" + rectHeight + " image at " + rect.x + ", " + rect.y);

			// Expand image size if need be.
			rightMostPixel = Math.ceil(Math.max(rightMostPixel, rect.x + rectWidth));
			lowestPixel = Math.ceil(Math.max(lowestPixel, rect.y + rectHeight));

			// Record this images placement
			outputData.push({
				x: Math.floor(rect.x),
				y: Math.floor(rect.y),
				w: headerData.width,
				h: headerData.height,
				path: path
			});
			images.push({
				x: Math.floor(rect.x),
				y: Math.floor(rect.y),
				width: headerData.width,
				height: headerData.height,
				bytes: bytes
			});

			// Debug
			var bar = "";
			var barLength = 20;
			for (i in 0...barLength)
				bar += (index / files.length > i / barLength) ? '=' : ' ';

			if (log)
				Sys.println('[' + bar + ']  ' + index + " / " + files.length + "\n");
		}

		// Construct the output image.
		var width = rightMostPixel;
		var height = lowestPixel;
		var bytes = new haxe.io.BytesOutput();

		// Loop through every pixel in image, see if there is an image placed there and
		// get appropriate pixel.
		for (y in 0...height) {
			for (x in 0...width) {
				// col is the colour at this pixel.
				// It's initial value below is the 'background' colour of the packed image.
				var col = colour(255, 255, 255, 0);
				for (image in images) {
					if (x > image.x && y > image.y && x < (image.x + image.width) && y < (image.y + image.height)) {
						var c = get(image.width, image.bytes, x - image.x, y - image.y);
						col = colour(c.r, c.g, c.b, c.a);
					}
				}
				bytes.writeInt32(col);
			}
		}

		// Write out image.
		var outputImage = format.png.Tools.build32BGRA(width, height, bytes.getBytes());
		var outWriter = sys.io.File.write("output.png", true);
		new format.png.Writer(outWriter).write(outputImage);
		outWriter.close();

		// Write out JSON data.
		sys.io.File.saveContent("./data.json", haxe.Json.stringify(outputData));

		Sys.println(Colour.BOLD + "Finished and exported to output.png and data.json" + Colour.RESET);
	}

	function findAllPngsIn(folder:String, deep = true):{pngs:Array<String>, nonPngs:Int} {
		var pngs:Array<String> = [];
		var nonPngs = 0;
		var filesAll = sys.FileSystem.readDirectory(folder);
		for (file in filesAll) {
			if (!sys.FileSystem.exists(folder + "/" + file)) {
				Sys.println("File removed.");
				continue;
			}

			if (file.substr(file.length - 4) == ".png") {
				pngs.push(folder + "/" + file);
			} else {
				if (sys.FileSystem.isDirectory(folder + "/" + file) == false)
					nonPngs++;
			}
			if (deep && sys.FileSystem.isDirectory(folder + "/" + file)) {
				file = "/" + file;
				pngs = pngs.concat(findAllPngsIn(folder + file).pngs);
			}
		}
		return {pngs: pngs, nonPngs: nonPngs};
	}

	// Get pixel at x,y of image. Needs image width and image in haxe bytes.
	function get(w:Int, bytes:haxe.io.Bytes, x, y) {
		var i = ((y * w) + (x)) * 4;
		return {
			r: bytes.get(i + 2),
			g: bytes.get(i + 1),
			b: bytes.get(i),
			a: bytes.get(i + 3)
		};
	}

	// Get hexidecimal representation of colours. Keep in mind this may be a weird for PNG format.
	function colour(r:Int, g:Int, b:Int, a:Int) {
		return ((a) << 24) + (r << 16) + (g << 8) + (b);
	}

	public static function main() {
		new AssetPacker();
	}
}
