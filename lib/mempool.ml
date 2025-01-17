open Types.Core_types
module TxMap = Map.Make (String)

type t = {
    config : config
  ; mutable transactions : transaction TxMap.t
  ; mutable status_map : tx_status TxMap.t
}

(** Create a new mempool *)
let create ?(config = default_config) () =
  {config; transactions = TxMap.empty; status_map = TxMap.empty}

(** Basic transaction validation *)
let validate_transaction t tx =
  if tx.fee < t.config.min_fee then Invalid "Fee too low"
  else if Unix.time () -. tx.timestamp > t.config.max_age then
    Invalid "Transaction too old"
  else Valid

(** Add transaction to mempool *)
let add_transaction t tx =
  if TxMap.cardinal t.transactions >= t.config.max_size then
    Error "Mempool is full"
  else if TxMap.mem tx.id t.transactions then Error "Transaction already exists"
  else
    let status = validate_transaction t tx in
    match status with
    | Valid ->
      t.transactions <- TxMap.add tx.id tx t.transactions ;
      t.status_map <- TxMap.add tx.id status t.status_map ;
      Ok ()
    | Invalid reason ->
      t.status_map <- TxMap.add tx.id status t.status_map ;
      Error reason
    | Pending ->
      t.transactions <- TxMap.add tx.id tx t.transactions ;
      t.status_map <- TxMap.add tx.id status t.status_map ;
      Ok ()

(** Remove transaction from mempool *)
let remove_transaction t tx_id =
  t.transactions <- TxMap.remove tx_id t.transactions ;
  t.status_map <- TxMap.remove tx_id t.status_map

(** Get transaction by ID *)
let get_transaction t tx_id = TxMap.find_opt tx_id t.transactions

(** Get all valid transactions sorted by fee *)
let get_transactions t =
  TxMap.bindings t.transactions
  |> List.filter (fun (id, _) ->
         match TxMap.find_opt id t.status_map with
         | Some Valid -> true
         | _ -> false)
  |> List.map snd
  |> List.sort (fun tx1 tx2 ->
         compare
           (tx2.fee /. float_of_int (String.length tx2.id))
           (tx1.fee /. float_of_int (String.length tx1.id)))

(** Get mempool statistics *)
let get_stats t =
  let count_status status =
    TxMap.fold
      (fun _ s acc -> if s = status then acc + 1 else acc)
      t.status_map
      0
  in
  let total_fees =
    TxMap.fold (fun _ tx acc -> acc +. tx.fee) t.transactions 0.0
  in
  {
    total_transactions = TxMap.cardinal t.transactions
  ; pending_transactions = count_status Pending
  ; invalid_transactions =
      TxMap.fold
        (fun _ s acc -> match s with Invalid _ -> acc + 1 | _ -> acc)
        t.status_map
        0
  ; total_fees
  }

(** Clean old transactions *)
let cleanup t =
  let current_time = Unix.time () in
  TxMap.iter
    (fun id tx ->
      if current_time -. tx.timestamp > t.config.max_age then
        remove_transaction t id)
    t.transactions
