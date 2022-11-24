open! Import
open Result.Syntax
module Event = Portmidi.Portmidi_event

type device = { device_id : int; device : Portmidi.Output_stream.t }

let error_to_string msg =
  Portmidi.Portmidi_error.sexp_of_t msg |> Sexplib0.Sexp.to_string

let () =
  match Portmidi.initialize () with
  | Ok () -> ()
  | Error _e -> failwith "error initializing portmidi"

(* TODO: don't hardcode device_id. get it from the portmidi [get_device] *)
let create_device device_id =
  match Portmidi.open_output ~device_id ~buffer_size:0l ~latency:1l with
  | Error _ ->
      Printf.eprintf "Can't find midi device with id: %i\nIs it connected?\n"
        device_id;
      exit 1
      (* let err = Printf.sprintf "Can't find midi device with id %i.Is it connected?" device_id in failwith err *)
  | Ok device -> { device; device_id }

let message_on ~note ~timestamp ?(volume = '\090') () =
  Event.create ~status:'\144' ~data1:note ~data2:volume ~timestamp

let message_off ~note ~timestamp ?(volume = '\090') () =
  Event.create ~status:'\128' ~data1:note ~data2:volume ~timestamp

let handle_error = function
  | Ok _ -> () (* print_endline "writing midi output should have worked" *)
  | Error _ -> ()
(* print_endline "writing midi output has failed" *)

let turn_off_everything device_id =
  let device = create_device device_id in
  let* _ =
    Portmidi.write_output device.device
      [ Event.create ~status:'\176' ~data1:'\123' ~data2:'\000' ~timestamp:0l ]
  in
  Portmidi.close_output device.device

let write_output { device; _ } msg =
  Portmidi.write_output device msg |> handle_error

type tone = {
  base_note : char;
  first : char;
  second : char;
  third : char;
  fourth : char;
}

let major base_note =
  {
    base_note = Char.chr base_note;
    first = Char.chr @@ (base_note + 2);
    second = Char.chr @@ (base_note + 4);
    third = Char.chr @@ (base_note + 5);
    fourth = Char.chr @@ (base_note + 7);
  }

let overtones base_note =
  {
    base_note = Char.chr base_note;
    first = Char.chr @@ (base_note + 12);
    second = Char.chr @@ (base_note + 19);
    third = Char.chr @@ (base_note + 31);
    fourth = Char.chr @@ (base_note + 35);
  }

let shutdown { device; device_id } =
  let* _ = Portmidi.close_output device in
  Unix.sleepf 0.5;
  turn_off_everything device_id
