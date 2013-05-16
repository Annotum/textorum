# objects.coffee - RELAX NG schema cache objects
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

  class PatternBuilder
    constructor: ->
    choice: (pattern1, pattern2) ->
      if pattern1 instanceof NotAllowed
        pattern2
      else if pattern2 instanceof NotAllowed
        pattern1
      else if pattern1 instanceof Empty and pattern2 instanceof Empty
        pattern1
      else
        if pattern1 instanceof Empty and pattern2 instanceof Empty
          return pattern1
        l1 = pattern1.choiceLeaves()
        l2 = pattern2.choiceLeaves()
        for p in l1
          index = l2.indexOf(p)
          if index isnt -1
            l2.splice(index, 1)
        c = new Choice(pattern1, pattern2)
        for p in l2
          c = c.pruneChoiceLeaf(p)
        return c

    group: (pattern1, pattern2) ->
      if pattern1 instanceof NotAllowed
        pattern1
      else if pattern2 instanceof NotAllowed
        pattern2
      else if pattern2 instanceof Empty
        pattern1
      else if pattern1 instanceof Empty
        pattern2
      else
        new Group(pattern1, pattern2)

    interleave: (pattern1, pattern2) ->
      if pattern1 instanceof NotAllowed
        pattern1
      else if pattern2 instanceof NotAllowed
        pattern2
      else if pattern2 instanceof Empty
        pattern1
      else if pattern1 instanceof Empty
        pattern2
      else
        new Interleave(pattern1, pattern2)

    after: (pattern1, pattern2) ->
      if pattern1 instanceof NotAllowed
        pattern1
      else if pattern2 instanceof NotAllowed
        pattern2
      else
        new After(pattern1, pattern2)

    oneOrMore: (pattern) ->
      if pattern instanceof NotAllowed
        pattern
      else
        new OneOrMore(pattern)

  builder = new PatternBuilder()

  class RNGException extends Error
    constructor: (message, @pattern = null, @node = null, @parser = null) ->
      return super message

  class Flip
    constructor: (@func, @arg2) ->
    apply: (thisarg, arg1) =>
      @func.apply(thisarg, [arg1, @arg2])

  class notFlip
    constructor: (@func, @arg1) ->
    apply: (thisarg, arg2) =>
      @func.apply(thisarg, [@arg1, arg2])


  applyAfter = (func, pattern) ->
    if pattern instanceof After
      builder.after pattern.pattern1, func.apply(this, pattern.pattern2)
    else if pattern instanceof Choice
      builder.choice applyAfter(func, pattern.pattern1), applyAfter(func, pattern.pattern2)
    else if pattern instanceof NotAllowed
      pattern
    else
      throw new RNGException("#{pattern} is not an After, Choice, or NotAllowed", pattern)




  ###*
   * Superclass for all (simplified) RNG pattern representation nodes
  ###
  class Pattern
    choiceLeaves: =>
      []
    pruneChoiceLeaf: (pattern) =>
      this

    startTagOpenDeriv: (node) =>
      return new NotAllowed("expected #{this}, found #{h.getLocalName(node)}", this, node)

    startTagCloseDeriv: (node) =>
      this

    endTagDeriv: (node) =>
      if this instanceof NotAllowed
        return this
      return new NotAllowed("invalid pattern: #{this}", this, node)

    attDeriv: (attribute) =>
      if h.getNamespacePrefix(attribute.name) is "xml"
        return this
      return new NotAllowed("unknown attribute #{attribute.name} (value #{attribute.value} - expecting #{this}", this, attribute)

    childDeriv: (node, descend = false) =>
      _nodelog(node, "starting childDeriv", node, this)
      if h.getNodeType(node) is Node.TEXT_NODE
        return @textDeriv(node)
      patt = @startTagOpenDeriv(node)
      if patt instanceof NotAllowed
        return patt
      for attr in h.getNodeAttributes(node)
        patt = patt.attDeriv(attr)
        if patt instanceof NotAllowed
          return patt
      patt = patt.startTagCloseDeriv(node)
      if patt instanceof NotAllowed
        return patt
      if descend
        unless descend is true
          descend = descend - 1
        patt = patt.childrenDeriv(node.childNodes, descend)
      else
        return new After(new Empty("skipping 1"), new Empty("skipping descent"))
      if patt instanceof NotAllowed
        return patt
      return patt.endTagDeriv(node)

    childrenDeriv: (children, descend) =>
      if not children.length
        @childrenDeriv [""]
      if children.length is 1 and h.isNodeWhitespace(children[0])
        p1 = @childDeriv(children[0], descend)
        return builder.choice(this, p1)
      patt = this
      for child in children
        switch h.getNodeType(child)
          when Node.TEXT_NODE
            if h.textContent(child).replace(/^\s+|\s+$/gm, "") is ""
              continue
          when Node.COMMENT_NODE
            continue
          when Node.ELEMENT_NODE
            lastElementNode = child
        nextPatt = patt.childDeriv(child, descend)
        if nextPatt instanceof NotAllowed
          return nextPatt
        patt = nextPatt
      return patt

    textDeriv: (node) =>
      return new NotAllowed("#{this}", this, node)
    toString: =>
      "<UNDEFINED PATTERN>"

    valueMatch: (value) =>
      if @nullable() and h.isNodeWhitespace(value)
        return new Empty()
      deriv = @textDeriv(value)
      if deriv.nullable()
        return new Empty()
      return NotAllowed("value mismatch: #{value} does not match #{this}: #{deriv}", this, value)

    nullable: =>
      return @_nullable()

    _nullable: ->
      false

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

  class After extends Pattern
    constructor: (@pattern1, @pattern2) ->
    startTagOpenDeriv: (node) =>
      f1 = new Flip(builder.after, @pattern2)
      applyAfter(f1, @pattern1.startTagOpenDeriv(node))
    startTagCloseDeriv: (node) =>
      builder.after(@pattern1.startTagCloseDeriv(node), @pattern2)
    endTagDeriv: (node) =>
      if @pattern1.nullable()
        return @pattern2
      else
        return new MissingContent("missing #{@pattern1} before close of #{h.getLocalName(node)}", this, node)
    attDeriv: (attribute) =>
      builder.after(@pattern1.attDeriv(attribute), @pattern2)
    textDeriv: (node) =>
      builder.after(@pattern1.textDeriv(node), @pattern2)
    toString: =>
      "\n [:first: -- #{@pattern1} \n -- :then: #{@pattern2}]"

  ###*
   * Nulled portion of a pattern.
  ###
  class Empty extends Pattern
    constructor: (@message, @pattern, @childNode) ->
    textDeriv: (node) =>
      return this
    toString: =>
      if @message
        "#{@message}"
      else
        "(null)"
    _nullable: =>
      true


  ###*
   * An empty Pattern node, matching only comments and empty text node blocks
  ###
  class EmptyNode extends Empty
    constructor: (@message, @pattern, @childNode) ->
    toString: =>
      "empty"
    _nullable: =>
      true


  ###*
   * A pattern denying all contents
  ###
  class NotAllowed extends Pattern
    constructor: (@message, @pattern, @childNode, @priority = 10) ->
      return this
    toString: =>
      if @message
        "notAllowed { #{@message} }"
      else
        "notAllowed"


  ###*
   * A pattern indicating missing content (end state)
  ###
  class MissingContent extends NotAllowed
    constructor: (@message, @pattern, @childNode, @priority = 10) ->
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
    textDeriv: (node) =>
      this
    _nullable: =>
      true

  ###*
   * A pattern fulfilled by either of its sub-pattern branches reducing to Empty
  ###
  class Choice extends Pattern
    constructor: (pattern1, pattern2) ->
      @pattern1 = getPattern pattern1
      @pattern2 = getPattern pattern2
    choiceLeaves: =>
      l1 = @pattern1.choiceLeaves()
      l2 = @pattern2.choiceLeaves()
      for c in l2
        unless c in l1
          l1.push(c)
      return l1
    pruneChoiceLeaf: (pattern) =>
      if @pattern1 is pattern
        return @pattern2.pruneChoiceLeaf(pattern)
      if @pattern2 is pattern
        return @pattern1.pruneChoiceLeaf(pattern)
      return this

    startTagOpenDeriv: (node) =>
      p1 = @pattern1.startTagOpenDeriv(node)
      p2 = @pattern2.startTagOpenDeriv(node)
      return builder.choice(p1, p2)
    startTagCloseDeriv: (node) =>
      builder.choice(@pattern1.startTagCloseDeriv(node), @pattern2.startTagCloseDeriv(node))
    endTagDeriv: (node) =>
      builder.choice(@pattern1.endTagDeriv(node), @pattern2.endTagDeriv(node))
    attDeriv: (attribute) =>
      builder.choice(@pattern1.attDeriv(attribute), @pattern2.attDeriv(attribute))
    textDeriv: (node) =>
      builder.choice(@pattern1.textDeriv(node), @pattern2.textDeriv(node))
    toString: =>
      "(#{@pattern1} | #{@pattern2})"
    contains: (nodeName) =>
      @pattern1.contains(nodeName) or @pattern2.contains(nodeName)
    _nullable: =>
      @pattern1.nullable() or @pattern2.nullable()


  ###*
   * A pattern requiring both of its subpatterns to be valid, in any order
  ###
  class Interleave extends Pattern
    constructor: (pattern1, pattern2) ->
      @pattern1 = getPattern pattern1
      @pattern2 = getPattern pattern2
    startTagOpenDeriv: (node) =>
      f1 = new Flip(builder.interleave, @pattern2)
      p1 = applyAfter(f1, @pattern1.startTagOpenDeriv(node))
      f2 = new notFlip(builder.interleave, @pattern1)
      p2 = applyAfter(f2, @pattern2.startTagOpenDeriv(node))
      builder.choice(p1, p2)
    startTagCloseDeriv: (node) =>
      builder.interleave(@pattern1.startTagCloseDeriv(node), @pattern2.startTagCloseDeriv(node))
    attDeriv: (attribute) =>
      p1 = builder.interleave(@pattern1.attDeriv(attribute), @pattern2)
      p2 = builder.interleave(@pattern1, @pattern2.attDeriv(attribute))
      builder.choice(p1, p2)
    toString: =>
      "(#{@pattern1} & #{@pattern2})"
    _nullable: =>
      @pattern1.nullable() and @pattern2.nullable()


  ###*
   * A pattern requiring both of its subpatterns to be valid, in the given order
  ###
  class Group extends Pattern
    constructor: (pattern1, pattern2) ->
      @pattern1 = getPattern pattern1
      @pattern2 = getPattern pattern2
    startTagOpenDeriv: (node) =>
      f1 = new Flip(builder.group, @pattern2)
      r1 = applyAfter(f1, @pattern1.startTagOpenDeriv(node))
      if @pattern1.nullable()
        builder.choice(r1, @pattern2.startTagOpenDeriv(node))
      else
        r1
    startTagCloseDeriv: (node) =>
      builder.group(@pattern1.startTagCloseDeriv(node), @pattern2.startTagCloseDeriv(node))
    attDeriv: (attribute) =>
      p1 = builder.group(@pattern1.attDeriv(attribute), @pattern2)
      p2 = builder.group(@pattern1, @pattern2.attDeriv(attribute))
      builder.choice(p1, p2)
    textDeriv: (node) =>
      p1 = builder.group(@pattern1.textDeriv(node), @pattern2)
      if @pattern1.nullable()
        return builder.choice(p1, @pattern2.textDeriv(node))
      return p1
    toString: =>
      "#{@pattern1}, #{@pattern2}"
    _nullable: =>
      @pattern1.nullable() and @pattern2.nullable()


  ###*
   * A pattern that requires at least one instance of its subpattern to be valid.
   *     Becomes a {@link Choice} between {@link Empty} and itself when satisfied.
  ###
  class OneOrMore extends Pattern
    constructor: (pattern) ->
      @pattern = getPattern pattern
    startTagOpenDeriv: (node) =>
      p1 = @pattern.startTagOpenDeriv(node)
      f1 = new Flip(builder.group, builder.choice(this, new Empty("empty | #{this}", this)))
      applyAfter(f1, p1)
    startTagCloseDeriv: (node) =>
      builder.oneOrMore(@pattern.startTagCloseDeriv(node))
    attDeriv: (attribute) =>
      builder.group(@pattern.attDeriv(attribute), builder.choice(this, new Empty("#{this}")))
    textDeriv: (node) =>
      builder.group(@pattern.textDeriv(node), builder.choice(this, new Empty("#{this}")))
    toString: =>
      "#{@pattern}+"
    _nullable: =>
      @pattern.nullable()


  ###*
   * A pattern that matches space-separated text tokens against its subpattern
  ###
  class List extends Pattern
    constructor: (pattern) ->
      @pattern = getPattern pattern
    textDeriv: (node) =>
      return new Empty("skipping List validation")
    toString: =>
      "list { #{@pattern} }"

  ###*
   * A pattern that matches data against a data validation library (currently unimplemented)
  ###
  class Data extends Pattern
    constructor: (@dataType, @type, paramList) ->
      @params = []
      @except = new NotAllowed()
      for param in paramList
        if param.local is "param"
          @params.push getPattern param
        else if param.local is "except"
          @except = getPattern param
    textDeriv: (node) =>
      return new Empty("Skipping Data validation")
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

  ###*
   * A pattern that matches data against a given value (currently minimally implemented)
  ###
  class Value extends Pattern
    constructor: (@dataType, @type, @ns, @string) ->
    textDeriv: (node) =>
      return new Empty("skipping Value validation")

    toString: =>
      output = ""

      if @dataType
        output += "" + @dataType + ":"
      if @type
        output += "#{@type} "
      output += '"' + @string + '"'

  ###*
   * A pattern that matches an attribute (name, value) on the given node
  ###
  class Attribute extends Pattern
    constructor: (@nameClass, pattern, @defaultValue = null) ->
      @pattern = getPattern pattern
    startTagCloseDeriv: (node) =>
      return new NotAllowed("attr StartTagCloseDeriv #{this}", this, node)
    attDeriv: (attribute) =>
      contains = @nameClass.contains(attribute.name)
      if contains instanceof NotAllowed
        return contains
      valuematch = @pattern.valueMatch(attribute.value)
      if valuematch instanceof NotAllowed
        return valuematch
      return new Empty("good attribute: #{this}", this, attribute)

    toString: =>
      "attribute '#{@nameClass} { #{@pattern} }".substr(0, 20) + "'"


  ###*
   * {@link Empty} subclass that specifically indicates a good element
  ###
  class GoodElement extends Empty
    constructor: (@name, @pattern) ->
    toString: => "(GOOD) element #{@name}"

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
    startTagOpenDeriv: (node) =>
      nameCheck = @name.contains node
      if nameCheck
        builder.after @pattern, new EmptyNode()
      else
        new NotAllowed("expecting #{@name}, found #{h.getLocalName(node)}", @name, node, 5 + h.depth(node))

    toString: =>
      "element #{@name} { #{@pattern} }"



  ###*
   * A reference to a pattern definition, for reference and reusability
  ###
  class Ref extends Pattern
    constructor: (@refname, @defines) ->
      @dereference()
    startTagOpenDeriv: (node) =>
      @dereference()
      if @pattern?
        return @pattern.startTagOpenDeriv(node)
      return new NotAllowed("cannot find reference '#{@refname}'", this, node)
    endTagDeriv: (node) =>
      @dereference()
      if @pattern?
        return @pattern.endTagDeriv(node)
      return new NotAllowed("cannot find reference '#{@refname}'", this, node)
    attDeriv: (attribute) =>
      @dereference()
      if @pattern?
        return @pattern.attDeriv(attribute)
      return new NotAllowed("cannot find reference '#{@refname}'", this, node)

    toString: =>
      @refname
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
    startTagOpenDeriv: (node) =>
      return @pattern.startTagOpenDeriv(node)
    endTagDeriv: (node) =>
      return @pattern.endTagDeriv(node)
    attDeriv: (node) =>
      return @pattern.attDeriv(node)
    toString: =>
      "#{@name} = #{@pattern}"


  {
    getPattern,
    setDebug,
    AnyName, Attribute,
    Choice,
    Data, Define,
    Empty, Element,
    Group, GoodElement, GoodParentElement,
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
