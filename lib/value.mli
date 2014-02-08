(*
 * Copyright (c) 2013-2014 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

(** Git objects. *)

open Core_kernel.Std

type t =
  | Blob   of Blob.t
  | Commit of Commit.t
  | Tag    of Tag.t
  | Tree   of Tree.t
(** Loose git objects. *)

val sha1: t -> SHA1.t
(** Return the SHA1 of the serialized contents. *)

include Object.S with type t := t

(** {2 Constructors} *)

val commit: Commit.t -> t
(** Cast a commit to an object. *)

val blob: Blob.t -> t
(** Cast a blob to an object. *)

val tree: Tree.t -> t
(** Cast a tree to an object. *)

val tag: Tag.t -> t
(** Cast a tag to an object. *)

(** {2 Successors} *)

type successor =
  [ `Commit of SHA1.t
  | `Tag of string * SHA1.t
  | `Tree of string * SHA1.t ]
(** Value representing object successors:

    - blobs have no successors;
    - commits might have commit successors (in this case, 'ancestors');
    - tags have commit successors;
    - trees have trees and blobs successors.
*)

val succ: successor -> SHA1.t
(** Return the sha1 of a successor object. *)

val mem: succ:(SHA1.t -> successor list Lwt.t) -> SHA1.t -> string list -> bool Lwt.t
(** [mem t sha1 path] check wether we can go from the object named
    [sha1] to an other object following the [path] labels. *)

val find: succ:(SHA1.t -> successor list Lwt.t) -> SHA1.t -> string list -> SHA1.t option Lwt.t
(** [find t sha1 path] returns (if it exists) the object named [sha1]
    to an other object following the [path] labels. *)

val find_exn: succ:(SHA1.t -> successor list Lwt.t) -> SHA1.t -> string list -> SHA1.t Lwt.t
(** [find t sha1 path] returns (if it exists) the object named [sha1]
    to an other object following the [path] labels. Raise [Not_found]
    if no such object exist.*)

(** {2 Inflated values} *)

val add_header: Bigbuffer.t -> Object_type.t -> int -> unit
(** Append the given object header to a buffer.  *)

val add_inflated: Bigbuffer.t -> t -> unit
(** Append the inflated serialization of an object to a buffer.
    Similar to [add], but without deflating the contents. *)

val input_inflated: Mstruct.t -> t
(** Build a value from an inflated contents. *)

val type_of_inflated: Mstruct.t -> Object_type.t
(** Return the type of the inflated object stored in the given
    buffer. *)
