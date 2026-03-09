WASMS = plasma.wasm plasma1k.wasm terrain1k.wasm

all: $(WASMS)
	@for f in $(WASMS); do printf "%-16s %4d bytes\n" $$f $$(wc -c < $$f); done

%.wasm: %.wat
	wat2wasm $< -o $@

serve: all
	python3 -m http.server 8080

clean:
	rm -f $(WASMS)

.PHONY: all serve clean
