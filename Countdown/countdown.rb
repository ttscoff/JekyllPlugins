# Title: jQuery countdown
# Author: Brett Terpstra <http://brettterpstra.com>
# Description: Output a countdown timer
#
# Syntax {% countdown caption YYYY-mm-dd HH:MM %}
#
# Example:
# {% countdown "Sale ends in..." 12-14-2014 12:00 %}

# Works with <https://github.com/Lexxus/jq-timeTo>
#
#       var $countdowns = $('.btcountdown');
#       if ($countdowns.length === 0) {
#         return;
#       }
#       $countdowns.each(function(i,n) {
#         var endTime = $(n).find('time').first().attr('datetime');
#         $(n).timeTo({
#             timeTo: new Date(endTime),
#             theme: "black",
#             displayCaptions: true,
#             fontSize: 36,
#             captionSize: 16
#         });
#       });

module Jekyll
  require 'time'

  class CountdownTag < Liquid::Tag
    @form = nil
    def initialize(tag_name, markup, tokens)
      if markup.strip =~ /^(.*?) +([\d\-: ]+)$/i
        @form = {'title' => $1, 'end_date' => $2}
      end
      super
    end

    def render(context)
      if @form
        begin
          end_date = Time.parse(@form["end_date"])
          if end_date >= Time.now
            %Q{<div class="btcountdownwrapper"><p class="btcountdowncaption">#{@form['title']}</p><div class="btcountdown"><time datetime="#{end_date.xmlschema}"></time></div></div>}
          else
            %Q{<p class="sorry"><em>Time&#8217;s up.</em></p>}
          end
        rescue
          ""
        end
      else
        "Error processing countdown tag"
      end
    end
  end
end

Liquid::Template.register_tag('countdown', Jekyll::CountdownTag)
