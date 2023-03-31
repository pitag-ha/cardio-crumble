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

let threshold = function
  | 0 -> -20.
  | 1 -> 0.
  | 2 -> 10.
  | 3 -> 20.
  | 4 -> 40.
  | 5 -> 50.
  | _ ->
      Format.printf
        "muahahahahhaha (won't start enumerating at 1 again ;)) \n%!";
      exit 1

let get_increment num_beats event =
  Mutex.lock event_table_lock;
  Mutex.lock quantifier_table_lock;
  let incr =
    match
      ( Hashtbl.find_opt event_table event,
        Hashtbl.find_opt quantifier_table event )
    with
    | None, _ -> Float.neg_infinity
    | Some _, None -> failwith "quantifier table hasn't been updated"
    | Some num_this_beat, Some all_so_far ->
        let average = Float.of_int all_so_far /. Float.of_int num_beats in
        100. -. (100. /. average *. Float.of_int num_this_beat)
  in
  Mutex.unlock event_table_lock;
  Mutex.unlock quantifier_table_lock;
  incr

let rec sequencer_main_func num_beats tones device bpm _ =
  let interesting_stuff =
    let compare e1 e2 =
      Int.neg (Event.compare ~f:(get_increment num_beats) e1 e2)
    in
    let sorted_events = List.sort compare Event.all in
    List.iter
      (fun e ->
        Format.printf "%s: %f\n%!"
          (Runtime_events.runtime_phase_name e)
          (get_increment num_beats e))
      sorted_events;
    print_endline "-------------------";

    let rec loop acc = function
      | hd :: tl ->
          let i = List.length acc in
          if i = 6 then acc
          else
            let new_acc =
              if get_increment num_beats hd > threshold i then Some hd :: acc
              else None :: acc
            in
            loop new_acc tl
      | [] -> acc
    in
    loop [] sorted_events
  in
  let n =
    List.fold_left
      (fun acc -> function Some _ -> acc + 1 | None -> acc)
      0 interesting_stuff
  in
  List.iter
    (function
      | None -> ()
      | Some event ->
          let note = Play.event_to_note tones event in
          Midi.(
            write_output device
              [
                message_on ~note:note.Scale.note ~timestamp:0l
                  ~volume:note.Scale.volume ();
              ]);
          (*FIXME: don't sleep, but use a timestamp*)
          Unix.sleepf (60. /. Float.of_int bpm /. Float.of_int n))
    interesting_stuff;
  Mutex.lock event_table_lock;
  Hashtbl.clear event_table;
  Mutex.unlock event_table_lock;
  (* Unix.sleepf (60. /. Float.of_int bpm); *)
  sequencer_main_func (num_beats + 1) tones device bpm ()

let tracing (bpm : int) device child_alive path_pid tones =
  let polling_domain = Domain.spawn (polling_main_func child_alive path_pid) in
  let sequencer_domain =
    Domain.spawn (sequencer_main_func 1 tones device bpm)
  in
  List.iter Domain.join [ polling_domain; sequencer_domain ]

let bpm = Arg.(value & opt int 120 & info [ "bpm"; "--bpm" ] ~docv:"BPM")
let stat_play bpm = Play.play ~tracing:(tracing bpm)

let play_t =
  Term.(const stat_play $ bpm $ Play.device_id $ Play.scale $ Play.argv)

let cmd = Cmd.v (Cmd.info "stat_engine") play_t
