# tree.coffee - Textorum TinyMCE plugin, element tree
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
  helper = require('../helper')
  ElementHandler = require('./element')

  tinymce = window.tinymce
  window.textorum ||= {}
  $ = window.jQuery

  window.textorum.w ||= {}
  w = window.textorum.w

  class TextorumTree
    constructor: (@treeSelector, @editor, makeNodeTitle) ->
      @treeIDPrefix = 'tmp_tree_'
      @ignoreNavigation = false
      @jsTree = $(@treeSelector)

      @jsTree.jstree @_jstreeOptions()
      if makeNodeTitle?
        @makeNodeTitle = makeNodeTitle
      @previousNode = null
      @elementHandler = new ElementHandler(@editor)

    _jstreeOptions: (jsonData, initiallyOpen) ->
      if not initiallyOpen?
        initiallyOpen = []
      if not jsonData?
        jsonData =
          data:
            data: 'Document'
            attr:
              id: 'root'
            state: 'open'
      returnData =
        json_data:
          data: jsonData
        ui:
          select_limit: 1
        core:
          animation: 0
          html_titles: true
          initially_open: initiallyOpen
        contextmenu:
          select_node: true
          show_at_node: true
          items: @contextMenuItemsCallback
        plugins: ['json_data', 'ui', 'themes', 'contextmenu']

    depthWalkCallback: (depth, node) =>
      if not node.getAttribute?
        return false
      id = node.getAttribute('id')
      if not id
        node.setAttribute('id', tinymce.DOM.uniqueId(@treeIDPrefix))
        id = node.getAttribute('id')
      while depth < (@holder.length - 1)
        @holder.shift()
      if not node.getAttribute('data-xmlel') && node.localName == "br"
        return false
      title = node.getAttribute('data-xmlel') || ("[" + node.localName + "]")
      if @makeNodeTitle
        additional = @makeNodeTitle(node, title)
        if additional
          title = helper.escapeHtml(additional.replace("%TITLE%", title))
      @holder[0]['children'] ||= []
      @holder[0]['state'] ||= 'closed'
      @holder[0]['children'].push
        'data': title
        'attr':
          id: "jstree_node_" + id
          name: id
          class: node.getAttribute('class')
          'data-xmlel': node.getAttribute('data-xmlel')

      if (depth) <= @holder.length - 1
        @holder.unshift @holder[0]['children'][@holder[0]['children'].length - 1]
      true

    # Return a function suitable for use as a jstree contextmenu action, given
    # the action type ("before", "change") and key (target element name)
    _submenuActionGenerator: (actionType, key) =>
      (obj) =>
        pos =
          x: parseInt($("#tree_popup").css("left"))
          y: parseInt($("#tree_popup").css("top"))

        @editor.currentBookmark = @editor.selection.getBookmark(1)
        @editor.execCommand "addSchemaTag", true,
          id: $(obj).attr("name")
          key: key
          pos: pos
          action: actionType

    # Given a list of keys, return a function to generate a list of submenu
    # items for a given action
    _submenuItemsForAction: (keys, treenode) =>
      (action) =>
        if @editor.plugins.textorum.validator
          validator = @editor.plugins.textorum.validator
          validKeys = []
          target = $(@editor.dom.select("##{treenode.attr('name')}"))
          for key, details of keys
            editorNode = $(document.createElement(@editor.plugins.textorum.translateElement(key)))
            editorNode.attr 'data-xmlel', key
            editorNode.addClass key
            switch action
              when "before"
                editorNode.insertBefore(target)
                res = validator.validatePartialOpportunistic(target.parents()[0], true, 1)
              when "after"
                editorNode.insertAfter(target)
                res = validator.validatePartialOpportunistic(target.parents()[0], true, 1)
              when "inside"
                editorNode.appendTo(target)
                res = validator.validatePartialOpportunistic(target[0], true, 1)
            editorNode.remove()
            if res
              validKeys[key] = details
        else
          validKeys = {}
          for key, details of keys
            validKeys[key] = details
        inserts = {}
        inserted = false
        for key of validKeys
          inserted = true
          inserts["#{action}-#{key}"] =
            label: key
            # icon: "img/tag.png"
            _class: "tag"
            action: @_submenuActionGenerator(action, key)

        unless inserted
          inserts["no_tags"] =
            label: "No tags available."
            icon: "img/cross.png"
            action: (obj) ->
        inserts

    # Given a node, produce a collection of context menu actions
    contextMenuItemsCallback: (node) =>
      schema = @editor.plugins.textorum.schema
      if not node.attr('data-xmlel')
        return {}
      editorNode = @editor.dom.select("##{node.attr('name')}")
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
      submenu = @_submenuItemsForAction(validNodes, node)
      siblingSubmenu = @_submenuItemsForAction(siblingNodes, node)
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
          action: (obj) =>
            @editor.execCommand "editSchemaTag", true, obj

        delete:
          label: "Remove Tag and Contents"
          # icon: "img/tag_delete.png"
          _class: "remove-tag"
          action: (obj) =>
            @editor.execCommand "removeSchemaTag", true, obj

      if not parent.attr('data-xmlel')
        delete items["delete"]
        delete items["before"]
        delete items["after"]
        delete items["around"]
      items

    # TODO: This should be passed in as part of the tree initialization
    makeNodeTitle: (node, title) ->
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

    selectNodeCallback: (event, data) =>
      if @ignoreNavigation
        return
      node = data.rslt.obj;
      id = node.attr('name');
      if (id)
        node = @editor.dom.select('#'+id);
        #node.append('<span class="empty_tag_remove_me"></span>');

        nodeEl = node[0]
        @editor.getWin().scrollTo(0, @editor.dom.getPos(nodeEl).y - 10);
        if id is @previousNode
          @editor.selection.select(nodeEl)
          @editor.nodeChanged()
        else
          @editor.selection.setCursorLocation(nodeEl, 0)
          @editor.nodeChanged()
          $(node).effect("highlight", {}, 350)

        @editor.focus()
        @previousNode = id

    updateTreeCallback: =>
      body = @editor.dom.getRoot()
      treeInstance = @jsTree.jstree('get_instance')

      openNodes = @jsTree.find('.jstree-open').map( (index, domElement) ->
        if not $(domElement).parentsUntil('.jstree', '.jstree-closed').length
          return domElement.getAttribute "id"
        return null
      ).get()
      top = {
        data: 'Document',
        state: 'open',
        children: []
      }
      @holder = []
      @holder.unshift top

      helper.depthFirstIterativePreorder body, @depthWalkCallback

      # jstree removes all .jstree-related hooks when destroying
      @jsTree.jstree(@_jstreeOptions([top['children']], openNodes))
        .on('select_node.jstree', @selectNodeCallback)
        .on('click.jstree', 'li.jstree-leaf > ins', (event) ->
            $(event.currentTarget).siblings('a').click()
          )

    navigateTreeCallback: (node, collapsed, extra) =>
      @ignoreNavigation = true
      treeInstance = @jsTree.jstree('get_instance')
      #treeInstance.close_all(-1, false)
      if not node.getAttribute
        return null
      firstNode = treeInstance._get_node("[name='#{node.getAttribute('id')}']")
      if firstNode
        # secondNode = treeInstance._get_parent(firstNode)
        # treeInstance.open_node(secondNode)
        treeInstance.open_node(firstNode)
        treeInstance.deselect_all()
        treeInstance.select_node(firstNode)
        $(firstNode[0]).scrollintoview(
          direction: "vertical"
        )
      @ignoreNavigation = false
      return null

    attributeFilterCallback: (nodes, name) =>
       i = nodes.length
       snip = @treeIDPrefix.length
       while (i--)
         if nodes[i].attr('id').substr(0, snip) is @treeIDPrefix
           nodes[i].attr(name, null)

  # Module return
  return {
    TextorumTree: TextorumTree
  }
