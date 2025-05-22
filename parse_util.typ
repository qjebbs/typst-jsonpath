#import "tokens.typ": token_str

#let expecting_msg(see, ..expected) = {
  let wants = expected.pos()
  if wants.len() == 0 {
    return "postion " + str(see.pos.start) + ": unexpected token '" + token_str(see) + "'"
  }
  return (
    "postion "
      + str(see.pos.start)
      + ": see '"
      + token_str(see)
      + "' expected "
      + wants.map(it => if it.len() == 1 {"'" + it + "'" } else { "<" + it + ">" }).join(", ")
  )
}

#let string_lit(s) = {
  let q = s.at(0)
  s = s.replace("'", "\\'")
  s = s.replace("\n", "\\n")
  s = s.replace("\r", "\\r")
  s = s.replace("\t", "\\t")
  return "'" + s + "'"
}

#let parse_string(s) = {
  if s == "" { return "" }
  let q = s.at(0)
  s = s.slice(1, -1)
  s = s.replace("\\t", "\t")
  s = s.replace("\\n", "\n")
  s = s.replace("\\r", "\r")
  s = s.replace("\\" + q, q)
  return s
}
