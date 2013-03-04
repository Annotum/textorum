define (require) ->
  module 'test module from within a requirejs module'
  test 'setup', ->
    ok true, 'Module loaded'
