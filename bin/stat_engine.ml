open Runtime_events
open Cmdliner

let event_table : (Runtime_events.runtime_phase, int) Hashtbl.t =
  Hashtbl.create 32

let event_table_lock = Mutex.create ()

let quantifier_table : (Runtime_events.runtime_phase, int) Hashtbl.t =
  Hashtbl.create 32

let quantifier_table_lock = Mutex.create ()

let add_to_hashtbl tbl lock event =
  Mutex.lock lock;
  (match Hashtbl.find_opt tbl event with
  | Some v -> Hashtbl.add tbl event (v + 1)
  | None -> Hashtbl.add tbl event 1);
  Mutex.unlock lock

let runtime_begin _domain_id _ts event =
  add_to_hashtbl event_table event_table_lock event;
  add_to_hashtbl quantifier_table quantifier_table_lock event

let polling_main_func child_alive path_pid _ =
  let c = create_cursor path_pid in
  let cbs = Callbacks.create ~runtime_begin () in
  while child_alive () do
    ignore (read_poll c cbs None);
    Unix.sleepf 0.1
  done

let rec sequencer_main_func num_beats tones device _ =
  let dom_event =
    Mutex.lock event_table_lock;
    Mutex.lock quantifier_table_lock;
    let current = (None, Float.neg_infinity) in
    let dom, _ =
      List.fold_left
        (fun ((_, current_max) as curr) new_event ->
          match
            ( Hashtbl.find_opt event_table new_event,
              Hashtbl.find_opt quantifier_table new_event )
          with
          | None, _ -> curr
          | Some _, None -> failwith "quantifier table hasn't been updated"
          | Some num_this_beat, Some all_so_far ->
              let average = Float.of_int all_so_far /. Float.of_int num_beats in
              let new_increment =
                100. -. (100. /. average *. Float.of_int num_this_beat)
              in
              if new_increment >= current_max then
                (Some new_event, new_increment)
              else curr)
        current Play.events
    in

    Mutex.unlock event_table_lock;
    Mutex.unlock quantifier_table_lock;
    dom
  in
  let () =
    match dom_event with
    | Some dom_event ->
        Format.printf "dominant event: %s\n%!"
          (Runtime_events.runtime_phase_name dom_event);
        let note = Play.event_to_note tones dom_event in
        Midi.(
          write_output device
            [ message_on ~note ~timestamp:0l (* ~volume:'\070' *) () ])
    | None -> Format.printf "no dominant event!! :cool_cry:\n %!"
  in
  Mutex.lock event_table_lock;
  Hashtbl.clear event_table;
  Mutex.unlock event_table_lock;
  Unix.sleepf 0.3;
  sequencer_main_func (num_beats + 1) tones device ()

let tracing device child_alive path_pid tones =
  let polling_domain = Domain.spawn (polling_main_func child_alive path_pid) in
  let sequencer_domain = Domain.spawn (sequencer_main_func 1 tones device) in
  List.iter Domain.join [ polling_domain; sequencer_domain ]

let stat_play = Play.play ~tracing
let play_t = Term.(const stat_play $ Play.device_id $ Play.argv)
let cmd = Cmd.v (Cmd.info "stat_engine") play_t
