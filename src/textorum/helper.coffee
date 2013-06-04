# helper.coffee - Utility and DOM manipulation functions
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
  # Check if a given name is:
  #  - The same as the "names" (names is a string)
  #  - A proeprty of "names" (names is an object)
  #  - An element of "names" (names is an array / array-like)
  __name_matcher = (names, nombre) ->
    return nombre == names or names[nombre]? or nombre in names

  entityMap =
    "&": "&amp;"
    "<": "&lt;"
    ">": "&gt;"
    '"': '&quot;'
    "'": '&#39;'
    "/": '&#x2F;'

  class Helpers
    ELEMENT_NODE: 1
    ATTRIBUTE_NODE: 2
    TEXT_NODE: 3
    CDATA_SECTION_NODE: 4
    ENTITY_REFERENCE_NODE: 5
    ENTITY_NODE: 6
    PROCESSING_INSTRUCTION_NODE: 7
    COMMENT_NODE: 8
    DOCUMENT_NODE: 9
    DOCUMENT_TYPE_NODE: 10
    DOCUMENT_FRAGMENT_NODE: 11
    NOTATION_NODE: 12


    constructor: ->

    clone: (obj) ->
      if not obj? or typeof obj isnt 'object'
        return obj

      if obj instanceof RegExp
        flags = ''
        flags += 'g' if obj.global?
        flags += 'i' if obj.ignoreCase?
        flags += 'm' if obj.multiline?
        flags += 'y' if obj.sticky?
        return new RegExp(obj.source, flags)

      if obj instanceof Date
        return new Date(obj.getTime())

      newInstance = new obj.constructor()

      for key of obj
        newInstance[key] = clone obj[key]

      return newInstance

    getFirstChildElement: (node, tagName) ->
      node = node.firstChild
      while node and node.nodeType isnt @ELEMENT_NODE
        node = node.nextSibling
      if node and tagName
        tagName = tagName.toLowerCase()
        if node.tagName and node.tagName.toLowerCase() isnt tagName
          node = @getNextSiblingElement(node, tagName)
      node


    followPath: (path, node) ->
      while path.length
        waypoint = path.shift()
        currentIndex = 0
        for child in node.childNodes
          if child.nodeType isnt @ELEMENT_NODE
            continue
          namematch = @getQname(child.nodeName).local is waypoint.local
          urimatch = not child.namespaceURI? or child.namespaceURI is waypoint.nsuri
          indexmatch = currentIndex is waypoint.index
          if namematch and urimatch
            if indexmatch
              node = child
              break
            currentIndex += 1
        if node isnt child
          return false
      return node

    followTextorumPath: (path, node) ->
      while waypoint = path.shift()
        currentIndex = 0
        childNodes = []
        for child in node.childNodes
          childNodes.push(child)
        while child = childNodes.shift()
          if child.nodeType isnt @ELEMENT_NODE
            continue
          if child.hasAttribute? and child.hasAttribute('data-xmlel')
            namematch = child.attributes['data-xmlel'].value.toLowerCase() is waypoint.local.toLowerCase()
            urimatch = not waypoint.nsuri?
            urimatch = urimatch or not child.hasAttribute['data-nsuribk']?
            urimatch = urimatch or child.attributes['data-nsuribk'].value is waypoint.nsuri
            indexmatch = currentIndex is waypoint.index
            if namematch and urimatch
              if indexmatch
                node = child
                break
              currentIndex += 1
          else
            for grandchild in child.childNodes
              childNodes.push(grandchild)
            continue
        if node isnt child
          break
      return node


    pathForNode: (node, root) ->
      while node.ownerElement?
        node = node.ownerElement
      path = []
      while parent = node.parentNode and parent isnt root
        index = 0
        if node.previousSibling
          sibling = node.previousSibling
          while sibling
            if sibling.nodeType is @ELEMENT_NODE and sibling.nodeName is node.nodeName
              index += 1
            sibling = sibling.previousSibling
        qname = @getQname(node.nodeName)
        path.unshift({local: qname.local, nsuri: node.namespaceURI, index: index})
        node = parent
      return path

    getChildNodes: (node) ->
      if node.hasAttribute and node.hasAttribute('data-xmlel')
        children = []
        remaining = []
        for child in node.childNodes
          remaining.push child
        while child = remaining.shift()
          if child.hasAttribute and child.hasAttribute('data-xmlel')
            children.push child
          else
            if child.childNodes and child.childNodes.length
              for grandchild in child.childNodes
                remaining.unshift grandchild
        return children

      return node.childNodes

    getNextSiblingElement: (node, tagName) ->
      node = node.nextSibling
      while node and node.nodeType isnt @ELEMENT_NODE
        node = node.nextSibling
      if tagName
        tagName = tagName.toLowerCase()
        while node and node.tagName and node.tagName.toLowerCase() isnt tagName
          node = node.nextSibling
      return node

    depth: (node) ->
      nodeDepth = 0
      while node.parentElement and node isnt prevnode
        prevnode = node
        nodeDepth += 1
        node = node.parentElement
      return nodeDepth

    getChildByName: (node, names, namespaceURI) ->
      for child in node.childNodes
        matches = __name_matcher(names, @getLocalName(child))
        nsOk = not child.namespaceURI? or child.namespaceURI is namespaceURI
        if matches and nsOk
          return child
      null

    getChildrenByName: (node, names, namespaceURI) ->
      children = []
      for child in node.childNodes
        matches = __name_matcher(names, @getLocalName(child))
        nsOk = not child.namespaceURI? or child.namespaceURI is namespaceURI
        if matches and nsOk
          children.push child
      children

    getQname: (nodeName) ->
      nodeName = "" + nodeName
      i = nodeName.indexOf(":")
      qualName = (if i < 0 then ["", nodeName] else nodeName.split(":"))
      prefix = qualName[0]
      local = qualName[1]

      # <x "xmlns"="http://foo">
      if nodeName is "xmlns"
        prefix = "xmlns"
        local = ""
      prefix: prefix
      local: local

    getNamespacePrefix: (nodeName) =>
      return '' if not nodeName?
      return @getQname(nodeName).prefix

    escapeHtml: (string) ->
      String(string).replace /[&<>"'\/]/g, (s) ->
        return entityMap[s]

    getNodeAttr: (node, target) ->
      attrs = @getNodeAttributes(node)
      if attrs[target]?.value isnt undefined
        return attrs[target].value
      if attrs[target] isnt undefined
        return attrs[target]
      index = attrs.length
      while index--
        if attrs[index].name is target
          return attrs[index].value
      return undefined

    getNodeAttributes: (node) ->
      if node.hasAttribute? and node.hasAttribute('data-xmlel')
        lastindex = node.attributes.length - 1
        attrs = []
        for attrindex in [0..lastindex]
          attr = node.attributes[attrindex]
          switch attr.name
            when "data-xmlel", "data-nsbk", "data-nsuribk" then continue
            when "data-clsbk"
              newattr = document.createAttribute('class')
              newattr.value = attr.value
              attrs[attrindex] = newattr
            when "class" then continue
            else
              if attr.value.substr(0, 9) is "tmp_tree_"
                continue
              attrs[attrindex] = attr
        return attrs
      if node.attributes?
        return node.attributes
      return []


    getNodeType: (node) ->
      switch true
        when node?.nodeType? then node.nodeType
        when typeof node is "string" then Node.TEXT_NODE
        else undefined

    isNodeWhitespace: (node) =>
      if @getNodeType(node) is Node.TEXT_NODE
        if @textContent(node).replace(/^\s+|\s+$/gm, "") is ""
          return true
      return false

    getLocalName: (node) ->
      return "" if node is undefined
      if node._localNameCache isnt undefined
        return node._localNameCache
      if typeof node is "string"
        return @getQname(node).local
      if node.hasAttribute? and node.hasAttribute('data-xmlel')
        return node._localNameCache = node.attributes['data-xmlel'].value
      if node.localName isnt undefined
        return node._localNameCache = node.localName
      if node.local isnt undefined
        return node._localNameCache = node.local
      if node.nodeName isnt undefined
        return node._localNameCache = @getQname(node.nodeName).local
      return @getQname(node).local

    textContent: (node) ->
      return node.textContent if node.textContent
      return node if typeof node is "string"
      result = ''
      for child in node.childNodes
        switch child.nodeType
          when @ELEMENT_NODE, @ENTITY_REFERENCE_NODE
            result += @textContent child
          when @ATTRIBUTE_NODE, @TEXT_NODE, @CDATA_SECTION_NODE
            result += child.nodeValue
      result

    getXHR: (url) ->
      resp = null
      if window.tinymce?.util?.XHR?
        tinymce.util.XHR.send {
          url: url,
          async: false,
          success: (text, response) ->
            resp = response
        }
        return resp
      xmlhttp = new XMLHttpRequest()
      xmlhttp.open("GET", url, false)
      xmlhttp.send('')
      return xmlhttp

    getXML: (url) ->
      xslDoc = null
      if window.tinymce?.util?.XHR?
        tinymce.util.XHR.send {
          url: url,
          content_type: 'text/xml'
          async: false,
          success: (text, response) ->
            xslDoc = response.responseXML
        }
        return xslDoc
      xmlhttp = new XMLHttpRequest()
      xmlhttp.open("GET", url, false)
      xmlhttp.send('')
      xslDoc = xmlhttp.responseXML


    parseXML: (data) ->
      if not data or typeof data isnt "string"
        return data
      try
        if window.DOMParser
          parser = new DOMParser()
          xml = parser.parseFromString(data, "text/xml")
        else
          xml = new ActiveXObject("Microsoft.XMLDOM")
          xml.async = "false"
          xml.loadXML data
      catch e
        xml = undefined
      xml

    parseJSON: (text) ->
      (window.jQuery?.parseJSON || window.tinymce?.util?.JSON?.parse)(text)

    hasDomError: (dom) ->
      errorNS = "http://www.mozilla.org/newlayout/xml/parsererror.xml"
      (!dom or
        !dom.documentElement or
        dom.documentElement.namespaceURI == errorNS or
        (dom.getElementsByTagName("parsererror").length > 0)
      )

    # Iteratively traverse a DOM fragment via depth first pre-order
    #
    # @overload depthFirstIterativePreorderEvents(root, handlerFunction)
    #   Calls handlerFunction once at the start of visiting every node, with 'this' set to the node
    #   @param [Node] root Root DOM node to traverse
    #   @param [Function] handler Function to call with 'this' set to every node as it is entered;
    #     two arguments (depth, node)
    #
    # @overload depthFirstIterativePreorderEvents(root, handlerObject)
    #   Calls handlerObject.startTag when entering a node and handlerObject.endTag when leaving a node
    #   @param [Node] root Root DOM node to traverse
    #   @param [Object] handler Handler object; startTag and endTag methods are called with
    #     two arguments (node, depth)
    #
    # @note To prune all children of a node (and not visit them), return 'false' from the handler function or startTag
    #
    depthFirstIterativePreorder: (root, handler) ->
      node = root
      depth = 0
      while node isnt null
        if handler.startTag
          processChildren = handler.startTag(node, depth)
        else if typeof handler is 'function'
          processChildren = handler.call(node, depth, node)
        else
          processChildren = true
        if node.hasChildNodes() and processChildren isnt false
          depth += 1
          node = node.firstChild
        else
          while node.nextSibling is null
            node = node.parentNode
            depth -= 1
            if handler.endTag
              handler.endTag(node, depth)
            if node is root
              return
          node = node.nextSibling


  new Helpers()
