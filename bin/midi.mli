module Event = Portmidi.Portmidi_event

val error_to_string : Portmidi.Portmidi_error.t -> string

module Device : sig
  type output
  type input = Portmidi.Input_stream.t

  val create_output : int -> output
  val create_input : int -> input
  val shutdown : output -> (unit, Portmidi.Portmidi_error.t) result
end

val channel : int ref

module Note : sig
  type t = { pitch : char; volume : char }
end

val message_on : note:Note.t -> ?timestamp:int32 -> unit -> Event.t
val message_off : note:Note.t -> ?timestamp:int32 -> unit -> Event.t
val bend_pitch : bend:int -> ?timestamp:int32 -> unit -> Event.t

val control_change : cc:int -> value:int -> ?timestamp:int32 -> unit -> Event.t
(** This helps to send MIDI Control Change messages

    @raise Invalid_argument if [cc] is greater than 119 *)

val write_output : Device.output -> Portmidi.Portmidi_event.t list -> unit

module Scale : sig
  type t = Major | Minor | Pentatonic | Nice | Blue | Overtones

  val get : base_note:int -> t -> int -> Note.t
end
