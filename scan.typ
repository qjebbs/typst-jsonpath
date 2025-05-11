#import "scan_util.typ": expecting_msg, runes_str, peek, peekn, skip_sp, EOL
#import "tokens.typ": *
#import "util.typ": ok, error

#let letter_ranges = (
  ("A".to-unicode(), "Z".to-unicode()),
  ("a".to-unicode(), "z".to-unicode()),
  ("$".to-unicode(), "$".to-unicode()),
  ("_".to-unicode(), "_".to-unicode()),
  (256, 1114111), // 100 - 0010FFFF
)

#let digit_ranges = (
  ("0".to-unicode(), "9".to-unicode()),
)

#let in_code_range(ch, range) = {
  let code = ch.to-unicode()
  for (a, b) in range {
    if code >= a and code <= b {
      return true
    }
  }
  return false
}

#let is_letter(ch) = {
  return in_code_range(ch, letter_ranges)
}

#let is_digit(ch) = {
  return in_code_range(ch, digit_ranges)
}

#let scan_string(runes, i) = {
  let start = i
  let left = peek(runes, i)
  if left != "'" and left != "\"" {
    return error("unexpected string")
  }
  i += 1
  let ch = peek(runes, i)
  while ch != EOL {
    if ch == "\\" {
      // skip next ch
      i += 2
      ch = peek(runes, i)
      continue
    }
    if ch == left {
      i += 1
      break
    }
    i += 1
    ch = peek(runes, i)
  }
  if ch == EOL {
    return error("unclosed quoted string")
  }
  return ok(Literal(start, i, lit_kind.String, runes_str(runes, start, i)))
}

#let scan_number(runes, i, seen_point) = {
  let start = i
  let point = false
  let ch = peek(runes, i)
  while ch != EOL {
    if ch == "." {
      point = true
      if not seen_point {
        let (r, err) = scan_number(runes, i + 1, true)
        if err != none {
          return error(err)
        }
        i = r.pos.end
      }
      break
    }
    if not is_digit(ch) {
      break
    }
    i += 1
    ch = peek(runes, i)
  }
  if point {
    return ok(Literal(start, i, lit_kind.FLoat, runes_str(runes, start, i)))
  }
  return ok(Literal(start, i, lit_kind.Int, runes_str(runes, start, i)))
}

#let scan_ident(runes, i, first) = {
  let start = i
  let ch = peek(runes, i)
  if is_letter(ch) {
    // ok
  } else if is_digit(ch) {
    return error("identifier cannot begin with digit '", ch + "'")
  } else {
    return error(expecting_msg(ch, "[$@_0-9a-zA-Z]"))
  }
  while ch != EOL {
    if is_letter(ch) or is_digit(ch) {
      i += 1
      ch = peek(runes, i)
      continue
    }
    break
  }
  let name = runes_str(runes, start, i)
  // possibly a keyword
  if first and name == "$" {
    return ok(Root(start, i))
  }
  return ok(Name(start, i, name))
}


#let next(runes, i) = {
  let first = i == 0
  i = skip_sp(runes, i)
  let ch = peek(runes, i)
  if ch == EOL {
    return ok(Eol(i, i))
  }
  if is_letter(ch) {
    return scan_ident(runes, i, first)
  }
  if ch == "?" {
    return ok(Filter(i, i + 1))
  }
  if ch == "@" {
    return ok(Current(i, i + 1))
  }
  if ch == "[" {
    return ok(Lbrack(i, i + 1))
  }
  if ch == "]" {
    return ok(Rbrack(i, i + 1))
  }
  if ch == "," {
    return ok(Comma(i, i + 1))
  }
  if ch == "*" {
    return ok(Wildcard(i, i + 1))
  }
  if ch == ":" {
    return ok(Colon(i, i + 1))
  }
  if ch == "." {
    if peek(runes, i + 1) == "." {
      return ok(DotDot(i, i + 2))
    }
    return ok(Dot(i, i + 1))
  }
  if is_digit(ch) {
    return scan_number(runes, i, false)
  }
  if ch == "'" {
    return scan_string(runes, i)
  }
  if ch == "-" {
    return ok(Operator(i, i + 1, "-"))
  }
  if ch == "!" {
    if peek(runes, i + 1) == "=" {
      return ok(Operator(i, i + 2, "!="))
    }
    return ok(Operator(i, i + 1, "!"))
  }
  if ch in ("=", ">", "<") {
    if peek(runes, i + 1) == "=" {
      return ok(Operator(i, i + 2, ch + "="))
    }
    return ok(Operator(i, i + 1, ch))
  }
  return error("postion " + str(i) + ": unexpected '" + ch + "'")
}

#let runes(s) = {
  let chs = ()
  for ch in s {
    chs.push(ch)
  }
  return chs
}
