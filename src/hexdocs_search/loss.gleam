import gleam
import gleam/dynamic/decode
import gleam/fetch

pub type Loss(a) =
  gleam.Result(a, HexdocsSearchError)

pub type HexdocsSearchError {
  FetchError(fetch.FetchError)
  DecodeError(List(decode.DecodeError))
}
