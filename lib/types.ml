(** Core types and configuration for mempool *)

module Core_types = struct
  (** Basic transaction structure *)
  type transaction = {
      id : string (* Unique identifier for the transaction *)
    ; sender : string (* Address of the sender *)
    ; receiver : string (* Address of the receiver *)
    ; amount : float (* Amount of tokens to be transferred *)
    ; fee : float (* Fee for the transaction *)
    ; timestamp : float (* Timestamp of the transaction *)
  }

  (** Transaction status *)
  type tx_status =
    | Pending
    | Valid
    | Invalid of string

  (** Basic mempool configuration *)
  type config = {
      max_size : int (* Maximum number of transactions *)
    ; min_fee : float (* Minimum fee required *)
    ; max_age : float (* Maximum transaction age in seconds *)
  }

  (** Mempool statistics *)
  type stats = {
      total_transactions : int
    ; pending_transactions : int
    ; invalid_transactions : int
    ; total_fees : float
  }

  (** Default configuration *)
  let default_config =
    {
      max_size = 5_000
    ; (* Store up to 5000 transactions *)
      min_fee = 0.001
    ; (* Minimum fee required *)
      max_age = 3600.0 (* 1 hour maximum age *)
    }
end
