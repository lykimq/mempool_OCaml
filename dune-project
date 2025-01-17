(lang dune 3.0)

(name mempool_OCaml)

(version 0.1.0)

(generate_opam_files true)

(formatting
 (enabled_for ocaml))

(package
 (name mempool_OCaml)
 (synopsis "Mempool implementation")
 (description "A mempool implementation for blockchain")
 (depends
  (ocaml (>= 4.14.0))
  (dune (>= 3.0.0))
  (alcotest :with-test)
  (ocamlformat :build)))
