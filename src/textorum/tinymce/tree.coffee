# tree.coffee - Textorum TinyMCE plugin, element tree
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
  window.textorum ||= {}
  $ = window.jQuery

  window.textorum.w ||= {}
  w = window.textorum.w

  treeIDPrefix = 'tmp_tree_'
  ignoreNavigation = false
  w.structs = {}
  w.deletedStructs = {}
  treeSelector = undefined
  createTree = (selector, editor) ->
    treeSelector = selector
    foo = $(selector).jstree({
      core: {
        animation: 0
        },
      themeroller: {},
      ui: {
        select_limit: 1
      },
      json_data: {
        data: {
          data: 'Document',
          attr: {id: 'root'},
          state: 'open'
        }
      },
      plugins: ['json_data', 'ui', 'themeroller', 'contextmenu']
      })

  _selectNodeHandlerGenerator = (editor) ->
    previousNode = null

    selectNodeHandler = (event, data) ->
      if ignoreNavigation
        return
      node = data.rslt.obj;
      id = node.attr('name');
      if (id)
        node = editor.dom.select('#'+id);
        #node.append('<span class="empty_tag_remove_me"></span>');

        nodeEl = node[0]
        editor.getWin().scrollTo(0, editor.dom.getPos(nodeEl).y - 10);
        if id is previousNode
          editor.selection.select(nodeEl)
          editor.nodeChanged()
        else
          editor.selection.setCursorLocation(nodeEl, 0)
          editor.nodeChanged()
          $(node).effect("highlight", {}, 350)

        editor.focus()
        previousNode = id

  _depthWalkCallbackGenerator = (holder, nodeTitleCallback) ->
    depthWalkCallback = (depth) ->
      node = this
      if not node.getAttribute?
        return false
      id = node.getAttribute('id')
      if not id
        node.setAttribute('id', tinymce.DOM.uniqueId(treeIDPrefix))
        id = node.getAttribute('id')
      while depth < (holder.length - 1)
        holder.shift()
      if not node.getAttribute('data-xmlel') && node.localName == "br"
        return false
      title = node.getAttribute('data-xmlel') || ("[" + node.localName + "]")
      if nodeTitleCallback
        additional = nodeTitleCallback(node, title)
        if additional
          title = helper.escapeHtml(additional.replace("%TITLE%", title))
      holder[0]['children'] ||= []
      holder[0]['state'] ||= 'closed'
      holder[0]['children'].push
        'data': title
        'attr':
          name: id
          class: node.getAttribute('class')
          'data-xmlel': node.getAttribute('data-xmlel')

      if (depth) <= holder.length - 1
        holder.unshift holder[0]['children'][holder[0]['children'].length - 1]
      true

  # Return a function that produces editor-specific context menu items
  _contextMenuItemsGenerator = (editor) ->
    # Return a function suitable for use as a jstree contextmenu action, given
    # the action type ("before", "change") and key (target element name)
    _submenuActionGenerator = (actionType, key) ->
      (obj) ->
        pos =
          x: parseInt($("#tree_popup").css("left"))
          y: parseInt($("#tree_popup").css("top"))

        editor.currentBookmark = editor.selection.getBookmark(1)
        editor.execCommand "addSchemaTag", true,
          id: $(obj).attr("name")
          key: key
          pos: pos
          action: actionType
    # Given a list of keys, return a function to generate a list of submenu
    # items for a given action
    _submenuItemsForAction = (keys) ->
      (action) ->
        inserts = {}
        inserted = false
        for key of keys
          inserted = true
          inserts["#{action}-#{key}"] =
            label: key
            # icon: "img/tag.png"
            _class: "tag"
            action: _submenuActionGenerator(action, key)

        unless inserted
          inserts["no_tags"] =
            label: "No tags available."
            icon: "img/cross.png"
            action: (obj) ->
        inserts

    # The returned function for _contextMenuItemsGenerator
    contextMenuItems = (node) ->
      schema = editor.plugins.textorum.schema
      if not node.attr('data-xmlel')
        return {}
      editorNode = editor.dom.select("##{node.attr('name')}")
      validNodes = schema.defs?[node.attr('data-xmlel')]?.contains
      siblingNodes = (
        parent = node.parents('li:first')
        if parent
          if parent.attr('data-xmlel')
            schema.defs?[parent.attr('data-xmlel')]?.contains
          else
            # schema.$root
            {}
        else
          {}
      )
      submenu = _submenuItemsForAction(validNodes)
      siblingSubmenu = _submenuItemsForAction(siblingNodes)
      if (x for own x of schema.defs?[node.attr('data-xmlel')]?.attr).length
        editDisabled = false
      else
        editDisabled = true
      items =
        before:
          label: "Insert Tag Before"
          # icon: "img/tag_add.png"
          _class: "submenu insert-tag"
          submenu: siblingSubmenu("before")

        after:
          label: "Insert Tag After"
          _class: "submenu insert-tag"
          submenu: siblingSubmenu("after")

        inside:
          label: "Insert Tag Inside"
          _class: "submenu insert-tag"
          separator_after: true
          submenu: submenu("inside")

        edit:
          label: "Edit Attributes"
          # icon: "img/tag_edit.png"
          _class: "edit-tag"
          _disabled: editDisabled
          action: (obj) ->
            editor.execCommand "editSchemaTag", true, obj

        delete:
          label: "Remove Tag Only"
          # icon: "img/tag_delete.png"
          _class: "remove-tag"
          action: (obj) ->
            editor.execCommand "removeSchemaTag", true, obj


      if not parent.attr('data-xmlel')
        delete items["delete"]
        delete items["before"]
        delete items["after"]
        delete items["around"]
      items

  # TODO: This should be passed in as part of the tree initialization
  _makeNodeTitle = (node, title) ->
    autotitle = true
    newtitle = switch title
      when "ref" then $(node).children('[data-xmlel="label"]').text() || false
      when "article"
        $(node).children('[data-xmlel="front"]')
          .find('[data-xmlel="article-title"]')
          .map((idx, ele) -> $(ele).text()).get().join(", ")
      when "title", "article-id" then $(node).text()
      when "journal-id", "issn", "publisher" then $(node).text()
      when "kwd" then $(node).text()
      when "kwd-group" then $(node).children('[data-xmlel="kwd"]')
        .map((idx, ele) -> $(ele).text()).get().join(", ")
      when "body"
        nodecount = $(node).children('[data-xmlel="sec"]').length
        "#{nodecount} section" + (if nodecount == 1 then "" else "s")
      when "sec", "ack" then $(node).children('[data-xmlel="title"]').text()
      when "ref-list"
        nodecount = $(node).children('[data-xmlel="ref"]').length
        $(node).children('[data-xmlel="title"]').text() + " - #{nodecount} reference" + (if nodecount == 1 then "" else "s")
      when "p" then $(node).text().substr(0, 20) + "..."
      when "table-wrap", "fig"
        jqnode = $(node)
        label = jqnode.children('[data-xmlel="label"]').text()
        caption = jqnode.children('[data-xmlel="caption"]').text()
        if caption.length > 15
          caption = caption.substr(0, 15) + "..."
        if label.length > 0 and caption.length > 0
          label = label + " "
        output = [label, caption].join("")
        if output.length > 0
          autotitle = false
          output = output + " [%TITLE%]"
        output
    if autotitle and newtitle and newtitle.indexOf("%TITLE%") is -1
      newtitle = "%TITLE%: " + newtitle
    newtitle



  updateTree = (selector, editor) ->
    body = editor.dom.getRoot()

    treeInstance = $(selector).jstree('get_instance')

    top = {
      data: 'Document',
      state: 'open',
      children: []
    }
    holder = []
    holder.unshift top

    helper.depthFirstIterativePreorder body, _depthWalkCallbackGenerator(holder, _makeNodeTitle)

    $(selector).jstree(
      json_data:
        data: [top['children']]
      ui:
        select_limit: 1
      core:
        animation: 0
        html_titles: true
      contextmenu:
        select_node: true
        show_at_node: true
        items: _contextMenuItemsGenerator(editor)
      plugins: ['json_data', 'ui', 'themes', 'contextmenu']
      ).on('select_node.jstree', _selectNodeHandlerGenerator(editor))

  navigateTree = (editor, controlmanager, node) ->
    ignoreNavigation = true
    treeInstance = $(treeSelector).jstree('get_instance')
    #treeInstance.close_all(-1, false)
    if not node.getAttribute
      return null
    firstNode = treeInstance._get_node("[name='#{node.getAttribute('id')}']")
    if firstNode
      secondNode = treeInstance._get_parent(firstNode)
      treeInstance.open_node(secondNode)
      treeInstance.open_node(firstNode)
      treeInstance.deselect_all()
      treeInstance.select_node(firstNode)
    ignoreNavigation = false
    return null

  # Module return
  {
    create: createTree
    update: updateTree
    navigate: navigateTree
    id_prefix: treeIDPrefix
  }


