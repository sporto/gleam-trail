pub type Segment {
  Segment(String)
  Parameter(name: String, type_: String)
}

pub type RouteTree {
  RouteTree(name: String, path: List(Segment), children: List(RouteTree))
  RouteNode(name: String, path: List(Segment))
}
