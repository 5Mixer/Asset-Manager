package;

import tink.Cli;
import binpacking.SimplifiedMaxRectsPacker;
import binpacking.Rect;

typedef PlacedImage = {
	var x:Int;
	var y:Int;
	var width:Int;
	var height:Int;
	var bytes:haxe.io.Bytes;
}

typedef OutputSprite = {
	var x:Int;
	var y:Int;
	var width:Int;
	var height:Int;
	var path:String;
}

class AssetPacker {
	/** Directory that source images are located in **/
	@:alias('p')
	public var sourcePath = "assets";

	/** File path that the packed texture will be written to **/
	@:alias('o')
	public var destinationPath = "output.png";

	/** File path that the JSON describe the sprite layout will be written to **/
	@:alias('j')
	public var jsonPath = "sprites.json";

	/** Flag to recurse through subdirectories in asset path **/
	@:alias('d')
	public var deepSearch = false;

	/** Flag to disable logging **/
	@:alias('q')
	public var quiet = false;

	/** Flag to continue to watch for changes after packing **/
	@:alias('w')
	public var watch = false;

	/** The maximum width of the output image**/
	@:alias('x')
	public var maxWidth = 4096;

	/** The maximum height of the output image **/
	@:alias('y')
	public var maxHeight = 4096;

	final watchTimePauseSeconds = 0.2;
	var lastFolderStructure:Array<String>;
	var lastPack = Sys.time();

	public function new() {}

	/** Execute AssetPacker with flags **/
	@:defaultCommand
	public function run() {
		Log.init();
		Log.enabled = !quiet;

		Log.logAsciiArt();

		Log.log("Building assets.\n");

		var pngPaths = findAllPngsIn(sourcePath, deepSearch);

		Log.log("Found " + pngPaths.length + " pngs.");

		packImages(pngPaths);

		lastFolderStructure = pngPaths;

		if (watch) {
			Log.log(Log.Colour.BOLD_BLUE + "Watching for changes");
			watchForChanges();
		}
	}

	/** Print help text **/
	@:command
	public function help() {
		Log.init();
		Log.logAsciiArt();
		Log.log(Cli.getDoc(this));
	}

	function watchForChanges() {
		while (true) {
			var folderContents = findAllPngsIn(sourcePath, deepSearch);
			if (lastFolderStructure.length != folderContents.length) {
				Log.log("File changes detected, repacking");
				packImages(folderContents);
			} else {
				for (file in folderContents) {
					if (!sys.FileSystem.exists(file)) {
						Log.log("File " + file + " removed, skipping.");
						continue;
					}
					if (sys.FileSystem.stat(file).mtime.getTime() / 1000 > lastPack) {
						Log.log(Log.Colour.BOLD_CYAN + "Filesystem change at " + file + ", repacking!");
						packImages(folderContents);
					}
				}
			}
			lastFolderStructure = folderContents.copy();

			Sys.sleep(watchTimePauseSeconds);
		}
	}

	function packImages(filePaths:Array<String>) {
		lastPack = Sys.time();

		// To crop off unused image space.
		var rightMostPixel = 0;
		var lowestPixel = 0;

		// Packer and output data
		var packer = new SimplifiedMaxRectsPacker(maxWidth, maxHeight);
		var images = new Array<PlacedImage>();
		var outputData:Array<OutputSprite> = [];

		var index = 0;
		for (filePath in filePaths) {
			index++;
			Log.log(Log.Colour.BOLD_CYAN + "Processing: " + filePath);

			if (!sys.FileSystem.exists(filePath)) {
				Log.log("File removed.");
				continue;
			}

			var file:sys.io.FileInput = null;
			var data:format.png.Data = null;
			try {
				file = sys.io.File.read(filePath, true);
				data = new format.png.Reader(file).read();
			} catch (e:Dynamic) {
				if (file != null)
					file.close();
				Log.log("Problem reading file " + filePath + ", perhaps it is a corrupt png? Error: " + e);
			}
			if (file == null || data == null)
				continue;
			var headerData = format.png.Tools.getHeader(data);
			var bytes = format.png.Tools.extract32(data);
			file.close();

			// Start packing rectangles
			var rectWidth:Int = headerData.width;
			var rectHeight:Int = headerData.height;
			var rect:Rect = packer.insert(rectWidth, rectHeight);
			if (rect == null) {
				Log.log(Log.Colour.RED + "Failed to pack!");
				continue;
			}
			Log.log("Placed " + rectWidth + "x" + rectHeight + " image at " + rect.x + ", " + rect.y);

			// Expand image size if need be.
			rightMostPixel = Math.ceil(Math.max(rightMostPixel, rect.x + rectWidth));
			lowestPixel = Math.ceil(Math.max(lowestPixel, rect.y + rectHeight));

			// Record this images placement
			outputData.push({
				x: Math.floor(rect.x),
				y: Math.floor(rect.y),
				width: headerData.width,
				height: headerData.height,
				path: filePath
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
				bar += (index / filePaths.length > i / barLength) ? '=' : ' ';

			Log.log('[' + bar + ']  ' + index + " / " + filePaths.length + "\n");
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
		var outWriter = sys.io.File.write(destinationPath, true);
		new format.png.Writer(outWriter).write(outputImage);
		outWriter.close();

		// Write out JSON data.
		sys.io.File.saveContent(jsonPath, haxe.Json.stringify(outputData));

		Log.log(Log.Colour.BOLD + 'Finished and exported to $destinationPath and $jsonPath');
	}

	function findAllPngsIn(folder:String, deep = true):Array<String> {
		var pngs:Array<String> = [];

		if (!sys.FileSystem.exists(folder)) {
			Log.log('Failed to read non-existent directory $folder');
			throw "Cannot pack assets if root directory does not exist";
			return [];
		}

		var directoryPaths = try {
			sys.FileSystem.readDirectory(folder);
		} catch (e:Any) {
			Log.log('Failed to read directory $folder, exception $e');
			throw "Cannot pack assets if root directory cannot be read";
		}

		for (path in directoryPaths) {
			var absolutePath = folder + "/" + path;
			if (!sys.FileSystem.exists(absolutePath)) {
				Log.log("Path removed.");
				continue;
			}

			if (sys.FileSystem.isDirectory(absolutePath)) {
				if (deep) {
					pngs = pngs.concat(findAllPngsIn(absolutePath));
				}
			} else {
				if (path.substr(path.length - 4) == ".png") {
					pngs.push(absolutePath);
				}
			}
		}
		return pngs;
	}

	// Get pixel at x,y of image. Needs image width and image in haxe bytes.
	inline function get(w:Int, bytes:haxe.io.Bytes, x, y) {
		var i = ((y * w) + (x)) * 4;
		return {
			a: bytes.get(i + 3),
			r: bytes.get(i + 2),
			g: bytes.get(i + 1),
			b: bytes.get(i)
		};
	}

	// Get hexidecimal representation of colours. Keep in mind this may be a weird for PNG format.
	inline function colour(r:Int, g:Int, b:Int, a:Int) {
		return ((a) << 24) + (r << 16) + (g << 8) + (b);
	}

	static function main() {
		Cli.process(Sys.args(), new AssetPacker()).handle(Cli.exit);
	}
}
