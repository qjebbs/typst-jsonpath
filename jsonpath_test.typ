#{
  import "./jsonpath.typ": json_path_b
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
      "$.b[?@]",
      // "$.b[?@==null]",
      // "$.c[?@.d==null]",
      "$.null",
    ),
  )
  for tc in test_cases {
    let selectors = ()
    let cells = ()
    for selector in tc.selectors {
      cells.push(table.cell(selector))
      let (r, err) = json_path_b(tc.obj, selector)
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
