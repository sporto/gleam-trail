import glance
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import justin
import trail/types.{type RouteTree}

pub fn build(routes: List(RouteTree)) {
  let contributes = build_route([], "Route", routes)

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

fn get_custom_types(c: Contributes) {
  c.custom_types
}

fn get_functions(c: Contributes) {
  c.functions
}

fn merge(a: Contributes, others: List(Contributes)) {
  let other_custom_types = others |> list.flat_map(get_custom_types)
  let other_functions = others |> list.flat_map(get_functions)

  let custom_types =
    a.custom_types
    |> list.append(other_custom_types)

  let functions = a.functions |> list.append(other_functions)

  Contributes(custom_types:, functions:)
}

fn build_route(ancestors: List(String), name: String, routes: List(RouteTree)) {
  let #(variants, variant_contributions) =
    routes
    |> list.map(build_route_variant(ancestors, _))
    |> list.unzip

  let this_custom_type =
    glance.CustomType(
      name:,
      publicity: glance.Public,
      opaque_: False,
      parameters: [],
      variants:,
    )
    |> glance.Definition(attributes: [], definition: _)

  let this_contributions =
    Contributes(custom_types: [this_custom_type], functions: [])

  merge(this_contributions, variant_contributions)
}

fn build_route_variant(
  ancestors: List(String),
  route: RouteTree,
) -> #(glance.Variant, Contributes) {
  let ancestors_with_this = ancestors |> list.append([route.name])

  let variant_name = make_variant_name(ancestors_with_this)

  let #(sub_route_contributes, sub_route_fields) = case route {
    types.RouteNode(_, _) -> {
      #(Contributes(custom_types: [], functions: []), [])
    }
    types.RouteTree(_, _, _) -> {
      let sub_route_name = variant_name <> "Route"

      let sub_route_contributes =
        build_route(ancestors_with_this, sub_route_name, route.children)

      let sub_route_fields = [
        glance.LabelledVariantField(
          label: "route",
          item: glance.NamedType(sub_route_name, module: None, parameters: []),
        ),
      ]

      #(sub_route_contributes, sub_route_fields)
    }
  }

  let parameter_fields =
    route.path
    |> list.filter_map(fn(segment) {
      case segment {
        types.Parameter(name, type_) -> {
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

  let fields = sub_route_fields |> list.append(parameter_fields)

  let variant = glance.Variant(name: variant_name, fields:)

  let this_variant_function_to_path = case route {
    types.RouteNode(_, _) -> {
      let name = make_path_name(ancestors_with_this) <> "_path"
      [
        glance.Function(
          name:,
          publicity: glance.Public,
          parameters: [],
          return: Some(glance.VariableType("Route")),
          body: [],
          location: glance.Span(0, 0),
        )
        |> glance.Definition(attributes: [], definition: _),
      ]
    }
    _ -> []
  }

  let this_contributes =
    Contributes(custom_types: [], functions: this_variant_function_to_path)

  let contributes = merge(this_contributes, [sub_route_contributes])

  #(variant, contributes)
}

fn make_path_name(path) {
  path
  |> string.join("_")
  |> string.lowercase
}

fn make_variant_name(path) {
  path
  |> string.join("_")
  |> justin.pascal_case
}
