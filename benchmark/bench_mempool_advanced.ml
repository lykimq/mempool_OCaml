open Core_bench
open Mempool_OCaml
open Types.Core_types

(* Helper function to create test transactions *)
let create_test_transactions n =
  List.init n (fun i -> {
    id = "tx" ^ string_of_int i;
    sender = "sender" ^ string_of_int i;
    receiver = "receiver" ^ string_of_int i;
    amount = float_of_int i; (* 1 token *)
    fee = float_of_int (i mod 100) *. 0.01; (* 1% fee *)
    timestamp = Unix.time () +. float_of_int i *. 0.001
  })


(* 1. Benchmark optimal batch sizes *)
let bench_optimal_batch_size () =
  let batch_sizes = [1000; 2000; 3000] in
  List.map (fun size ->
    let mempool = Mempool.create () in
    let transactions = create_test_transactions size in
    Bench.Test.create ~name:(Printf.sprintf "optimal_batch_%d" size) (fun () ->
      List.iter (fun tx -> ignore (Mempool.add_transaction mempool tx)) transactions;
      ignore (Mempool.get_transactions mempool)
    )
  ) batch_sizes

(* Helper function to split a list into two parts *)
let split_at n lst =
  let rec aux i acc rest =
    if i = 0 then (List.rev acc, rest)
    else
      match rest with
      | [] -> (List.rev acc, [])
      | x :: xs -> aux (i - 1) (x :: acc) xs
  in
  aux n [] lst


(* 2. Benchmark batch processing vs single processing *)
let bench_batch_processing () =
  let mempool = Mempool.create () in
  let large_batch_size = 10000 in
  let batch_chunk_size = 1000 in
  let transactions = create_test_transactions large_batch_size in

  let single_process =
    Bench.Test.create ~name:"single_process_10k" (fun () ->
      List.iter (fun tx -> ignore (Mempool.add_transaction mempool tx)) transactions
    ) in

  let batch_process =
    Bench.Test.create ~name:"batch_process_10k_in_1k_chunks" (fun () ->
      let rec process_chunks = function
        | [] -> ()
        | txs ->
            let (chunk, rest) = split_at batch_chunk_size txs in
            List.iter (fun tx -> ignore (Mempool.add_transaction mempool tx)) chunk;
            process_chunks rest
      in
      process_chunks transactions
    ) in
  [single_process; batch_process]

(* 3. Benchmark frequent cleanup operations *)
let bench_frequent_cleanup () =
  let mempool = Mempool.create () in
  let size = 1000 in
  let transactions = create_test_transactions size in
  List.iter (fun tx -> ignore (Mempool.add_transaction mempool tx)) transactions;

  (* 10: very frequent, 50: moderate, 100: low frequency *)
  let cleanup_frequencies = [10; 50; 100] in
  List.map (fun freq ->
    Bench.Test.create ~name:(Printf.sprintf "cleanup_every_%d_tx" freq) (fun () ->
      List.iteri (fun i tx ->
        ignore (Mempool.add_transaction mempool tx);
        if i mod freq = 0 then ignore (Mempool.cleanup mempool)
      ) transactions
    )
  ) cleanup_frequencies

(* Run all benchmarks *)
let () =
  let all_tests = List.concat [
    bench_optimal_batch_size ();
    bench_batch_processing ();
    bench_frequent_cleanup ()
  ] in
  Command_unix.run (Bench.make_command all_tests)
