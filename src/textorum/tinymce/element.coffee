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
      editor.addCommand 'addSchemaTag', @addTag, this
      editor.addCommand 'changeSchemaTag', @changeTag, this
      editor.addCommand 'editSchemaTag', @editTag, this
      editor.addCommand 'removeSchemaTag', @removeTag, this
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
    # Replace a tag with another one
    changeTag: (ui, params) ->
      newtagname = params['key']
      if not @editor.plugins.textorum.schema.defs[newtagname]
        console.log "error", "no such tag in schema: #{newtagname}"
        return
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
      el = $(document.createElement("li"))
      el.addClass "attr_#{origname.replace(/:/, '__')}"
      el.data "target", "attr_#{origname.replace(/:/, '__')}"
      el.append(document.createTextNode(name))
      if not params.required
        el.addClass "optional"
      if attrValue?
        el.addClass "visible"
      el

    attrFormElement: (name, params, editorNode) ->
      origname = name
      name = @nameWithPrefix(name, params, editorNode)
      attrValue = editorNode.attr name

      if params.required or attrValue?
        display = "block"
      else
        display = "none"
      out = $(document.createElement("div"))
      out.attr "style", """display: #{display};"""
      out.addClass "attr_#{origname.replace(/:/, '__')}"
      out.data 'attribute_name', name
      out.addClass "attrform"
      label = $(document.createElement("label"))
      label.append document.createTextNode("#{name}")
      out.append label

      if params.value?.length
        sel = $(document.createElement("select"))
        sel.addClass "attrinput"
        sel.name = "attr_#{name}"
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
        out.append sel
      else if params.data isnt undefined
        sel = $(document.createElement("input"))
        sel.addClass "attrinput"
        sel.prop "type", "text"
        if attrValue?
          sel.val attrValue
        out.append sel
      else if params.$?
        sel = $(document.createElement("textarea"))
        sel.addClass "attrinput"
        if attrValue?
          sel.append document.createTextNode(attrValue)
        out.append sel

      out

    editWindow: (params, node) ->
      attroptional = {}
      attrrequired = {}
      attrgroups = {}
      editorNode = @editorNodeFromListNode node
      creating = false
      if not node or not editorNode.length
        creating = true


      newtagname = $(editorNode).attr("data-xmlel") || params['key']
      elementattrs = @editor.plugins.textorum.schema.defs[newtagname]?.attr

      attrRequiredList = $(document.createElement("ul"))
      attrlist = $(document.createElement("ul"))
      attrform = $(document.createElement("div"))

      attrwindow = $(document.createElement("div"))
      attrwindow.addClass "textorum_attributewindow"
      attrlists = $(document.createElement("div"))
      attrlists.append attrRequiredList
      attrlists.append attrlist
      attrwindow.append attrlists
      attrwindow.append attrform
      
      attrlists.on 'click', 'li.optional', (e) ->
        el = $(this)
        window.foo = el
        el.parents(".textorum_attributewindow").find("div.#{el.data('target')}").toggle()

      for own attr of elementattrs
        attrform.append @attrFormElement(attr, elementattrs[attr], editorNode)
        if elementattrs[attr].required
          attrRequiredList.append @attrListElement(attr, elementattrs[attr], editorNode)
          attroptional[attr] = elementattrs[attr]
        else
          attrlist.append @attrListElement(attr, elementattrs[attr], editorNode)
          attrrequired[attr] = elementattrs[attr]
      if attrform.children().length
        window.attrform = attrform
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

              attrform.find("div.attrform:hidden").each (e) ->
                console.log "removing", $(this).data('attribute_name')
                editorNode.removeAttr $(this).data('attribute_name')
              attrform.find("div.attrform:visible").each (e) ->
                console.log "setting", $(this).data('attribute_name'), "to", $(this).find('.attrinput').val()
                editorNode.attr $(this).data('attribute_name'), $(this).find('.attrinput').val()
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


  init = (editor) ->
    return new ElementHandler(editor)

  {
    init: init    
  }