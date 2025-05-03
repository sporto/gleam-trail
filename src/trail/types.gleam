pub type Segment {
  Segment(String)
  Parameter(name: String, type_: String)
}

pub type Route {
  Route(name: String, path: List(Segment), children: List(Route))
}
