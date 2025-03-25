open Core_bench
open Mempool_OCaml
open Types.Core_types

(* Create test transactions with different fees and sizes *)
let create_test_transactions  n =
  List.init n (fun i -> {
    id = "tx" ^ string_of_int i;
    sender = "sender" ^ string_of_int i;
    receiver = "receiver" ^ string_of_int i;
    amount = float_of_int i;
    fee = float_of_int (i mod 100) *. 0.01;
    timestamp = Unix.time () +. float_of_int i *. 0.001
  })

(* Benchmark adding transactions to mempool *)
let bench_add_transactions n =
  let mempool = Mempool.create () in
  let transactions = create_test_transactions n in
    Bench.Test.create ~name:(Printf.sprintf "add_%d_transactions" n) (fun () ->
      List.iter (fun tx ->
        ignore (Mempool.add_transaction mempool tx)) transactions
    )


(* Benchmark getting sorted transactions from mempool *)
let bench_get_sorted_transactions n =
  let mempool = Mempool.create () in
  let transactions = create_test_transactions n in
  List.iter (fun tx -> ignore (Mempool.add_transaction mempool tx)) transactions;
    Bench.Test.create ~name:(Printf.sprintf "get_sorted_transactions_%d" n) (fun () ->
      ignore (Mempool.get_transactions mempool)
    )

(* Benchmark cleanup *)
let bench_cleanup n =
  let mempool = Mempool.create () in
  let transactions = create_test_transactions n in
  List.iter (fun tx -> ignore (Mempool.add_transaction mempool tx)) transactions;
  Bench.Test.create ~name:(Printf.sprintf "cleanup_%d" n) (fun () ->
    ignore (Mempool.cleanup mempool)
  )


(* Run all benchmarks *)
let () =
  let sizes = [100; 1000; 10000] in
 let tests = List.concat_map (fun n -> [
    bench_add_transactions n;
    bench_get_sorted_transactions n;
    bench_cleanup n
  ]) sizes in
  Command_unix.run (Bench.make_command tests)

