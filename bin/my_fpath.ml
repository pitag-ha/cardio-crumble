include Fpath

let handle_result = function
  | Error (`Msg msg) ->
      let s = Printf.sprintf "Error from Fpath: %s" msg in
      failwith s
  | Ok x -> x
