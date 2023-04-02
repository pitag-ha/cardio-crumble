module Event = Portmidi.Portmidi_event

val error_to_string : Portmidi.Portmidi_error.t -> string

module Device : sig
  type t

  val create : int -> t
  val shutdown : t -> (unit, Portmidi.Portmidi_error.t) result
end

val message_on :
  note:char -> timestamp:int32 -> volume:char -> channel:int -> unit -> Event.t

val message_off :
  note:char -> timestamp:int32 -> volume:char -> channel:int -> unit -> Event.t

val bend_pitch : bend:int -> timestamp:int32 -> channel:int -> Event.t

val control_change : cc:int -> value:int -> timestamp:int32 -> Event.t
(** This helps to send MIDI Control Change messages

    @raise Invalid_argument if [cc] is greater than 119 *)

val write_output : Device.t -> Portmidi.Portmidi_event.t list -> unit

module Scale : sig
  type t = Major | Minor | Pentatonic | Nice | Blue | Overtones
  type note_data = { note : char; volume : char }

  val get : base_note:int -> t -> int -> note_data
end
