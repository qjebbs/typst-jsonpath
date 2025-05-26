#import "scan.typ": next as next_token
#import "tokens.typ": types as token_types, lit_kind
#import "nodes.typ": *
#import "util.typ": ok, error
#import "parse_util.typ": expecting_msg, parse_string

#let root_node(runes, i) = {
  let (tok, err) = next_token(runes, i)
  if err != none {
    return error(err)
  }
  if tok.type != token_types.Root {
    return error("root identifier '$' must be first")
  }
  return ok(Root(tok.pos.start, tok.pos.end))
}

#let name_or_wildcard_selector_node(runes, tok) = {
  let (next_tok, err) = next_token(runes, tok.pos.end)
  if err != none {
    return error(err)
  }
  if next_tok.type == token_types.Name {
    return ok(NameSelector(next_tok.lit, tok.pos.start, next_tok.pos.end))
  }
  if next_tok.type == token_types.Wildcard {
    return ok(WildcardSelector(tok.pos.start, next_tok.pos.end))
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
  let (tok, err) = next_token(runes, tok.pos.end)
  if err != none {
    return false
  }
  return tok.type == token_types.Literal and tok.litkind in (lit_kind.Int, lit_kind.FLoat)
}

#let format_number(runes, tok, format_int) = {
  if tok.type == token_types.Literal {
    if tok.litkind == lit_kind.Int {
      return ok((int(tok.lit), tok))
    } else if not format_int or tok.litkind == lit_kind.FLoat {
      return ok((float(tok.lit), tok))
    } else {
      return error(expecting_msg(tok, "int"))
    }
  }
  if tok.type != token_types.Operator and tok.op != "-" {
    return error(expecting_msg(tok, "number"))
  }
  let (tok, err) = next_token(runes, tok.pos.end)
  if err != none {
    return error(err)
  }
  let ((num, tok), err) = format_number(runes, tok, format_int)
  if err != none {
    return error(err)
  }
  return ok((-num, tok))
}

#let filter_selector_node(runes, tok) = {
  // support only the extended external filter function syntax
  // $[?]
  let start_tok = tok
  let (next, err) = next_token(runes, tok.pos.end)
  if err != none {
    return error(err)
  }
  if next.type == token_types.Comma or next.type == token_types.Rbrack {
    return ok(FilterSelector(0, start_tok.pos.start, start_tok.pos.end))
  }
  // $[?1]
  // filter index
  let filter_index = 0
  if next.type != token_types.Literal or next.litkind != lit_kind.Int {
    return error(expecting_msg(next, "]", "filter_index"))
  }
  filter_index = int(next.lit)
  tok = next

  // check RBrack
  let (next, err) = next_token(runes, tok.pos.end)
  if err != none {
    return error(err)
  }
  if next.type == token_types.Comma or next.type == token_types.Rbrack {
    return ok(FilterSelector(filter_index, start_tok.pos.start, tok.pos.end))
  }
  return error(expecting_msg(tok, ",", "]"))
}

