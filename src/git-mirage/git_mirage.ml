module Fs = Fs_lwt_mirage
module Net = Net_lwt_mirage

module Ocaml_deflate = Ocaml_deflate
module Ocaml_inflate = Ocaml_inflate
module Sha1 = Sha1

module Make
    (L : Git.S.LOCK with type +'a io = 'a Lwt.t
                     and type key = Fpath.t)
    (Fs : Git.S.FS with type +'a io = 'a Lwt.t
                    and type path = Fpath.t
                    and type File.lock = L.elt
                    and type File.raw = Cstruct.t
                    and type Mapper.raw = Cstruct.t) =
struct
  include Git.Store.Make(Sha1)(Fpath)(L)(Fs)(Ocaml_inflate)(Ocaml_deflate)
end
