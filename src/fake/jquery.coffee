define (require) ->
  if !localjquery
    localjquery = window.jQuery
  return localjquery
