# pathhelper.coffee - Display a list of elements with insertion buttons
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
  CKEDITOR = require('ckeditor')

  commands = toolbarFocus:
    editorFocus: false
    readOnly: 1
    exec: (editor) ->
      idBase = editor._.txtElementsPath.idBase
      element = CKEDITOR.document.getById(idBase + "0")
      
      # Make the first button focus accessible for IE. (#3417)
      # Adobe AIR instead need while of delay.
      element and element.focus(CKEDITOR.env.ie or CKEDITOR.env.air)

  emptyHtml = "<span class=\"cke_path_empty\">&nbsp;</span>"
  extra = ""
  
  # Some browsers don't cancel key events in the keydown but in the
  # keypress.
  # TODO: Check if really needed for Gecko+Mac.
  extra += " onkeypress=\"return false;\""  if CKEDITOR.env.opera or (CKEDITOR.env.gecko and CKEDITOR.env.mac)
  
  # With Firefox, we need to force the button to redraw, otherwise it
  # will remain in the focus state.
  extra += " onblur=\"this.style.cssText = this.style.cssText;\""  if CKEDITOR.env.gecko
  pathItemTpl = CKEDITOR.addTemplate("pathItem", "<a" + " id=\"{id}\"" + " href=\"{jsTitle}\"" + " tabindex=\"-1\"" + " class=\"cke_path_item\"" + " title=\"{label}\"" + ((if (CKEDITOR.env.gecko and CKEDITOR.env.version < 10900) then " onfocus=\"event.preventBubble();\"" else "")) + extra + " hidefocus=\"true\" " + " onkeydown=\"return CKEDITOR.tools.callFunction({keyDownFn},'{index}', event );\"" + " onclick=\"CKEDITOR.tools.callFunction({clickFn},'{index}', event); return false;\"" + " role=\"button\" aria-label=\"{label}\">" + "{text}" + "</a>")
  CKEDITOR.plugins.add "txtElementsPath",
    init: (editor) ->
      # Elements path isn't available in inline mode.
      
      # Register the ui element to the focus manager.
      onClick = (elementIndex, ev) ->
        element = editor._.txtElementsPath.list[elementIndex]
        if !element
          return
        editor.focus()
        if element.equals(editor.editable())
          range = editor.createRange()
          range.selectNodeContents element
          range.select()
        else
          editor.getSelection().selectElement element

      onClickHanlder = CKEDITOR.tools.addFunction(onClick)

      onClickEditHandler = CKEDITOR.tools.addFunction((elementIndex, ev) ->
        element = editor._.txtElementsPath.list[elementIndex]
        if !element
          return
        editor.focus()
        elementName = filterName(element, findName(element))
        attributes = CKEDITOR.textorum.schema.defs[elementName]?.attr
        if CKEDITOR.tools.isEmpty attributes
          window.alert "whoops, no attributes for #{elementName}"
          return
        attNames = []
        for own attName, v of attributes
          attNames.push attName
        attributeName = window.prompt "Enter an attribute name.  Attributes for #{elementName}: " + attNames.join(", ")
        if not attributeName in attNames
          window.alert "whoops, #{attributeName} not a valid attribute for #{elementName}"
          return
        attributeValue = window.prompt "Enter a value for #{attributeName}.  Previous value: " + element.getAttribute(attributeName)
        if attributeValue isnt null
          if attributeValue
            element.setAttribute attributeName, attributeValue
            window.alert "set #{elementName} #{attributeName} to #{attributeValue}"
            return
          else
            element.removeAttribute attributeName
            window.alert "removed #{elementName}'s #{attributeName}"
            return
        else
          window.alert "no change to #{elementName}'s #{attributeName}"
        return
        if element.equals(editor.editable())
          range = editor.createRange()
          range.selectNodeContents element
          range.select()
        else
          editor.getSelection().selectElement element
      )
      # LEFT-ARROW
      # TAB
      # RIGHT-ARROW
      # SHIFT + TAB
      # ESC
      # ENTER	// Opera
      # SPACE
      empty = ->
        spaceElement and spaceElement.setHtml(emptyHtml)
        delete editor._.txtElementsPath.list
      return  if editor.elementMode is CKEDITOR.ELEMENT_MODE_INLINE
      spaceName = "txtpath"
      spaceId = editor.ui.spaceId(spaceName)
      spaceElement = undefined
      getSpaceElement = ->
        spaceElement = CKEDITOR.document.getById(spaceId)  unless spaceElement
        spaceElement

      idBase = "cke_txtElementsPath_" + CKEDITOR.tools.getNextNumber() + "_"
      editor._.txtElementsPath =
        idBase: idBase
        filters: []

      editor.on "uiSpace", (event) ->
        event.data.html += "<span id=\"" + spaceId + "_label\" class=\"cke_voice_label\">" + "Textorum Elements Path" + "</span>" + "<div id=\"" + spaceId + "\" class=\"cke_path\" role=\"group\" aria-labelledby=\"" + spaceId + "_label\">" + emptyHtml + "</div>"  if event.data.space is "bottom"

      editor.on "uiReady", ->
        element = editor.ui.space(spaceName)
        element and editor.focusManager.add(element, 1)

      
      onKeyDownHandler = CKEDITOR.tools.addFunction((elementIndex, ev) ->
        idBase = editor._.txtElementsPath.idBase
        element = undefined
        ev = new CKEDITOR.dom.event(ev)
        rtl = editor.lang.dir is "rtl"
        switch ev.getKeystroke()
          when (if rtl then 39 else 37), 9
            element = CKEDITOR.document.getById(idBase + (elementIndex + 1))
            element = CKEDITOR.document.getById(idBase + "0")  unless element
            element.focus()
            return false
          when (if rtl then 37 else 39), CKEDITOR.SHIFT + 9
            element = CKEDITOR.document.getById(idBase + (elementIndex - 1))
            element = CKEDITOR.document.getById(idBase + (editor._.txtElementsPath.list.length - 1))  unless element
            element.focus()
            return false
          when 27
            editor.focus()
            return false
          when 13, 32
            onClick elementIndex, ev
            return false
        true
      )

      addElementHandler = CKEDITOR.tools.addFunction((elementIndex, ev) ->
        realIndex = elementIndex.substr(elementIndex.indexOf('-') + 1)
        insertType = elementIndex.substr(0, elementIndex.indexOf('-'))
        element = editor._.txtElementsPath.list[realIndex]
        # console.log "addElementHandler", element, elementIndex, realIndex, insertType, ev
        if !element
          return
        editor.focus()
        if element.equals(editor.editable())
          range = editor.createRange()
          range.selectNodeContents element
          range.select()
        else
          switch insertType
            when 'inside'
              target = element
            else
              target = element.getParent()
          targetName = filterName(target, findName(target))
          contains = CKEDITOR.textorum.schema.defs[targetName]?.contains
          if CKEDITOR.tools.isEmpty(contains)
            window.alert "Whoops, #{targetName} can't actually contain anything"
            return
          targetContains = []
          for contained, v of contains
            targetContains.push contained
          domElement = prompt("Enter an element name: " + targetContains.join(", "))
          if not domElement in targetContains
            window.alert "Whoops, #{domElement} not in " + targetContains.join(", ")
            return
          editor.fire( 'saveSnapshot' )

          domHtml = editor.dataProcessor.toHtml '<' + domElement + ' data-xmlel="' + domElement + '"></' + domElement + '>'
          insertable = CKEDITOR.dom.element.createFromHtml(domHtml, editor.document)
          dummy = editor.document.createText( '\u00A0' );
          dummy.appendTo( insertable );
          switch insertType
            when 'before'
              insertable.insertBefore(element)
            when 'after'
              insertable.insertAfter(element)
            when 'inside'
              insertable.appendTo(element)
            else
              console.log "can't insert #{insertType}", elementIndex, ev
          range = new CKEDITOR.dom.range( editor.document )
          range.moveToPosition(insertable, CKEDITOR.POSITION_BEFORE_END)
          insertable.scrollIntoView()
          editor.focus()
          range = editor.createRange()
          range.selectNodeContents insertable
          range.select()
          editor.fire( 'saveSnapshot' )
      )

      genericHandler = CKEDITOR.tools.addFunction((elementIndex, ev) ->
        realIndex = elementIndex.substr(elementIndex.indexOf('-') + 1)
        console.log elementIndex, realIndex, ev
        onClick realIndex, ev
      )

      filterName = (element, name) ->
        filters = editor._.txtElementsPath.filters
        for filter in filters
          ret = filter(element, name)
          if ret is false
            return ret
          name = ret or name
        name

      findName = (element) ->
        name = undefined
        if element.data("cke-display-name")
          name = element.data("cke-display-name")
        else if element.data("cke-real-element-type")
          name = element.data("cke-real-element-type")
        else
          name = element.getName()
        name

      editor.on "selectionChange", (ev) ->
        env = CKEDITOR.env
        schema = CKEDITOR.textorum.schema.defs
        editable = editor.editable()
        selection = ev.data.selection
        element = selection.getStartElement()
        html = []
        closehtml = []
        elementsList = editor._.txtElementsPath.list = []
        filters = editor._.txtElementsPath.filters
        while element
          ignore = 0
          name = findName(element)
          elementParent = element.getParent()
          parentName = filterName(elementParent, findName(elementParent))
          # console.log "parent", parentName
          ret = filterName(element, name)
          if ret is false
            ignore = 1
          name = ret or name
          unless ignore
            index = elementsList.push(element) - 1
            label = "%1 element".replace(/%1/, name)
            item = pathItemTpl.output(
              id: idBase + index
              label: label
              text: name
              jsTitle: "javascript:void('" + name + "')"
              index: index
              keyDownFn: onKeyDownHandler
              clickFn: onClickHanlder
            )
            html.unshift item

            if not element.equals(editable)
              if not CKEDITOR.tools.isEmpty(schema[parentName]?.contains)
                parentContains = []
                for contained, v of schema[parentName]?.contains
                  parentContains.push contained

                beforeitem = pathItemTpl.output(
                  id: idBase + "before" + index
                  label: parentName + " element - " + parentContains.join(", ")
                  text: "+"
                  jsTitle: "javascript:void('before " + name + "')"
                  index: "before-" + index
                  keyDownFn: genericHandler
                  clickFn: addElementHandler
                )
                html.unshift beforeitem

            if index == 0
              if not CKEDITOR.tools.isEmpty(schema[name]?.contains)
                contains = []
                for contained, v of schema[name]?.contains
                  contains.push contained


                insideitem = pathItemTpl.output(
                  id: idBase + "inside" + index
                  label: label + " - " + contains.join(", ")
                  text: "+"
                  jsTitle: "javascript:void('inside " + name + "')"
                  index: "inside-" + index
                  keyDownFn: genericHandler
                  clickFn: addElementHandler
                )
                html.push insideitem

            closeitem = pathItemTpl.output(
              id: idBase + "close" + index
              label: label
              text: "/" + name
              jsTitle: "javascript:void('edit-" + name + "')"
              index: index
              keyDownFn: onKeyDownHandler
              clickFn: onClickEditHandler
            )
            html.push closeitem

            if not element.equals(editable)
              if not CKEDITOR.tools.isEmpty(schema[parentName]?.contains)
                afteritem = pathItemTpl.output(
                  id: idBase + "after" + index
                  label: parentName + " element - " + parentContains.join(", ")
                  text: "+"
                  jsTitle: "javascript:void('after " + name + "')"
                  index: "after-" + index
                  keyDownFn: genericHandler
                  clickFn: addElementHandler
                )
                html.push afteritem



          if element.equals(editable)
            break
          element = elementParent

        space = getSpaceElement()
        space.setHtml html.join("") + emptyHtml
        editor.fire "txtElementsPathUpdate",
          space: space


      editor.on "readOnly", empty
      editor.on "contentDomUnload", empty
      editor.addCommand "txtElementsPathFocus", commands.toolbarFocus
      editor.setKeystroke CKEDITOR.ALT + 122, "txtElementsPathFocus" #F11

###
Fired when the contents of the txtElementsPath are changed.

@event txtElementsPathUpdate
@member CKEDITOR.editor
@param data
@param {Object} data.space The txtElementsPath container.
###