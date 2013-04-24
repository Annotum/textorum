# element.coffee - Textorum element-editing popups
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
  helper = require('../helper')
  tinymce = window.tinymce
  $ = window.jQuery

  class ElementHandler
    namespaceIdx: 0
    constructor: (@editor) ->
      @editor.addCommand 'addSchemaTag', @addTag, this
      @editor.addCommand 'editSchemaTag', @editTag, this
      @editor.addCommand 'removeSchemaTag', @removeTag, this
    # Create a new tag, bring up editing window
    addTag: (ui, params) ->
      newtagname = params['key']
      if not @editor.plugins.textorum.schema.defs[newtagname]
        console.log "error", "no such tag in schema: #{newtagname}"
        return
      @editWindow params
    # Bring up editing window for existing tag
    editTag: (ui, params) ->
      @editWindow {}, params
    # Delete a tag
    removeTag: (ui, params) ->

    editorNodeFromListNode: (node) ->
      node = $(node)
      if node.length
        return $(@editor.dom.select("##{node.attr('name')}"))
      else
        return node

    nameWithPrefix: (name, params, editorNode) ->
      if params.ns
        prefix = @editor.plugins.textorum.nsmap[params.ns]
        if prefix is undefined
          prefix = "txtns#{@namespaceIdx}"
          @editor.plugins.textorum.nsmap[params.ns] = prefix
          @namespaceIdx += 1
          # TODO: Better way to get the actual base document element?
          # TODO: Only set this when necessary, maybe?
          @editor.dom.select("body")[0].firstElementChild.setAttribute("xmlns:#{prefix}", params.ns)
          if editorNode.length
            attrValue = editorNode[0].getAttributeNS params.ns, name
            if attrValue
              editorNode[0].removeAttributeNS params.ns, name
              editorNode.attr "#{prefix}:#{name}", attrValue
          else
        if prefix
          return "#{prefix}:#{name}"
      return name

    attrListElement: (name, params, editorNode) ->
      origname = name
      name = @nameWithPrefix(name, params, editorNode)
      attrValue = editorNode.attr name

      out = $(document.createElement("li"))

      if params.required or attrValue?
        out.addClass('open textorum-open')

      out.addClass "attr textorum-attr textorum-attr-#{origname.replace(/:/, '--')}"
      out.data 'textorum-attribute-name', name

      label = $(document.createElement("label"))
      label.append document.createTextNode("#{name}")
      out.append label

      sel = undefined

      if params.value?.length
        sel = $(document.createElement("select"))
        if not params.required
          opt = $(document.createElement("option"))
          opt.val ""
          opt.append document.createTextNode(" -- empty -- ")
          sel.append opt
        for value in params.value
          opt = $(document.createElement("option"))
          opt.val value
          if value is attrValue
            opt.prop "selected", true
          opt.append document.createTextNode(value)
          sel.append opt
      else if params.data isnt undefined
        sel = $(document.createElement("input"))
        sel.prop "type", "text"
        if attrValue?
          sel.val attrValue
      else if params.$?
        sel = $(document.createElement("textarea"))
        if attrValue?
          sel.append document.createTextNode(attrValue)

      if sel isnt undefined
        sel.addClass "attrinput textorum-attrinput"
        sel.name = "attr-#{name}"
        out.append sel

      out

    editWindow: (params, node) ->
      editorNode = @editorNodeFromListNode node
      creating = false
      if not node or not editorNode.length
        creating = true

      newtagname = $(editorNode).attr("data-xmlel") || params['key']
      elementattrs = @editor.plugins.textorum.schema.defs[newtagname]?.attr

      attrwindow = $(document.createElement("div"))
      attrwindow.addClass "attributewindow textorum-attributewindow"

      attrRequiredList = $(document.createElement("ul"))
      attrRequiredList.addClass "required-attributes textorum-required-attributes"
      attrlist = $(document.createElement("ul"))
      attrlist.addClass "textorum-optional-attributes"

      attrlist.on 'click', 'li.textorum-attr label', (e) ->
        el = $(this)
        el.parents("li").toggleClass('open textorum-open')

      for own attr of elementattrs
        if elementattrs[attr].required
          attrRequiredList.append @attrListElement(attr, elementattrs[attr], editorNode)
        else
          attrlist.append @attrListElement(attr, elementattrs[attr], editorNode)

      if attrlist.children().length or attrRequiredList.children().length
        if attrRequiredList.children().length
          heading = $(document.createElement("h2"))
          heading.append document.createTextNode("Required Attributes")
          attrwindow.append heading, attrRequiredList
        if attrlist.children().length
          heading = $(document.createElement("h2"))
          heading.append document.createTextNode("Optional Attributes")
          attrwindow.append heading, attrlist

        wm = @editor.windowManager
        thiseditor = @editor
        w = wm.open {
          inline: true
          resizable: true
          title: "Edit #{newtagname}"
          content: attrwindow
          buttons: [{
            text: 'Ok'
            click: (e) ->
              if creating
                console.log "creating node"
                console.log "params", params
                editorNode = $(document.createElement(thiseditor.plugins.textorum.translateElement(newtagname)))
                editorNode.attr 'data-xmlel', newtagname
                editorNode.addClass newtagname

              attrwindow.find("li.textorum-attr").each (e) ->
                attrli = $(this)
                if attrli.hasClass "textorum-open"
                  console.log "setting", attrli.data('textorum-attribute-name'), "to", attrli.find('.attrinput').val()
                  editorNode.attr attrli.data('textorum-attribute-name'), attrli.find('.attrinput').val()
                else
                  console.log "removing", attrli.data('textorum-attribute-name')
                  editorNode.removeAttr attrli.data('textorum-attribute-name')

              if creating
                target = $(thiseditor.dom.select("##{params.id}"))
                console.log "inserting", editorNode, params.action, target
                switch params.action
                  when "before"
                    editorNode.insertBefore(target)
                  when "after"
                    editorNode.insertAfter(target)
                  when "inside"
                    editorNode.appendTo(target)
              thiseditor.undoManager.add()
              thiseditor.execCommand('mceRepaint')
              thiseditor.plugins.textorum.updateTree()

              thiseditor.focus()
              wm.close(null, w.id)
          }, {
            text: 'Cancel'
            click: (e) ->
              console.log "Cancel button clicked:", e, w
              wm.close(null, w.id)
          }]
        }
      else
        console.log "no attributes"
        if creating
          console.log "creating node"
          editorNode = $(document.createElement(@editor.plugins.textorum.translateElement(newtagname)))
          editorNode.attr 'data-xmlel', newtagname
          editorNode.addClass newtagname
          target = $(@editor.dom.select("##{params.id}"))
          console.log "inserting", editorNode, params.action, target
          switch params.action
            when "before"
              editorNode.insertBefore(target)
            when "after"
              editorNode.insertAfter(target)
            when "inside"
              editorNode.appendTo(target)
        @editor.undoManager.add()
        @editor.execCommand('mceRepaint')
        @editor.plugins.textorum.updateTree()

        @editor.focus()

  return ElementHandler
