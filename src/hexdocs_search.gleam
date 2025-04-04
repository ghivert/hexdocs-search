import gleam/dict
import gleam/dynamic/decode
import gleam/hexpm
import gleam/http/response.{type Response}
import gleam/list
import gleam/option.{Some}
import gleam/pair
import gleam/result
import gleam/string
import grille_pain
import grille_pain/lustre/toast
import hexdocs_search/data/model.{type Model, Model}
import hexdocs_search/data/msg.{type Msg}
import hexdocs_search/effects
import hexdocs_search/loss.{type Loss}
import hexdocs_search/services/hexdocs
import hexdocs_search/setup
import hexdocs_search/view
import lustre
import lustre/effect
import modem

pub fn main() {
  let flags = Nil
  let assert Ok(_) = grille_pain.simple()
  lustre.application(setup.init, update, view.view)
  |> lustre.start("#app", flags)
}

fn update(model: Model, msg: Msg) {
  case msg |> echo {
    msg.ApiReturnedPackageVersions(package, response) ->
      api_returned_package_versions(model, package, response)
    msg.ApiReturnedPackages(response) -> api_returned_packages(model, response)
    msg.ApiReturnedTypesenseSearch(response) ->
      api_returned_typesense_search(model, response)

    msg.DocumentChangedLocation(location:) ->
      document_changed_location(model, location)
    msg.DocumentRegisteredEventListener(unsubscriber:) ->
      document_registered_event_listener(model, unsubscriber)

    msg.UserToggledDarkMode -> #(model, effect.none())
    msg.UserClickedGoBack -> user_clicked_go_back(model)

    msg.UserFocusedSearch -> user_focused_search(model)
    msg.UserBlurredSearch -> model.blur_search(model)

    msg.UserEditedSearch(search:) -> model.update_search(model, search)
    msg.UserClickedAutocompletePackage(package:) ->
      user_clicked_autocomplete_package(model, package)
    msg.UserSelectedNextAutocompletePackage ->
      user_selected_next_autocomplete_package(model)
    msg.UserSelectedPreviousAutocompletePackage ->
      user_selected_previous_autocomplete_package(model)
    msg.UserSubmittedSearch -> user_submitted_search(model)

    msg.UserEditedPackagesFilter(packages_filter_input:) ->
      user_edited_packages_filter(model, packages_filter_input)
    msg.UserEditedSearchInput(search_input:) ->
      user_edited_search_input(model, search_input)
    msg.UserSubmittedPackagesFilter -> user_submitted_packages_filter(model)
    msg.UserSubmittedSearchInput -> user_submitted_search_input(model)
    msg.UserSuppressedPackagesFilter(filter:) ->
      user_suppressed_packages_filter(model, filter)
  }
}

fn api_returned_package_versions(
  model: Model,
  package: String,
  response: Loss(Response(hexpm.Package)),
) -> #(Model, effect.Effect(Msg)) {
  case response {
    Ok(response.Response(status: 200, body:, ..)) -> {
      let package_versions = dict.insert(model.package_versions, package, body)
      let model = Model(..model, package_versions:)
      model.focus_search(model)
    }
    _ -> #(model, toast.error("Server error. Retry later."))
  }
}

fn api_returned_packages(model: Model, response: Loss(Response(String))) {
  case response {
    Ok(response.Response(status: 200, body:, ..)) ->
      body
      |> string.split(on: "\n")
      |> model.add_packages(model, _)
      |> pair.new(effect.none())
    _ -> #(model, toast.error("Server error. Retry later."))
  }
}

fn api_returned_typesense_search(
  model: Model,
  response: Loss(Response(decode.Dynamic)),
) {
  response
  |> result.then(fn(response) {
    response.body
    |> decode.run(hexdocs.typesense_decoder())
    |> result.map_error(loss.DecodeError)
  })
  |> result.map(model.set_search_results(model, _))
  |> result.map(pair.new(_, effect.none()))
  |> result.unwrap(#(model, effect.none()))
}

fn document_changed_location(model: Model, location) {
  model
  |> model.update_route(location)
  |> pair.new(effect.none())
}

fn document_registered_event_listener(model: Model, unsubscriber: fn() -> Nil) {
  let dom_click_unsubscriber = Some(unsubscriber)
  Model(..model, dom_click_unsubscriber:)
  |> pair.new(effect.none())
}

fn user_edited_search_input(model: Model, search_input: String) {
  Model(..model, search_input:)
  |> pair.new(effect.none())
}

fn user_submitted_search_input(model: Model) {
  model.search_input
  |> effects.typesense_search(model.packages_filter)
  |> pair.new(model, _)
}

fn user_focused_search(model: Model) {
  let #(model, effect) = model.focus_search(model)
  let effects = effect.batch([effect, effects.subscribe_blurred_search()])
  #(model, effects)
}

fn user_selected_next_autocomplete_package(model: Model) {
  model
  |> model.select_next_package
  |> pair.new(effect.none())
}

fn user_selected_previous_autocomplete_package(model: Model) {
  model
  |> model.select_previous_package
  |> pair.new(effect.none())
}

fn user_clicked_autocomplete_package(model: Model, package: String) {
  model
  |> model.select_autocomplete_option(package)
  |> model.blur_search
  |> pair.map_second(fn(effects) {
    effect.batch([effects.package_versions(package), effects])
  })
}

fn user_edited_packages_filter(model: Model, packages_filter_input) {
  model
  |> model.set_packages_filter_input(packages_filter_input)
  |> pair.new(effect.none())
}

fn user_clicked_go_back(model: Model) {
  #(model, modem.back(1))
}

fn user_submitted_packages_filter(model: Model) {
  model.packages_filter
  |> list.reverse
  |> list.prepend(model.packages_filter_input)
  |> list.reverse
  |> list.unique
  |> model.set_packages_filter(model, _)
  |> model.set_packages_filter_input("")
  |> pair.new(effect.none())
}

fn user_submitted_search(model: Model) {
  let #(model, effects) = model.blur_search(model)
  let package = model.displayed
  #(model, effect.batch([effects.package_versions(package), effects]))
}

fn user_suppressed_packages_filter(model: Model, filter: String) {
  model.packages_filter
  |> list.filter(fn(f) { f != filter })
  |> model.set_packages_filter(model, _)
  |> pair.new(effect.none())
}
