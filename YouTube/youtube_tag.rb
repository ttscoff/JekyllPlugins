# Title: Responsive YouTube embed tag for Jekyll
# Author: Brett Terpstra <http://brettterpstra.com>
# Description: Output a simple YouTube embed tag with code to make it responsive
#
# Syntax {% youtube video_id [width height] %}
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
      if markup =~ /(?:(?:https?:\/\/)?(?:www.youtube.com\/(?:embed\/|watch\?v=)|youtu.be\/)?(\S+)(?:\?rel=\d)?)(?:\s+(\d+)\s(\d+))?/i
        @videoid = $1
        @width = $2 || "480"
        @height = $3 || "360"
      end
      super
    end

    def render(context)
      ouptut = super
      if @videoid
        # remove/comment the next line and adjust the class name on the following line if you already have CSS for responsive video
        video = "<style>.bt-video-container{position:relative;padding-bottom:56.25%;padding-top:30px;height:0;overflow:hidden}.bt-video-container iframe,.bt-video-container object,.bt-video-container embed{position:absolute;top:0;left:0;width:100%;height:100%;margin-top:0}</style>\n"
        video += %Q{<div class="bt-video-container"><iframe width="#{@width}" height="#{@height}" src="http://www.youtube.com/embed/#{@videoid}?rel=0" frameborder="0" allowfullscreen></iframe></div>}
      else
        "Error processing input, expected syntax: {% youtube video_id [width height] %}"
      end
    end
  end
end

Liquid::Template.register_tag('youtube', Jekyll::YouTubeTag)
