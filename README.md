# Asset-Manager
A CLI application that packs multiple source textures into a single output texture, alongside a JSON file describe the image layout.

Made with:
 - Haxe
 - Packing algorithms from https://github.com/Tw1ddle/Rectangle-Bin-Packing
 - PNG generation with https://github.com/HaxeFoundation/format.
 - CLI flags with https://github.com/haxetink/tink_cli

 Features
 - The ability to watch the filesystem. Adding/removing/editing files triggers texture packing.
 - Simple JSON output.
 - Optional recursive discovery of images in source folder.

```
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
		╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝


    Execute AssetPacker with flags

    Subcommands:
      help : Print help text

  Flags:
           --sourcePath, -p : Directory that source images are located in
      --destinationPath, -o : File path that the packed texture will be written to
             --jsonPath, -j : File path that the JSON describe the sprite layout will be written to
           --deepSearch, -d : Flag to recurse through subdirectories in asset path
                --quiet, -q : Flag to disable logging
                --watch, -w : Flag to continue to watch for changes after packing
             --maxWidth, -x : The maximum width of the output image
            --maxHeight, -y : The maximum height of the output image

```
 