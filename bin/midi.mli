module Event = Portmidi.Portmidi_event

val error_to_string : Portmidi.Portmidi_error.t -> string

module Device :
  sig
    type t
    val create : int -> t
    val shutdown : t -> (unit, Portmidi.Portmidi_error.t) result
  end

val message_on :
  note:char -> timestamp:int32 -> ?volume:char -> unit -> Event.t

val message_off :
  note:char -> timestamp:int32 -> ?volume:char -> unit -> Event.t

val write_output : Device.t -> Portmidi.Portmidi_event.t list -> unit

module Scale :
  sig
    type t = Major | Nice | Blue | Overtones
    val get : base_note:int -> t -> int -> char
  end
