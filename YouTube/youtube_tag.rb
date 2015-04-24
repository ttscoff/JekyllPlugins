# Title: Responsive Lazy Load YouTube embed tag for Jekyll
# Author: Brett Terpstra <http://brettterpstra.com>
# Description: Output a styled element for onClick replacement with responsive layout
#
# Syntax {% youtube video_id [width height] ["Caption"] %}
#
# Example:
# {% youtube B4g4zTF5lDo 480 360 %}
# {% youtube http://youtu.be/2NI27q3xNyI %}

module Jekyll
  class YouTubeTag < Liquid::Tag
    @videoid = nil
    @width = ''
    @height = ''

    def initialize(tag_name, markup, tokens)
      if markup =~ /(?:(?:https?:\/\/)?(?:www.youtube.com\/(?:embed\/|watch\?v=)|youtu.be\/)?(\S+)(?:\?rel=\d)?)(?:\s+(\d+)\s(\d+))?(?:\s+"(.*?)")?/i
        @videoid = $1
        @width = $2 || "480"
        @height = $3 || "360"
        @caption = $4 ? "<figcaption>#{$4}</figcaption>" : ""
      end
      super
    end

    def render(context)
      context.environments.first['page']['youtube'] = @videoid
      if @videoid
        # Thanks to Andrew Clark for the inline CSS calculation idea <http://contentioninvain.com/2013/02/13/video-embeds-for-responsive-designs/>
        intrinsic = ((@height.to_f / @width.to_f) * 100)
        padding_bottom = ("%.2f" % intrinsic).to_s  + "%"
        video = %Q{<a class="youtube" href="https://www.youtube.com/watch?v=#{@videoid}" data-videoid="#{@videoid}" data-width="#{@width}" data-height="#{@height}">YouTube Video</a>}
        %Q{<figure class="bt-video-container" style="padding-bottom:#{padding_bottom}">#{video}#{@caption}</figure>}
      else
        "Error processing input, expected syntax: {% youtube video_id [width height] %}"
      end
    end
  end
end

Liquid::Template.register_tag('youtube', Jekyll::YouTubeTag)
