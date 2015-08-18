# Title: Lazy Load Animated Gif embed tag for Jekyll
# Author: Brett Terpstra <http://brettterpstra.com>
# Description: Output a styled animated gif img element for onClick play/pause with preloading
#
# Syntax {% gif path_to_gif %}
#
# Example:
# {% gif /uploads/2015/08/test.gif %}
#
# Notes:
# You can pass in either the jpg/png path or the gif path, as long as both exist.
#
# If a JPEG or PNG image with the same base name exists in the same folder,
# it will be used as the poster image. If not, and ImageMagick's convert command is,
# available, a JPEG will be created from the first frame.
#
# To provide a path to the convert command, "imagemagick_convert" can be set
# in _config.yml to point to a valid installation of ImageMagick's `convert`.
#
#   imagemagick_convert: /usr/local/bin/convert
#
# If `sips` is available (OS X), image width and height will be included in the tag

module Jekyll
  class GifTag < Liquid::Tag
    @img = nil
    @poster = nil

    def initialize(tag_name, markup, tokens)
      if markup =~ /\s*(\S+\.(jpg|png|gif))\s*$/i
        @img = $1
      end
      super
    end

    def render(context)
      base = context.registers[:site].source
      if @img
        img_path = @img
        error = nil

        base_img = img_path.sub(/\.(gif|png|jpe?g)$/,'')
        if img_path =~ /\.gif$/
          # if the path provided is a gif
          @img = img_path
          # check for png or jpeg poster images with same basename
          if File.exists?(File.join(base, base_img + '.png'))
            @poster = base_img + '.png'
          elsif File.exists?(File.join(base, base_img + '.jpg'))
            @poster = base_img + '.jpg'
          else
            # No existing poster image found
            # if the convert command exists, create a jpg from the gif
            convert = context.registers[:site].config['imagemagick_convert']
            convert ||= 'convert' if system "which convert &> /dev/null"

            if convert
              orig_img = File.join(base, img_path)
              %x{#{convert} "#{orig_img}"[0] "#{orig_img.sub(/\.gif/,'.jpg')}"}
              @poster = img_path.sub(/\.gif/,'.jpg')
            else
              error = "<Poster image for #{@img} not found>"
            end
          end
        else
          if File.exists?( File.join(base, base_img + '.gif') )
            @poster = img_path
            @img = base_img + '.gif'
          else
            error = "<Gif for #{@img} not found>"
          end
        end

        if @poster && error.nil?
          width = ''
          height = ''
          res = system "which sips &> /dev/null"
          if res
            img_w = %x{sips -g pixelWidth "#{File.join(base, @poster)}"  2> /dev/null|awk '{print $2}'}.strip
            img_h = %x{sips -g pixelHeight "#{File.join(base, @poster)}"  2> /dev/null|awk '{print $2}'}.strip
            width = %Q{ width="#{img_w}"}
            height = %Q{ height="#{img_h}"}
          end
          %Q{<figure class="animated_gif_frame"><img src="#{@poster}" data-source="#{@img}"#{width}#{height}></figure>}
        else
          error || "<Error processing input, expected syntax: {% gif poster_path %}>"
        end
      else
        "<Error processing input, expected syntax: {% gif poster_path %}>"
      end
    end
  end
end

Liquid::Template.register_tag('gif', Jekyll::GifTag)


## JS (jQuery)
# var gif = [];
#
# $('figure.animated_gif_frame img').each(function(i, n) {
#     var data = $(n).attr('src').replace(/\.(png|jpg)$/,'.gif');
#     gif.push(data);
#     $(n).attr('data-source', data).data('alt', data).on('click', function() {
#       var $img = $(this),
#           imgSrc = $img.attr('src'),
#           imgAlt = $img.attr('data-source'),
#           imgExt = imgAlt.replace(/^.*?\.(\w+)$/,'$1');

#       if(imgExt === 'gif') {
#           $img.attr('src', $img.data('alt')).attr('data-source', imgSrc);
#           $img.closest('.animated_gif_frame').addClass('playing');
#       } else {
#           $img.attr('src', imgAlt).attr('data-source', $img.data('alt'));
#           $img.closest('.animated_gif_frame').removeClass('playing');
#       }
#     });
# });

# var image = [];

# $.each(gif, function(index) {
#     image[index]     = new Image();
#     image[index].src = gif[index];
# });
# }

## CSS
# figure.animated_gif_frame {
#   position: relative;
#   cursor: pointer;
#   opacity: 0.85;
#   transition: opacity, 0.2s, ease-in-out; }
#   figure.animated_gif_frame:hover, figure.animated_gif_frame.playing {
#     opacity: 1; }
#   figure.animated_gif_frame::before {
#     content: ' ';
#     pointer-events: none;
#     position: absolute;
#     z-index: 100;
#     background: url(/images/gif-play-button.png) center center no-repeat;
#     width: 100%;
#     height: 100%; }
#   figure.animated_gif_frame.playing::before {
#     display: none; }
#   figure.animated_gif_frame.playing img {
#     opacity: 1; }
