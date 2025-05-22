#{
  import "./jsonpath.typ": json_path_b, json_path
  import "parse.typ": all as all_node
  import "nodes.typ": node_str
  import "scan_util.typ": runes

  set page(
    paper: "a4",
    margin: (top: 2cm, bottom: 2cm, left: 1cm, right: 1cm),
    footer: context [
      #set align(right)
      #set text(8pt)
      #counter(page).display(
        "1 of 1",
        both: true,
      )
    ],
  )
  set text(size: 12pt)
  show heading: set text(size: 18pt)

  let test_case(name, obj, ..selectors) = {
    return (
      name: name,
      obj: obj,
      selectors: selectors.pos(),
    )
  }
  let test_cases = (
    // test_case(
    //   [rfc9535 1.5 JSONPath Examples],
    //   json("data/rfc9535-1-5.json"),
    //   "$.store.bicycle.price",
    //   "$.store.bicycle.*",
    //   "$.store.book.*.price",
    //   "$['store']['bicycle']['price']",
    //   "$.store.book[0,1:2,2:,:,*,'a'].price",
    //   "$.store.book[1].price",
    //   "$.store.book[*].author",
    //   "$['store'].*",
    //   "$..author",
    //   "$.store..price",
    //   "$..book[2]",
    //   "$..book[2].author",
    //   "$..book[-1]",
    //   "$..book[:2]",
    //   "$..book[0,1]",
    // "$.book[1,3]",
    //   "$..*",
    // ),
    test_case(
      [rfc9535 2.3.1.3 Name Selector Examples],
      json("data/rfc9535-2-3-1-3.json"),
      "$.o['j j']",
      "$.o['j j']['k.k']",
      "$.o[\"j j\"][\"k.k\"]",
      "$[\"'\"][\"@\"]",
    ),
    test_case(
      [rfc9535 2.3.2.3 Wildcard Selector Examples],
      json("data/rfc9535-2-3-2-3.json"),
      "$[*]",
      "$.o[*]",
      "$.o[*, *]",
      "$.a[*]",
    ),
    test_case(
      [rfc9535 2.3.3.3 Index Selector Examples],
      json("data/rfc9535-2-3-3-3.json"),
      "$[1]",
      "$[-2]",
    ),
    test_case(
      [rfc9535 2.3.4.3 Array Slice Selector Examples],
      json("data/rfc9535-2-3-4-3.json"),
      "$[1:3]",
      "$[5:]",
      "$[1:5:2]",
      "$[5:1:-2]",
      "$[::-1]",
      "$[-3::-1]",
      "$[:3:-1]",
      "$[::-4]",
    ),
    test_case(
      [rfc9535 2.3.5.3 Filter Selector Examples (Supported by alternative syntax and external filters, see source code for details)],
      json("data/rfc9535-2-3-5-3.json"),
      (
        "$.a[?@.b == 'kilo']",
        "$.a[?]",
        it => json_path(it, "$.b") == ("kilo",),
      ),
      (
        "$.a[?@>3.5]",
        "$.a[?]",
        it => type(it) in (int, float) and it > 3.5,
      ),
      (
        "$.a[?@.b]",
        "$.a[?]",
        it => json_path(it, "$.b") != (),
      ),
      (
        "$[?@.*]",
        "$[?]",
        it => json_path(it, "$.*") != (),
      ),
      (
        "$[?@[?@.b]]",
        "$[?]",
        it => (
          json_path(
            it,
            "$[?]",
            it => json_path(it, "$.b") != (),
          )
            != ()
        ),
      ),
      (
        "$.o[?@<3, ?@<3]",
        "$.o[?,?]",
        it => type(it) in (int, float) and it < 3,
      ),
      (
        "$.a[?@<2 || @.b == 'k']",
        "$.a[?]",
        it => type(it) in (int, float) and it < 2 or json_path(it, "$.b") == ("k",),
      ),
      (
        "$.a[?match(@.b, '[jk]')]",
        "$.a[?]",
        it => {
          let r = json_path(it, "$.b")
          if r == () {
            return false
          }
          let s = r.first()
          if type(s) != str {
            return false
          }
          return s.match(regex("^[jk]$")) != none
        },
      ),
      (
        "$.a[?search(@.b, '[jk]')]",
        "$.a[?]",
        it => {
          let r = json_path(it, "$.b")
          if r == () {
            return false
          }
          let s = r.first()
          if type(s) != str {
            return false
          }
          return s.match(regex("[jk]")) != none
        },
      ),
      (
        "$.o[?@>1 && @<4]",
        "$.o[?]",
        it => type(it) in (int, float) and it > 1 and it < 4,
      ),
      (
        "$.o[?@.u || @.x]",
        "$.o[?]",
        it => json_path(it, "$.u") != () or json_path(it, "$.x") != (),
      ),
      (
        "$.a[?@.b == $.x]",
        "$.a[?]",
        // `$.x` is empty which can be fetched by `json_path(obj, "$.x")`
        // where the `obj` is outside of the filter function's scope
        it => json_path(it, "$.b") == (), // json_path(obj, "$.x"),
      ),
      (
        "$.a[?@ == @]",
        "$.a[?]",
        it => it == it,
      ),
      (
        "$.a[?@<2, ?@<3]",
        "$.a[?0,?1]",
        it => type(it) in (int, float) and it < 2,
        it => type(it) in (int, float) and it < 3,
      ),
    ),
    test_case(
      [rfc9535 2.5.1.3 Child Segment Selector Examples],
      json("data/rfc9535-2-3-4-3.json"),
      "$[0, 3]",
      "$[0:2, 5]",
      "$[0, 0]",
    ),
    test_case(
      [rfc9535 2.5.2.3 Descendant Segment Examples],
      json("data/rfc9535-2-5-2-3.json"),
      "$..j",
      "$..[0]",
      "$..*",
      "$..o",
      "$.o..[*, *]",
      "$.a..[0, 1]",
    ),
    test_case(
      [rfc9535 2.6.1 Semantics of null Examples],
      json("data/rfc9535-2-6-1.json"),
      "$.a",
      "$.a[0]",
      "$.a.d",
      "$.b[0]",
      "$.b[*]",
      // "$.b[?@]",
      // "$.b[?@==null]",
      // "$.c[?@.d==null]",
      "$.null",
    ),
  )
  for tc in test_cases {
    let selectors = ()
    let cells = ()
    for selector in tc.selectors {
      let title = selector
      let sel = selector
      let fns = ()
      if type(selector) == array {
        title = selector.at(0)
        sel = selector.at(1)
        fns = selector.slice(2)
      }
      cells.push(table.cell(title))
      let (r, err) = json_path_b(tc.obj, sel, ..fns)
      if err != none {
        cells.push([❌ #text(err, fill: red)])
      } else {
        cells.push([#r])
      }
      // let runes = runes(selector)
      // let (nodes, err) = all_node(runes)
      // if err != none {
      //   cells.push([❌ #text(err, fill: red)])
      // } else {
      //   cells.push([#nodes.map(node_str).join("\n")])
      // }
    }
    [== #tc.name]
    line(length: 100%)
    grid(
      columns: (5fr, 3fr),
      column-gutter: 1em,
      {
        // set text(hyphenate: true)
        show table.cell: cell => {
          show regex("\b.+?\b"): it => it.text.codepoints().join(sym.zws)
          cell
        }
        table(
          // columns: (1fr, 1fr, 2fr),
          columns: (1fr, 2fr),
          // table.header([path], [value], [node]),
          table.header([path], [value]),
          ..cells,
        )
      },
      [#tc.obj],
    )
  }
}