#let index_or_slice_selector_node(runes, tok) = {
  let start_tok = tok
  let params = ()
  let num = 0
  let err = none
  if is_number_token(runes, tok) {
    ((num, tok), err) = format_number(runes, tok, true)
    if err != none {
      return error(err)
    }
    let (next, err) = next_token(runes, tok.pos.end)
    if err != none {
      return error(err)
    }
    if next.type == token_types.Comma or next.type == token_types.Rbrack {
      return ok(IndexSelector(num, start_tok.pos.start, tok.pos.end))
    }
    tok = next
    params.push(num)
  } else {
    params.push(none)
  }
  if tok.type != token_types.Colon {
    return error(expecting_msg(tok, ":"))
  }
  while params.len() < 3 and tok.type == token_types.Colon {
    let (next, err) = next_token(runes, tok.pos.end)
    if err != none {
      return error(err)
    }
    if next.type == token_types.Comma or next.type == token_types.Rbrack {
      break
    }
    tok = next
    if next.type == token_types.Colon {
      params.push(none)
      continue
    }
    if is_number_token(runes, tok) {
      ((num, tok), err) = format_number(runes, tok, true)
      if err != none {
        return error(err)
      }
      params.push(num)
      let (next, err) = next_token(runes, tok.pos.end)
      if err != none {
        return error(err)
      }
      if next.type == token_types.Colon {
        tok = next
      }
    } else {
      return error(expecting_msg(tok, "number"))
    }
  }
  let (next, err) = next_token(runes, tok.pos.end)
  if err != none {
    return error(err)
  }
  if next.type != token_types.Comma and next.type != token_types.Rbrack {
    return error(expecting_msg(tok, ",", "]"))
  }
  if params.len() == 3 {
    return ok(
      SliceSelector(
        params.at(0),
        params.at(1),
        params.at(2),
        start_tok.pos.start,
        tok.pos.end,
      ),
    )
  } else if params.len() == 2 {
    return ok(
      SliceSelector(
        params.at(0),
        params.at(1),
        none,
        start_tok.pos.start,
        tok.pos.end,
      ),
    )
  }
  return ok(
    SliceSelector(
      params.at(0),
      none,
      none,
      start_tok.pos.start,
      tok.pos.end,
    ),
  )
}

#let child_segment_node(runes, tok) = {
  let start_tok = tok
  let selectors = ()
  let (tok, err) = next_token(runes, tok.pos.end)
  if err != none {
    return error(err)
  }
  while tok.type != token_types.EOF {
    if tok.type == token_types.Rbrack {
      if selectors.len() == 0 {
        return error(expecting_msg(tok, "wildcard selector", "name selector", "index selector", "slice selector"))
      }
      return ok(ChildSegment(selectors, start_tok.pos.start, tok.pos.end))
    }
    if tok.type == token_types.Wildcard {
      selectors.push(WildcardSelector(tok.pos.start, tok.pos.end))
    } else if tok.type == token_types.Filter {
      // [:] / [:-1]
      let (node, err) = filter_selector_node(runes, tok)
      if err != none {
        return error(err)
      }
      selectors.push(node)
    } else if (
      tok.type == token_types.Colon or is_number_token(runes, tok)
    ) {
      // [:] / [:-1]
      let (node, err) = index_or_slice_selector_node(runes, tok)
      if err != none {
        return error(err)
      }
      selectors.push(node)
    } else if tok.type == token_types.Literal and tok.litkind == lit_kind.String {
      // ["name"]
      let (name, err) = parse_string(tok.lit)
      if err != none {
        return error("postion " + str(tok.pos.start) + ": parse " + tok.lit  + err)
      }
      selectors.push(NameSelector(name, tok.pos.start, tok.pos.end))
    } else if tok.type == token_types.Comma {
      // nothing
      (tok, err) = next_token(runes, tok.pos.end)
      if err != none {
        return error(err)
      }
      continue
    } else {
      return error(expecting_msg(tok, "wildcard selector", "name selector", "index selector", "slice selector"))
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
  if tok.type == token_types.EOF {
    return ok(none)
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
    let start_tok = tok
    let (next, err) = next_token(runes, tok.pos.end)
    if err != none {
      return error(err)
    }
    if next.type == token_types.Lbrack {
      let (r, err) = child_segment_node(runes, next)
      if err != none {
        return error(err)
      }
      return ok(DescendantSegment(r, start_tok.pos.start, r.pos.end))
    } else {
      let (r, err) = name_or_wildcard_selector_node(runes, tok)
      if err != none {
        return error(err)
      }
      return ok(DescendantSegment(r, start_tok.pos.start, r.pos.end))
    }
  }
  return error(expecting_msg(tok))
}

#let all(runes) = {
  let pos = 0
  let nodes = ()
  while true {
    let (r, err) = next(runes, pos)
    if err != none {
      error(err)
    }
    if r == none {
      break
    }
    nodes += r
    pos = r.last().pos.end
  }
  return ok(nodes)
}
