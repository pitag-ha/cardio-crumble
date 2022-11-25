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

type tone_old = {
  base_note : char;
  first : char;
  second : char;
  third : char;
  fourth : char;
  fifth : char;
  sixth : char;
}

let _major base_note =
  {
    base_note = Char.chr base_note;
    first = Char.chr @@ (base_note + 2);
    second = Char.chr @@ (base_note + 4);
    third = Char.chr @@ (base_note + 5);
    fourth = Char.chr @@ (base_note + 7);
    fifth = Char.chr @@ (base_note + 9);
    sixth = Char.chr @@ (base_note + 11);
  }

type tone = int -> char

let partition note_as_int =
  (*
0 -> (0, 0)
1 -> (0,1)
(...)
6 -> (0,6)
7 -> (1,0)
8 -> (1,1)
*)
  let scale_func = note_as_int mod 7 in
  let octave = (note_as_int - scale_func) / 7 in
  (octave, scale_func)

let major base_note i =
  let octave, scale_func = partition i in
  match scale_func with
  | 0 -> Char.chr @@ (base_note + (12 * octave))
  | 1 -> Char.chr @@ (base_note + 2 + (12 * octave))
  | 2 -> Char.chr @@ (base_note + 4 + (12 * octave))
  | 3 -> Char.chr @@ (base_note + 5 + (12 * octave))
  | 4 -> Char.chr @@ (base_note + 7 + (12 * octave))
  | 5 -> Char.chr @@ (base_note + 9 + (12 * octave))
  | 6 -> Char.chr @@ (base_note + 11 + (12 * octave))
  | _ ->
      failwith "Why on earth is something mod 7 not element of {0,1,2,3,4,5,6}?"

let overtones base_note =
  {
    base_note = Char.chr base_note;
    first = Char.chr @@ (base_note + 12);
    second = Char.chr @@ (base_note + 19);
    third = Char.chr @@ (base_note + 31);
    fourth = Char.chr @@ (base_note + 35);
    fifth = Char.chr base_note;
    (*FIXME*)
    sixth = Char.chr base_note;
    (*FIXME*)
  }

let shutdown { device; device_id } =
  let* _ = Portmidi.close_output device in
  Unix.sleepf 0.5;
  turn_off_everything device_id
