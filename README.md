Lua Iso Tools
=============

[![Lua CI (5.1, 5.2, 5.3, 5.4)](https://github.com/james2doyle/lua-isometric-tools/actions/workflows/lua.yml/badge.svg)](https://github.com/james2doyle/lua-isometric-tools/actions/workflows/lua.yml)

https://github.com/user-attachments/assets/f96188b6-0de3-49a2-bde5-2ded8423b5ab

> A toolkit of functions and classes to help build isometric games with Lua

*Event-driven to work with Raylib or Love2D*
*Works with Lua 5.1+ and Luajit*
*Completely documented with docblocks*
*Fully tested*

### Includes

- `Vector` - a vector class for handling grid-based coordinates
- `Tile` - a tile class for handling tile drawing, events, and textures
- `TileMap` - a tile map class for handling movement, calculating paths, and selecting, replacing, or finding tiles
- `Map (deprecated)` - class for managing tiles, calculating dijkstra paths, and handling movement

### Example

The example is a Love2D project. Just run `love ./example` from the root of the project.

You can then press \` to see the debug overlays

https://gist.github.com/oatmealine/655c9e64599d0f0dd47687c1186de99f
https://stevedonovan.github.io/ldoc/manual/doc.md.html
https://love2d-community.github.io/love-api/

### Formatting

Formatting uses [stylua](https://github.com/JohnnyMorganz/StyLua)

```sh
stylua .
```

### Linting

Linting uses [selene](https://kampfkarren.github.io/selene/selene.html)

```sh
selene .
```

### Tests

Tests use [lester](https://edubart.github.io/lester/) to do all the assertions.

Run a test suite:

```sh
lua tests/map_tests.lua --stop-on-fail
```

Run a single test matching a filter:

```sh
lua tests/tilemap_tests.lua --filter="events"
```

Running all tests:

```sh
find tests/ -name '*.lua' -exec lua {} --stop-on-fail \;
```