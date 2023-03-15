open Runtime_events
open Cmdliner

let starting_time = ref None

let adjust_time ts =
  (* The ints64 representing the duration of a runtime phase are in units of nanoseconds, whereas the ints32 representing the timestamps of midi notes are in units of miliseconds.
     So this function indirectly  multiplies the timestamp by a a factor 1000 (intentionally). *)
  let int64_to_32 i = Int32.of_int @@ Int64.to_int @@ i in
  Option.map
    (fun st ->
      Int64.sub (Timestamp.to_int64 ts) (Timestamp.to_int64 st) |> int64_to_32)
    !starting_time

let runtime_counter device tones _domain_id ts counter _value =
  match counter with
  | EV_C_MINOR_PROMOTED ->
      starting_time := Some ts;
      Midi.(
        let { Scale.note; volume } = tones 0 in
        write_output device
          [ message_on ~note ~timestamp:0l ~volume ~channel:0 () ])
      (* Unix.sleep 5;
         Midi.(write_output [ message_off ~note:base_note () ]) *)
  | _ -> ()

let runtime_begin device tones _domain_id ts event =
  let { Midi.Scale.note; volume } = Play.event_to_note tones event in
  match adjust_time ts with
  | None -> ()
  | Some ts ->
      Midi.(
        write_output device
          [ message_off ~note ~timestamp:ts ~volume ~channel:0 () ]);
      Printf.printf "%f: start of %s. ts: %ld\n%!" (Sys.time ())
        (Runtime_events.runtime_phase_name event)
        ts

let runtime_end device tones _domain_id ts event =
  let { Midi.Scale.note; volume } = Play.event_to_note tones event in
  match adjust_time ts with
  | None -> ()
  | Some ts ->
      Midi.(
        write_output device
          [ message_off ~note ~timestamp:ts ~volume ~channel:0 () ]);
      Printf.printf "%f: start of %s. ts: %ld\n%!" (Sys.time ())
        (Runtime_events.runtime_phase_name event)
        ts

let tracing device child_alive path_pid tones =
  let c = create_cursor path_pid in
  let runtime_begin = runtime_begin device tones in
  let runtime_end = runtime_end device tones in
  let runtime_counter = runtime_counter device tones in
  let cbs = Callbacks.create ~runtime_begin ~runtime_end ~runtime_counter () in
  let watchdog_domain = Domain.spawn (Watchdog.watchdog_func child_alive)  in
  while not (Atomic.get Watchdog.terminate) do
    ignore (read_poll c cbs None);
    Unix.sleepf 0.1
  done;
  Domain.join watchdog_domain

let simple_play = Play.play ~tracing
let play_t = Term.(const simple_play $ Play.device_id $ Play.scale $ Play.argv)
let cmd = Cmd.v (Cmd.info "simple_engine") play_t
