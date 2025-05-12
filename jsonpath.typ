#import "scan_util.typ": runes
#import "parse.typ": next
#import "execute.typ": execute
#import "util.typ": ok, error

// json_path_b is like `json_path` but returns `(result, err)` instead of panicking on error.
#let json_path_b(obj, path) = {
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
    result = execute(obj, node, result)
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
#let json_path(obj, path) = {
  let (r, err) = json_path_b(obj, path)
  if err != none {
    panic(err)
  }
  return r
}

// json_path_fallback is like `json_path`, but returns an array of fallback values if the path does not match any value.
// = Example:
// ```typst
// #{
//   let obj = (a: 1)
//   let r = json_path_fallback(obj, "$.absent", 0) // r = (0,)
// }
// ```
#let json_path_fallback(obj, path, ..fallback_values) = {
  let r = json_path(obj, path)
  if r.len() == 0 {
    return fallback_values.pos()
  }
  return r
}

// filter applies a filter function to a json_path result.
// It serves as an alternative method to address the lack of filter selector support in `json_path`.
// = Example:
// ```typst
// #{
//   // The following code is equivalent to:
//   // $.store.book[?(@.price > 10)].title
//   let obj = json("data/rfc9535-1-5.json")
//   let result = json_path(obj, "$.store.book")
//   result = filter(result, it => json_path_fallback(it, "$.price", 0).first() > 10)
//   result = json_path(result, "$.*.title")
// }
// ```
#let filter(result , fn) = {
  let filtered = ()
  for value in result {
    if type(value) == array {
      for v in value {
        if fn(v) {
          filtered.push(v)
        }
      }
    }
    if type(value) == dictionary {
      for (_, v) in value {
        if fn(v) {
          filtered.push(v)
        }
      }
    }
  }
  return filtered
}
