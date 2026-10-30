# Lightning

Lightning is planned as a text editor. For now, it is an exploration of the Zig
language and does not yet provide editing functionality.

Requires Zig 0.17.0.

## Build and run

```sh
zig build
./zig-out/bin/lightning path/to/file.txt
```

## Install

Build a release executable and install it under your user-local prefix:

```sh
zig build -Doptimize=ReleaseFast --prefix "$HOME/.local"
```

The executable is installed at `~/.local/bin/lightning`. If `~/.local/bin` is on
your `PATH`, run it with `lightning path/to/file.txt`.

## Notes on AI usage
This repo is intentionally coded by hand. AI may be used to plan some things out as I am new to creating text editors and this is my first project in Zig.

Uses:

### As a search engine replacement:
I find AI can quickly get me relevant information better than a search can in some instances. For example I may ask AI how most editors handle very large files and use that as a basis to design my own editor, or ask it if there are common clean patterns in zig that I'm not using that I may leverage. 

### Crud tasks
I may use it for minor crud tasks such as "move this block I wrote into this other file instead", or other menial tasks that don't actually contribute anything to how the repository is written or designed. I often write other classes I need inline as temporary placeholders to compile without fleshing them out, then moving those blocks into separate files to fill them out later. Sometimes I design from the high to the low, so that the high level logic is sound without the helper functions being implemented. Often these functions end up in their own files. Copying and pasting things around files isn't exactly exciting engaging work, and is a great use of AI in my opinion.

### As a learning tool
I may ask it what functions are used to read from a file for example (I am not familiar with zigs standard library yet), small code snippets on how to do things I don't know how to do in zig yet, and then ask questions about how they work before implementing them myself, etc.

### Writing documentation
I may also use it to create documentation, draw architecture diagrams, or do non-code but code-related tasks such as these that I don't like doing myself. AI was used to help create some of this README.

### Notes on AI usage changes
If I extend AI usage in the future I will update this section, but for now it's primarily just a learning tool and not doing any real work.
