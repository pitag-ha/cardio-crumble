open Runtime_events

let events =
  [
    EV_EXPLICIT_GC_SET;
    EV_EXPLICIT_GC_STAT;
    EV_EXPLICIT_GC_MINOR;
    EV_EXPLICIT_GC_MAJOR;
    EV_EXPLICIT_GC_FULL_MAJOR;
    EV_EXPLICIT_GC_COMPACT;
    EV_MAJOR;
    EV_MAJOR_SWEEP;
    EV_MAJOR_MARK_ROOTS;
    EV_MAJOR_MARK;
    EV_MINOR;
    EV_MINOR_LOCAL_ROOTS;
    EV_MINOR_FINALIZED;
    EV_EXPLICIT_GC_MAJOR_SLICE;
    EV_FINALISE_UPDATE_FIRST;
    EV_FINALISE_UPDATE_LAST;
    EV_INTERRUPT_REMOTE;
    EV_MAJOR_EPHE_MARK;
    EV_MAJOR_EPHE_SWEEP;
    EV_MAJOR_FINISH_MARKING;
    EV_MAJOR_GC_CYCLE_DOMAINS;
    EV_MAJOR_GC_PHASE_CHANGE;
    EV_MAJOR_GC_STW;
    EV_MAJOR_MARK_OPPORTUNISTIC;
    EV_MAJOR_SLICE;
    EV_MAJOR_FINISH_CYCLE;
    EV_MINOR_CLEAR;
    EV_MINOR_FINALIZERS_OLDIFY;
    EV_MINOR_GLOBAL_ROOTS;
    EV_MINOR_LEAVE_BARRIER;
    EV_STW_API_BARRIER;
    EV_STW_HANDLER;
    EV_STW_LEADER;
    EV_MAJOR_FINISH_SWEEPING;
    EV_MINOR_FINALIZERS_ADMIN;
    EV_MINOR_REMEMBERED_SET;
    EV_MINOR_REMEMBERED_SET_PROMOTE;
    EV_MINOR_LOCAL_ROOTS_PROMOTE;
    EV_DOMAIN_CONDITION_WAIT;
    EV_DOMAIN_RESIZE_HEAP_RESERVATION;
  ]

let event_to_int event =
  let rec loop i = function
    | x :: xs -> if x = event then i else loop (i + 1) xs
    | [] -> raise Not_found
  in
  loop 0 events

let event_to_note (tones : Midi.tone) event = tones (event_to_int event)

let handle_control_c device =
  let handle =
    Sys.Signal_handle
      (fun _ ->
        match Midi.shutdown device with
        | Ok _ -> ()
        | Error msg ->
            let s = Midi.error_to_string msg in
            Printf.eprintf "(ctrl-c handler) Error during device shutdown: %s" s;
            exit 1)
  in
  Sys.(signal sigint handle)

let play ~tracing device_id argv =
  let prog, args =
    match argv with
    | prog :: args -> (prog, Array.of_list args)
    | _ -> failwith "No program given"
  in
  let device = Midi.create_device device_id in
  let _ = handle_control_c device in
  (* Extract the user supplied program and arguments. *)
  let proc =
    Unix.create_process_env prog args
      [| "OCAML_RUNTIME_EVENTS_START=1" |]
      Unix.stdin Unix.stdout Unix.stderr
  in
  Unix.sleepf 0.1;
  tracing device (Util.child_alive proc) (Some (".", proc)) (Midi.major 48);
  print_endline "got to the end";
  match Midi.shutdown device with
  | Ok () -> 0
  | Error msg ->
      let s = Midi.error_to_string msg in
      Printf.eprintf "Error during device shutdown: %s" s;
      1

open Cmdliner

let argv = Arg.(non_empty & pos_all string [] & info [] ~docv:"ARGV")

let device_id =
  Arg.(value & opt int 0 & info [ "d"; "device_id" ] ~docv:"DEVICE_ID")
