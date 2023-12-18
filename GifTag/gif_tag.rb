# Title: Lazy Load Animated Gif embed tag for Jekyll
# Author: Brett Terpstra <http://brettterpstra.com>
# Description: Output a styled animated gif img element for onClick play/pause with preloading
#
# Syntax {% gif path_to_gif_or_poster [caption] %}
#
# Example:
# {% gif /uploads/2015/08/test.gif %}
#
# Notes:
# You can pass in either the jpg/png poster path or the gif path, as long as both exist.
#
# If a GIF is specified and a JPEG or PNG image with the same base name exists in the same
# folder, it will be used as the poster image. If not, and ImageMagick's convert command is
# available, a JPEG will be created from the first frame.
#
# To provide a path to the convert command, "imagemagick_convert" can be set
# in _config.yml to point to a valid installation of ImageMagick's `convert`.
#
#   imagemagick_convert: /usr/local/bin/convert
#
# If ImageMagick `identify` is available (or set in _config.yml with "imagemagick_identify")
# image width and height will be included in the tag as attributes. A fallback to `sips` is
# provided if available (OS X).

class Numeric
  def to_human
    units = %w{B KB MB GB TB}
    e = (Math.log(self)/Math.log(1024)).floor
    s = "%.1f" % (to_f / 1024**e)
    s.sub(/\.?0*$/, units[e])
  end
end

module Jekyll
  class GifTag < Liquid::Tag
    @figcap = ""
    @img = nil
    @poster = nil

    def initialize(tag_name, markup, tokens)
      if markup =~ /\s*(\S+\.(?:jpg|png|gif|mp4))(?:\s+"(.*?)")?\s*(.*)$/i
        @img = $1.sub(/^\//,'')
        if $2
          @alt = $2
        end

        if $3
          caption = $3.strip.sub(/^"(.*?)"$/,'\1')
          if caption.length > 0
            @figcap = "<figcaption>#{caption}</figcaption>"
          end
        end
      end
      super
    end

    def render(context)
      base = context.registers[:site].source
      if @img
        img_path = @img
        error = nil

        base_img = img_path.sub(/\.(gif|png|jpe?g|mp4)$/,'')
        if img_path =~ /\.(gif|mp4)$/
          # if the path provided is a gif
          @img = img_path
          orig_img = File.join(base, img_path)
          if File.exist?(orig_img)
            File.chmod(0644, orig_img)
          end

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
              %x{#{convert} "#{orig_img}"[0] "#{orig_img.sub(/\.(gif|mp4)/,'.jpg')}"}
              @poster = img_path.sub(/\.(gif|mp4)/,'.jpg')
            else
              error = "<Poster image for #{@img} not found>"
            end
          end
        else
          if File.exists?( File.join(base, base_img + '.gif') )
            @poster = img_path
            @img = base_img + '.gif'
          elsif File.exists?( File.join(base, base_img + '.mp4') )
            @poster = img_path
            @img = base_img + '.mp4'
          else
            error = "<gif/mp4 for #{@img} not found>"
          end
        end

        if img_path =~ /\.mp4$/
          webm_path = File.join(base, base_img + '.webm')
          unless File.exist?(webm_path)
            `ffmpeg -i "#{orig_img}" -c:v libvpx -crf 10 -b:v 1M -c:a libvorbis #{webm_path}`
          end
        end

        size = ''
        filesize = File.size(File.join(base, @img)).to_human rescue nil
        unless filesize.nil?
          size = " (#{filesize})"
        end

        if @poster && error.nil?
          img_w = nil
          img_h = nil
          width = ''
          height = ''
          # if the identify command exists, measure image with it
          identify = context.registers[:site].config['imagemagick_identify']
          identify ||= 'identify' if system "which identify &> /dev/null"

          if identify
            img_w = %x{#{identify} -format "%[fx:w]" "#{File.join(base, @poster)}" 2> /dev/null}.strip
            img_h = %x{#{identify} -format "%[fx:h]" "#{File.join(base, @poster)}" 2> /dev/null}.strip
            style_w = %Q( style="width:#{img_w}px;height:#{img_h}px")
            width = %Q{ width="#{img_w}"}
            height = %Q{ height="#{img_h}"}
          elsif system "which sips &> /dev/null"
            img_w = %x{sips -g pixelWidth "#{File.join(base, @poster)}"  2> /dev/null|awk '{print $2}'}.strip
            img_h = %x{sips -g pixelHeight "#{File.join(base, @poster)}"  2> /dev/null|awk '{print $2}'}.strip
            style_w = %Q( style="width:#{img_w}px;height:#{img_h}px")
            width = %Q{ width="#{img_w}"}
            height = %Q{ height="#{img_h}"}
          end

          cdn = ''
          if context.registers[:site].config["production"]
            cdn = context.registers[:site].config["cdn_url"]
            cdn.sub!(/\/$/,'') if cdn
          end

          if @img =~ /\.mp4$/
            intrinsic = ((img_h.to_f / img_w.to_f) * 100)
            padding_bottom = ("%.2f" % intrinsic).to_s  + "%"
            %(<figure title="#{@alt}" class="animated_vid_frame" data-caption="&#9654; MP4#{size}" style="padding-bottom:#{padding_bottom}" tabindex="0">
              <video class="lazy" muted loop playsinline poster="#{cdn}/#{@poster}" style="background:center/contain no-repeat url('#{cdn}/#{@poster}')">
                <source src="#{cdn}/#{@img.sub(/\.mp4/, '.webm')}" type="video/webm">
                <source src="#{cdn}/#{@img}" type="video/mp4">
              </video>
            #{@figcap}</figure>)
          else
            %(<figure class="animated_gif_frame" data-caption="&#9654; GIF#{size}" tabindex="0">
              <img class="animated_gif" alt="#{@alt}" src="#{cdn}/#{@poster}" data-source="#{cdn}/#{@img}"#{width}#{height}>#{@figcap}
              #{@figcap}</figure>)
          end
        else
          error || "<Error processing input, expected syntax: {% gif PATH [alt] [caption] %}>"
        end
      else
        "<Error processing input, expected syntax: {% gif PATH [alt] [caption] %}>"
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
