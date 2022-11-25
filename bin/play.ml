let event_to_note (tones : Midi.tone) event = tones (Event.event_to_int event)

let handle_control_c device =
  let handle =
    Sys.Signal_handle
      (fun _ ->
        match Midi.shutdown device with
        | Ok _ -> ()
        | Error msg ->
            let s = Midi.error_to_string msg in
            Printf.eprintf "(ctrl-c handler) Error during device shutdown: %s" s;
            exit 1)
  in
  Sys.(signal sigint handle)

let play ~tracing device_id argv =
  let prog, args =
    match argv with
    | prog :: args -> (prog, Array.of_list args)
    | _ -> failwith "No program given"
  in
  let device = Midi.create_device device_id in
  let _ = handle_control_c device in
  (* Extract the user supplied program and arguments. *)
  let proc =
    Unix.create_process_env prog args
      [| "OCAML_RUNTIME_EVENTS_START=1" |]
      Unix.stdin Unix.stdout Unix.stderr
  in
  Unix.sleepf 0.1;
  tracing device (Util.child_alive proc) (Some (".", proc)) (Midi.nice_scale 48);
  print_endline "got to the end";
  match Midi.shutdown device with
  | Ok () -> 0
  | Error msg ->
      let s = Midi.error_to_string msg in
      Printf.eprintf "Error during device shutdown: %s" s;
      1

open Cmdliner

let argv = Arg.(non_empty & pos_all string [] & info [] ~docv:"ARGV")

let device_id =
  Arg.(value & opt int 0 & info [ "d"; "device_id" ] ~docv:"DEVICE_ID")
