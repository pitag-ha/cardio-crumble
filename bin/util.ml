(* this file is imported from Patrick Ferris's work at https://github.com/patricoferris/runtime-events-demo/ *)
let child_alive child_pid () =
  match Unix.waitpid [ Unix.WNOHANG ] child_pid with
  | 0, _ -> true
  | p, _ when p = child_pid -> false
  | _, _ -> assert false
