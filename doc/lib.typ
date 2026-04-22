// Sizes used across the template.
#let script-size = 8pt
#let footnote-size = 10pt
#let small-size = 11pt
#let normal-size = 12pt
#let large-size = 14pt

// This function gets your whole document as its `body` and formats
// it as an article in the style of the American Mathematical Society.
#let ams-article(
  // The article's title.
  title: [Paper title],

  // An array of authors. For each author you can specify a name,
  // department, organization, location, and email. Everything but
  // but the name is optional.
  authors: (),

  // Your article's abstract. Can be omitted if you don't have one.
  abstract: none,

  // The article's paper size. Also affects the margins.
  paper-size: "a4",

  // The result of a call to the `bibliography` function or `none`.
  bibliography: none,

  // The document's content.
  body,
) = {
  // Formats the author's names in a list with commas and a
  // final "and".
  let names = authors.map(author => author.name)
  let author-string = if authors.len() == 2 {
    names.join(" and ")
  } else {
    names.join(", ", last: ", and ")
  }

  // Set document metadata.
  set document(title: title, author: names)

  // Set the body font. AMS uses the LaTeX font.
  set text(size: normal-size, font: "New Computer Modern")

  // Configure the page.
  set page(
    paper: paper-size,
    margin: (top: 7em),

    // The page header should show the page number and list of
    // authors, except on the first page. The page number is on
    // the left for even pages and on the right for odd pages.
    header-ascent: 3.5em,
    header: context {
      let i = counter(page).get().first()
      if i == 1 { return }
      set text(size: script-size)
      grid(
        columns: (6em, 1fr, 6em),
        align: (start, center, end),
        if calc.even(i) [#i],
        upper(
          if calc.odd(i) { title } else { author-string }
        ),
        if calc.odd(i) { [#i] }
      )
    },
  )

  // Configure headings.
  set heading(numbering: "1.")
  show heading: it => {
    let is-ack = it.body in ([Acknowledgment], [Acknowledgement], [Acknowledgments], [Acknowledgements])

    // Create the heading numbering.
    let number = if it.numbering != none and not is-ack {
      counter(heading).display(it.numbering)
      h(7pt, weak: true)
    }

    // Level 1 headings are centered and smallcaps.
    // The other ones are run-in.
    set text(size: normal-size, weight: 400)
    set par(first-line-indent: 0em)
    if it.level == 1 {
      set align(center)
      set text(size: large-size)
      smallcaps[
        #v(28pt, weak: true)
        #number
        #it.body
        #v(2em, weak: true)
      ]
      counter(figure.where(kind: "theorem")).update(0)
    } else {
      v(16pt, weak: true)
      number
      let styled = if it.level == 2 { strong } else { emph }
      styled(it.body + [. ])
      h(7pt, weak: true)
    }
  }

  // Configure lists and links.
  set list(indent: 24pt, body-indent: 5pt)
  set enum(indent: 24pt, body-indent: 5pt)
  show link: set text(fill: rgb("#0000FF"))

  // Configure equations.
  show math.equation: set block(below: 8pt, above: 9pt)
  show math.equation: set text(weight: 400)
  set math.equation(numbering: "(1)", supplement: [])
  show ref: it => {
    let eq = math.equation
    let el = it.element
    if el != none and el.func() == eq {
      let numb = numbering(
        "1",
        ..counter(eq).at(el.location())
      )
      link(el.location(), text("(" + str(numb) + ")", fill: rgb("#800000")))
    } else {
      text(it, fill: rgb("#0000ff"))
    }
  }

  // Configure citation and bibliography styles.
  set std.bibliography(style: "springer-mathphys", title: [Tài liệu Tham khảo])

  set figure(gap: 17pt)
  show figure: set block(above: 12.5pt, below: 15pt)
  show figure: it => {
    // Customize the figure's caption.
    show figure.caption: caption => {
      smallcaps(caption.supplement)
      if caption.numbering != none {
        [ ]
        numbering(caption.numbering, ..caption.counter.at(it.location()))
      }
      [. ]
      caption.body
    }

    // We want a bit of space around tables and images.
    show selector.or(table, image): pad.with(x: 23pt)

    // Display the figure's body and caption.
    it
  }

  // Theorems.
  show figure.where(kind: "theorem"): set align(start)
  show figure.where(kind: "theorem"): it => block(spacing: 11.5pt, {
    strong({
      it.supplement
      if it.numbering != none {
        [ ]
        it.counter.display(it.numbering)
      }
      [.]
    })
    [ ]
    emph(it.body)
  })

  // Display the title and authors.
  v(35pt, weak: true)
  align(center, [
    #text(size: large-size, weight: 700, title)
    #v(25pt, weak: true)

    // ugly-ass ilgwg's hardcode
    #text(size: small-size, [*Lưu Nam Đạt*\*])

    #text(size: small-size, [_\* Email: dat.luu\@siglaz.com_])
  ])

  // Configure paragraph properties.
  set par(justify: true)

  // Display the abstract
  if abstract != none {
    v(20pt, weak: true)
    set text(small-size)
    show: pad.with(x: 35pt)

    line(length: 100%, stroke: 0.4pt)
    v(-1.5mm)
    [*Tóm tắt: *]
    abstract
    v(-1mm)
    line(length: 100%, stroke: 0.4pt)
  }

  // Display the article's contents.
  v(29pt, weak: true)
  body

  // Display the bibliography, if any is given.
  if bibliography != none {
    show std.bibliography: set text(footnote-size)
    show std.bibliography: set block(above: 11pt)
    show std.bibliography: pad.with(x: 0.5pt)
    v(28pt)
    bibliography
  }
}

// The ASM template also provides a theorem function.
#let theorem(body, numbered: true) = figure(
  body,
  kind: "theorem",
  supplement: [Theorem],
  numbering: if numbered { n => counter(heading).display() + [#n] }
)

// And a function for a proof.
#let proof(body) = block(spacing: 11.5pt, {
  emph[Proof.]
  [ ]
  body
  h(1fr)

  // Add a word-joiner so that the proof square and the last word before the
  // 1fr spacing are kept together.
  sym.wj

  // Add a non-breaking space to ensure a minimum amount of space between the
  // text and the proof square.
  sym.space.nobreak

  $square.stroked$
})

#let fig = figure.with(supplement: [Hình])
#let tablefig = figure.with(supplement: [Bảng], kind: "table")
#let secref = ref.with(supplement: "Mục")

