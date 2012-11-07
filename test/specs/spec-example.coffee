define (require) ->
  pavlov.specify "Textorum Example", ->
    describe "A feature that is being described from within a requirejs test", ->
      describe "and in coffeescript, no less", ->
        foo = undefined
        before ()->
          foo = "bar"
        after ()->
          foo = "baz"

        it "can be specified like so", ->
          assert(foo).equals 'bar'
        it "is boringly true", ->
          assert(1).equals 1