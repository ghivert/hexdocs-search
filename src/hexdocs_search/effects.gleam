import document
import gleam/function
import gleam/javascript/promise
import hexdocs_search/data/msg
import hexdocs_search/services/hex
import hexdocs_search/services/hexdocs
import lustre/effect

pub fn packages() {
  use dispatch <- effect.from()
  use _ <- function.tap(Nil)
  use response <- promise.map(hexdocs.packages())
  dispatch(msg.ApiReturnedPackages(response))
}

pub fn package_versions(package: String) {
  use dispatch <- effect.from()
  use _ <- function.tap(Nil)
  use response <- promise.map(hex.package_versions(package))
  dispatch(msg.ApiReturnedPackageVersions(response))
}

pub fn subscribe_blurred_search() {
  use dispatch <- effect.from()
  dispatch(
    msg.DocumentRegisteredEventListener({
      use <- document.add_listener()
      dispatch(msg.UserBlurredSearch)
    }),
  )
}
