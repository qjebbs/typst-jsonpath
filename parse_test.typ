#{
  import "scan_util.typ": runes
  import "parse.typ": next
  import "tokens.typ": types
  import "nodes.typ": node_str
  set page(
    paper: "a4",
    margin: (top: 1cm, bottom: 1cm, left: 1cm, right: 1cm),
  )
  set text(size: 12pt)
  let max_columns = 4
  let selectors = (
    // weired, but valid
    "$.$.book",
    "$.书籍 [ 'abc \\n 中文' , -1, *,: ] \n['ignored']",
    "$[ * , 'a' ]",
    // ok
    "$.store.book[*].price",
    "$['store'].*",
    "$..author",
    "$.store..price",
    "$..book[2]",
    "$..book[2].author",
    "$..book[-1]",
    "$..book[:2]",
    "$..book[0,1]",
    "$.book[1,3]",
    "$..*",
    // "$.book[?@.price>=10]",
  )
  let tables = selectors
    .chunks(max_columns)
    .map(part => [
      #table(
        columns: part.len(),
        table.header(
          repeat: true,
          ..part.map(it => [#it]),
        ),
        ..part.map(it => {
          let runes = runes(it)
          let pos = 0
          while true {
            let (node, err) = next(runes, pos)
            if err != none {
              [❌ #text(err, fill: red)]
              return
            }
            if node == none {
              break
            }
            pos = node.pos.end
            [#node_str(node) \ ]
          }
        }),
      )
    ])
  let idx = 0
  for table in tables {
    idx += 1
    [= Part #idx]
    table
  }
}

