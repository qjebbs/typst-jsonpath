#import "nodes.typ": types
#import "util.typ": ok, error

#let exec_filter_selector(node, result) = {
  panic("not supported")
}

#let descendant_collect(obj, node, result) = {
  let collect(value) = {
    let values = ()
    if type(value) == array {
      values.push(value)
      for v in value {
        if type(v) == array or type(v) == dictionary {
          values += collect(v)
          continue
        }
      }
    }
    if type(value) == dictionary {
      values.push(value)
      for (_, v) in value {
        if type(v) == array or type(v) == dictionary {
          values += collect(v)
          continue
        }
      }
    }
    // don't collect values other than array and dictionary,
    // becase selector executing will surely drop them.
    return values
  }
  let r = ()
  for item in result {
    r += collect(item)
  }
  return r
}

#let exec_wildcard_selector(node, result) = {
  let r = ()
  for item in result {
    if type(item) == array {
      r += item
    } else if type(item) == dictionary {
      for (_, v) in item {
        r.push(v)
      }
    }
  }
  return r
}

#let exec_slice_selector(node, result) = {
  let r = ()
  for item in result {
    if type(item) != array {
      continue
    }
    let n_array = item.len()
    let step = node.step
    if step == none {
      step = 1
    }
    let start = node.start
    if start == none {
      if step > 0 {
        start = 0
      } else {
        start = n_array - 1
      }
    } else {
      if start < 0 {
        start += n_array
      }
      if start > n_array {
        start = n_array
      }
    }
    let end = node.end
    if end == none {
      if step > 0 {
        end = n_array
      } else {
        end = -1
      }
    } else {
      if end < 0 {
        end += n_array
      }
      if end > n_array {
        end = n_array
      }
    }
    if step == 1 {
      r += item.slice(start, end)
    } else {
      let i = start
      if step > 0 {
        while i < end {
          r.push(item.at(i))
          i += step
        }
      } else {
        while i > end {
          r.push(item.at(i))
          i += step
        }
      }
    }
  }
  return r
}

#let exec_index_selector(node, result) = {
  let r = ()
  for item in result {
    if type(item) != array {
      continue
    }
    let n_array = item.len()
    let index = node.index
    if index < 0 {
      index += n_array
    }
    if index >= n_array {
      continue
    }
    r.push(item.at(index))
  }
  return r
}

#let exec_name_selector(node, result) = {
  let r = ()
  for item in result {
    if type(item) != dictionary {
      continue
    }
    if not node.name in item {
      continue
    }
    r.push(item.at(node.name))
  }
  return r
}

#let exec_root(obj, result) = {
  return result + (obj,)
}

#let execute(obj, node, result) = {
  if node.type == types.Root {
    return exec_root(obj, result)
  }
  if node.type == types.NameSelector {
    return exec_name_selector(node, result)
  }
  if node.type == types.IndexSelector {
    return exec_index_selector(node, result)
  }
  if node.type == types.SliceSelector {
    return exec_slice_selector(node, result)
  }
  if node.type == types.WildcardSelector {
    return exec_wildcard_selector(node, result)
  }
  if node.type == types.FilterSelector {
    return exec_filter_selector(node, result)
  }
  if node.type == types.ChildSegment {
    let r = ()
    for node in node.selectors {
      let r2 = execute(obj, node, result)
      r += r2
    }
    return r
  }
  if node.type == types.DescendantSegment {
    return execute(obj, node.selector, descendant_collect(obj, node, result))
  }
  panic("unexpected node: " + node.type)
}
