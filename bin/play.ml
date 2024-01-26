let event_to_note tones event = tones (Event.event_to_int event)

let handle_control_c () =
  let handle =
    Sys.Signal_handle (fun _ -> Atomic.set Watchdog.terminate true)
  in
  Sys.(signal sigint handle)

let play ~tracing midi_out channel scale argv =
  Midi.channel := channel - 1;
  let prog, args =
    match argv with
    | prog :: args -> (prog, Array.of_list args)
    | _ -> failwith "No program given"
  in
  let device = Midi.Device.create_output midi_out in
  let _ = handle_control_c () in
  (* Extract the user supplied program and arguments. *)
  let proc =
    Unix.create_process_env prog args
      [| "OCAML_RUNTIME_EVENTS_START=1" |]
      Unix.stdin Unix.stdout Unix.stderr
  in
  Unix.sleepf 0.1;
  tracing device (Util.child_alive proc)
    (Some (".", proc))
    (Midi.Scale.get ~base_note:48 scale);
  print_endline "got to the end";
  match Midi.Device.shutdown device with
  | Ok () -> 0
  | Error msg ->
      let s = Midi.error_to_string msg in
      Printf.eprintf "Error during device shutdown: %s" s;
      1

open Cmdliner

let argv = Arg.(non_empty & pos_all string [] & info [] ~docv:"ARGV")

let midi_out =
  Arg.(value & opt int 0 & info [ "o"; "midi-out" ] ~docv:"DEVICE_ID")

let channel = Arg.(value & opt int 1 & info [ "c"; "channel" ] ~docv:"CHANNEL")

let scale_enum =
  Arg.enum
    [
      ("nice", Midi.Scale.Nice);
      ("major", Midi.Scale.Major);
      ("minor", Midi.Scale.Minor);
      ("pentatonic", Midi.Scale.Pentatonic);
      ("blue", Midi.Scale.Blue);
      ("overtones", Midi.Scale.Overtones);
    ]

let scale =
  Arg.(
    value & opt scale_enum Midi.Scale.Nice & info [ "s"; "scale" ] ~docv:"SCALE")
