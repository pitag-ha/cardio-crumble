let () =
  while true do
    let _ = String.make 16 'a' in
    Gc.minor ()
  done;
  print_endline "Hello, World!"
