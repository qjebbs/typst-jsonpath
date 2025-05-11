#let ok(token) = {
  return (token, none)
}

#let error(err) = {
  return (none, err)
}
