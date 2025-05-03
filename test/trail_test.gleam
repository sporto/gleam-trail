import birdie
import glacier
import trail
import trail/types.{Parameter, Route, Segment}

pub fn main() {
  glacier.main()
}

pub fn generate_test() {
  let routes = [
    Route("App", [Segment("app")], children: [
      //
      Route("Top", [], []),
      Route("Users", [Segment("users")], []),
      Route("User", [Segment("users"), Parameter(name: "id", type_: "UserId")], [
        Route("Top", [], []),
        Route("Delete", [], []),
      ]),
    ]),
  ]
  trail.generate(routes)
  |> birdie.snap(title: "routes")
}
