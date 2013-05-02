###
  require(['textorum/relaxng/parse', 'textorum/helper'],
  function(ser) {
    var x = new ser(); x.debug = true;
    x.process('<rng:grammar xmlns:rng="http://relaxng.org/ns/structure/1.0">\n<start xmlns="http://relaxng.org/ns/structure/1.0">\n<rng:ref name="__addressBook-elt-idp496"/>\n</start>\n<rng:define name="__addressBook-elt-idp496">\n<element xmlns="http://relaxng.org/ns/structure/1.0">\n<rng:name ns="">addressBook</rng:name>\n<rng:choice>\n<rng:empty/>\n<rng:oneOrMore>\n<rng:ref name="__card-elt-idp1216"/>\n</rng:oneOrMore>\n</rng:choice>\n</element>\n</rng:define>\n<rng:define name="__card-elt-idp1216">\n<element xmlns="http://relaxng.org/ns/structure/1.0">\n<rng:name ns="">card</rng:name>\n<rng:group>\n<rng:ref name="__name-elt-idp2192"/>\n<rng:ref name="__email-elt-idp2576"/>\n</rng:group>\n</element>\n</rng:define>\n<rng:define name="__name-elt-idp2192">\n<element xmlns="http://relaxng.org/ns/structure/1.0">\n<rng:name ns="">name</rng:name>\n<text/>\n</element>\n</rng:define>\n<rng:define name="__email-elt-idp2576">\n<element xmlns="http://relaxng.org/ns/structure/1.0">\n<rng:name ns="">email</rng:name>\n<text/>\n</element>\n</rng:define>\n</rng:grammar>');
  }); true;
###

define (require) ->
  pavlov.specify "Textorum RNG parsing", ->
    describe "Simple RNG loading", ->
      RNGParser = require('textorum/relaxng/parse')
      loader = undefined
      simpleRNG = require("text!test/rng/simple.srng")
      before ->
        loader = new RNGParser()

      it "does not throw exceptions", ->
        expect(0)
        loader.process simpleRNG

      it "finds the correct grammar starts", ->
        loader.process simpleRNG
        assert(loader.start.refname).equals "__addressBook-elt-idp496"

      it "finds the correct defines", ->
        loader.process simpleRNG
        defines = ["__addressBook-elt-idp496", "__card-elt-idp1216", "__email-elt-idp2576", "__name-elt-idp2192"]
        for key, val of loader.defines
          assert(defines.indexOf key).isNotEqualTo(-1, "found #{key}")
          defines.splice defines.indexOf(key), 1
        assert(defines.length).equals 0, "did not define anything extra"

      it "stringifies properly", ->
        loader.process simpleRNG
        defines =
          "__addressBook-elt-idp496": "__addressBook-elt-idp496 = element addressBook { (empty | __card-elt-idp1216+) }"
          "__card-elt-idp1216": "__card-elt-idp1216 = element card { __name-elt-idp2192, __email-elt-idp2576 }"
          "__name-elt-idp2192": "__name-elt-idp2192 = element name { text }"
          "__email-elt-idp2576": "__email-elt-idp2576 = element email { text }"
        for key, val of loader.defines
          assert(defines[key].toString()).isEqualTo(val, "define #{key} properly stringified")

        assert(loader.start.toString()).isEqualTo("__addressBook-elt-idp496", "start properly stringified")


    describe "Kipling RNG loading", ->
      kipling = require("text!test/rng/kipling-jp3-xsl.srng")
      RNGParser = require('textorum/relaxng/parse')
      loader = undefined

      before ->
        loader = new RNGParser()
        loader.process kipling

      it "does not throw exceptions", ->
        expect(0)

      it "finds the amusing pair of start options", ->
        assert(loader.start.toString()).isEqualTo("(article-idp2181872 | hr-idp2536272)", "start is article OR hr")

      it "handles the related-article define properly", ->
        relatedArticle = loader.defines["related-article-idp2366528"]
        relatedToString = """related-article-idp2366528 = element related-article { (empty | attribute id { http://www.w3.org/2001/XMLSchema-datatypes:ID }), attribute related-article-type { text }, (empty | attribute ext-link-type { text }), (empty | attribute vol { text }), (empty | attribute page { text }), (empty | attribute issue { text }), (empty | attribute elocation-id { text }), (empty | attribute journal-id { text }), (empty | attribute journal-id-type { text }), (empty | attribute http://www.w3.org/1999/xlink:type { token "simple" }), (empty | attribute http://www.w3.org/1999/xlink:href { text }), text }"""
        assert(relatedArticle.toString()).isEqualTo(relatedToString, "related-article is defined correctly overall")
        assert(relatedArticle.constructor.name).isEqualTo("Define")
        assert(relatedArticle.pattern.constructor.name).isEqualTo("Element")
        assert(relatedArticle.pattern.pattern.constructor.name).isEqualTo("Group")


