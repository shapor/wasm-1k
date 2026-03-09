# wasm-1k

Demoscene-style visual demos in hand-crafted WebAssembly, each under 1KB.

Built as an experiment in human-AI collaboration: I directed Claude to write raw WAT (WebAssembly Text format) by hand, iterating on visual quality while staying under strict size limits. No compilers, no Rust, no C — just raw WAT instructions, a single `Math.sin` import, and a canvas.

## The Demos

### Plasma 400B (399 bytes)
The starting point. A rotozoom plasma with 3 interfering sine waves, rotating over time with a rainbow palette. Surprisingly good for under 400 bytes of machine code.

### Plasma 1K (647 bytes)
The 400B version cranked up: 5 sine waves, per-pixel warp distortion, pulsing zoom, wobbling rotation, and a time-cycling rainbow palette. More complex interference patterns, more organic movement.

### Terrain 1K (796 bytes)
A 3D terrain flyover using column-based raycasting. 3 octaves of sine-wave terrain with rainbow coloring, distance fog, and a swaying camera. The most ambitious effect — voxel-style rendering in under 800 bytes.

## How It Works

Each demo is a single WASM function that writes RGBA pixels to shared memory. The architecture is minimal:

- **WASM module**: imports `Math.sin`, exports a memory buffer and a `render(time)` function
- **HTML harness**: creates a 256x256 canvas, calls `render()` each frame, blits the memory buffer via `ImageData`
- **No palette tables**: colors are computed mathematically using phase-shifted sin waves — the same trick that makes the plasma look good also generates the rainbow palette, for zero bytes of data

The key size trick: everything is computed from `sin()`. Terrain height, rotation, zoom, color — it's all sine waves at different frequencies. One import, infinite variety.

## Building

Requires [wabt](https://github.com/WebAssembly/wabt) (`wat2wasm`):

```bash
make        # builds all .wasm files, prints sizes
make serve  # starts a local server on :8080
```

Then open `http://localhost:8080/gallery.html` to see all demos running side by side.

## What I Learned

**WAT is surprisingly writable.** The stack machine model maps well to mathematical expressions — a plasma formula reads almost naturally as nested function calls. The annoying part is the verbosity of `f64.const` (9 bytes each in the binary), which is where most of the size budget goes.

**`wasm-opt -Oz` doesn't help much.** On hand-written WAT that's already tight, the optimizer saved only ~20 bytes. Most of its wins come from simplifying compiler-generated cruft, which doesn't exist here.

**The 1KB limit is generous for 2D effects** but tight for 3D. The plasma fit comfortably in 400 bytes. The terrain needed 800 and still has visual artifacts. A proper tunnel or fractal zoom would likely need the full 1024.

**AI + human iteration works well for this.** Claude wrote the WAT, I evaluated the visual output and directed adjustments. The feedback loop was: write code → build → screenshot → "make it more X" → repeat. The AI handles the tedious byte-level WAT syntax; the human handles aesthetic judgment.

## Size Budget

| Demo | Size | Limit | Headroom |
|------|------|-------|----------|
| Plasma 400B | 399 bytes | 1024 | 625 bytes |
| Plasma 1K | 647 bytes | 1024 | 377 bytes |
| Terrain 1K | 796 bytes | 1024 | 228 bytes |

## License

MIT
