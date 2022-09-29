module Event = Portmidi.Portmidi_event

let () =
  match Portmidi.initialize () with
  | Ok () -> ()
  | Error _e -> failwith "error initializing portmidi"

(* TODO: don't hardcode device_id. get it from the portmidi [get_device] *)
let device =
  match Portmidi.open_output ~device_id:2 ~buffer_size:0l ~latency:0l with
  | Error _ -> failwith "Is the midi device connected?"
  | Ok device -> device

let message_on =
  Event.create ~status:'\144' ~data1:'\060' ~data2:'\090' ~timestamp:0l

let message_off =
  Event.create ~status:'\128' ~data1:'\060' ~data2:'\090' ~timestamp:0l

let turn_off_everything =
  Event.create ~status:'\176' ~data1:'\123' ~data2:'\000' ~timestamp:0l

let handle_error = function
  | Ok _ -> print_endline "writing midi output should have worked"
  | Error _ -> print_endline "writing midi output has failed"

let write_output msg = Portmidi.write_output device msg |> handle_error
