type clock_source = Internal of int | External of int

let milestone : (Midi.Note.t option * int) Atomic.t = Atomic.make (None, 96)
let clock_iterator = ref 0

let process_event queue device (ev : Portmidi.Portmidi_event.t) =
  let tick () =
    incr clock_iterator;
    let note, note_length = Atomic.get milestone in
    if !clock_iterator >= note_length then (
      (match note with
      | Some note ->
          Midi.(write_output device [ message_off ~note () ]);
          print_endline "milestone ended: turn off note"
      | None -> ());
      match Saturn.Queue.pop_opt queue with
      | None -> Atomic.set milestone (None, 96)
      | Some (note, notes_per_beat) ->
          let cycles = 24 / notes_per_beat in
          print_endline "milestone started: turn on note";
          Midi.(write_output device [ message_on ~note () ]);
          Atomic.set milestone (Some note, cycles);
          clock_iterator := 0)
  in
  match ev.message with
  | 0xF8l -> tick ()
  | 0xFCl -> clock_iterator := 0
  | _ -> ()

let external_main input_device_id output_device note_queue =
  let device = Midi.Device.create_input input_device_id in
  while not (Atomic.get Watchdog.terminate) do
    match Portmidi.read_input ~length:1 device with
    | Ok l -> List.iter (process_event note_queue output_device) l
    | Error _ -> print_endline "oh no"
  done;
  match Portmidi.close_input device with
  | Error _ -> Printf.eprintf "Error while closing input device\n"
  | _ -> ()

let internal_main bpm device note_queue =
  while not (Atomic.get Watchdog.terminate) do
    match Saturn.Queue.pop_opt note_queue with
    | None -> Unix.sleepf (60. /. float_of_int bpm)
    | Some (note, n) ->
        Midi.(write_output device [ message_on ~note () ]);
        Unix.sleepf (60. /. float_of_int bpm /. float_of_int n);
        Midi.(write_output device [ message_off ~note () ])
  done

let clock_func clock_source output_device note_queue () =
  match clock_source with
  | External input_device_id ->
      external_main input_device_id output_device note_queue
  | Internal bpm -> internal_main bpm output_device note_queue
