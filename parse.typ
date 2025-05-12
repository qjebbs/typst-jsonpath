#import "scan.typ": next as next_token
#import "tokens.typ": types as token_types, lit_kind
#import "nodes.typ": *
#import "util.typ": ok as ok_single, error
#import "parse_util.typ": expecting_msg, parse_string

#let ok(..nodes) = {
  return ok_single(nodes.pos())
}

#let root_node(runes, i) = {
  let (tok, err) = next_token(runes, i)
  if err != none {
    return error(err)
  }
  if tok.type != token_types.Root {
    return error("root identifier '$' must be first")
  }
  return ok(Root(tok))
}

#let name_or_wildcard_selector_node(runes, tok) = {
  let (next_tok, err) = next_token(runes, tok.pos.end)
  if err != none {
    return error(err)
  }
  if next_tok.type == token_types.Name {
    return ok(NameSelector(next_tok.lit, tok, next_tok))
  }
  if next_tok.type == token_types.Wildcard {
    return ok(WildcardSelector(tok, next_tok))
  }
  return error(expecting_msg(next_tok, "*", "name"))
}

#let is_number_token(runes, tok) = {
  if tok.type == token_types.Literal and tok.litkind in (lit_kind.Int, lit_kind.FLoat) {
    return true
  }
  if tok.type != token_types.Operator and tok.op != "-" {
    return false
  }
  let (next_tok, err) = next_token(runes, tok.pos.end)
  if err != none {
    return false
  }
  return is_number_token(runes, next_tok)
}

#let format_number(runes, tok, format_int) = {
  if tok.type == token_types.Literal {
    if tok.litkind == lit_kind.Int {
      return ok(int(tok.lit), tok)
    } else if not format_int or tok.litkind == lit_kind.FLoat {
      return ok(float(tok.lit), tok)
    } else {
      return error(expecting_msg(tok, "int"))
    }
  }
  if tok.type != token_types.Operator and tok.op != "-" {
    return error(expecting_msg(tok, "number"))
  }
  let (next_tok, err) = next_token(runes, tok.pos.end)
  if err != none {
    return error(err)
  }
  let (r, err) = format_number(runes, next_tok, format_int)
  if err != none {
    return error(err)
  }
  let (num, next_tok) = r
  return ok(-num, next_tok)
}

#let slice_selector_node(runes, tok) = {
  let start_tok = tok
  let start = 0
  let end = -1
  let colon_tok = none
  if tok.type == token_types.Colon {
    start = 0
    colon_tok = tok
  } else if is_number_token(runes, tok) {
    let (r, err) = format_number(runes, tok, true)
    if err != none {
      return error(err)
    }
    (start, tok) = r
  } else {
    return error(expecting_msg(next_tok, "number", ":"))
  }
  if colon_tok == none {
    let (mid_tok, err) = next_token(runes, tok.pos.end)
    if err != none {
      return error(err)
    }
    if mid_tok.type != token_types.Colon {
      return error(expecting_msg(mid_tok, ":"))
    }
    colon_tok = mid_tok
  }
  let (right_tok, err) = next_token(runes, colon_tok.pos.end)
  if err != none {
    return error(err)
  }
  if right_tok.type == token_types.Rbrack or right_tok.type == token_types.Comma {
    end = -1
    return ok(SliceSelector(start, end, start_tok, colon_tok))
  } else if is_number_token(runes, right_tok) {
    let ((end, right_tok), err) = format_number(runes, right_tok, true)
    if err != none {
      return error(err)
    }
    return ok(SliceSelector(start, end, start_tok, right_tok))
  }
  return error(expecting_msg(right_tok, "number", ",", "]"))
}

#let index_selector_node(runes, tok) = {
  let start_tok = tok
  let index = 0
  let ((index, tok), err) = format_number(runes, tok, true)
  if err != none {
    return error(err)
  }
  let (next_tok, err) = next_token(runes, tok.pos.end)
  if err != none {
    return error(err)
  }
  return ok(IndexSelector(index, start_tok, tok))
}

#let child_segment_node(runes, tok) = {
  let start_tok = tok
  let selectors = ()
  let (tok, err) = next_token(runes, tok.pos.end)
  if err != none {
    return error(err)
  }
  while tok.type != token_types.EOL {
    if tok.type == token_types.Rbrack {
      return ok(ChildSegment(selectors, start_tok, tok))
    }
    if tok.type == token_types.Wildcard {
      // let (nodes, err) = wildcard_selector_node(runes, tok)
      // if err != none {
      //   return error(err)
      // }
      // selectors += nodes
      selectors.push(WildcardSelector(tok))
    } else if tok.type == token_types.Colon {
      // [:] / [:-1]
      let (nodes, err) = slice_selector_node(runes, tok)
      if err != none {
        return error(err)
      }
      selectors += nodes
    } else if is_number_token(runes, tok) {
      // [1] / [1:]
      let ((num, t), err) = format_number(runes, tok, true)
      if err != none {
        return error(err)
      }
      let (after_num_tok, err) = next_token(runes, t.pos.end)
      if after_num_tok.type == token_types.Colon {
        let (nodes, err) = slice_selector_node(runes, tok)
        if err != none {
          return error(err)
        }
        selectors += nodes
      } else {
        let (nodes, err) = index_selector_node(runes, tok)
        if err != none {
          return error(err)
        }
        selectors += nodes
      }
    } else if tok.type == token_types.Literal and tok.litkind == lit_kind.String {
      // ["name"]
      selectors.push(NameSelector(parse_string(tok.lit), tok))
    } else if tok.type == token_types.Comma {
      // nothing
      (tok, err) = next_token(runes, tok.pos.end)
      if err != none {
        return error(err)
      }
      continue
    } else {
      return error(expecting_msg(tok, "selectors"))
    }
    (tok, err) = next_token(runes, selectors.last().pos.end)
    if err != none {
      return error(err)
    }
  }
  return error(expecting_msg(tok, "]"))
}
#let next(runes, i) = {
  if i == 0 {
    return root_node(runes, i)
  }
  let (tok, err) = next_token(runes, i)
  if err != none {
    return error(err)
  }
  if tok.type == token_types.EOL {
    return ok_single(none)
  }
  if tok.type == token_types.Dot {
    // .name / .*
    return name_or_wildcard_selector_node(runes, tok)
  }
  if tok.type == token_types.Lbrack {
    // [<selectors>]
    return child_segment_node(runes, tok)
  }
  if tok.type == token_types.DotDot {
    // ..name / ..* / ..[<selectors>]
    let nodes = (
      DescendantSegment(tok),
    )
    let (next, err) = next_token(runes, tok.pos.end)
    if err != none {
      return error(err)
    }
    if next.type == token_types.Lbrack {
      return child_segment_node(runes, tok)
    } else {
      let (n, err) = name_or_wildcard_selector_node(runes, tok)
      if err != none {
        return error(err)
      }
      nodes += n
      return ok(..nodes)
    }
  }
  return error(expecting_msg(tok))
}
