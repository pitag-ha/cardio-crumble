open Runtime_events
open Cmdliner

let event_table : (Runtime_events.runtime_phase, int) Hashtbl.t =
  Hashtbl.create 32

let event_table_lock = Mutex.create ()

let runtime_begin _domain_id _ts event =
  Mutex.lock event_table_lock;
  (match Hashtbl.find_opt event_table event with
  | Some v -> Hashtbl.add event_table event (v + 1)
  | None -> Hashtbl.add event_table event 1);
  Mutex.unlock event_table_lock

let polling_main_func child_alive path_pid _ =
  let c = create_cursor path_pid in
  let cbs = Callbacks.create ~runtime_begin () in
  while child_alive () do
    ignore (read_poll c cbs None);
    Unix.sleepf 0.1
  done

let events =
  [
    EV_MAJOR;
    EV_MAJOR_SWEEP;
    EV_MAJOR_MARK_ROOTS;
    EV_MAJOR_MARK;
    EV_MINOR;
    EV_MINOR_LOCAL_ROOTS;
  ]

let rec sequencer_main_func tones device _ =
  let dom_event =
    Mutex.lock event_table_lock;
    let current = (None, 0) in
    let dom, _ =
      List.fold_left
        (fun ((_, current_max) as curr) new_event ->
          match Hashtbl.find_opt event_table new_event with
          | None -> curr
          | Some num ->
              if num > current_max then (Some new_event, num) else curr)
        current events
    in
    Mutex.unlock event_table_lock;
    dom
  in
  let _ =
    Option.map
      (fun dom_event ->
        match Play.event_to_note tones dom_event with
        | None -> ()
        | Some note ->
            Midi.(
              write_output device
                [ message_on ~note ~timestamp:0l (* ~volume:'\070' *) () ]);
            Printf.printf "%f: start of %s.\n%!" (Sys.time ())
              (Runtime_events.runtime_phase_name dom_event))
      dom_event
  in
  Mutex.lock event_table_lock;
  Hashtbl.clear event_table;
  Mutex.unlock event_table_lock;
  Unix.sleepf 0.3;
  sequencer_main_func tones device ()

let tracing device child_alive path_pid tones =
  let polling_domain = Domain.spawn (polling_main_func child_alive path_pid) in
  let sequencer_domain = Domain.spawn (sequencer_main_func tones device) in
  List.iter Domain.join [ polling_domain; sequencer_domain ]

let stat_play = Play.play ~tracing
let play_t = Term.(const stat_play $ Play.device_id $ Play.argv)
let cmd = Cmd.v (Cmd.info "stat_engine") play_t
