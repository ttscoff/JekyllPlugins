#
# Author: Brett Terpstra
# Define a section of text to be used as the OpenGraph description meta tag
#
# Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
# tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
# quis nostrud exercitation {% describe %}ullamco laboris nisi ut aliquip ex ea commodo
# consequat.{% enddescribe %} Duis aute irure dolor in reprehenderit in voluptate velit esse.

class String
  def remove_markup
    # strip all Markdown and Liquid tags
    output = self.dup
    begin
      output = output.
        gsub(/\{%.*?%\}/,'').
        gsub(/\{[:\.].*?\}/,'').
        gsub(/\[\^.+?\](\: .*?$)?/,'').
        gsub(/\s{0,2}\[.*?\]: .*?$/,'').
        gsub(/\!\[.*?\][\[\(].*?[\]\)]/,"").
        gsub(/\[(.*?)\][\[\(].*?[\]\)]/,"\\1").
        gsub(/^\s{1,2}\[(.*?)\]: (\S+)( ".*?")?\s*$/,'').
        gsub(/^\#{1,6}\s*/,'').
        gsub(/(\*{1,2})(\S.*?\S)\1/,"\\2").
        gsub(/\{[%{](.*?)[%}]\}/,"\\1").
        gsub(/(`{3,})(.*?)\1/m,"\\2").
        gsub(/^-{3,}\s*$/,"").
        gsub(/`(.+)`/,"\\1").
        gsub(/(?i-m)(_|\*)+(\S.*?\S)\1+/) {|match|
          $2.gsub(/(?i-m)(_|\*)+(\S.*?\S)\1+/,"\\2")
        }.
        gsub(/\n{2,}/,"\n\n").
        gsub(/<(script|style|pre|code|figure).*?>.*?<\/\1>/im, '').
        gsub(/<!--.*?-->/m, '').
        gsub(/<(img|hr|br).*?>/i, " ").
        gsub(/<(dd|a|h\d|p|small|b|i|blockquote|li)( [^>]*?)?>(.*?)<\/\1>/i, " \\3 ").
        gsub(/<\/?(dt|a|ul|ol)( [^>]+)?>/i, " ").
        gsub(/<[^>]+?>/, '').
        gsub(/\[\d+\]/, '').
        gsub(/&#8217;/,"'").gsub(/&.*?;/,' ').gsub(/;/,' ').
        gsub(/\u2028/,'').
        lstrip.force_encoding("ASCII-8BIT").
        gsub("\xE2\x80\x98","'").
        gsub("\xE2\x80\x99","'").
        gsub("\xCA\xBC","'").
        gsub("\xE2\x80\x9C",'"').
        gsub("\xE2\x80\x9D",'"').
        gsub("\xCB\xAE",'"').squeeze(" ")
    rescue
      return self
    end
    output
  end
end

module Jekyll

  class OGDescriptionTag < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super
    end

    def render(context)
      output = super
      context.environments.first['page']['description'] = CGI.escapeHTML(output.remove_markup)
      output
    end
  end
end

Liquid::Template.register_tag('describe', Jekyll::OGDescriptionTag)
