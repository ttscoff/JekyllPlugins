# Title: Audio tag for Jekyll
# Author: Brett Terpstra
# Description: Output HTML5 audio tag
#
# Syntax {% audio url/to/mp3,ogg,blank ["Title"] %}
#
# Example (creates both ogg and mp3 sources because no extension is given):
# {% audio /share/junkyangel "Junky Angel" %}
#
#
# Output:
# <figure class="audio">
#   <audio controls="true">
#       <source src="/share/JunkyAngel.mp3" type="audio/mp3">
#       <source src="/share/JunkyAngel.ogg" type="audio/ogg">
#       HTML5 audio not supported
#   </audio>
#   <figcaption>Junky Angel</figcaption>
# </figure>
#

module Jekyll

  class AudioTag < Liquid::Tag
    @mp3 = nil
    @ogg = nil
    @title = nil

    def initialize(tag_name, markup, tokens)
        # if no mp3 or ogg extension, assume both
      if markup =~ /((https?:\/\/|\/)(\S+)(mp3|ogg)?)(\s+(.*))?/i
        song = $1
        @title = $6 unless $5.nil?

        if song =~ /\.mp3$/
            @mp3  = song
        elsif song =~ /\.ogg$/
            @ogg = song
        else
            @mp3 = song+".mp3"
            @ogg = song+".ogg"
        end
      end
      super
    end

    def render(context)
      output = super
      if @mp3 || @ogg
        if context.registers[:site].config["production"]
          @mp3 = context.registers[:site].config["cdn_url"] + @mp3 if @mp3
          @ogg = context.registers[:site].config["cdn_url"] + @ogg if @ogg
        end
        audio =  %Q{<figure class="audio"><audio controls="true">}
        audio += %Q{<source src="#{@mp3}" type="audio/mp3">} if @mp3
        audio += %Q{<source src="#{@ogg}" type="audio/ogg">} if @ogg
        audio += "HTML5 audio not supported </audio>"
        audio += "<figcaption>#{@title}</figcaption>" if @title
        audio += "</figure>"
      else
        "Error processing input, expected syntax: {% audio url/to/mp3,ogg,blank [\"Title\"] %}"
      end
    end
  end

end

Liquid::Template.register_tag('audio', Jekyll::AudioTag)
