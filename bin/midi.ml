open! Import
open Result.Syntax
module Event = Portmidi.Portmidi_event

let error_to_string msg =
  Portmidi.Portmidi_error.sexp_of_t msg |> Sexplib0.Sexp.to_string

let () =
  match Portmidi.initialize () with
  | Ok () -> ()
  | Error _e -> failwith "error initializing portmidi"

module Device = struct
  type t = { device_id : int; device : Portmidi.Output_stream.t }

  (* TODO: don't hardcode device_id. get it from the portmidi [get_device] *)
  let create device_id =
    match Portmidi.open_output ~device_id ~buffer_size:0l ~latency:1l with
    | Error _ ->
        Printf.eprintf "Can't find midi device with id: %i\nIs it connected?\n"
          device_id;
        exit 1
        (* let err = Printf.sprintf "Can't find midi device with id %i.Is it connected?" device_id in failwith err *)
    | Ok device -> { device; device_id }

  let turn_off_everything device_id =
    let device = create device_id in
    let* _ =
      Portmidi.write_output device.device
        [
          Event.create ~status:'\176' ~data1:'\123' ~data2:'\000' ~timestamp:0l;
        ]
    in
    Portmidi.close_output device.device

  let shutdown { device; device_id } =
    let* _ = Portmidi.close_output device in
    Unix.sleepf 0.5;
    turn_off_everything device_id
end

let message_on ~note ~timestamp ?(volume = '\090') () =
  Event.create ~status:'\144' ~data1:note ~data2:volume ~timestamp

let message_off ~note ~timestamp ?(volume = '\090') () =
  Event.create ~status:'\128' ~data1:note ~data2:volume ~timestamp

(* Best function ever!! <3 *)
let handle_error = function Ok _ -> () | Error _ -> ()

let write_output { Device.device; _ } msg =
  Portmidi.write_output device msg |> handle_error

module Scale = struct
  type t = Major | Minor | Pentatonic | Nice | Blue | Overtones

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
        failwith
          "Why on earth is something mod 7 not element of {0,1,2,3,4,5,6}?"

  let minor base_note i =
    let octave, scale_func = partition i in
    match scale_func with
    | 0 -> Char.chr @@ (base_note + (12 * octave))
    | 1 -> Char.chr @@ (base_note + 2 + (12 * octave)) 
    | 2 -> Char.chr @@ (base_note + 3 + (12 * octave))
    | 3 -> Char.chr @@ (base_note + 5 + (12 * octave))
    | 4 -> Char.chr @@ (base_note + 7 + (12 * octave))
    | 5 -> Char.chr @@ (base_note + 8 + (12 * octave))
    | 6 -> Char.chr @@ (base_note + 10 + (12 * octave))
    | _ ->
        failwith
          "Why on earth is something mod 7 not element of {0,1,2,3,4,5,6}?"

  
  let pentatonic base_note i =
    let octave, scale_func = partition i in
    match scale_func with
    | 0 -> Char.chr @@ (base_note + (12 * octave))
    | 1 -> Char.chr @@ (base_note + 2 + (12 * octave))
    | 2 -> Char.chr @@ (base_note + 4 + (12 * octave))
    | 3 -> Char.chr @@ (base_note + 7 + (12 * octave))
    | 4 -> Char.chr @@ (base_note + 9 + (12 * octave))
    | 5 -> Char.chr @@ (base_note + 12 + (12 * octave))
    | 6 -> Char.chr @@ (base_note + 14 + (12 * octave))
    | _ ->
        failwith
          "Why on earth is something mod 7 not element of {0,1,2,3,4,5,6}?"

  let nice_scale base_note i =
    let octave, scale_func = partition i in
    match scale_func with
    | 0 -> Char.chr @@ (base_note + (12 * octave))
    | 1 -> Char.chr @@ (base_note + 2 + (12 * octave))
    | 2 -> Char.chr @@ (base_note + 3 + (12 * octave))
    | 3 -> Char.chr @@ (base_note + 4 + (12 * octave))
    | 4 -> Char.chr @@ (base_note + 7 + (12 * octave))
    | 5 -> Char.chr @@ (base_note + 9 + (12 * octave))
    | 6 -> Char.chr @@ (base_note + 12 + (12 * octave))
    | _ ->
        failwith
          "Why on earth is something mod 7 not element of {0,1,2,3,4,5,6}?"

  let blue base_note i =
    let octave, scale_func = partition i in
    match scale_func with
    | 0 -> Char.chr @@ (base_note + (12 * octave))
    | 1 -> Char.chr @@ (base_note + 3 + (12 * octave))
    | 2 -> Char.chr @@ (base_note + 5 + (12 * octave))
    | 3 -> Char.chr @@ (base_note + 6 + (12 * octave))
    | 4 -> Char.chr @@ (base_note + 7 + (12 * octave))
    | 5 -> Char.chr @@ (base_note + 10 + (12 * octave))
    | 6 -> Char.chr @@ (base_note + 12 + (12 * octave))
    | _ ->
        failwith
          "Why on earth is something mod 7 not element of {0,1,2,3,4,5,6}?"

  let overtones base_note i =
    let octave, scale_func = partition i in
    match scale_func with
    | 0 -> Char.chr @@ (base_note + (12 * octave))
    | 1 -> Char.chr @@ (base_note + 12 + (12 * octave))
    | 2 -> Char.chr @@ (base_note + 19 + (12 * octave))
    | 3 -> Char.chr @@ (base_note + 31 + (12 * octave))
    | 4 -> Char.chr @@ (base_note + 35 + (12 * octave))
    | 5 -> Char.chr @@ (base_note + (12 * octave)) (*FIXME*)
    | 6 -> Char.chr @@ (base_note + (12 * octave)) (*FIXME*)
    | _ ->
        failwith
          "Why on earth is something mod 7 not element of {0,1,2,3,4,5,6}?"

  let get ~base_note = function
    | Nice -> nice_scale base_note
    | Blue -> blue base_note
    | Major -> major base_note
    | Minor -> minor base_note
    | Pentatonic -> pentatonic base_note
    | Overtones -> overtones base_note
end
