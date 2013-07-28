Liquid = require \liquid-node
Liquid.Drop = require \Liquid/Drop

class BlockDrop extends Liquid.Drop
  (@block) ~>
  super:
    @block.call_super @context

module.exports = class Block extends Liquid.Block
  parent = null
  Syntax = /(\w)+/
  SyntaxHelp = "Syntax Error in 'block' - Valid syntax: block [name]"

  (tag_name, markup, tokens) ->
    matches = Syntax.exec markup
    if matches
      @name = matches.1
    else
      throw new Liquid.SyntaxError SyntaxHelp
    super if tokens

  render: (context) ->
    context.stack ~>
      context.set \block, new BlockDrop @
      @renderAll @nodelist, context

  addParent: (nodelist) ->
    if parent
      parent.addParent nodelist
    else
      parent = new Block @tag_name, @name, null
      parent.nodelist = nodelist

  callSuper: (context) ->
    if parent
      parent.render context
    else
      ''

Liquid.Template.registerTag \block, Block
