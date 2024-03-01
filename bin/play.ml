let event_to_note tones event = tones (Event.event_to_int event)

let handle_control_c () =
  let handle =
    Sys.Signal_handle (fun _ -> Atomic.set Watchdog.terminate true)
  in
  Sys.(signal sigint handle)

let play ~tracing midi_out channel scale argv =
  Midi.channel := channel - 1;
  let dir, pid, child_alive =
    match argv with
    | first_arg :: args ->
        let dir, file =
          My_fpath.(split_base @@ handle_result @@ of_string first_arg)
        in
        if String.equal (My_fpath.get_ext file) ".event" then
          let pid = int_of_string @@ My_fpath.(to_string @@ rem_ext file) in
          (My_fpath.to_string dir, pid, fun () -> true)
        else
          let args = Array.of_list args in
          let pid =
            Unix.create_process_env first_arg args
              [| "OCAML_RUNTIME_EVENTS_START=1" |]
              Unix.stdin Unix.stdout Unix.stderr
          in
          (".", pid, Util.child_alive pid)
    | _ ->
        failwith
          "cardio-crumble expects a positional argument. It can be either the \
           path to the executable you want cardio-crumble to run or the path \
           to the event ring of a running process. In the latter case, the \
           process has to be spawned with OCAML_RUNTIME_EVENTS_START=1 :)"
  in
  let device = Midi.Device.create_output midi_out in
  let _ = handle_control_c () in
  Unix.sleepf 0.1;
  tracing device child_alive
    (Some (dir, pid))
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
