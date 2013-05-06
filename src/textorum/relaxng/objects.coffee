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

  getPattern = (node) =>
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
      when 'value' then new Value h.getNodeAttr(node, "dataTypeLibrary"), h.getNodeAttr(node, "type"), h.getNodeAttr(node, "ns"), children[0]
      when 'list' then new List children[0]
      when 'attribute' then new Attribute children[0], children[1]
      when 'ref' then new Ref h.getNodeAttr(node, "name")
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

  class AnyName extends NameClass
    constructor: (exceptPattern) ->
      @except = getPattern exceptPattern
    toString: =>
      if @except instanceof NotAllowed
        "*"
      else
        "* - #{@except}"

  class Name extends NameClass
    constructor: (@ns, @name) ->
    toString: =>
      if @ns
        "#{@ns}:#{@name}"
      else
        "#{@name}"

  class NsName extends NameClass
    constructor: (@ns, exceptPattern) ->
      @except = getPattern exceptPattern
    toString: =>
      if @except instanceof NotAllowed
        "#{@ns}:*"
      else
        "#{@ns}:* - #{@except}]"

  #** Pattern Classes

  class Pattern
    check: (node) =>
      return new NotAllowed()
    nullable: =>
      false

  class Empty extends Pattern
    constructor: ->
    toString: =>
      "empty"
    nullable: =>
      true

  class NotAllowed extends Pattern
    constructor: (@message, @pattern, @childNode, @priority) ->
    toString: =>
      if @message
        "notAllowed # #{@message}\n"
      else
        "notAllowed"
    check: (node) =>
      return this

  class MissingContent extends NotAllowed
    constructor: (@message, @pattern, @childNode, @priority) ->
    toString: =>
      if @message
        "missingContent # #{@message}\n"
      else
        "missingContent"

  class Text extends Pattern
    toString: =>
      "text"
    check: (node) =>
      switch h.getNodeType()
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
    nullable: =>
      @pattern1.nullable() or @pattern2.nullable()
    check: (node) =>
      if @pattern1 instanceof NotAllowed
        return @pattern2.check(node)
      @pattern1.check(node)


  class Interleave extends Pattern
    constructor: (pattern1, pattern2) ->
      @pattern1 = getPattern pattern1
      @pattern2 = getPattern pattern2
    toString: =>
      "(#{@pattern1} & #{@pattern2})"
    nullable: =>
      @pattern1.nullable() and @pattern2.nullable()

  class Group extends Pattern
    constructor: (pattern1, pattern2) ->
      @pattern1 = getPattern pattern1
      @pattern2 = getPattern pattern2
    toString: =>
      "#{@pattern1}, #{@pattern2}"
    nullable: =>
      @pattern1.nullable() and @pattern2.nullable()

  class OneOrMore extends Pattern
    constructor: (pattern) ->
      @pattern = getPattern pattern
    toString: =>
      "#{@pattern}+"
    nullable: =>
      @pattern.nullable()

  class List extends Pattern
    constructor: (pattern) ->
      @pattern = getPattern pattern
    toString: =>
      "list { #{@pattern} }"

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

  class Value extends Pattern
    constructor: (@dataType, @type, @ns, @string) ->
    toString: =>
      output = ""

      if @dataType
        output += "" + @dataType + ":"
      if @type
        output += "#{@type} "
      output += '"' + @string + '"'

  class Attribute extends Pattern
    constructor: (@nameClass, pattern, @defaultValue = null) ->
      @pattern = getPattern pattern
    toString: =>
      "attribute #{@nameClass} { #{@pattern} }"

  class Element extends Pattern
    constructor: (@name, pattern) ->
      @pattern = getPattern pattern
    toString: =>
      "element #{@name} { #{@pattern} }"

  class Ref extends Pattern
    constructor: (@refname, pattern = null) ->
      if pattern
        @pattern = getPattern pattern
    toString: =>
      @refname

  class Define
    constructor: (@name, pattern) ->
      @pattern = getPattern pattern
    toString: =>
      "#{@name} = #{@pattern}"

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
