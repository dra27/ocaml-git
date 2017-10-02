(*
 * Copyright (c) 2013-2017 Thomas Gazagnaire <thomas@gazagnaire.org>
 * and Romain Calascibetta <romain.calascibetta@gmail.com>
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

module type CLIENT =
sig
  type headers
  type body
  type resp
  type meth
  type uri

  type +'a io

  val call : ?headers:headers -> ?body:body -> meth -> uri -> resp io
end

module type FLOW =
sig
  type raw

  type +'a io

  type i = (raw * int * int) option -> unit io
  type o = unit -> (raw * int * int) option io
end

module Lwt_cstruct_flow : FLOW with type raw = Cstruct.t and type +'a io = 'a Lwt.t

module type S =
sig
  module Web : S.WEB
  module Client : CLIENT
    with type headers = Web.HTTP.headers
     and type meth = Web.HTTP.meth
     and type uri = Web.uri
     and type resp = Web.resp
  module Store : Minimal.S
  module Buffer : S.BUFFER

  module Decoder : Smart.DECODER
    with module Hash = Store.Hash

  module PACKDecoder : Unpack.P
    with module Hash = Store.Hash
     and module Inflate = Store.Inflate

  type error =
    [ `Decoder of Decoder.error
    | `DecoderFlow of string
    | `PackDecoder of PACKDecoder.error
    | `Unresolved_object
    | `Apply of string ]

  val pp_error : error Fmt.t

  val clone :
       Store.t
    -> ?headers:Web.HTTP.headers
    -> ?port:int
    -> ?reference:Store.Reference.t
    -> string -> string -> (Store.Hash.t, error) result Lwt.t
end

module Make
    (K : Sync.CAPABILITIES)
    (W : S.WEB with type +'a io = 'a Lwt.t
                and type raw = Cstruct.t
                and type uri = Uri.t
                and type Request.body = Lwt_cstruct_flow.i
                and type Response.body = Lwt_cstruct_flow.o)
    (C : CLIENT with type +'a io = 'a W.io
                 and type headers = W.HTTP.headers
                 and type body = Lwt_cstruct_flow.o
                 and type meth = W.HTTP.meth
                 and type uri = W.uri
                 and type resp = W.resp)
    (G : Minimal.S with type Hash.Digest.buffer = Cstruct.t
                    and type Hash.hex = string)
    (B : S.BUFFER with type raw = string
                   and type fixe = Cstruct.t)
  : S with module Web = W
       and module Client = C
       and module Store = G
       and module Buffer = B
