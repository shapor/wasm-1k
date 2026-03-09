all: plasma.wasm
	@echo "WASM size: $$(wc -c < plasma.wasm) bytes (limit: 1024)"

plasma.wasm: plasma.wat
	wat2wasm $< -o $@
	wasm-opt -Oz $@ -o $@

serve: all
	python3 -m http.server 8080

clean:
	rm -f plasma.wasm

.PHONY: all serve clean
