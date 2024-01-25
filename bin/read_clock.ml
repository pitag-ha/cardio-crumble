type clock_source =
| Internal of int
| External of int

let milestone : (char option * int) Atomic.t = Atomic.make (None, 96)
let clock_iterator = ref 0

let process_event queue device (ev : Portmidi.Portmidi_event.t) =
  let tick () =
    incr clock_iterator;
    let note, note_length = Atomic.get milestone in 
    if !clock_iterator >= note_length then begin
        (match note with
        | Some note -> Midi.(
          write_output device
            [ message_off ~note ~timestamp:0l ~volume:'\090' ~channel:6 () ]);
            print_endline "milestone ended: turn off note"
        | None -> ());
      match Queue.take_opt queue with
      | None -> Atomic.set milestone (None, 96)
      | Some (note, cycles) -> 
        print_endline "milestone started: turn on note";
        Midi.(
          write_output device
            [ message_on ~note ~timestamp:0l ~volume:'\090' ~channel:6 () ]);
        Atomic.set milestone (Some note, cycles);
      clock_iterator := 0
    end
  in
  match ev.message with
  | 0xF8l -> tick ()
  | 0xFCl -> clock_iterator := 0
  | _ -> ()


let external_main input_device_id output_device note_queue =
  let device = Midi.Device.create_input input_device_id in
  let rec aux () =
      if Atomic.get Watchdog.terminate then
        ()
      else
      match Portmidi.read_input ~length:1 device with
      | Ok l -> List.iter (process_event note_queue output_device ) l; aux ()
      | Error _ -> print_endline "oh no"
  in
  aux ()

let clock_domain_main clock_source output_device note_queue () =
  match clock_source with
  | External input_device_id -> external_main input_device_id output_device note_queue
  | Internal _bpm -> assert false