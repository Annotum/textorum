# objects.coffee - RELAX NG schema cache objects
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
  h = require('../helper')

  getPattern = (node, defines) =>
    if node instanceof Pattern or node instanceof NameClass
      return node
    if not node
      return new NotAllowed()

    children = node.childNodes

    pattern = switch h.getLocalName(node)
      when 'element' then new Element children[0], children[1]
      when 'define' then new Define h.getNodeAttr(node, "name"), children[0]
      when 'notAllowed' then new NotAllowed()
      when 'empty' then new Empty()
      when 'text' then new Text()
      when 'data' then new Data h.getNodeAttr(node, "datatypeLibrary"), h.getNodeAttr(node, "type"), children
      when 'value' then new Value(h.getNodeAttr(node, "dataTypeLibrary"),
        h.getNodeAttr(node, "type"), h.getNodeAttr(node, "ns"), children[0])
      when 'list' then new List children[0]
      when 'attribute' then new Attribute children[0], children[1]
      when 'ref' then new Ref h.getNodeAttr(node, "name"), defines
      when 'oneOrMore' then new OneOrMore children[0]
      when 'choice' then new Choice children[0], children[1]
      when 'group' then new Group children[0], children[1]
      when 'interleave' then new Interleave children[0], children[1]
      when "anyName" then new AnyName children[0]
      when "nsName" then new NsName h.getNodeAttr(node, "ns"), children[0]
      when "name" then new Name h.getNodeAttr(node, "ns"), children[0]
      when "choice" then new Choice children[0], children[1]
      when 'except' then getPattern children[0]
      when 'param' then new Param h.getNodeAttr(node, "name"), children[0]
      else
        throw new RNGException("can't parse pattern for #{h.getLocalName(node)}")
    pattern


  class RNGException extends Error
    constructor: (message, @node = null, @parser = null) ->
      return super message

  # Param - represents a single (localName, string) tuple
  class Param
    constructor: (@localName, @string) ->

  class Context
    constructor: (@uri, @map) ->

  class Datatype
    constructor: (@uri, @localName) ->

  #** Name Classes

  class NameClass
    contains: (node) =>
      throw new RNGException("Checking contains(#{node}) on undefined NameClass")

  class AnyName extends NameClass
    constructor: (exceptPattern) ->
      @except = getPattern exceptPattern
    contains: (node) =>
      unless @except instanceof NotAllowed
        return not @except.contains(node)
      true
    toString: =>
      if @except instanceof NotAllowed
        "*"
      else
        "* - #{@except}"

  class Name extends NameClass
    constructor: (@ns, @name) ->
    contains: (node) =>
      # TODO: namespace URI handling
      @name is h.getLocalName(node)
    toString: =>
      if @ns
        "#{@ns}:#{@name}"
      else
        "#{@name}"

  class NsName extends NameClass
    constructor: (@ns, exceptPattern) ->
      @except = getPattern exceptPattern
    contains: (node) =>
      # TODO: namespace URI handling
      unless @except instanceof NotAllowed
        @except.contains(node)
      true
    toString: =>
      if @except instanceof NotAllowed
        "#{@ns}:*"
      else
        "#{@ns}:* - #{@except}]"

  #** Pattern Classes

  class Pattern
    check: (node) =>
      return new NotAllowed("pattern check failed", this, node)
    attrCheck: (node) =>
      return new NotAllowed("invalid attribute", this, node)
    toString: =>
      "<UNDEFINED PATTERN>"
    nullable: =>
      false
    contains: (nodeName) =>
      throw new RNGException("Cannot call 'contains(#{nodeName})' on pattern '#{@toString()}'")
    dereference: =>
      return this

  class Empty extends Pattern
    constructor: ->
    toString: =>
      "empty"
    nullable: =>
      true
    check: (node) =>
      if h.getNodeType(node) is Node.TEXT_NODE and node.replace(/^\s+|\s+$/gm, "") is ""
        return this
      return new NotAllowed("expected nothing, found #{h.getLocalName(node)}", this, node)
    attrCheck: (node) =>
      return this

  class NotAllowed extends Pattern
    constructor: (@message, @pattern, @childNode, @priority) ->
    toString: =>
      if @message
        "notAllowed # #{@message}\n"
      else
        "notAllowed"
    check: (node) =>
      return this
    attrCheck: (node) =>
      return this

  class MissingContent extends NotAllowed
    constructor: (@message, @pattern, @childNode, @priority) ->
    toString: =>
      if @message
        "missingContent # #{@message}\n"
      else
        "missingContent"

  class Text extends Empty
    toString: =>
      "text"
    check: (node) =>
      switch h.getNodeType(node)
        when Node.TEXT_NODE
          return this
        else
          return new NotAllowed("expected text node, found #{h.getLocalName(node)}", this, node)
    nullable: =>
      true

  class Choice extends Pattern
    constructor: (pattern1, pattern2) ->
      @pattern1 = getPattern pattern1
      @pattern2 = getPattern pattern2
    toString: =>
      "(#{@pattern1} | #{@pattern2})"
    contains: (nodeName) =>
      @pattern1.contains(nodeName) or @pattern2.contains(nodeName)
    nullable: =>
      @pattern1.nullable() or @pattern2.nullable()
    check: (node) =>
      if @pattern1 instanceof NotAllowed
        return @pattern2.check(node)
      p1 = @pattern1.check(node)
      if p1 instanceof NotAllowed
        return @pattern2.check(node)
      p2 = @pattern2.check(node)
      if p2 instanceof NotAllowed
        return p1
      return new Choice(p1, p2)
    attrCheck: (node) =>
      p1 = @pattern1.attrCheck(node)
      p2 = @pattern2.attrCheck(node)
      return new Choice(p1, p2)

  class Interleave extends Pattern
    constructor: (pattern1, pattern2) ->
      @pattern1 = getPattern pattern1
      @pattern2 = getPattern pattern2
    toString: =>
      "(#{@pattern1} & #{@pattern2})"
    nullable: =>
      @pattern1.nullable() and @pattern2.nullable()
    check: (node) =>
      if @pattern1 instanceof NotAllowed or @pattern2 instanceof Empty
        return @pattern1.check(node)
      if @pattern2 instanceof NotAllowed or @pattern1 instanceof Empty
        return @pattern2.check(node)
      p1 = @pattern1.check(node)
      unless p1 instanceof NotAllowed
        return @pattern2
      p2 = @pattern2.check(node)
      unless p2 instanceof NotAllowed
        return @pattern1
      return new Interleave(p1, p2)
    attrCheck: (node) =>
      p1 = @pattern1.attrCheck(node)
      choice1 = new Interleave(p1, @pattern2)
      p2 = @pattern2.attrCheck(node)
      choice2 = new Interleave(@pattern1, p2)
      return new Choice(choice1, choice2)


  class Group extends Pattern
    constructor: (pattern1, pattern2) ->
      @pattern1 = getPattern pattern1
      @pattern2 = getPattern pattern2
    toString: =>
      "#{@pattern1}, #{@pattern2}"
    nullable: =>
      @pattern1.nullable() and @pattern2.nullable()
    check: (node) =>
      if @pattern1.instanceof NotAllowed or @pattern2 instanceof Empty
        return @pattern1.check(node)
      if @pattern2.instanceof NotAllowed or @pattern1 instanceof Empty
        return @pattern2.check(node)
      p1 = @pattern1.check(node)
      if p1 instanceof NotAllowed
        return p1
      p2 = @pattern2.check(node)
      if p2.instanceof NotAllowed
        return p2
      return new Group(p1, p2)
    attrCheck: (node) =>
      p1 = @pattern1.attrCheck(node)
      choice1 = new Group(p1, @pattern2)
      p2 = @pattern2.attrCheck(node)
      choice2 = new Group(@pattern1, p2)
      return new Choice(choice1, choice2)


  class OneOrMore extends Pattern
    constructor: (pattern) ->
      @pattern = getPattern pattern
    toString: =>
      "#{@pattern}+"
    nullable: =>
      @pattern.nullable()
    check: (node) =>
      p1 = @pattern.check(node)
      if p1 instanceof NotAllowed
        return p1
      return this
    attrCheck: (node) =>
      p1 = @pattern.attrCheck(node)
      return new Group(p1, new Choice(@pattern, new Empty()))

  class List extends Pattern
    constructor: (pattern) ->
      @pattern = getPattern pattern
    toString: =>
      "list { #{@pattern} }"
    check: (node) =>
      switch h.getNodeType(node)
        when Node.TEXT_NODE
          for text in h.textContent(node).split(/\s+/)
            if text
              res = @pattern.check(text)
              if res instanceof NotAllowed
                return res
          return new Empty()
        else
          return new NotAllowed("expected text node, found #{h.getLocalName(node)}", this, node)


  class Data extends Pattern
    constructor: (@dataType, @type, paramList) ->
      @params = []
      @except = new NotAllowed()
      for param in paramList
        if param.local is "param"
          @params.push getPattern param
        else if param.local is "except"
          @except = getPattern param

    toString: =>
      output = ""
      if @dataType
        output += "#{@dataType}:"
      output += "#{@type}"
      if @paramList
        output += " { #{@paramList} }"
      unless @except instanceof NotAllowed
        output += " - #{@except}"
      output
    check: (node) =>
      unless @except instanceof NotAllowed
        except = @except.check(node)
        if except instanceof NotAllowed
          return except
      switch h.getNodeType(node)
        when Node.TEXT_NODE
          # TODO: handle data validation
          return new Empty()
        else
          return new NotAllowed("expected text(data) node, found #{h.getLocalName(node)}", this, node)

  class Value extends Pattern
    constructor: (@dataType, @type, @ns, @string) ->
    toString: =>
      output = ""

      if @dataType
        output += "" + @dataType + ":"
      if @type
        output += "#{@type} "
      output += '"' + @string + '"'
    check: (node) =>
      switch h.getNodeType(node)
        when Node.TEXT_NODE
          # TODO: handle proper value validation
          if h.textContent(node) is @string
            return new Empty()
          return new NotAllowed("expected #{@string}, found #{h.textContent(node)}", this, node)
        else
          return new NotAllowed("expected text(value) node, found #{h.getLocalName(node)}", this, node)

  class Attribute extends Pattern
    constructor: (@nameClass, pattern, @defaultValue = null) ->
      @pattern = getPattern pattern
    toString: =>
      "attribute #{@nameClass} { #{@pattern} }"
    check: (node) =>
      return new Empty()
    attrCheck: (node) =>
      error = []
      for attr in h.getNodeAttributes(node)
        if @nameClass.contains(attr.name)
          attrCheck = @pattern.check(attr.value)
          unless attrCheck instanceof NotAllowed
            return new Empty()
          error.push attrCheck

      if attrCheck.length
        return new NotAllowed("Attribute failure: #{error.join(',')}", this, node)
      return new MissingContent("expected to find an attribute #{@nameClass}", this, node)


  class Element extends Pattern
    constructor: (name, pattern) ->
      @name = getPattern name
      @pattern = getPattern pattern
    toString: =>
      "element #{@name} { #{@pattern} }"
    check: (node, parent, descend = false) =>
      nameCheck = @name.contains node
      if nameCheck instanceof NotAllowed
        return nameCheck
      attrCheck = @pattern.attrCheck node
      if attrCheck instanceof NotAllowed
        return attrCheck
      if descend
        nextPattern = @pattern
        for child in h.childNodes
          nextPattern = nextPattern.check(child, descend)
          if nextPattern instanceof NotAllowed
            return nextPattern



  class Ref extends Pattern
    constructor: (@refname, @defines) ->
      @dereference()
    toString: =>
      @refname
    check: (node) =>
      @dereference()
      if @pattern?
        if not @pattern.check?
          console.log("failed", this)
        return @pattern.check(node)
      return new NotAllowed("cannot find reference '#{@refname}'", this, node)
    dereference: =>
      return @pattern if @pattern?
      if @defines and @defines[@refname]?
        @pattern = @defines[@refname]
      @pattern

  class Define
    constructor: (@name, pattern) ->
      @pattern = getPattern pattern
    toString: =>
      "#{@name} = #{@pattern}"
    check: (node) =>
      @pattern.check(node)
    attrCheck: (node) =>
      @pattern.attrCheck(node)

  { getPattern,
    AnyName, Attribute,
    Choice, Context,
    Data, Datatype, Define,
    Empty, Element,
    Group,
    Interleave,
    List,
    MissingContent,
    Name, NameClass, NotAllowed, NsName,
    OneOrMore,
    Param, Pattern,
    Ref,
    Text,
    Value
  }
