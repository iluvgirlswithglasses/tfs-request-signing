
#v(3em)
#show outline.entry.where(
  level: 1
): it => {
  if it.element.at("label", default: none) == <sec__ack> {
    [*#it.body() #box(width: 1fr, repeat(gap: 0.15em)[. ]) #it.page()*]
  } else {
    strong(it)
  }
}
#grid(
  columns: (1.7cm, 1fr, 1.7cm),
  [],
  outline(
    title: "Mục lục",
    indent: auto,
    depth: 2
  ),
  []
)
#v(3em)

