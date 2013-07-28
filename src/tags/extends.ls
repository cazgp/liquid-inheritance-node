Liquid = require \liquid
P = require \prelude-ls
LiquidInheritance = require \../../../liquid-inheritance-node

module.exports = class Extends extends Liquid.Block
  Syntax = //(#{Liquid.QuotedFragment})//
  SyntaxHelp = "Syntax Error in tag 'extends' - Valid syntax: extends [template]"

  (tagName, markup, tokens) ->
    matches = Syntax.exec markup
    if matches
      @template_name = matches.1

    else
      throw new Liquid.SyntaxError SyntaxHelp

    super

    # fold == foldl == inject
    @blocks = P.fold (m, node) ->
      m[node.name] = node if node instanceof LiquidInheritance.Block
      m
    , {}, @nodelist

  parse: (tokens) ->
    @parseAll tokens

  render: (context) ->
    template = @loadTemplate context
    parent_blocks = findBlocks template.root

    for name, block in @blocks
      pb = parent_blocks[name]
      if pb
        pb.parent = block.parent
        pb.addParent pb.nodelist
        pb.nodelist = block.nodelist

      else
        if @isExtending template
          template.root.nodelist += block

      template.render context

  parseAll: (tokens) ->
    @nodelist ||= []
    @nodelist.clear!

    while token = tokens.shift
      switch token
      | //^#{Liquid.TagStart}// =>
        matches = //^#{Liquid.TagStart}\s*(\w+)\s*(.*)?#{Liquid.TagEnd}$// .exec token
        if matches
          tag = Liquid.Template.tags matches[1]
          if tag
            @nodelist += new tag matches.1, matches.2, tokens
          # This tag is not registered with the system
          # pass it to the current block for special handling or error reporting
          else
            @unknownTag tag matches.1, matches.2, tokens
        else
          throw new Liquid.SyntaxError "Tag #{token} was not properly terminated"

      | //^#{Liquid.VariableStart}// =>
        @nodelist += @createVariable token

      | '' =>

      | otherwise => @nodelist += token

  loadTemplate: (context) ->
    # TODO vow promises
    console.log context[template_name]
    template = Liquid.Template.parse content

  isExtending: (template) ->
    P.any (node) ->
      node instanceof Extends
    , template.root.nodelist

Liquid.Template.registerTag \extends, Extends
