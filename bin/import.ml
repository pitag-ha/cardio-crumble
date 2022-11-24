module Result = struct
  include Result

  module Syntax = struct
    let ( let+ ) x f = Result.map f x
    let ( let* ) x f = Result.bind x f

    let ( let*! ) : 'a 'b 'e. ('a, 'e) t -> ('a -> 'b) -> 'b =
     fun x f -> f (Result.get_ok x)

    let ( >>| ) x f = Result.map f x
    let ( >>= ) x f = Result.bind x f
  end
end
