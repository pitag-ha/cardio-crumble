(* this function is extrated from the Portmidi bindings by Michael Bacarella.
   Licenced under LGPL-2.1-or-later with OCaml-LGPL-linking-exception
   See https://github.com/mbacarella/portmidi *)
open Cmdliner

let list_devices () =
  let num_devices = Portmidi.count_devices () in
  Printf.printf "number of devices: %d\n" num_devices;
  for i = 0 to pred num_devices do
    Printf.printf "device %d\n" i;
    match Portmidi.get_device_info i with
    | None -> Printf.printf "device %d not found\n" i
    | Some di ->
        Printf.printf "      name: %s\n"
          (Option.value ~default:"null" di.Portmidi.Device_info.name);
        Printf.printf " interface: %s\n"
          (Option.value ~default:"null" di.Portmidi.Device_info.interface);
        Printf.printf "     input: %B\n" di.Portmidi.Device_info.input;
        Printf.printf "    output: %B\n" di.Portmidi.Device_info.output
  done;
  Portmidi.terminate ();
  0

let devices_t = Term.(const list_devices $ const ())
let cmd = Cmd.v (Cmd.info "list_devices") devices_t
