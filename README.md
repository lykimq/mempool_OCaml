# Mempool OCaml Implementation

A lightweight and efficient mempool implementation in OCaml for managing blockchain transactions in general. This implementation focuses on transaction validation, fee-based prioritization, and memory management.

## Features

- Transaction validation with configurable rules
- Fee-based transaction prioritization
- Duplicate transaction detection
- Automatic cleanup of expired transactions
- Configurable memory pool size limits
- Comprehensive test suite

## Technical Choices

### Data Structure Selection

The implementation uses OCaml's `Map` module with `String` as the key type for the following reasons:

#### Why Map?
- **Time Complexity**: O(log(n)) for lookups, insertions, and deletions
- **Space Complexity**: O(n) for memory usage
- **Immutability**: While the Map data structure itself is immutable, the mempool record contains mutable fields for transactions and status. This design provides thread-safety for the data structures but requires synchronization for write operations in multi-threaded scenarios. But currently the implementation is for single-threaded application.
- **Ordering**: Guaranteed ordering of transactions

#### Alternative Considerations
1. **Hash Table**
   - Pros: O(1) lookups, lower memory overhead
   - Cons: No guaranteed ordering, mutable data structure, rehashing overhead

2. **Priority Queue**
   - Pros: Natural for fee-based prioritization
   - Cons: Complex status updates, higher memory usage, difficult restructuring

### Architecture Design

The implementation separates transactions and their status for several benefits:

1. **Memory Efficiency**
   - Status tracking without duplicating transaction data
   - Reduced memory footprint for large transaction sets

2. **Performance**
   - O(1) status updates
   - Independent transaction and status management
   - No need to modify transaction data when status changes

3. **Maintainability**
   - Clear separation of concerns
   - Easier to extend status types
   - Simplified transaction validation logic

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
