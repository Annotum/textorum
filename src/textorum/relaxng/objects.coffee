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

  DEBUG = false

  setDebug = (debug) =>
    DEBUG = debug
    return DEBUG

  ### @private ###
  _nodelog = (node, message...) =>
    unless DEBUG
      return
    depth = h.depth(node) + 0
    indent = ""
    x = 0
    while x < depth
      indent += "| "
      x += 1
    if indent.length
      message.unshift indent
    console.log.apply(console, message)

  ###*
   * Create a pattern from a node (or return a {@link Pattern} unmodified)
   * @param  {Pattern,Node} node
   * @param  {Object} defines The (shared) named pattern definitions
   * @return {Pattern}
  ###
  getPattern = (node, defines) =>
    if node instanceof Pattern
      return node
    if not node
      return new NotAllowed("trying to load empty pattern")

    children = node.childNodes

    pattern = switch h.getLocalName(node)
      when 'element' then new Element children[0], children[1]
      when 'define' then new Define h.getNodeAttr(node, "name"), children[0]
      when 'notAllowed' then new NotAllowed("not allowed by pattern", node)
      when 'empty' then new EmptyNode("empty node", node)
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

  ###*
   * Superclass for all (simplified) RNG pattern representation nodes
  ###
  class Pattern
    ###*
     * Interface for running node validity tests
     *
     * @param  {Node} node    DOM Node to check
     * @param  {Boolean|Integer} descend Boolean true: Unlimited descent.  Integer: Descend to that total depth
     * @return {Node}         Composed node - Empty, NotAllowed, or Choice/Group/etc types
    ###
    check: (node, descend) =>
      unless node?
        _nodelog node, "missing node", node, this
        throw new Error("ack node missing")
      _nodelog node, "checking #{this} against", node, [this, node]
      res = @_check(node, descend)
      _nodelog node, "result for #{this} against", node, "is #{res}", [this, node, res]
      return res
    ###*
     * Implementation for running node validity tests per-type, intended to be overridden
     *
     * @see Pattern#check
    ###
    _check: (node, descend) =>
      return new NotAllowed("pattern check failed", this, node)

    ###*
     * Check the validity of this node's attributes
     * @param  {Node} node
     * @return {Pattern}      an Empty or NotAllowed type
    ###
    attrCheck: (node) =>
      return new Empty("not checking an attribute", this, node)

    toString: =>
      "<UNDEFINED PATTERN>"

    nullable: =>
      false
    ###*
     * Reduce this pattern to a minimum, preferring successful validation.  Choices prefer
     *   GoodElement status.
     * @return {Node} GoodElement or NotAllowed type
    ###
    require: =>
      return this

    ###*
     * Stub for Name class patterns
     * @see NameClass#contains
    ###
    contains: (nodeName) =>
      throw new RNGException("Cannot call 'contains(#{nodeName})' on pattern '#{@toString()}'")

    ###*
     * Stub for Ref class patterns
     * @see Ref#dereference
    ###
    dereference: =>
      return this

  #** Name Classes

  class NameClass extends Pattern
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

  ###*
   * Nulled portion of a pattern.
  ###
  class Empty extends Pattern
    constructor: (@message, @pattern, @childNode) ->
    toString: =>
      if @message
        "(null: #{@message})"
      else
        "(null)"
    nullable: =>
      true
    _check: (node, descend) =>
      return this
    attrCheck: (node) =>
      return this

  ###*
   * An empty Pattern node, matching only comments and empty text node blocks
  ###
  class EmptyNode extends Empty
    constructor: (@message, @pattern, @childNode) ->
    toString: =>
      "empty"
    nullable: =>
      true
    require: =>
      return new Empty("#{this}", this)
    _check: (node, descend) =>
      switch h.getNodeType(node)
        when Node.TEXT_NODE
          if h.textContent(node).replace(/^\s+|\s+$/gm, "") is ""
            return this
        when Node.COMMENT_NODE
          return this
      return new NotAllowed("expected nothing, found #{h.getLocalName(node)}", this, node)
    attrCheck: (node) =>
      return this

  ###*
   * A pattern denying all contents
  ###
  class NotAllowed extends Pattern
    constructor: (@message, @pattern, @childNode, @priority) ->
    toString: =>
      if @message
        "notAllowed { #{@message} }"
      else
        "notAllowed"
    _check: (node, descend) =>
      return this
    attrCheck: (node) =>
      return this

  ###*
   * A pattern indicating missing content (end state)
  ###
  class MissingContent extends NotAllowed
    constructor: (@message, @pattern, @childNode, @priority) ->
    toString: =>
      if @message
        "missingContent { #{@message} }"
      else
        "missingContent"

  ###*
   * A pattern accepting any text content
  ###
  class Text extends Empty
    toString: =>
      "text"
    _check: (node, descend) =>
      switch h.getNodeType(node)
        when Node.TEXT_NODE
          return this
        else
          return new NotAllowed("expected text node, found #{h.getLocalName(node)}", this, node)
    nullable: =>
      true

  ###*
   * A pattern fulfilled by either of its sub-pattern branches reducing to Empty
  ###
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
    require: =>
      p1 = @pattern1.require()
      if p1 instanceof GoodElement
        return p1
      p2 = @pattern2.require()
      if p2 instanceof GoodElement
        return p2
      if p1 instanceof NotAllowed
        if p2 instanceof Empty
          return new Empty("#{p2}", p2)
        return new Choice(p1, new MissingContent("Missing: #{p2}", p2))
      if p2 instanceof NotAllowed
        if p1 instanceof Empty
          return new Empty("#{p1}", p1)
        return new Choice(new MissingContent("Missing: #{p1}"), p2)
      if p2 instanceof Empty
        return new Empty("#{p2}", p2)
      return p2

    _check: (node, descend) =>
      if @pattern1 instanceof Empty and @pattern2 instanceof Attribute
        return @pattern1
      if @pattern2 instanceof Empty and @pattern1 instanceof Attribute
        return @pattern2
      if @pattern1 instanceof GoodElement
        return @pattern1
      if @pattern2 instanceof GoodElement
        return @pattern2
      # if @pattern1 instanceof NotAllowed
      #   return @pattern2.check(node, descend)
      # if @pattern2 instanceof NotAllowed
      #   return @pattern1.check(node, descend)
      p1 = @pattern1.check(node, descend)
      p2 = @pattern2.check(node, descend)
      if @pattern2 + "" is "c-idp9392+"
        console.log "tick"
      if p1 instanceof NotAllowed and @pattern1.require() instanceof Empty
        return new Choice(@pattern1, p2)
      if p2 instanceof NotAllowed and @pattern2.require() instanceof Empty
        return new Choice(p1, @pattern2)
      if p2.require() instanceof Empty and p1.require() instanceof Empty
        if p1 instanceof Empty
          return p2
        if p2 instanceof Empty
          return p1
        return new Choice(p1, p2)
      if p1 instanceof NotAllowed and p2 instanceof NotAllowed
        failed = new Choice(p1, p2)
        return new NotAllowed("choice failed: #{failed}", failed, node)
      return new Choice(p1, p2)
    attrCheck: (node) =>
      if @pattern1 instanceof NotAllowed or @pattern1 instanceof Empty
        return @pattern2.attrCheck(node)
      if @pattern2 instanceof NotAllowed or @pattern2 instanceof Empty
        return @pattern1.attrCheck(node)
      p1 = @pattern1.attrCheck(node)
      if p1 instanceof NotAllowed
        return @pattern2.attrCheck(node)
      p2 = @pattern2.attrCheck(node)
      if p2 instanceof NotAllowed or p2 instanceof Empty
        return p1
      if p1 instanceof Empty
        return p2
      return (new Choice(p1, p2)).attrCheck(node)

  ###*
   * A pattern requiring both of its subpatterns to be valid, in any order
  ###
  class Interleave extends Pattern
    constructor: (pattern1, pattern2) ->
      @pattern1 = getPattern pattern1
      @pattern2 = getPattern pattern2
    toString: =>
      "(#{@pattern1} & #{@pattern2})"
    nullable: =>
      @pattern1.nullable() and @pattern2.nullable()
    require: =>
      p1 = @pattern1.require()
      if p1 instanceof Empty
        return @pattern2.require()
      p2 = @pattern2.require()
      if p2 instanceof Empty
        return p1
      if p1 instanceof GoodElement and p2 instanceof GoodElement
        return p1
      if p1 instanceof NotAllowed
        return p1
      if p2 instanceof NotAllowed
        return p2
      return p2

    _check: (node, descend) =>
      if @pattern1 instanceof NotAllowed or @pattern2 instanceof Empty
        return @pattern1.check(node, descend)
      if @pattern2 instanceof NotAllowed or @pattern1 instanceof Empty
        return @pattern2.check(node, descend)
      p1 = @pattern1.check(node, descend)
      unless p1 instanceof NotAllowed
        return @pattern2
      p2 = @pattern2.check(node, descend)
      unless p2 instanceof NotAllowed
        return @pattern1
      return new Interleave(p1, p2)
    attrCheck: (node) =>
      p1 = @pattern1.attrCheck(node)
      choice1 = new Interleave(p1, @pattern2)
      p2 = @pattern2.attrCheck(node)
      choice2 = new Interleave(@pattern1, p2)
      return (new Choice(choice1, choice2)).attrCheck(node)

  ###*
   * A pattern requiring both of its subpatterns to be valid, in the given order
  ###
  class Group extends Pattern
    constructor: (pattern1, pattern2) ->
      @pattern1 = getPattern pattern1
      @pattern2 = getPattern pattern2
    toString: =>
      "#{@pattern1}, #{@pattern2}"
    nullable: =>
      @pattern1.nullable() and @pattern2.nullable()
    require: =>
      p1 = @pattern1.require()
      p2 = @pattern2.require()
      if p1 instanceof GoodElement
        if p2 instanceof Empty
          return p1
      if p2 instanceof GoodElement
        if p1 instanceof Empty
          return p2
      if p1 instanceof Empty and p2 instanceof Empty
        return p1
      if p1 instanceof Empty
        return new MissingContent("missing group element 2", this)
      if p2 instanceof Empty
        return new MissingContent("missing group element 1", this)
      return new MissingContent("missing both group elements", this)

    _check: (node, descend) =>
      if @pattern2 instanceof GoodElement
        return new Empty("null branch")
      if @pattern1 instanceof Empty and @pattern2 instanceof Empty
        return @pattern1
      if @pattern1 instanceof NotAllowed
        return @pattern1
      if @pattern2 instanceof NotAllowed
        return @pattern2
      if @pattern1 instanceof Empty or @pattern1 instanceof GoodElement
        return @pattern2.check(node, descend)
      if @pattern2 instanceof Empty
        return @pattern1.check(node, descend)
      _nodelog node, "p1 group, checking pattern1 #{@pattern1} against", node, [this, @pattern1, node]
      p1 = @pattern1.check(node, descend)
      if p1 instanceof NotAllowed
        return p1
      if p1 instanceof GoodElement
        return @pattern2
      _nodelog node, "p2 group, checking pattern2 #{@pattern2} against", node, [this, @pattern2, node]
      p2 = @pattern2.check(node, descend)
      if p2 instanceof NotAllowed
        # Return nullabled group
        return new Group(p1, @pattern2)
      return new Group(p1, p2)
    attrCheck: (node) =>
      p1 = @pattern1.attrCheck(node)
      if p1 instanceof NotAllowed or p1 instanceof Empty
        return @pattern2.attrCheck(node)
      p2 = @pattern2.attrCheck(node)
      if p2 instanceof NotAllowed or p2 instanceof Empty
        return p1
      return (new Interleave(p1, p2)).attrCheck(node)

  ###*
   * A pattern that requires at least one instance of its subpattern to be valid.
   *     Becomes a {@link Choice} between {@link Empty} and itself when satisfied.
  ###
  class OneOrMore extends Pattern
    constructor: (pattern) ->
      @pattern = getPattern pattern
    toString: =>
      "#{@pattern}+"
    nullable: =>
      @pattern.nullable()
    require: =>
      return new MissingContent("missing #{this}", this)
    _check: (node, descend) =>
      p1 = @pattern.check(node, descend)
      if p1 instanceof NotAllowed
        return p1
      return new Choice(new Empty("oneOrMore satisfied"), this)
    attrCheck: (node) =>
      p1 = @pattern.attrCheck(node)
      return (new Choice(new Empty("oneOrMore satisfied"), this))

  ###*
   * A pattern that matches space-separated text tokens against its subpattern
  ###
  class List extends Pattern
    constructor: (pattern) ->
      @pattern = getPattern pattern
    toString: =>
      "list { #{@pattern} }"
    _check: (node, descend) =>
      switch h.getNodeType(node)
        when Node.TEXT_NODE
          for text in h.textContent(node).split(/\s+/)
            if text
              res = @pattern.check(text, descend)
              if res instanceof NotAllowed
                return res
          return new Empty()
        else
          return new NotAllowed("expected text node, found #{h.getLocalName(node)}", this, node)

  ###*
   * A pattern that matches data against a data validation library (currently unimplemented)
  ###
  class Data extends Pattern
    constructor: (@dataType, @type, paramList) ->
      @params = []
      @except = new NotAllowed("shouldn't happen - data except")
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
    _check: (node, descend) =>
      unless @except instanceof NotAllowed
        except = @except.check(node, descend)
        if except instanceof NotAllowed
          return except
      switch h.getNodeType(node)
        when Node.TEXT_NODE
          # TODO: handle data validation
          return new Empty()
        else
          return new NotAllowed("expected text(data) node, found #{h.getLocalName(node)}", this, node)

  ###*
   * A pattern that matches data against a given value (currently minimally implemented)
  ###
  class Value extends Pattern
    constructor: (@dataType, @type, @ns, @string) ->
    toString: =>
      output = ""

      if @dataType
        output += "" + @dataType + ":"
      if @type
        output += "#{@type} "
      output += '"' + @string + '"'
    _check: (node, descend) =>
      switch h.getNodeType(node)
        when Node.TEXT_NODE
          # TODO: handle proper value validation
          if h.textContent(node) is @string
            return new Empty()
          return new NotAllowed("expected #{@string}, found #{h.textContent(node)}", this, node)
        else
          return new NotAllowed("expected text(value) node, found #{h.getLocalName(node)}", this, node)

  ###*
   * A pattern that matches an attribute (name, value) on the given node
  ###
  class Attribute extends Pattern
    constructor: (@nameClass, pattern, @defaultValue = null) ->
      @pattern = getPattern pattern
    toString: =>
      "attribute #{@nameClass} { #{@pattern} }"
    _check: (node, descend) =>
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

  ###*
   * {@link Empty} subclass that specifically indicates a good element
  ###
  class GoodElement extends Empty
    constructor: (@name, @pattern) ->
    toString: => "(GOOD) element #{@name}"
    _check: (node, descend = false) =>
      throw new Error("checking good stuff")
      return this

  ###*
   * {@link GoodElement} subclass that has (unvalidated) children of the node remaining
  ###
  class GoodParentElement extends GoodElement
    constructor: (@name, @pattern, @childNodes) ->
      super(name, pattern)
    toString: => "(GOOD) element #{@name} (with #{childNodes?.length + 0} children)"

  ###*
   * Pattern matching an element node, validating name, attributes (disabled),
   *     and children (optionally)
  ###
  class Element extends Pattern
    constructor: (name, pattern) ->
      @name = getPattern name
      @pattern = getPattern pattern
    toString: =>
      "element #{@name} { #{@pattern} }"
    _check: (node, descend = false) =>
      nameCheck = @name.contains node
      _nodelog node, "Namechecking", node, "against", @name, "result", nameCheck
      if not nameCheck
        return new NotAllowed("name check failed - expecting #{@name}, found #{h.getLocalName(node)}", @name, node)
      if nameCheck instanceof NotAllowed
        return nameCheck
      # attrCheck = @pattern.attrCheck node
      # if attrCheck instanceof NotAllowed
      #   return attrCheck
      if descend
        unless descend is true
          descend = descend - 1
        nextPattern = @pattern
        if node.childNodes?.length
          for child in node.childNodes
            switch h.getNodeType(child)
              when Node.TEXT_NODE
                if h.textContent(child).replace(/^\s+|\s+$/gm, "") is ""
                  continue
              when Node.COMMENT_NODE
                continue
            curPattern = nextPattern
            _nodelog node, "==> checking child", child, "against", nextPattern
            nextPattern = nextPattern.check(child, descend)
            _nodelog node, "child result of", child, "against", curPattern, "was", nextPattern
            if nextPattern instanceof NotAllowed
              return nextPattern
        # TODO: Detect missing elements
        if nextPattern.require() instanceof Empty
          return new GoodElement(@name, nextPattern)
        else
          return nextPattern.require()
      else
        emptyPattern = new Empty("not descending into #{h.getLocalName(node)}", @pattern, node)
        return new GoodElement(emptyPattern, node)
        if node.childNodes?.length
          return new GoodParentElement(@name, @pattern, node.childNodes)
        return new GoodElement(@name, @pattern)


  ###*
   * A reference to a pattern definition, for reference and reusability
  ###
  class Ref extends Pattern
    constructor: (@refname, @defines) ->
      @dereference()
    toString: =>
      @refname
    _check: (node, descend) =>
      @dereference()
      if @pattern?
        if not @pattern.check?
          _nodelog node, "failed", this
        return @pattern.check(node, descend)
      return new NotAllowed("cannot find reference '#{@refname}'", this, node)
    dereference: =>
      return @pattern if @pattern?
      if @defines and @defines[@refname]?
        @pattern = @defines[@refname]
      @pattern

  ###*
   * A named pattern definition, for reference and reusability
  ###
  class Define extends Pattern
    constructor: (@name, pattern) ->
      @pattern = getPattern pattern
    toString: =>
      "#{@name} = #{@pattern}"
    _check: (node, descend) =>
      @pattern.check(node, descend)
    attrCheck: (node) =>
      @pattern.attrCheck(node)

  {
    getPattern,
    setDebug,
    AnyName, Attribute,
    Choice,
    Data, Define,
    Empty, Element,
    Group,
    Interleave,
    List,
    MissingContent,
    Name, NameClass, NotAllowed, NsName,
    OneOrMore,
    Pattern,
    Ref,
    Text,
    Value
  }
