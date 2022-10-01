module Event = Portmidi.Portmidi_event

let () =
  match Portmidi.initialize () with
  | Ok () -> ()
  | Error _e -> failwith "error initializing portmidi"

(* TODO: don't hardcode device_id. get it from the portmidi [get_device] *)
let create_device () =
  match Portmidi.open_output ~device_id:2 ~buffer_size:0l ~latency:1l with
  | Error _ -> failwith "Is the midi device connected?"
  | Ok device -> device

let buffer_device = create_device ()

let message_on ~note ~timestamp ?(volume = '\090') () =
  Event.create ~status:'\144' ~data1:note ~data2:volume ~timestamp

let message_off ~note ~timestamp ?(volume = '\090') () =
  Event.create ~status:'\128' ~data1:note ~data2:volume ~timestamp

let handle_error = function
  | Ok _ -> () (* print_endline "writing midi output should have worked" *)
  | Error _ -> ()
(* print_endline "writing midi output has failed" *)

let turn_off_everything () =
  let turn_off_device = create_device () in
  Portmidi.write_output turn_off_device
    [ Event.create ~status:'\176' ~data1:'\123' ~data2:'\000' ~timestamp:0l ]
  |> handle_error

let write_output msg = Portmidi.write_output buffer_device msg |> handle_error


type tone = {
  base_note : char;
  first : char;
  second : char;
  third : char;
  fourth : char;
}

let major base_note = {
  base_note = Char.chr base_note;
  first = Char.chr @@ base_note + 2;
  second = Char.chr @@ base_note + 4;
  third = Char.chr @@ base_note + 5;
  fourth = Char.chr @@ base_note + 7;
}

let overtones base_note = {
  base_note = Char.chr base_note;
  first = Char.chr @@ base_note + 12;
  second = Char.chr @@ base_note + 19;
  third = Char.chr @@ base_note + 31;
  fourth = Char.chr @@ base_note + 35;
}

let shutdown () =
  let _ = Portmidi.close_output buffer_device in
  Unix.sleepf 0.5;
  turn_off_everything ()