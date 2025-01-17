open Mempool_OCaml
open Types.Core_types
open Mempool

(** Helper function to create test transactions *)
let create_test_tx ?(id = "test_tx") ?(sender = "alice") ?(receiver = "bob")
    ?(amount = 10.0) ?(fee = 0.1) ?(timestamp = Unix.time ()) () =
  {id; sender; receiver; amount; fee; timestamp}

(** Test cases for mempool functionality *)
let test_create_mempool () =
  let pool = create () in
  let stats = get_stats pool in
  Alcotest.(check int)
    "empty pool has 0 transactions"
    0
    stats.total_transactions

let test_add_valid_transaction () =
  let pool = create () in
  let tx = create_test_tx () in
  match add_transaction pool tx with
  | Ok () ->
    let stats = get_stats pool in
    Alcotest.(check int)
      "pool should have 1 transaction"
      1
      stats.total_transactions ;
    Alcotest.(check bool)
      "transaction should be retrievable"
      true
      (get_transaction pool tx.id <> None)
  | Error msg -> Alcotest.fail ("Failed to add valid transaction: " ^ msg)

let test_add_duplicate_transaction () =
  let pool = create () in
  let tx = create_test_tx () in
  match add_transaction pool tx with
  | Ok () -> (
    match add_transaction pool tx with
    | Ok () -> Alcotest.fail "Should not allow duplicate transaction"
    | Error msg ->
      Alcotest.(check string)
        "should get duplicate error"
        "Transaction already exists"
        msg)
  | Error msg -> Alcotest.fail ("Failed to add initial transaction: " ^ msg)

let test_add_low_fee_transaction () =
  let pool = create () in
  let tx = create_test_tx ~fee:0.0001 () in
  match add_transaction pool tx with
  | Ok () -> Alcotest.fail "Should not accept transaction with low fee"
  | Error msg ->
    Alcotest.(check string) "should get low fee error" "Fee too low" msg

let test_add_old_transaction () =
  let pool = create () in
  (* 2 hours ago *)
  let old_timestamp = Unix.time () -. 7200.0 in
  let tx = create_test_tx ~timestamp:old_timestamp () in
  match add_transaction pool tx with
  | Ok () -> Alcotest.fail "Should not accept old transaction"
  | Error msg ->
    Alcotest.(check string) "should get age error" "Transaction too old" msg

let test_remove_transaction () =
  let pool = create () in
  let tx = create_test_tx () in
  match add_transaction pool tx with
  | Ok () ->
    remove_transaction pool tx.id ;
    let stats = get_stats pool in
    Alcotest.(check int)
      "pool should be empty after removal"
      0
      stats.total_transactions ;
    Alcotest.(check bool)
      "transaction should not be retrievable"
      true
      (get_transaction pool tx.id = None)
  | Error msg ->
    Alcotest.fail ("Failed to add transaction for removal test: " ^ msg)

let test_get_transactions_sorted () =
  let pool = create () in
  let tx1 = create_test_tx ~id:"tx1" ~fee:0.1 () in
  let tx2 = create_test_tx ~id:"tx2" ~fee:0.2 () in
  let tx3 = create_test_tx ~id:"tx3" ~fee:0.3 () in

  List.iter
    (fun tx ->
      match add_transaction pool tx with
      | Ok () -> ()
      | Error msg -> Alcotest.fail ("Failed to add transaction: " ^ msg))
    [tx1; tx2; tx3] ;

  let sorted_txs = get_transactions pool in
  match sorted_txs with
  | [tx_high; tx_mid; tx_low] ->
    Alcotest.(check @@ float 0.0001) "highest fee first" 0.3 tx_high.fee ;
    Alcotest.(check @@ float 0.0001) "middle fee second" 0.2 tx_mid.fee ;
    Alcotest.(check @@ float 0.0001) "lowest fee last" 0.1 tx_low.fee
  | _ -> Alcotest.fail "Wrong number of transactions returned"

let test_cleanup_old_transactions () =
  let pool = create () in
  let current_tx = create_test_tx ~id:"current" () in
  let old_tx =
    create_test_tx ~id:"old" ~timestamp:(Unix.time () -. 7200.0) ()
  in

  match add_transaction pool current_tx with
  | Ok () -> (
    match add_transaction pool old_tx with
    | Ok () ->
      cleanup pool ;
      let stats = get_stats pool in
      Alcotest.(check int)
        "should only have current transaction"
        1
        stats.total_transactions ;
      Alcotest.(check bool)
        "old transaction should be removed"
        true
        (get_transaction pool old_tx.id = None) ;
      Alcotest.(check bool)
        "current transaction should remain"
        true
        (get_transaction pool current_tx.id <> None)
    | Error _ -> ())
  | Error msg -> Alcotest.fail ("Failed to add current transaction: " ^ msg)

let test_mempool_full () =
  (* 2 transactions max *)
  let config = {default_config with max_size = 2} in
  let pool = create ~config () in
  let tx1 = create_test_tx ~id:"tx1" () in
  let tx2 = create_test_tx ~id:"tx2" () in
  let tx3 = create_test_tx ~id:"tx3" () in

  match add_transaction pool tx1 with
  | Ok () -> (
    match add_transaction pool tx2 with
    | Ok () -> (
      match add_transaction pool tx3 with
      | Ok () -> Alcotest.fail "Should not accept transaction when pool is full"
      | Error msg ->
        Alcotest.(check string)
          "should get pool full error"
          "Mempool is full"
          msg)
    | Error msg -> Alcotest.fail ("Failed to add second transaction: " ^ msg))
  | Error msg -> Alcotest.fail ("Failed to add first transaction: " ^ msg)

(** Main test suite *)
let () =
  let open Alcotest in
  run
    "Mempool"
    [
      ( "basic"
      , [
          test_case "create empty mempool" `Quick test_create_mempool
        ; test_case "add valid transaction" `Quick test_add_valid_transaction
        ; test_case
            "reject duplicate transaction"
            `Quick
            test_add_duplicate_transaction
        ; test_case
            "reject low fee transaction"
            `Quick
            test_add_low_fee_transaction
        ; test_case "reject old transaction" `Quick test_add_old_transaction
        ; test_case "remove transaction" `Quick test_remove_transaction
        ; test_case
            "get sorted transactions"
            `Quick
            test_get_transactions_sorted
        ; test_case
            "cleanup old transactions"
            `Quick
            test_cleanup_old_transactions
        ; test_case "reject when pool is full" `Quick test_mempool_full
        ] )
    ]
