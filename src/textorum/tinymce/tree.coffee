# tree.coffee - Textorum TinyMCE plugin, element tree
#
# Copyright (C) 2012 Crowd Favorite, Ltd. All rights reserved.
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
  tinymce = require('tinymce')
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
      console.log "select_node", event, data
      node = data.rslt.obj;
      id = node.attr('name');
      if (id)
        console.log "clicked", id

        node = editor.dom.select('#'+id);
        #node.append('<span class="empty_tag_remove_me"></span>');

        nodeEl = node[0]
        editor.getWin().scrollTo(0, editor.dom.getPos(nodeEl).y - 10);
        if id is previousNode
          editor.selection.select(nodeEl)
        else
          editor.selection.setCursorLocation(nodeEl, 0)
        editor.nodeChanged()

        editor.focus()
        previousNode = id

  _depthWalkCallbackGenerator = (holder) ->
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
      title = node.getAttribute('data-xmlel') || ("[" + node.localName + "]")
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

  _contextMenuItemsGenerator = (editor) ->
    _getSubmenu = (keys) ->
      inserts = {}
      inserted = false
      for key of keys
        inserted = true
        inserts[key] =
          label: key
          icon: "img/tag.png"
          action: (obj) ->
            actionType = obj.parents("li.submenu").children("a").attr("rel")
            key = obj.text()
            pos =
              x: parseInt($("#tree_popup").css("left"))
              y: parseInt($("#tree_popup").css("top"))

            if actionType is "change"
              id = $("#tree a.ui-state-active").closest("li").attr("name")
              editor.execCommand "changeTag",
                key: key
                pos: pos
                id: id

            else
              editor.currentBookmark = editor.selection.getBookmark(1)
              editor.execCommand "addSchemaTag",
                key: key
                pos: pos
                action: actionType

      unless inserted
        inserts["no_tags"] =
          label: "No tags available."
          icon: "img/cross.png"
          action: (obj) ->
      inserts


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
      submenu = _getSubmenu(validNodes)
      siblingSubmenu = _getSubmenu(siblingNodes)
      items =
        before:
          label: "Insert Tag Before"
          icon: "img/tag_add.png"
          _class: "submenu"
          submenu: siblingSubmenu

        after:
          label: "Insert Tag After"
          icon: "img/tag_add.png"
          _class: "submenu"
          submenu: siblingSubmenu

        inside:
          label: "Insert Tag Inside"
          icon: "img/tag_add.png"
          _class: "submenu"
          separator_after: true
          submenu: submenu

        change:
          label: "Change Tag"
          icon: "img/tag_edit.png"
          _class: "submenu"
          submenu: siblingSubmenu

        edit:
          label: "Edit Tag"
          icon: "img/tag_edit.png"
          action: (obj) ->


        delete:
          label: "Remove Tag Only"
          icon: "img/tag_delete.png"
          action: (obj) ->


      if not parent.attr('data-xmlel')
        delete items["delete"]
        delete items["before"]
        delete items["after"]
        delete items["around"]
      items

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

    helper.depthFirstWalk body, _depthWalkCallbackGenerator(holder)

    $(selector).jstree(
      json_data:
        data: [top]
      ui: 
        select_limit: 1
      core:
        animation: 0
      contextmenu:
        select_node: true
        show_at_node: true
        items: _contextMenuItemsGenerator(editor)
      plugins: ['json_data', 'ui', 'themes', 'contextmenu']
      ).on('select_node.jstree', _selectNodeHandlerGenerator(editor))
    
  navigateTree = (editor, controlmanager, node) ->
    ignoreNavigation = true
    treeInstance = $(treeSelector).jstree('get_instance')
    treeInstance.close_all(-1, false)
    firstNode = treeInstance._get_node("[name='#{node.getAttribute('id')}']")
    if firstNode
      secondNode = treeInstance._get_parent(firstNode)
      treeInstance.open_node(secondNode)
      treeInstance.open_node(firstNode)
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
    

