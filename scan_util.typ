#let EOL = "\n"

#let expecting_msg(see, ..expected) = {
  let rune_preprocess(v) = {
    if v == EOL {
      v = "EOL"
    }
    if v.len() == 1 {
      return "'" + v + "'"
    }
    return "<" + v + ">"
  }
  let wants = expected.pos().map(rune_preprocess)
  return "see " + rune_preprocess(see) + " expected " + wants.join(", ")
}

#let runes(s) = {
  let chs = ()
  for ch in s {
    chs.push(ch)
  }
  return chs
}

#let runes_str(runes, start, end) = {
  let a = runes.slice(start, end)
  if a.len() == 0 {
    return ""
  }
  if a.len() == 1 {
    return a.at(0)
  }
  return a.join()
}

#let peek(s, pos) = {
  let slen = s.len()
  if pos >= slen {
    return EOL
  }
  let rune = s.at(pos)
  if rune == "\r" {
    return EOL
  }
  return rune
}

#let peekn(s, pos, n) = {
  let slen = s.len()
  if pos >= slen {
    return EOL
  }
  let end = pos + n
  if end > slen {
    end = slen
  }
  return s.slice(pos, end).join()
}

#let skip_sp(s, i) = {
  while peek(s, i) == " " {
    i += 1
  }
  return i
}
