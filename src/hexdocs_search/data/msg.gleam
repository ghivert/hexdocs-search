import gleam/dynamic/decode
import gleam/hexpm
import gleam/http/response
import gleam/option.{type Option}
import gleam/uri
import hexdocs_search/loss.{type Loss}

pub type Msg {
  ApiReturnedPackageVersions(
    package: String,
    response: Loss(response.Response(hexpm.Package)),
  )
  ApiReturnedPackages(Loss(response.Response(String)))
  ApiReturnedTypesenseSearch(Loss(response.Response(decode.Dynamic)))

  DocumentChangedLocation(location: uri.Uri)
  DocumentRegisteredEventListener(unsubscriber: fn() -> Nil)

  UserToggledDarkMode
  UserClickedGoBack

  UserFocusedSearch
  UserBlurredSearch
  UserEditedSearch(search: String)
  UserClickedAutocompletePackage(package: String)
  UserSelectedNextAutocompletePackage
  UserSelectedPreviousAutocompletePackage
  UserSubmittedSearch

  UserDeletedPackagesFilter(#(String, Option(String)))
  UserSubmittedPackagesFilter
  UserEditedSearchInput(search_input: String)
  UserSubmittedSearchInput
  UserEditedPackagesFilterInput(String)
  UserEditedPackagesFilterVersion(String)
}
