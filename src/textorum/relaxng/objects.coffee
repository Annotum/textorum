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
  skipAttributes = false

  uniqueIndex = 0
  indexCount = {}

  patternIntern = {
    internSuccess: 0,
    internCheck: 0,
    attributeShutDown: 0,
    startTagOpenDeriv: 0
  }

  setSkipAttributes = (skip) =>
    prevSkip = skipAttributes
    skipAttributes = skip
    return prevSkip

  setDebug = (debug) =>
    prevDebug = DEBUG
    DEBUG = debug
    return prevDebug

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
  getPattern = (node, defines) ->
    if node instanceof Pattern
      return node
    if not node
      return builder.notAllowed("trying to load empty pattern")

    children = node.childNodes

    pattern = switch h.getLocalName(node)
      when 'element' then new Element children[0], children[1]
      when 'define' then new Define h.getNodeAttr(node, "name"), children[0]
      when 'notAllowed' then builder.notAllowed("not allowed by pattern", node)
      when 'empty' then builder.empty(undefined, node)
      when 'text' then new Text()
      when 'data' then new Data h.getNodeAttr(node, "datatypeLibrary"), h.getNodeAttr(node, "type"), children
      when 'value' then new Value(h.getNodeAttr(node, "dataTypeLibrary"),
        h.getNodeAttr(node, "type"), h.getNodeAttr(node, "ns"), children[0])
      when 'list' then new List children[0]
      when 'attribute'
        if skipAttributes
          attr = new Empty("#{attr}")
        else
          attr = new Attribute children[0], children[1]
        attr
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
      @choiceMap = {}
      patternIntern['empty'] = new Empty()
      patternIntern['notallowed'] = new NotAllowed()
    notAllowed: (message, pattern, childnode, priority) ->
      if message isnt undefined
        return new NotAllowed(message, pattern, childnode, priority)
      return patternIntern['notallowed']
    empty: (message, node) ->
      return patternIntern['empty']
      if message? or node?
        return new Empty(message, node)
      return patternIntern['empty']
    noteChoices: (pattern) ->
      if pattern._notedChoices?
        return pattern._notedChoices
      if pattern instanceof Choice
        c1 = @noteChoices(pattern.pattern1)
        c2 = @noteChoices(pattern.pattern2)
        pattern._notedChoices = c1.concat(c2)
        return pattern._notedChoices
      else
        @choiceMap[pattern.uniqueIndex] = pattern
        return [pattern]
    removeChoices: (pattern) ->
      if pattern instanceof Choice
        pattern1 = @removeChoices(pattern.pattern1)
        pattern2 = @removeChoices(pattern.pattern2)
        if pattern1.uniqueIndex is pattern.pattern1.uniqueIndex and pattern2.uniqueIndex is pattern.pattern2.uniqueIndex
          return pattern
        if pattern1 instanceof NotAllowed
          return pattern2
        if pattern2 instanceof NotAllowed
          return pattern1
        return @internChoice(pattern1, pattern2)
      else
        if @choiceMap[pattern.uniqueIndex] isnt undefined
          return @notAllowed()
      return pattern

    choice: (pattern1, pattern2) ->
      if pattern1.uniqueIndex is pattern2.uniqueIndex
        return pattern1
      if pattern1 instanceof NotAllowed
        return pattern2
      if pattern2 instanceof NotAllowed
        return pattern1
      if pattern1 instanceof Empty and pattern2 instanceof Empty
        return pattern1
      unless pattern1 instanceof Choice
        if pattern2.containsChoice(pattern1)
          return pattern2
      unless pattern2 instanceof Choice
        if pattern1.containsChoice(pattern2)
          return pattern1

      @noteChoices(pattern1)
      pattern2 = @removeChoices(pattern2)
      @choiceMap = {}
      if pattern2 instanceof NotAllowed
        return pattern1


      if pattern1 instanceof After and pattern2 instanceof After
        if pattern1.pattern1.uniqueIndex is pattern2.pattern1.uniqueIndex
          return @after(pattern1.pattern1, @choice(pattern1.pattern2, pattern2.pattern2))
        if pattern1.pattern1 instanceof NotAllowed
          return pattern2
        if pattern2.pattern1 instanceof NotAllowed
          return pattern1
        if pattern1.pattern2.uniqueIndex is pattern2.pattern2.uniqueIndex
          return @after(@choice(pattern1.pattern1, pattern2.pattern1), pattern1.pattern2)

      return @internChoice(pattern1, pattern2)

    internChoice: (pattern1, pattern2) ->
      if pattern1 instanceof Ref
        pattern1.dereference()
      if pattern2 instanceof Ref
        pattern2.dereference()
      if pattern1.uniqueIndex < pattern2.uniqueIndex
        choices = "Choice,choices," + pattern1.uniqueIndex + "," + pattern2.uniqueIndex
      else
        choices = "Choice,choices," + pattern2.uniqueIndex + "," + pattern1.uniqueIndex

      patternIntern["internCheck"] += 1
      if patternIntern[choices] is undefined
        patternIntern[choices] = new Choice(pattern1, pattern2)
      else
        patternIntern["internSuccess"] += 1
      return patternIntern[choices]

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
        hash = "Group,choices," + pattern1.uniqueIndex + "," + pattern2.uniqueIndex
        patternIntern["internCheck"] += 1
        if patternIntern[hash] is undefined
          patternIntern[hash] = new Group(pattern1, pattern2)
        else
          patternIntern["internSuccess"] += 1
        return patternIntern[hash]


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
        parts = ["Interleave"]
        choices = [pattern1.uniqueIndex, pattern2.uniqueIndex].sort()
        parts.push "choices"
        parts.push choices
        hash = parts.join("|")

        patternIntern["internCheck"] += 1
        if patternIntern[hash] is undefined
          patternIntern[hash] = new Interleave(pattern1, pattern2)
        else
          patternIntern["internSuccess"] += 1
        return patternIntern[hash]

    after: (pattern1, pattern2) ->
      if pattern1 instanceof NotAllowed
        pattern1
      else if pattern2 instanceof NotAllowed
        pattern2
      else
        parts = ["After"]
        choices = [pattern1.uniqueIndex, pattern2.uniqueIndex]
        parts.push "choices"
        parts.push choices
        hash = parts.join("|")

        patternIntern["internCheck"] += 1
        if patternIntern[hash] is undefined
          patternIntern[hash] = new After(pattern1, pattern2)
        else
          patternIntern["internSuccess"] += 1
        return patternIntern[hash]

    oneOrMore: (pattern) ->
      if pattern instanceof NotAllowed or pattern instanceof Empty or pattern instanceof OneOrMore
        pattern
      else
        hash = "OneOrMore," + pattern.uniqueIndex

        patternIntern["internCheck"] += 1
        if patternIntern[hash] is undefined
          patternIntern[hash] = new OneOrMore(pattern)
        else
          patternIntern["internSuccess"] += 1
        return patternIntern[hash]

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
    constructor: ->
      if this instanceof Empty
        @uniqueIndex = "empty"
      else
        @uniqueIndex = uniqueIndex++
        indexCount[@constructor.name] ||= 0
        indexCount[@constructor.name]++

    choiceLeaves: ->
      [@uniqueIndex]
    pruneChoiceLeaf: (pattern) ->
      this
    containsChoice: (pattern) ->
      return this.uniqueIndex is pattern.uniqueIndex

    startTagOpenDeriv: (node) ->
      if node._memoizedStartTagOpenDeriv is undefined
        node._memoizedStartTagOpenDeriv = {}
      if node._memoizedStartTagOpenDeriv[this.uniqueIndex] is undefined
        node._memoizedStartTagOpenDeriv[this.uniqueIndex] = @_startTagOpenDeriv(node)
        patternIntern['startTagOpenDeriv'] += 1
      return node._memoizedStartTagOpenDeriv[this.uniqueIndex]

    _startTagOpenDeriv: (node) ->
      return builder.notAllowed("expected #{this}", this, node)

    startTagCloseDeriv: (node) ->
      if node._memoizedstartTagCloseDeriv is undefined
        node._memoizedstartTagCloseDeriv = {}
      if node._memoizedstartTagCloseDeriv[this.uniqueIndex] is undefined
        node._memoizedstartTagCloseDeriv[this.uniqueIndex] = @_startTagCloseDeriv(node)
      return node._memoizedstartTagCloseDeriv[this.uniqueIndex]

    _startTagCloseDeriv: (node) ->
      this

    endTagDeriv: (node) ->
      if node._memoizedendTagDeriv is undefined
        node._memoizedendTagDeriv = {}
      if node._memoizedendTagDeriv[this.uniqueIndex] is undefined
        node._memoizedendTagDeriv[this.uniqueIndex] = @_endTagDeriv(node)
      return node._memoizedendTagDeriv[this.uniqueIndex]

    _endTagDeriv: (node) ->
      if this instanceof NotAllowed
        return this
      return builder.notAllowed("invalid pattern: #{this}", this, node)

    attDeriv: (attribute) ->
      if h.getNamespacePrefix(attribute.name) is "xml"
        return this
      return builder.notAllowed("unknown attribute #{attribute.name} (value #{attribute.value})", this, attribute)

    childDeriv: (node, descend = false) ->
      _nodelog(node, "starting childDeriv", node, this)
      if h.getNodeType(node) is Node.TEXT_NODE
        return @textDeriv(node)
      patt = @startTagOpenDeriv(node)
      if patt instanceof NotAllowed
        return patt
      if not skipAttributes
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
        return builder.after(builder.empty("skipping 1"), builder.empty("skipping descent"))
      if patt instanceof NotAllowed
        return patt
      return patt.endTagDeriv(node)

    childrenDeriv: (children, descend) ->
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

    textDeriv: (node) ->
      return builder.notAllowed("#{this}", this, node)

    toString: ->
      if @_toStringCache is undefined
        @_toStringCache = @_toString()
      @_toStringCache

    _toString: ->
        "<UNDEFINED PATTERN>"

    valueMatch: (value) ->
      if @nullable() and h.isNodeWhitespace(value)
        return builder.empty()
      deriv = @textDeriv(value)
      if deriv.nullable()
        return builder.empty()
      return NotAllowed("value mismatch: #{value} does not match #{this}: #{deriv}", this, value)

    nullable: ->
      return @_nullable()

    _nullable: ->
      false

    ###*
     * Stub for Name class patterns
     * @see NameClass#contains
    ###
    contains: (nodeName) ->
      throw new RNGException("Cannot call 'contains(#{nodeName})' on pattern '#{@toString()}'")

    ###*
     * Stub for Ref class patterns
     * @see Ref#dereference
    ###
    dereference: ->
      return this

  #** Name Classes

  class NameClass extends Pattern
    contains: (node) ->
      throw new RNGException("Checking contains(#{node}) on undefined NameClass")

  class AnyName extends NameClass
    constructor: (exceptPattern) ->
      super()
      @except = getPattern exceptPattern
    contains: (node) ->
      unless @except instanceof NotAllowed
        return not @except.contains(node)
      true
    _toString: ->
      if @except instanceof NotAllowed
        "*"
      else
        "* - #{@except}"

  class Name extends NameClass
    constructor: (ns, name) ->
      super()
      @ns = ns
      @name = name
    contains: (node) ->
      # TODO: namespace URI handling
      @name is node.localName or @name is h.getLocalName(node)
    _toString: ->
      if @ns
        "#{@ns}:#{@name}"
      else
        "#{@name}"

  class NsName extends NameClass
    constructor: (ns, exceptPattern) ->
      super()
      @ns = ns
      @except = getPattern exceptPattern
    contains: (node) ->
      # TODO: namespace URI handling
      unless @except instanceof NotAllowed
        @except.contains(node)
      true
    _toString: ->
      if @except instanceof NotAllowed
        "#{@ns}:*"
      else
        "#{@ns}:* - #{@except}]"

  #** Pattern Classes

  class After extends Pattern
    constructor: (@pattern1, @pattern2) ->
      super()
    _startTagOpenDeriv: (node) ->
      f1 = new Flip(builder.after, @pattern2)
      applyAfter(f1, @pattern1.startTagOpenDeriv(node))
    _startTagCloseDeriv: (node) ->
      builder.after(@pattern1.startTagCloseDeriv(node), @pattern2)
    _endTagDeriv: (node) ->
      if @pattern1.nullable()
        return @pattern2
      else
        return new MissingContent("missing #{@pattern1} before close", this, node)
    attDeriv: (attribute) ->
      if @pattern2 instanceof NotAllowed
        return @pattern2
      p1 = @pattern1.attDeriv(attribute)
      if p1.uniqueIndex is @pattern1.uniqueIndex
        return this
      return builder.after(p1, @pattern2)
    textDeriv: (node) ->
      builder.after(@pattern1.textDeriv(node), @pattern2)
    _toString: ->
      "\n [:first: -- #{@pattern1} \n -- :then: #{@pattern2}]"

  ###*
   * Nulled portion of a pattern.
  ###
  class Empty extends Pattern
    constructor: (@message, @pattern, @childNode) ->
      super()
    textDeriv: (node) ->
      return this
    _toString: ->
      if @message
        "#{@message}"
      else
        "empty"
    _nullable: ->
      true


  ###*
   * A pattern denying all contents
  ###
  class NotAllowed extends Pattern
    constructor: (@message, @pattern, @childNode, @priority = 10) ->
      super()
      return this
    _toString: ->
      if @message
        "notAllowed { #{@message} }"
      else
        "notAllowed"


  ###*
   * A pattern indicating missing content (end state)
  ###
  class MissingContent extends NotAllowed
    constructor: (@message, @pattern, @childNode, @priority = 10) ->
      super(@message, @pattern, @childNode, @priority)
    _toString: ->
      if @message
        "missingContent { #{@message} }"
      else
        "missingContent"

  ###*
   * A pattern accepting any text content
  ###
  class Text extends Empty
    _toString: ->
      "text"
    textDeriv: (node) ->
      this
    _nullable: ->
      true

  ###*
   * A pattern fulfilled by either of its sub-pattern branches reducing to Empty
  ###
  class Choice extends Pattern
    constructor: (pattern1, pattern2) ->
      @pattern1 = getPattern pattern1
      @pattern2 = getPattern pattern2
      super()
    choiceLeaves: ->
      l1 = @pattern1.choiceLeaves()
      l2 = @pattern2.choiceLeaves()
      for c in l2
        unless c in l1
          l1.push(c)
      return l1

    pruneChoiceLeaf: (pattern) ->
      if @pattern1.uniqueIndex is pattern
        return @pattern2.pruneChoiceLeaf(pattern)
      if @pattern2.uniqueIndex is pattern
        return @pattern1.pruneChoiceLeaf(pattern)
      return this

    containsChoice: (pattern) ->
      if @pattern1.uniqueIndex is pattern.uniqueIndex
        return true
      if @pattern2.unqiueIndex is pattern.uniqueIndex
        return true
      if @pattern1 instanceof Choice and @pattern1.containsChoice(pattern)
        return true
      if @pattern2 instanceof Choice and @pattern2.containsChoice(pattern)
        return true
      return false

    _startTagOpenDeriv: (node) ->
      p1 = @pattern1.startTagOpenDeriv(node)
      p2 = @pattern2.startTagOpenDeriv(node)
      return builder.choice(p1, p2)
    _startTagCloseDeriv: (node) ->
      builder.choice(@pattern1.startTagCloseDeriv(node), @pattern2.startTagCloseDeriv(node))
    _endTagDeriv: (node) ->
      if @pattern1 instanceof Attribute
        if @pattern2 instanceof Attribute
          return builder.notAllowed()
        return @pattern2.endTagDeriv(node)
      if @pattern2 instanceof Attribute
        return @pattern1.endTagDeriv(node)
      p1 = @pattern1.endTagDeriv(node)
      p2 = @pattern2.endTagDeriv(node)
      if p1.uniqueIndex is @pattern1.uniqueIndex and p2.uniqueIndex is @pattern2.uniqueIndex
        return this
      return builder.choice(p1, p2)
    attDeriv: (attribute) ->
      builder.choice(@pattern1.attDeriv(attribute), @pattern2.attDeriv(attribute))
    textDeriv: (node) ->
      builder.choice(@pattern1.textDeriv(node), @pattern2.textDeriv(node))
    _toString: ->
      "(#{@pattern1} | #{@pattern2})"
    contains: (nodeName) ->
      @pattern1.contains(nodeName) or @pattern2.contains(nodeName)
    _nullable: ->
      @pattern1.nullable() or @pattern2.nullable()


  ###*
   * A pattern requiring both of its subpatterns to be valid, in any order
  ###
  class Interleave extends Pattern
    constructor: (pattern1, pattern2) ->
      @pattern1 = getPattern pattern1
      @pattern2 = getPattern pattern2
      super()
    _startTagOpenDeriv: (node) ->
      f1 = new Flip(builder.interleave, @pattern2)
      p1 = applyAfter(f1, @pattern1.startTagOpenDeriv(node))
      f2 = new notFlip(builder.interleave, @pattern1)
      p2 = applyAfter(f2, @pattern2.startTagOpenDeriv(node))
      builder.choice(p1, p2)
    _endTagDeriv: (node) ->
      p1 = @pattern1.endTagDeriv(node)
      p2 = @pattern2.endTagDeriv(node)
      if p1.uniqueIndex is @pattern1.uniqueIndex and p2.uniqueIndex is @pattern2.uniqueIndex
        return this
      return builder.interleave(p1, p2)
    _startTagCloseDeriv: (node) ->
      builder.interleave(@pattern1.startTagCloseDeriv(node), @pattern2.startTagCloseDeriv(node))
    attDeriv: (attribute) ->
      p1 = builder.interleave(@pattern1.attDeriv(attribute), @pattern2)
      p2 = builder.interleave(@pattern1, @pattern2.attDeriv(attribute))
      builder.choice(p1, p2)
    _toString: ->
      "(#{@pattern1} & #{@pattern2})"
    _nullable: ->
      @pattern1.nullable() and @pattern2.nullable()


  ###*
   * A pattern requiring both of its subpatterns to be valid, in the given order
  ###
  class Group extends Pattern
    constructor: (pattern1, pattern2) ->
      @pattern1 = getPattern pattern1
      @pattern2 = getPattern pattern2
      super()
    _startTagOpenDeriv: (node) ->
      f1 = new Flip(builder.group, @pattern2)
      r1 = applyAfter(f1, @pattern1.startTagOpenDeriv(node))
      if @pattern1.nullable()
        builder.choice(r1, @pattern2.startTagOpenDeriv(node))
      else
        r1
    _endTagDeriv: (node) ->
      if @pattern1 instanceof Attribute or @pattern2 instanceof Attribute
        return builder.notAllowed()
      p1 = @pattern1.endTagDeriv(node)
      p2 = @pattern2.endTagDeriv(node)
      if p1.uniqueIndex is @pattern1.uniqueIndex and p2.uniqueIndex is @pattern2.uniqueIndex
        return this
      return builder.group(p1, p2)
    _startTagCloseDeriv: (node) ->
      builder.group(@pattern1.startTagCloseDeriv(node), @pattern2.startTagCloseDeriv(node))
    attDeriv: (attribute) ->
      p1 = @pattern1.attDeriv(attribute)
      p2 = @pattern2.attDeriv(attribute)
      if p1.uniqueIndex is @pattern1.uniqueIndex and p2.uniqueIndex is @pattern2.uniqueIndex
        return this
      g1 = builder.group(p1, @pattern2)
      g2 = builder.group(@pattern1, p2)
      builder.choice(g1, g2)
    textDeriv: (node) ->
      p1 = builder.group(@pattern1.textDeriv(node), @pattern2)
      if @pattern1.nullable()
        return builder.choice(p1, @pattern2.textDeriv(node))
      return p1
    _toString: ->
      "#{@pattern1}, #{@pattern2}"
    _nullable: ->
      @pattern1.nullable() and @pattern2.nullable()


  ###*
   * A pattern that requires at least one instance of its subpattern to be valid.
   *     Becomes a {@link Choice} between {@link Empty} and itself when satisfied.
  ###
  class OneOrMore extends Pattern
    constructor: (pattern) ->
      @pattern = getPattern pattern
      super()
    _startTagOpenDeriv: (node) ->
      p1 = @pattern.startTagOpenDeriv(node)
      f1 = new Flip(builder.group, builder.choice(this, builder.empty("empty | #{this}", this)))
      applyAfter(f1, p1)
    _endTagDeriv: (node) ->
      p = @pattern.endTagDeriv(node)
      if p.uniqueIndex is @pattern.uniqueIndex
        return this
      return builder.oneOrMore(p)
    _startTagCloseDeriv: (node) ->
      builder.oneOrMore(@pattern.startTagCloseDeriv(node))
    attDeriv: (attribute) ->
      builder.group(@pattern.attDeriv(attribute), builder.choice(this, builder.empty("#{this}")))
    textDeriv: (node) ->
      builder.group(@pattern.textDeriv(node), builder.choice(this, builder.empty("#{this}")))
    _toString: ->
      "#{@pattern}+"
    _nullable: ->
      @pattern.nullable()


  ###*
   * A pattern that matches space-separated text tokens against its subpattern
  ###
  class List extends Pattern
    constructor: (pattern) ->
      @pattern = getPattern pattern
      super()
    textDeriv: (node) ->
      return builder.empty("skipping List validation")
    _toString: ->
      "list { #{@pattern} }"

  ###*
   * A pattern that matches data against a data validation library (currently unimplemented)
  ###
  class Data extends Pattern
    constructor: (dataType, type, paramList) ->
      @dataType = dataType
      @type = type
      @params = []
      @except = builder.notAllowed()
      for param in paramList
        if param.local is "param"
          @params.push getPattern param
        else if param.local is "except"
          @except = getPattern param
      super()
    textDeriv: (node) ->
      return builder.empty("Skipping Data validation")
    _toString: ->
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
    constructor: (dataType, type, ns, string) ->
      @dataType = dataType
      @type = type
      @ns = ns
      @string = string
      super()
    textDeriv: (node) ->
      return builder.empty("skipping Value validation")

    _toString: ->
      output = ""

      if @dataType isnt undefined
        output += "" + @dataType + ":"
      if @type isnt undefined
        output += "#{@type} "
      output += '"' + @string + '"'

  ###*
   * A pattern that matches an attribute (name, value) on the given node
  ###
  class Attribute extends Pattern
    constructor: (nameClass, pattern, @defaultValue = null) ->
      @nameClass = nameClass
      @pattern = getPattern pattern
      super()
    _startTagCloseDeriv: (node) ->
      patternIntern['attributeShutDown'] += 1
      return builder.notAllowed()
      return builder.notAllowed("attr StartTagCloseDeriv #{this}", this, node)
    matchAttrName: (attribute) ->

    attDeriv: (attribute) ->
      contains = @nameClass.contains(attribute.name)
      if contains instanceof NotAllowed
        return contains
      valuematch = @pattern.valueMatch(attribute.value)
      if valuematch instanceof NotAllowed
        return valuematch
      return builder.empty("good attribute: #{this}", this, attribute)

    _toString: ->
      "attribute #{@nameClass} { #{@pattern} }"


  ###*
   * {@link Empty} subclass that specifically indicates a good element
  ###
  class GoodElement extends Empty
    constructor: (@name, @pattern) ->
      super(@name, @pattern)
    _toString: -> "(GOOD) element #{@name}"

  ###*
   * {@link GoodElement} subclass that has (unvalidated) children of the node remaining
  ###
  class GoodParentElement extends GoodElement
    constructor: (@name, @pattern, @childNodes) ->
      super(name, pattern)
    _toString: -> "(GOOD) element #{@name} (with #{childNodes?.length + 0} children)"

  ###*
   * Pattern matching an element node, validating name, attributes (disabled),
   *     and children (optionally)
  ###
  class Element extends Pattern
    constructor: (name, pattern) ->
      @name = getPattern name
      @pattern = getPattern pattern
      super()
    _startTagOpenDeriv: (node) ->
      nameCheck = @name.contains node
      if nameCheck
        builder.after @pattern, builder.empty()
      else
        builder.notAllowed("expecting #{@name}", @name, node, 5 + h.depth(node))

    _toString: ->
      "element #{@name} { #{@pattern} }"



  ###*
   * A reference to a pattern definition, for reference and reusability
  ###
  class Ref extends Pattern
    constructor: (@refname, @defines) ->
      super()
      @dereference()
    _startTagOpenDeriv: (node) ->
      @dereference()
      if @pattern?
        return @pattern.startTagOpenDeriv(node)
      return builder.notAllowed("cannot find reference '#{@refname}'", this, node)
    _endTagDeriv: (node) ->
      @dereference()
      if @pattern?
        return @pattern.endTagDeriv(node)
      return builder.notAllowed("cannot find reference '#{@refname}'", this, node)
    attDeriv: (attribute) ->
      @dereference()
      if @pattern?
        return @pattern.attDeriv(attribute)
      return builder.notAllowed("cannot find reference '#{@refname}'", this, node)

    _toString: ->
      @refname
    dereference: ->
      return @pattern if @pattern?
      if @defines and @defines[@refname]?
        @pattern = @defines[@refname]
        @pattern['dereferenced_from'] = @refname
        @uniqueIndex = @pattern.uniqueIndex
      @pattern

  ###*
   * A named pattern definition, for reference and reusability
  ###
  class Define extends Pattern
    constructor: (@name, pattern) ->
      @pattern = getPattern pattern
      @pattern['defined_from'] = @name
      @uniqueIndex = @pattern.uniqueIndex
      super()
    _startTagOpenDeriv: (node) ->
      return @pattern.startTagOpenDeriv(node)
    _endTagDeriv: (node) ->
      return @pattern.endTagDeriv(node)
    attDeriv: (node) ->
      return @pattern.attDeriv(node)
    _toString: ->
      "#{@name} = #{@pattern}"

  builder = new PatternBuilder()

  {
    getPattern,
    setDebug, setSkipAttributes,
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
    Value,
    patternIntern, uniqueIndex, indexCount
  }
