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
  _getAttr = (node, attr) ->
    return node?.attributes?[attr]?.value

  getPattern = (node, children = []) =>
    if node instanceof Pattern or node instanceof NameClass
      return node
    if not node
      return new NotAllowed()
    foo = switch node.local
      when 'element' then new Element children[0], children[1]
      when 'define' then new Define _getAttr(node, "name"), children[0]
      when 'notAllowed' then new NotAllowed()
      when 'empty' then new Empty()
      when 'text' then new Text()
      when 'data' then new Data _getAttr(node, "datatypeLibrary"), _getAttr(node, "type"), children
      when 'value' then new Value _getAttr(node, "dataTypeLibrary"), _getAttr(node, "type"), _getAttr(node, "ns"), children[0]
      when 'list' then new List children[0]
      when 'attribute' then new Attribute children[0], children[1]
      when 'ref' then new Ref _getAttr(node, "name")
      when 'oneOrMore' then new OneOrMore children[0]
      when 'choice' then new Choice children[0], children[1]
      when 'group' then new Group children[0], children[1]
      when 'interleave' then new Interleave children[0], children[1]
      when "anyName" then new AnyName node, children[0]
      when "nsName" then new NsName node, children[0]
      when "name" then new Name node, children[0]
      when "choice" then new Choice children[0], children[1]
      when 'except' then getPattern children[0]
      when 'param' then new Param _getAttr(node, "name"), children[0]
      else
        throw new RNGException("can't parse pattern for #{node.local}")
    foo


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
    constructor: (nameClassNode, exceptPattern) ->
      @except = getPattern exceptPattern
    toString: =>
      if @except instanceof NotAllowed
        "*"
      else
        "* - #{@except}"

  class Name extends NameClass
    constructor: (nameClassNode, @name) ->
      @ns = _getAttr nameClassNode, "ns"
    toString: =>
      if @ns
        "#{@ns}:#{@name}"
      else
        "#{@name}"

  class NsName extends NameClass
    constructor: (nameClassNode, exceptPattern) ->
      @ns = _getAttr nameClassNode, "ns"
      @except = getPattern exceptPattern
    toString: =>
      if @except instanceof NotAllowed
        "#{@ns}:*"
      else
        "#{@ns}:* - #{@except}]"

  #** Pattern Classes

  class Pattern

  class Empty extends Pattern
    constructor: ->
    toString: =>
      "empty"

  class NotAllowed extends Pattern
    constructor: (@message, @pattern, @childNode, @priority) ->
    toString: =>
      if @message
        "notAllowed # #{@message}\n"
      else
        "notAllowed"

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

  class Choice extends Pattern
    constructor: (pattern1, pattern2) ->
      @pattern1 = getPattern pattern1
      @pattern2 = getPattern pattern2
    toString: =>
      "(#{@pattern1} | #{@pattern2})"

  class Interleave extends Pattern
    constructor: (pattern1, pattern2) ->
      @pattern1 = getPattern pattern1
      @pattern2 = getPattern pattern2
    toString: =>
      "(#{@pattern1} & #{@pattern2})"

  class Group extends Pattern
    constructor: (pattern1, pattern2) ->
      @pattern1 = getPattern pattern1
      @pattern2 = getPattern pattern2
    toString: =>
      "#{@pattern1}, #{@pattern2}"

  class OneOrMore extends Pattern
    constructor: (pattern) ->
      @pattern = getPattern pattern
    toString: =>
      "#{@pattern}+"

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


  #** QName - label for elements and attributes

  class QName
    constructor: (@uri, @localName) ->

  #** XML document classes

  class ChildNode

  class ElementNode extends ChildNode
    constructor: (@qName, @context, @attributeNodes, @childNodes) ->

  class TextNode extends ChildNode
    constructor: (@string)

  class AttributeNode
    constructor: (@qName, @string) ->

  { _getAttr, getPattern, AnyName, Attribute, AttributeNode,
    ChildNode, Choice, Context, Data, Datatype, Define,
    Empty,
    Element, ElementNode, Group, Interleave, List, MissingContent,
    Name, NameClass, NotAllowed, NsName,
    OneOrMore, Param, Pattern, QName, Ref, Text, TextNode,
    Value }
