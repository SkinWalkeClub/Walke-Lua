# Walke Lua

A Luau parser and code beautifier written in pure Lua. Feed it ugly, minified, or decompiled code — one giant line, no spacing, `L0_1`/`L1_1` variable soup — and it hands back clean, indented, one-statement-per-line source you can actually read.

It doesn't regex the text and hope. It runs a real lexer and a recursive-descent parser, builds an AST, and prints that back out. So the formatting is structural, not guessed, and if the input isn't valid Luau it tells you instead of quietly mangling it.

## Load it

```lua
local WalkeLua = loadstring(game:HttpGet("https://raw.githubusercontent.com/SkinWalkeClub/Walke-Lua/main/walkelua.lua"))()

local clean = WalkeLua.safe(source)
print(clean)
```

`safe` never throws — if the code doesn't parse it just returns the original string back plus an error message, so you can drop it straight into a pipeline without wrapping it in `pcall` yourself.

## Typical use

Beautifying whatever your decompiler spat out:

```lua
local src = decompile(game.ReplicatedStorage.SomeModule)
local pretty, err = WalkeLua.safe(src)
if err then
    warn("couldn't parse: " .. err)
else
    writefile("SomeModule_clean.lua", pretty)
end
```

Tabs instead of 4 spaces:

```lua
WalkeLua.safe(src, { indent = "\t" })
```

## Before / after

In:

```lua
local a=1;local b=2 if a<b then print("smaller")else print("bigger")end for i=1,3 do print(i)end
```

Out:

```lua
local a = 1
local b = 2
if a < b then
    print("smaller")
else
    print("bigger")
end
for i = 1, 3 do
    print(i)
end
```

## API

```lua
WalkeLua.beautify(src, opts)  -- returns clean source; THROWS on a syntax error
WalkeLua.safe(src, opts)      -- returns (clean, nil) or (original, errmsg); never throws
WalkeLua.lex(src)             -- returns the raw token list
WalkeLua.parse(tokens)        -- returns the AST
```

`opts.indent` is the indent unit (default `"    "`, four spaces). Pass `"\t"` for tabs or `"  "` for two spaces.

If you're building your own tool, `lex` and `parse` are exposed on purpose — walk the AST, count nodes, rename locals, whatever. The kind of each node is in its `k` field.

## What it handles

Full Lua 5.1 plus the Luau additions you actually hit in dumped scripts:

- compound assignment — `+= -= *= /= %= ^= ..=`
- `continue`
- string interpolation — `` `sum is {a + b}` ``
- `goto` / labels — `::again::`, `goto again`
- long strings and long comments of any level — `[[ ]]`, `[==[ ]==]`
- numbers in every form — hex `0xFF`, floats, exponents, `_` separators
- method calls, chained indexing, multiple assignment/returns, varargs

Operator precedence and right-associativity (`^`, `..`) are done properly, so it re-parenthesizes nothing it doesn't have to and never changes what your code means.

## Honest limits

- **Comments are dropped.** The parser reads them so they don't break anything, but the beautifier prints from the AST and comments aren't in it. Decompiled code has no comments anyway, which is the main thing this is for — but if you run it on your own commented source, the comments won't survive. Keep an original.
- **It reformats, it doesn't rename.** `L0_1` stays `L0_1`. This makes structure readable; it won't guess what a variable was called.
- **Type annotations** (`local x: number`, `-> Type`) aren't parsed. Plain Luau and decompiler output don't emit them, so this is fine for the common case, but hand-written strictly-typed code will error out (and `safe` will just return it untouched).
- Blank lines from the original aren't preserved — output spacing is uniform.

If `beautify` throws or `safe` hands you back your input unchanged, it means the parser genuinely couldn't make sense of the code. That's usually a type annotation, or truncated/corrupt decompiler output.

## License

MIT — Weegee_MLG / The Skin Walke Team.
