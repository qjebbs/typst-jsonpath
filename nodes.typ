#import "parse_util.typ": string_lit

#let types = (
  Root: "root",
  NameSelector: "name_selector",
  WildcardSelector: "wildcard_selector",
  IndexSelector: "index_selector",
  SliceSelector: "slice_selector",
  FilterSelector: "filter_selector",
  ChildSegment: "child_segment",
  DescendantSegment: "descendant_segment",
)

#let node(type, dict, ..start_end_tokens) = {
  let toks = start_end_tokens.pos()
  return (
    dict
      + (
        type: type,
        pos: (
          start: toks.first().pos.start,
          end: toks.last().pos.end,
        ),
      )
  )
}

#let Root(..start_end_tokens) = {
  return node(
    types.Root,
    (:),
    ..start_end_tokens,
  )
}

#let NameSelector(name, ..start_end_tokens) = {
  return node(
    types.NameSelector,
    (
      name: name,
    ),
    ..start_end_tokens,
  )
}
#let WildcardSelector(..start_end_tokens) = {
  return node(
    types.WildcardSelector,
    (:),
    ..start_end_tokens,
  )
}

#let IndexSelector(index, ..start_end_tokens) = {
  return node(
    types.IndexSelector,
    (
      index: index,
    ),
    ..start_end_tokens,
  )
}

#let SliceSelector(start, end, ..start_end_tokens) = {
  return node(
    types.SliceSelector,
    (
      start: start,
      end: end,
    ),
    ..start_end_tokens,
  )
}

#let ChildSegment(selectors, ..start_end_tokens) = {
  return node(
    types.ChildSegment,
    (
      selectors: selectors,
    ),
    ..start_end_tokens,
  )
}
#let DescendantSegment(..tokens) = {
  return node(
    types.DescendantSegment,
    (:),
    ..tokens,
  )
}


#let indent_str(indent, level) = {
  let r = ""
  let i = 0
  let j = 0
  while i < level * indent {
    r += " "
    i += 1
  }
  return r
}

#let node_str(node, ..level) = {
  let lvl = 0
  level = level.pos()
  if level.len() > 0 {
    lvl = level.first()
  }
  let indent = indent_str(2, lvl)
  if node.type == types.Root {
    return indent + types.Root + "()"
  }
  if node.type == types.NameSelector {
    return indent + types.NameSelector + "(" + string_lit(node.name) + ")"
  }
  if node.type == types.WildcardSelector {
    return indent + types.WildcardSelector + "()"
  }
  if node.type == types.IndexSelector {
    return indent + types.IndexSelector + "(" + str(node.index) + ")"
  }
  if node.type == types.SliceSelector {
    return indent + types.SliceSelector + "(" + str(node.start) + ", " + str(node.end) + ")"
  }
  if node.type == types.FilterSelector {
    return indent + types.FilterSelector + "(<unsupported>)"
  }
  if node.type == types.ChildSegment {
    let children = node.selectors.map(s => node_str(s, lvl + 1))
    if children.len() == 0 {
      return indent + types.ChildSegment + "()"
    }
    return indent + types.ChildSegment + indent + "(\n" + children.join("\n") + indent + "\n)"
  }
  if node.type == types.DescendantSegment {
    return indent + types.DescendantSegment + "()"
  }
}
