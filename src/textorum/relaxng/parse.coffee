# parse.coffee - Turn a RelaxNG simplified XML schema into a pattern representation
#
# Copyright (C) 2013 Crowd Favorite, Ltd. All rights reserved.
#
# This file is part of Textorum.
#
# Textorum is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# Textorum is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.

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

      @currentTag = null
      @currentPrefixMapping = {}
      @errors = []
      @output = ""
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
        @handleChildren parentNode, children

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

    handleChildren: (parentNode, children) =>
      switch h.getLocalName(parentNode)
        when "grammar"
          0 + 0
        when "start"
          if @start
            throw new RNGException("Found a second start")
          @start = children[0]
        when "define"
          @defines[h.getNodeAttr parentNode, "name"] = o.getPattern(parentNode, children)
        else
          @grammarStack.push o.getPattern(parentNode, children)

    handleGrammar: (node) =>
      if h.getLocalName(node) isnt "grammar"
        throw new RNGException("expecting grammar, found #{h.getLocalName(node)}")
      @nextHandler = @handleStart
      return node

    handleStart: (node) =>

    onopencdata: =>
      @output += "<![CDATA["
    oncdata: (data) =>
      @output += data
    onclosecdata: =>
      @output += "]]>"

    ontext: (text) =>
      text = text.replace /^\s+|\s+$/g, ''
      if text
        @grammarStack.push text

    onopennamespace: (ns) =>
      @currentPrefixMapping[ns.prefix] = ns.uri
    onclosenamespace: (ns) =>
      @currentPrefixMapping[ns.prefix] = undefined

    onend: =>
      if @debug
        console.log "defines are", @defines
        console.log "start is", @start

    process: (text) ->
      @parser.write(text)
      @parser.close()
      if @errors.length > 0
        for err in @errors
          console.error "Error parsing RelaxNG schema", err.message
        throw new Error "Error parsing RelaxNG schema"



  return RNGParser
