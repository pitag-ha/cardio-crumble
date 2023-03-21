module Event = Portmidi.Portmidi_event
(** [Event] is the entry module of [Portmidi] for synchronous communication. Loads [MIDI] data/messages *)

val error_to_string : Portmidi.Portmidi_error.t -> string
(** [error_to_string] converts [Portmidi_error.t] message to string. *)

module Device :
(** [Device] represents the implementation of the [MIDI device] that receives [MIDI data]. *)

  sig
    type t
    (** [t] is a [Device type] *)
    
    val create : int -> t
    (** [create] returns [Device.t]. Requires [int]-the output [MIDI] device 
    which can be retrieved by [list_devices] command in [cardio-crumble]. On failure, [create] exits the program
    with [exit 1]. *)

    val shutdown : t -> (unit, Portmidi.Portmidi_error.t) result
    (** [shutdown] waits till output queue is empty via [sleepf],
    then closes [portmidi_output] stream. Requires [Device.t] *)

  end

val message_on :
  note:char -> timestamp:int32 -> ?volume:char -> unit -> Event.t
(** [message_on] creates a portmidi message. Where [volume] may be provided.
[message_on] requires [note] and [timestamp]. *)

val message_off :
  note:char -> timestamp:int32 -> ?volume:char -> unit -> Event.t
(** [message_off] creates a portmidi message. Where [volume] may be provided. 
[message_off] requires [note] and [timestamp]. *)

val write_output : Device.t -> Portmidi.Portmidi_event.t list -> unit
(** [write_output] writes a midi_event message to the [output_device]. Returns a unit regardless
of if the message was successfully sent*)

module Scale :
(** [Scale] represents the implementation of the different musical scales *)

  sig
    type t = Major | Nice | Blue | Overtones
    (** [t] is a musical [Scale] - it can either be a [Major], [Nice], [Blue], or [Overtones] scale. *)

    val get : base_note:int -> t -> int -> char
    (** [get] returns the corresponding [char] for either the [Major], [Nice], [Blue] or [Overtones] scale.*)
  end
