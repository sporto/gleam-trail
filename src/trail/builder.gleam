import glance
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import justin
import trail/types.{type RouteTree}

pub fn build(routes: List(RouteTree)) {
  let contributes = build_route([], "Route", routes)

  let custom_types =
    contributes.custom_types
    |> list.map(custom_type_to_glance)

  let functions =
    contributes.functions
    |> list.map(function_to_glance)

  glance.Module(
    imports: [],
    custom_types:,
    type_aliases: [],
    constants: [],
    functions:,
  )
}

type CustomType {
  CustomType(name: String, variants: List(Variant))
}

fn custom_type_to_glance(
  custom_type: CustomType,
) -> glance.Definition(glance.CustomType) {
  let variants =
    custom_type.variants
    |> list.map(variant_to_glance)

  glance.CustomType(
    name: custom_type.name,
    publicity: glance.Public,
    opaque_: False,
    parameters: [],
    variants:,
  )
  |> glance.Definition([], _)
}

type Variant {
  Variant(name: String, fields: List(VariantField))
}

fn variant_to_glance(variant: Variant) -> glance.Variant {
  let fields = variant.fields |> list.map(variant_field_to_glance)
  glance.Variant(name: variant.name, fields:)
}

type VariantField {
  VariantField(item: String, label: String)
}

fn variant_field_to_glance(field: VariantField) {
  glance.LabelledVariantField(
    item: glance.VariableType(field.item),
    label: field.label,
  )
}

type Function {
  Function(name: String, parameters: List(FunctionParameter), body: Expression)
}

fn function_to_glance(fun: Function) {
  let body = [glance.Expression(expression_to_glance(fun.body))]

  glance.Function(
    name: fun.name,
    publicity: glance.Public,
    parameters: [],
    return: Some(glance.VariableType("Route")),
    body:,
    location: glance.Span(0, 0),
  )
  |> glance.Definition(attributes: [], definition: _)
}

type FunctionParameter {
  FunctionParameter(name: String, type_: String)
}

type Expression {
  Literal(String)
  Pipe(left: Expression, right: Expression)
}

fn expression_to_glance(exp: Expression) {
  case exp {
    Literal(val) -> glance.Variable(val)
    Pipe(left, right) ->
      glance.BinaryOperator(
        glance.Pipe,
        left: expression_to_glance(left),
        right: expression_to_glance(right),
      )
  }
}

type Contributes {
  Contributes(custom_types: List(CustomType), functions: List(Function))
}

type Ancestor {
  Ancestor(name: String, fields: List(VariantField))
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

fn build_route(ancestors: List(Ancestor), name: String, routes: List(RouteTree)) {
  let #(variants, variant_contributions) =
    routes
    |> list.map(build_route_variant(ancestors, _))
    |> list.unzip

  let this_custom_type = CustomType(name:, variants:)

  let this_contributions =
    Contributes(custom_types: [this_custom_type], functions: [])

  merge(this_contributions, variant_contributions)
}

fn build_route_variant(
  ancestors: List(Ancestor),
  route: RouteTree,
) -> #(Variant, Contributes) {
  let parameter_fields =
    route.path
    |> list.filter_map(fn(segment) {
      case segment {
        types.Parameter(name, type_) -> {
          let field = VariantField(label: name, item: "String")

          Ok(field)
        }
        _ -> Error(Nil)
      }
    })

  let ancestors_and_this =
    ancestors |> list.append([Ancestor(route.name, parameter_fields)])

  let variant_name = make_variant_name(ancestors_and_this)

  let #(sub_route_contributes, sub_route_fields) = case route {
    types.RouteNode(_, _) -> {
      #(Contributes(custom_types: [], functions: []), [])
    }
    types.RouteTree(_, _, _) -> {
      let sub_route_name = variant_name <> "Route"

      let sub_route_contributes =
        build_route(ancestors_and_this, sub_route_name, route.children)

      let sub_route_fields = [
        VariantField(label: "route", item: sub_route_name),
      ]

      #(sub_route_contributes, sub_route_fields)
    }
  }

  let fields = sub_route_fields |> list.append(parameter_fields)

  let variant = Variant(name: variant_name, fields:)

  let this_variant_functions = case route {
    types.RouteNode(_, _) -> {
      [make_route_fn(ancestors_and_this)]
    }
    _ -> []
  }

  let this_contributes =
    Contributes(custom_types: [], functions: this_variant_functions)

  let contributes = merge(this_contributes, [sub_route_contributes])

  #(variant, contributes)
}

fn make_path_name(ancestors: List(Ancestor)) {
  ancestors
  |> list.map(fn(a) { a.name })
  |> string.join("_")
  |> string.lowercase
}

fn make_variant_name(ancestors: List(Ancestor)) {
  ancestors
  |> list.map(fn(a) { a.name })
  |> string.join("_")
  |> justin.pascal_case
}

fn make_route_fn(ancestors: List(Ancestor)) {
  let name = make_path_name(ancestors) <> "_route"

  let make_ancestor = fn(ancestor: Ancestor) {
    case ancestor.fields {
      [] -> Literal(ancestor.name)
      _ -> {
        // ancestor.fields
        // |> list.map(fn(f) { f.name })
        Literal(ancestor.name)
      }
    }
  }

  let body =
    ancestors
    // |> list.reverse
    |> list.fold(Literal(""), fn(acc, ancestor) {
      case acc {
        Literal("") -> make_ancestor(ancestor)
        _ -> {
          Pipe(left: make_ancestor(ancestor), right: acc)
        }
      }
    })

  Function(name:, parameters: [], body:)
}
