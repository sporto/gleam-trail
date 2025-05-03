import glance_printer
import trail/builder
import trail/types

pub fn generate(routes: List(types.RouteTree)) {
  routes |> builder.build |> glance_printer.print
}
