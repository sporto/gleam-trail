import birdie
import glacier
import trail
import trail/types.{Parameter, RouteNode, RouteTree, Segment}

pub fn main() {
  glacier.main()
}

pub fn generate_test() {
  let routes = [
    RouteTree("App", [Segment("app")], children: [
      //
      RouteNode("Top", []),
      RouteNode("Users", [Segment("users")]),
      RouteTree(
        "User",
        [Segment("users"), Parameter(name: "id", type_: "UserId")],
        [RouteNode("Top", []), RouteNode("Delete", [])],
      ),
    ]),
  ]
  trail.generate(routes)
  |> birdie.snap(title: "routes")
}
