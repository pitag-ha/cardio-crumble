let () = print_endline "Hello, World!"

open Runtime_events

let runtime_counter _domain_id _ts counter _value =
  match counter with
  | EV_C_MINOR_PROMOTED ->
      Midi.(write_output [ message_on ~note:base_note () ]);
      Unix.sleep 5;
      Midi.(write_output [ message_off ~note:base_note () ])
  | _ -> ()

let runtime_begin _domain_id ts = function
  | EV_MAJOR ->
      Midi.(
        write_output [ message_on ~note:third_overtone (* ~volume:'\070' *) () ]);
      Printf.printf "%f: start of EV_MAJOR. ts: %Ld\n" (Sys.time ())
        (Timestamp.to_int64 ts)
      (* outest *)
  | EV_MAJOR_SWEEP -> ()
  (*   print_endline "start of EV_MAJOR_SWEEP" inside EV_MAjOR *)
  | EV_MAJOR_MARK_ROOTS ->
      ()
      (*
      print_endline "start of EV_MAJOR_MARK_ROOTS" (* inside EV_MAJOR *)*)
  | EV_MAJOR_MARK ->
      Midi.(
        write_output [ message_on ~note:fourth_overtone (*~volume:'\060'*) () ]);
      Printf.printf "%f: start of EV_MAJOR_MARK. ts: %Ld\n" (Sys.time ())
        (Timestamp.to_int64 ts)
      (* inside EV_MAJOR *)
  | EV_MINOR ->
      Midi.(write_output [ message_on ~note:first_overtone () ]);
      Printf.printf "%f: start of EV_MINOR. ts: %Ld\n" (Sys.time ())
        (Timestamp.to_int64 ts)
      (* outest *)
  | EV_MINOR_LOCAL_ROOTS ->
      Midi.(
        write_output [ message_on ~note:second_overtone (*~volume:'\070'*) () ]);
      Printf.printf "%f: start of EV_MINOR_LOCAL_ROOTS ts: %Ld\n" (Sys.time ())
        (Timestamp.to_int64 ts)
      (* inside EV_MINOR *)
  | _ -> ()

let runtime_end _domain_id _ts = function
  | EV_MAJOR ->
      (* Midi.(write_output [ message_off ~note:third_overtone ~volume:'\070' () ]); *)
      Printf.printf "%f: end of EV_MAJOR\n" (Sys.time ())
  | EV_MAJOR_SWEEP -> () (* Printf.printf "end of EV_MAJOR_SWEEP\n" *)
  | EV_MAJOR_MARK_ROOTS -> ()
  (* Printf.printf "end of EV_MAJOR_MARK_ROOTS\n" *)
  | EV_MAJOR_MARK ->
      (* Midi.(
         write_output [ message_off ~note:fourth_overtone ~volume:'\060' () ]); *)
      Printf.printf "%f: end of EV_MAJOR_MARK\n" (Sys.time ())
  | EV_MINOR ->
      (* Midi.(write_output [ message_off ~note:first_overtone () ]); *)
      Printf.printf "%f: end of EV_MINOR\n" (Sys.time ())
  | EV_MINOR_LOCAL_ROOTS ->
      (* Midi.(
         write_output [ message_off ~note:second_overtone ~volume:'\070' () ]); *)
      Printf.printf "%f: end of EV_MINOR_LOCAL_ROOTS\n" (Sys.time ())
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
  let cbs = Callbacks.create ~runtime_begin ~runtime_end ~runtime_counter () in
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
      Unix.stdin Unix.stdout Unix.stderr
  in
  Unix.sleepf 1.;
  tracing (Util.child_alive proc) (Some (".", proc));
  print_endline "got to the end";
  let _ = Midi.(write_output [ turn_off_everything ]) in
  ()
