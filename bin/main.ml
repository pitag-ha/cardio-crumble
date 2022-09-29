let () = print_endline "Hello, World!"

open Runtime_events

let runtime_counter _domain_id _ts counter _value =
  match counter with
  | EV_C_MINOR_PROMOTED ->
      Midi.(write_output [ message_on ]);
      Unix.sleep 5;
      Midi.(write_output [ message_off ])
  | _ -> ()

let handle_control_c () =
  let handle =
    Sys.Signal_handle
      (fun _ ->
        Midi.(
          write_output [ turn_off_everything ];
          exit 1))
  in
  Sys.(signal sigint handle)

let tracing child_alive path_pid =
  let c = create_cursor path_pid in
  let cbs = Callbacks.create ~runtime_counter () in
  while child_alive () do
    ignore (read_poll c cbs None);
    Unix.sleepf 0.1
  done

let () =
  let _ = handle_control_c () in
  (* Extract the user supplied program and arguments. *)
  let prog, args = Util.prog_args_from_sys_argv Sys.argv in
  let proc =
    Unix.create_process_env prog args
      [| "OCAML_RUNTIME_EVENTS_START=1" |]
      Unix.stdin Util.dev_null_out Util.dev_null_out
  in
  Unix.sleepf 0.1;
  tracing (Util.child_alive proc) (Some (".", proc))
