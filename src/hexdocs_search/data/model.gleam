import gleam/bool
import gleam/option.{type Option, None, Some}
import gleam/string
import hexdocs_search/data/model/autocomplete.{type Autocomplete}

pub type Model {
  Model(
    packages: List(String),
    search: String,
    displayed: String,
    search_focused: Bool,
    autocomplete: Option(Autocomplete),
  )
}

pub fn new() -> Model {
  Model(
    packages: [],
    search: "",
    displayed: "",
    search_focused: False,
    autocomplete: None,
  )
}

pub fn add_packages(model: Model, packages: List(String)) {
  Model(..model, packages:)
}

pub fn update_search(model: Model, search: String) {
  Model(..model, search:, displayed: search)
  |> autocomplete_packages
}

pub fn focus_search(model: Model) {
  Model(..model, search_focused: True)
  |> autocomplete_packages
}

pub fn blur_search(model: Model) {
  Model(
    ..model,
    search_focused: False,
    autocomplete: None,
    search: model.displayed,
  )
}

pub fn autocomplete_packages(model: Model) {
  let set_packages = fn(p) { Model(..model, autocomplete: p) }
  let no_search = string.is_empty(model.search)
  use <- bool.lazy_guard(when: no_search, return: fn() { set_packages(None) })
  let autocomplete = autocomplete.init(model.packages, model.search)
  set_packages(Some(autocomplete))
}

pub fn select_next_package(model: Model) -> Model {
  let autocomplete = option.map(model.autocomplete, autocomplete.next)
  Model(..model, autocomplete:)
  |> update_displayed
}

pub fn select_previous_package(model: Model) -> Model {
  let autocomplete = option.map(model.autocomplete, autocomplete.previous)
  Model(..model, autocomplete:)
  |> update_displayed
}

fn update_displayed(model: Model) {
  model.autocomplete
  |> option.then(autocomplete.current)
  |> option.map(fn(displayed) { Model(..model, displayed:) })
  |> option.unwrap(Model(..model, displayed: model.search))
}
