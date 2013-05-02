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
      when 'data' then new Data _getAttr(node, "type"), _getAttr(node, "datatype"), children
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

  class Name extends NameClass
    constructor: (nameClassNode, @name) ->
      @ns = _getAttr nameClassNode, "ns"

  class NsName extends NameClass
    constructor: (nameClassNode, exceptPattern) ->
      @ns = _getAttr nameClassNode, "ns"
      @except = getPattern exceptPattern

  #** Pattern Classes

  class Pattern

  class Empty extends Pattern
    constructor: () ->

  class NotAllowed extends Pattern
    constructor: (@message, @pattern, @childNode, @priority) ->

  class MissingContent extends NotAllowed
    constructor: (@message, @pattern, @childNode, @priority) ->

  class Text extends Pattern

  class Choice extends Pattern
    constructor: (pattern1, pattern2) ->
      @pattern1 = getPattern pattern1
      @pattern2 = getPattern pattern2

  class Interleave extends Pattern
    constructor: (pattern1, pattern2) ->
      @pattern1 = getPattern pattern1
      @pattern2 = getPattern pattern2

  class Group extends Pattern
    constructor: (pattern1, pattern2) ->
      @pattern1 = getPattern pattern1
      @pattern2 = getPattern pattern2

  class OneOrMore extends Pattern
    constructor: (pattern) ->
      @pattern = getPattern pattern

  class List extends Pattern
    constructor: (pattern) ->
      @pattern = getPattern pattern

  class Data extends Pattern
    constructor: (@dataType, @paramList) ->

  class DataExcept extends Pattern
    constructor: (@dataType, @paramList, pattern) ->
      if pattern
        @pattern = getPattern pattern

  class Value extends Pattern
    constructor: (@dataType, @string, @context) ->

  class Attribute extends Pattern
    constructor: (@nameClass, pattern, @defaultValue = null) ->
      @pattern = getPattern pattern

  class Element extends Pattern
    constructor: (@name, pattern) ->
      @pattern = getPattern pattern

  class Ref extends Pattern
    constructor: (@refname, pattern = null) ->
      if pattern
        @pattern = getPattern pattern

  class Define
    constructor: (@name, pattern) ->
      @pattern = getPattern pattern


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
    ChildNode, Choice, Context, Data, DataExcept, Datatype, Define,
    Empty,
    Element, ElementNode, Group, Interleave, List, MissingContent,
    Name, NameClass, NotAllowed, NsName,
    OneOrMore, Param, Pattern, QName, Ref, Text, TextNode,
    Value }
