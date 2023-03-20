module Event = Portmidi.Portmidi_event
(** [Event] is the entry module of [Portmidi] for synchronous communication. Loads [MIDI] data/messages *)

val error_to_string : Portmidi.Portmidi_error.t -> string
(** [error_to_string] returns [Portmidi_error] message if initializing the portmidi library fails *)

module Device :
(** [Device] entails the implementation of the [output_device] *)

  sig
    type t
    (** [t] is a [Device type] having the [device_id] and [device] parameters.
    [device] stores the [midi] stream data *)
    
    val create : int -> t
    (** [create] creates and opens MIDI [output_device], returns [device] and [device_id]. 
    Requires [device_id], [buffer_size], and [latency]. Fails with "can't find midi device with [device_id]" 
    if opening [output_device] throws error i.e if Portmidi.open_output = _ *)

    val shutdown : t -> (unit, Portmidi.Portmidi_error.t) result
    (** [shutdown] waits till output queue is empty via [sleepf],
    then closes [portmidi_output] stream. Requires [device] and [device_id] *)

  end

val message_on :
  note:char -> timestamp:int32 -> ?volume:char -> unit -> Event.t
(** [message_on] creates a portmidi message. Where [volume] may be provided.
[message_on] requires [note] and [timestamp]. *)

val message_off :
  note:char -> timestamp:int32 -> ?volume:char -> unit -> Event.t
(** [message_off] creates a portmidi message. Where [volume] may be provided. 
[message_on] requires [note] and [timestamp]. *)

val write_output : Device.t -> Portmidi.Portmidi_event.t list -> unit
(** [write_output] writes a midi_event message to the [output_device]. Returns a unit for
both cases of a success [ok] or fail [Error] *)

module Scale :
(** [Scale] entails the implementation of the different scales *)

  sig
    type t = Major | Nice | Blue | Overtones
    (** [t] takes any of the [Scale] as a value. *)

    val get : base_note:int -> t -> int -> char
    (** [get] returns the corresponding [base_note] for either the [Major], [Nice], [Blue] or [Overtones] scale.
    Requires [note_as_int] *)
  end
