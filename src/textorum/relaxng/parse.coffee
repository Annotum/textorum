# parse.coffee - Turn a RelaxNG simplified XML schema into a pattern representation
#
# Copyright (C) 2013 Crowd Favorite, Ltd. All rights reserved.
#
# This file is part of Textorum.
#
# Licensed under the MIT license:
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

define (require) ->
  sax = require('sax')
  h = require('../helper')
  o = require('./objects')

  _rngURI = 'http://relaxng.org/ns/structure/1.0'
  _annURI = 'http://relaxng.org/ns/compatibility/annotations/1.0'

  RNGException = o.RNGException

  class RNGParser
    constructor: ->
      @nodeStack = []
      @grammarStack = []
      @rngStack = []

      @defines = {}
      @start = null

      @debug = false

      @currentPrefixMapping = {}
      @errors = []

      saxOptions =
        xmlns: true
        trim: false
        normalize: false
        position: true
      @parser = sax.parser(true, saxOptions)
      for event in sax.EVENTS
        @parser["on#{event}"] = this["on#{event}"] if this["on#{event}"]

    onerror: (error) =>
      @errors.push error
      console.log "error", error.message
      @parser.resume()

    onopentag: (node) =>
      @nodeStack.push node
      if node.uri isnt _rngURI
        return
      @grammarStack.push node

      if @nodeIsParent node
        @rngStack.push node

    onclosetag: (tagname) =>
      prevnode = @nodeStack.pop()
      if prevnode is @rngStack[@rngStack.length - 1]
        parentNode = @rngStack.pop()
        children = []
        while @grammarStack[@grammarStack.length - 1] isnt parentNode and @grammarStack
          children.unshift @grammarStack.pop()
        @grammarStack.pop()
        parentNode.childNodes = children
        @handleChildren parentNode

    nodeIsParent: (node) =>
      return switch h.getLocalName(node)
        when "grammar", "start", "define", "element", "data", "value", "list"
          true
        when "attribute", "ref", "oneOrMore", "choice", "group", "interleave"
          true
        when "param"
          true
        when "except"
          true
        when "anyName", "nsName", "name", "choice"
          true
        else
          false

    handleChildren: (parentNode) =>
      switch h.getLocalName(parentNode)
        when "grammar"
          0 + 0
        when "start"
          if @start
            throw new RNGException("Found a second start")
          @start = parentNode.childNodes[0]
        when "define"
          @defines[h.getNodeAttr parentNode, "name"] = o.getPattern parentNode, @defines
        else
          @grammarStack.push o.getPattern parentNode, @defines

    ontext: (text) =>
      strippedtext = text.replace /^\s+|\s+$/g, ''
      if strippedtext
        @grammarStack.push text

    onopennamespace: (ns) =>
      @currentPrefixMapping[ns.prefix] = ns.uri
    onclosenamespace: (ns) =>
      @currentPrefixMapping[ns.prefix] = undefined

    onend: =>
      if @debug
        console.log "defines are", @defines
        console.log "start is", @start

    getObjects: ->
      return o

    process: (text, skipAttributes) ->
      o.setSkipAttributes skipAttributes
      @parser.write(text)
      @parser.close()
      if @errors.length > 0
        for err in @errors
          console.error "Error parsing RelaxNG schema", err.message
        throw new Error "Error parsing RelaxNG schema"



  return {
    RNGParser: RNGParser
  }
