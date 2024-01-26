(* When set to true, all reading threads should stop. *)
let terminate = Atomic.make false

(*
  The watchdog will periodically check that the child process is still alive.
  If the child process is gone, then it will set the terminate atomic variable to true.
  Threads should be checking for this atomic variable periodically, and shut down gracefully.
  Note: It is also possible that the terminate variable is set by a signal handler.
*)
let rec watchdog_func child_alive () =
  Unix.sleepf 0.1;
  match Atomic.get terminate with
  | true -> ()
  | false ->
      if not (child_alive ()) then Atomic.set terminate true
      else watchdog_func child_alive ()
