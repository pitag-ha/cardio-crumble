let prog_args_from_sys_argv argv =
  let length = Array.length argv in
  if length < 1 then failwith "Expected a program with optional arguments"
  else if length = 2 then (argv.(1), [| argv.(1) |])
  else (argv.(1), Array.sub argv 1 (length - 1))

let child_alive child_pid () =
  match Unix.waitpid [ Unix.WNOHANG ] child_pid with
  | 0, _ -> true
  | p, _ when p = child_pid -> false
  | _, _ -> assert false

let words_to_bytes words = words * (Sys.word_size / 8)

let rec pp_int_comma ppf n =
  if n < 1000 then Printf.fprintf ppf "%d" n
  else (
    pp_int_comma ppf (n / 1000);
    Printf.printf ",%03d" (n mod 1000))

let print_stats ~major ~minor_alloc ~minor_prom =
  Printf.printf "major_alloc_shr_req: %a, minor_alloc: %aB, minor prom: %aB\n%!"
    pp_int_comma !major pp_int_comma
    (words_to_bytes !minor_alloc)
    pp_int_comma
    (words_to_bytes !minor_prom)

let dev_null = if Sys.win32 then "nul" else "/dev/null"
let open_null flags = Unix.openfile dev_null flags 0o666
let dev_null_in = open_null [ Unix.O_RDONLY; Unix.O_CLOEXEC ]
let dev_null_out = open_null [ Unix.O_WRONLY; Unix.O_CLOEXEC ]
