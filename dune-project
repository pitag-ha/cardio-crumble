(lang dune 3.3)

(name cardio_crumble)

(generate_opam_files true)

(source
 (github username/reponame))

(authors "Author Name")

(maintainers "Maintainer Name")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name cardio_crumble)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends 
  (ocaml
    (>= 5.0.0))
  dune
  (portmidi
    (>= 0.1))
  (cmdliner
    (>= 1.1.1))
)
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
