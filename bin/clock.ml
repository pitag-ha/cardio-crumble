type clock_source = Internal of int | External of int

module CQueue = struct
  type t = {
    cond : Condition.t;
    mutex : Mutex.t;
    queue : (Midi.Note.t * int) Queue.t;
  }

  let create () =
    let queue = Queue.create () in
    let mutex = Mutex.create () in
    let cond = Condition.create () in
    { queue; cond; mutex }
end

let milestone : (Midi.Note.t option * int) Atomic.t = Atomic.make (None, 96)
let clock_iterator = ref 0

let process_event { CQueue.queue; cond; _ } device
    (ev : Portmidi.Portmidi_event.t) =
  let tick () =
    incr clock_iterator;
    let note, note_length = Atomic.get milestone in
    if !clock_iterator >= note_length then (
      (match note with
      | Some note -> Midi.(write_output device [ message_off ~note () ])
      | None -> ());
      match Queue.take_opt queue with
      | None ->
          Condition.signal cond;
          Atomic.set milestone (None, 1)
      | Some (note, notes_per_beat) ->
          let cycles = 24 / notes_per_beat in
          Midi.(write_output device [ message_on ~note () ]);
          Atomic.set milestone (Some note, cycles);
          clock_iterator := 0;
          if Queue.is_empty queue then Condition.signal cond)
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
  Condition.signal note_queue.CQueue.cond;
  match Portmidi.close_input device with
  | Error _ -> Printf.eprintf "Error while closing input device\n"
  | _ -> ()

let internal_main bpm device { CQueue.queue; cond; _ } =
  while not (Atomic.get Watchdog.terminate) do
    match Queue.take_opt queue with
    | None ->
        Condition.signal cond;
        Unix.sleepf 0.01
    | Some (note, n) ->
        Midi.(write_output device [ message_on ~note () ]);
        Unix.sleepf (60. /. float_of_int bpm /. float_of_int n);
        Midi.(write_output device [ message_off ~note () ]);
        if Queue.is_empty queue then Condition.signal cond
  done;
  Condition.signal cond

let clock_func clock_source output_device note_queue () =
  match clock_source with
  | External input_device_id ->
      external_main input_device_id output_device note_queue
  | Internal bpm -> internal_main bpm output_device note_queue
