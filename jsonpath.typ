#import "scan_util.typ": runes
#import "parse.typ": next
#import "execute.typ": execute
#import "util.typ": ok, error

// json_path_b is like `json_path` but returns `(result, err)` instead of panicking on error.
#let json_path_b(obj, path, ..filters) = {
  let runes = runes(path)
  let pos = 0
  let result = ()
  while true {
    let (node, err) = next(runes, pos)
    if err != none {
      return error(err)
    }
    if node == none {
      break
    }
    pos = node.pos.end
    (result, err) = execute(obj, node, result, ..filters)
    if err != none {
      return error(err)
    }
  }
  return ok(result)
}

// json_path extracts JSON values from a JSON object using a JSONPath expression as per RFC 9535, except filter selectors are not supported (see `filter` function for workaround).
// It always returns an array of results. If there are no results, it returns an empty array.
// = Example:
// ```typst
// #{
//   let obj = json("data/rfc9535-1-5.json")
//   let result = json_path(obj, "$.store.book.*.title")")
// }
// ```
#let json_path(obj, path, ..filters) = {
  let (r, err) = json_path_b(obj, path, ..filters)
  if err != none {
    panic(err)
  }
  return r
}
