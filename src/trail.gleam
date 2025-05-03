import glance_printer
import trail/builder
import trail/types

pub fn generate(routes: List(types.Route)) {
  routes |> builder.build |> glance_printer.print
}
