import glance
import glance_printer
import gleam/list
import gleam/option.{type Option, None}
import gleam/pair

pub type Segment {
  Segment(String)
  Parameter(name: String, type_: String)
}

pub type Route {
  Route(name: String, path: List(Segment), children: List(Route))
}

pub fn build_ast(routes: List(Route)) {
  let contributes = route_contributes("Route", routes)

  glance.Module(
    imports: [],
    custom_types: contributes.custom_types,
    type_aliases: [],
    constants: [],
    functions: contributes.functions,
  )
}

type Contributes {
  Contributes(
    custom_types: List(glance.Definition(glance.CustomType)),
    functions: List(glance.Definition(glance.Function)),
  )
}

fn route_contributes(name: String, routes: List(Route)) {
  let variant_contributions =
    routes
    |> list.map(route_variant_contributes)

  let variants = list.map(variant_contributions, pair.first)

  let this_custom_type =
    glance.CustomType(
      name:,
      publicity: glance.Public,
      opaque_: False,
      parameters: [],
      variants:,
    )
    |> glance.Definition(attributes: [], definition: _)

  let contributions = variant_contributions |> list.map(pair.second)

  let sub_custom_types =
    contributions |> list.flat_map(fn(c) { c.custom_types })

  let functions = contributions |> list.flat_map(fn(c) { c.functions })

  let custom_types = [this_custom_type, ..sub_custom_types]

  Contributes(custom_types:, functions:)
}

fn route_variant_contributes(route: Route) -> #(glance.Variant, Contributes) {
  let #(contributes, fields) = case route.children {
    [] -> #(Contributes(custom_types: [], functions: []), [])
    _ -> {
      let sub_route_name = route.name <> "Route"
      #(route_contributes(sub_route_name, route.children), [
        glance.LabelledVariantField(
          label: "route",
          item: glance.NamedType(sub_route_name, module: None, parameters: []),
        ),
      ])
    }
  }

  let parameter_fields =
    route.path
    |> list.filter_map(fn(segment) {
      case segment {
        Parameter(name, type_) -> {
          let field =
            glance.LabelledVariantField(
              label: name,
              item: glance.VariableType("String"),
            )

          Ok(field)
        }
        _ -> Error(Nil)
      }
    })

  let fields = fields |> list.append(parameter_fields)

  let variant = glance.Variant(name: route.name, fields:)

  #(variant, contributes)
}

pub fn generate(routes: List(Route)) {
  routes |> build_ast |> glance_printer.print
}
