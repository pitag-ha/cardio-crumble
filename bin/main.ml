let () = print_endline "Hello, World!"

open Runtime_events

let runtime_counter _domain_id _ts counter _value =
  match counter with
  | EV_C_MINOR_PROMOTED ->
      Midi.(write_output [ message_on ]);
      Unix.sleep 1;
      Midi.(write_output [ message_off ])
  | _ -> ()

let tracing child_alive path_pid =
  let c = create_cursor path_pid in
  let cbs = Callbacks.create ~runtime_counter () in
  while child_alive () do
    ignore (read_poll c cbs None);
    Unix.sleepf 0.1
  done

let () =
  (* Extract the user supplied program and arguments. *)
  let prog, args = Util.prog_args_from_sys_argv Sys.argv in
  let proc =
    Unix.create_process_env prog args
      [| "OCAML_RUNTIME_EVENTS_START=1" |]
      Unix.stdin Util.dev_null_out Util.dev_null_out
  in
  Unix.sleepf 0.1;
  tracing (Util.child_alive proc) (Some (".", proc));
  Printf.printf "\n"
