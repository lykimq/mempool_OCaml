.PHONY: all build test bench clean install uninstall doc

all: build

build:
	dune build @install

test:
	dune runtest

bench:
	dune exec benchmark/mempool_bench.exe

clean:
	dune clean

install:
	dune install

uninstall:
	dune uninstall

doc:
	dune build @doc

watch:
	dune build @all -w

.PHONY: format
format:
	dune build @fmt --auto-promote

.PHONY: utop
utop:
	dune utop lib