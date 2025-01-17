# Mempool OCaml Implementation

A lightweight and efficient mempool implementation in OCaml for managing blockchain transactions in general. This implementation focuses on transaction validation, fee-based prioritization, and memory management.

## Features

- Transaction validation with configurable rules
- Fee-based transaction prioritization
- Duplicate transaction detection
- Automatic cleanup of expired transactions
- Configurable memory pool size limits
- Comprehensive test suite

## Prerequisites

- OCaml (>= 4.14.0)
- Dune (>= 3.0.0)
- Alcotest (for testing)

## Build the project

```bash
dune build
```

## Run the tests

```bash
dune runtest
```

## Format the code

```bash
dune build @fmt --auto-promote
```

## Benchmarks

The project includes performance benchmarks (using `Core_bench`) to measure and optimize critical operations. Benchmarks are located in the `benchmark/` directory and cover:

- Transaction insertion throughput
- Memory usage patterns
- Transaction validation performance
- Priority queue operations

To run the benchmarks:

```bash
cd benchmark
dune build
dune exec bench_mempool.exe
dune exec bench_mempool_advanced.exe
```
