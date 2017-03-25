# Asset-Manager
A little program to help me manage game assets, for example through texture packing.
Made with haxe, using packing algorithms from https://github.com/Tw1ddle/Rectangle-Bin-Packing and processing PNG's with https://github.com/HaxeFoundation/format.

Still WIP but features:
 - Can (and is set by default to) watch the filesystem. Adding/removing/editing files triggers a repackage.
 - Outputs JSON data with everything needed to redivide original images.
 - Can (and is set by default to) iterate through nested subfolders.
 
 Currently, the project doesn't have a proper CLI, even though it logs extensively. This means that
  - Your assets must be in a folder called 'assets', next to the program.
  - The program will watch the file system until 'control-c'.
  
  Feel free to send feedback, issues, etc!
