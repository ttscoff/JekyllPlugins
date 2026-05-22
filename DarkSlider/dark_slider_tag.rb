# Title: Dark/Light image comparison slider for Jekyll
# Author: Brett Terpstra <https://brettterpstra.com>
# Description: Interactive before/after slider comparing light and dark screenshots.
#
# Syntax {% dark_slider [classes] [position] path_to_light_image ["alt" ["caption"]] %}
#        {% dark_slider [classes] path_to_light_image [position] ["alt" ["caption"]] %}
#
#   position — optional integer 0–100 (default 50): 0 = full dark, 100 = full light
#
# Examples:
# {% dark_slider /images/screenshot1.jpg %}
# {% dark_slider 0 /images/screenshot1.jpg %}
# {% dark_slider shadow 25 /images/ui.png "App UI" "Light vs dark mode" %}
#
# Assets (same directory as the light image):
#   screenshot1.jpg          — light (passed to the tag)
#   screenshot1-dark.jpg     — dark (-dark before extension)
#   screenshot1@2x.jpg       — optional retina
#   .webp / .avif            — optional; generated at build when tools exist
#
# Requires dark-slider.css and dark-slider.js in your site layout (no jQuery).
#
# Optional _config.yml (paths to binaries; omit to use PATH):
#   dark_slider:
#     cwebp: /opt/homebrew/bin/cwebp
#     avifenc: /opt/homebrew/bin/avifenc
#     identify: /opt/homebrew/bin/identify
#
require "fileutils"

module Jekyll
  module DarkSliderAssets
    @cwebp_warned = false
    @avif_warned = false
    @cwebp_available = nil
    @avif_available = nil

    class << self
      def dark_path(light_url)
        light_url.sub(/\.(jpe?g|png)$/i, "-dark.\\1")
      end

      def normalize_url(url)
        url = url.sub(%r{^/}, "")
        "/#{url}"
      end

      def resolve_dirs(site)
        [File.expand_path(site.source), File.expand_path(site.dest)]
      end

      def source_path(image, source_dir)
        File.join(source_dir, image.sub(%r{^/}, ""))
      end

      def output_paths(rel_path, source_dir, dest_dir)
        rel = rel_path.sub(%r{^/}, "")
        [File.join(source_dir, rel), File.join(dest_dir, rel)]
      end

      def plugin_settings(config)
        settings = config["dark_slider"]
        settings.is_a?(Hash) ? settings : {}
      end

      def config_path(config, key)
        val = plugin_settings(config)[key] || plugin_settings(config)[key.to_sym]
        return nil if val.nil? || val.to_s.strip.empty?

        val.to_s
      end

      def tool_path(config, key, default_cmd)
        custom = config_path(config, key)
        if custom && File.executable?(custom)
          return custom
        end
        return default_cmd if system("which #{default_cmd} >/dev/null 2>&1")

        nil
      end

      def cwebp_available?(config)
        return @cwebp_available unless @cwebp_available.nil?

        @cwebp_available = !tool_path(config, "cwebp", "cwebp").nil?
      end

      def avifenc_available?(config)
        return @avif_available unless @avif_available.nil?

        @avif_available = !tool_path(config, "avifenc", "avifenc").nil?
      end

      def warn_missing_cwebp!
        return if @cwebp_warned

        @cwebp_warned = true
        Jekyll.logger.warn "dark_slider:",
          "cwebp not found in PATH — skipping WebP generation. " \
          "Install cwebp (e.g. brew install webp) or add pre-built .webp files."
      end

      def warn_missing_avifenc!
        return if @avif_warned

        @avif_warned = true
        Jekyll.logger.warn "dark_slider:",
          "avifenc not found in PATH — skipping AVIF generation. " \
          "Install libavif (e.g. brew install libavif) or add pre-built .avif files."
      end

      def identify_dimensions(filename, config)
        identify = config_path(config, "identify")
        identify ||= "identify" if system("which identify >/dev/null 2>&1")
        if identify && File.exist?(filename)
          w = %x{#{identify} -format "%[fx:w]" "#{filename}" 2>/dev/null}.strip
          h = %x{#{identify} -format "%[fx:h]" "#{filename}" 2>/dev/null}.strip
          return [w, h] unless w.empty? || h.empty?
        end
        if system("which sips >/dev/null 2>&1") && File.exist?(filename)
          w = %x{sips -g pixelWidth "#{filename}" 2>/dev/null | awk '/pixelWidth/ {print $2}'}.strip
          h = %x{sips -g pixelHeight "#{filename}" 2>/dev/null | awk '/pixelHeight/ {print $2}'}.strip
          return [w, h] unless w.empty? || h.empty?
        end
        [nil, nil]
      end

      def generate_webp(raster_file, webp_rel, source_dir, dest_dir, config)
        return nil unless raster_file =~ /\.(jpe?g|png)$/i

        webp_rel = webp_rel.sub(/\.(jpe?g|png)$/i, ".webp") if webp_rel =~ /\.(jpe?g|png)$/i
        outfile, pubfile = output_paths(webp_rel, source_dir, dest_dir)
        return normalize_url(webp_rel) if File.exist?(outfile)

        unless cwebp_available?(config)
          warn_missing_cwebp!
          return nil
        end

        cwebp = tool_path(config, "cwebp", "cwebp")
        FileUtils.mkdir_p(File.dirname(outfile))
        FileUtils.mkdir_p(File.dirname(pubfile))
        system(cwebp, "-q", "80", raster_file, "-o", outfile)
        if File.exist?(outfile)
          FileUtils.cp(outfile, pubfile) if outfile != pubfile
          normalize_url(webp_rel)
        end
      end

      def generate_avif(raster_file, avif_rel, at2x_file, source_dir, dest_dir, config)
        return nil unless raster_file =~ /\.(jpe?g|png)$/i

        avif_rel = avif_rel.sub(/\.(jpe?g|png)$/i, ".avif") if avif_rel =~ /\.(jpe?g|png)$/i
        outfile, pubfile = output_paths(avif_rel, source_dir, dest_dir)
        return normalize_url(avif_rel) if File.exist?(outfile)

        unless avifenc_available?(config)
          warn_missing_avifenc!
          return nil
        end

        avifenc = tool_path(config, "avifenc", "avifenc")
        src = (at2x_file && File.exist?(at2x_file)) ? at2x_file : raster_file
        FileUtils.mkdir_p(File.dirname(outfile))
        FileUtils.mkdir_p(File.dirname(pubfile))
        system(avifenc, "-q", "50", "--qalpha", "50", src, outfile)
        if File.exist?(outfile)
          FileUtils.cp(outfile, pubfile) if outfile != pubfile
          normalize_url(avif_rel)
        end
      end

      def local_image?(url)
        url !~ %r{^https?://}i
      end

      def build_sources(image, context)
        return nil unless local_image?(image)

        site = context.registers[:site]
        config = site.config
        image = normalize_url(image.dup)
        image2 = image =~ /@2x\./i ? image : image.sub(/\.(png|jpe?g)$/i, "@2x.\\1")

        source_dir, dest_dir = resolve_dirs(site)
        filename = source_path(image, source_dir)

        unless File.exist?(filename)
          Jekyll.logger.error "dark_slider:", "Image not found: #{filename}"
          return nil
        end

        at2x_file = filename.sub(/\.(png|jpe?g)$/i, "@2x.\\1")

        width, height = identify_dimensions(filename, config)
        webp = {}
        avif = {}

        if image =~ /(jpe?g|png)/i
          webp_rel = image.sub(/\.(jpe?g|png)$/i, ".webp")
          webp2_rel = image2.sub(/\.(jpe?g|png)$/i, ".webp")
          w1 = generate_webp(filename, webp_rel, source_dir, dest_dir, config)
          webp["1x"] = w1 if w1
          w2_out, _ = output_paths(webp2_rel, source_dir, dest_dir)
          unless File.exist?(w2_out)
            if File.exist?(at2x_file)
              generate_webp(at2x_file, webp2_rel, source_dir, dest_dir, config)
            else
              generate_webp(filename, webp2_rel, source_dir, dest_dir, config)
            end
          end
          webp["2x"] = normalize_url(webp2_rel) if File.exist?(w2_out)

          avif_rel = image.sub(/\.(jpe?g|png)$/i, ".avif")
          avif2_rel = image2.sub(/\.(jpe?g|png)$/i, ".avif")
          a1 = generate_avif(filename, avif_rel, nil, source_dir, dest_dir, config)
          avif["1x"] = a1 if a1
          a2_out, _ = output_paths(avif2_rel, source_dir, dest_dir)
          unless File.exist?(a2_out)
            if File.exist?(at2x_file)
              generate_avif(at2x_file, avif2_rel, at2x_file, source_dir, dest_dir, config)
            else
              generate_avif(filename, avif2_rel, at2x_file, source_dir, dest_dir, config)
            end
          end
          avif["2x"] = normalize_url(avif2_rel) if File.exist?(a2_out)
        end

        {
          "original" => image,
          "at2x" => image2,
          "src" => image,
          "webp" => webp,
          "avif" => avif,
          "width" => width,
          "height" => height
        }
      end

      def picture_html(sources, alt)
        return "" if sources.nil?

        avif = sources["avif"] || {}
        webp = sources["webp"] || {}
        avifsource = if avif["2x"]
            %(<source type="image/avif" srcset="#{avif["1x"]} 1x, #{avif["2x"]} 2x">)
          elsif avif["1x"]
            %(<source type="image/avif" srcset="#{avif["1x"]}">)
          else
            ""
          end
        webpsource = if webp["2x"]
            %(<source type="image/webp" srcset="#{webp["1x"]} 1x, #{webp["2x"]} 2x">)
          elsif webp["1x"]
            %(<source type="image/webp" srcset="#{webp["1x"]}">)
          else
            ""
          end

        img_attrs = {
          "src" => sources["src"],
          "alt" => alt || "",
          "loading" => "lazy",
          "decoding" => "async"
        }
        img_attrs["width"] = sources["width"] if sources["width"]
        img_attrs["height"] = sources["height"] if sources["height"]
        img_tag = "<img #{img_attrs.map { |k, v| %(#{k}="#{v}") if v }.compact.join(" ")}>"

        %(<picture>
            #{avifsource}
            #{webpsource}
            <source srcset="#{sources["original"]} 1x, #{sources["at2x"]} 2x">
            #{img_tag}
          </picture>)
      end
    end
  end

  class DarkSliderTag < Liquid::Tag
    PATH_PATTERN = %r{((?:https?://|/|\S+/)\S+\.(?:jpe?g|png))}i

    def initialize(tag_name, markup, tokens)
      @classes = ""
      @light = nil
      @alt = ""
      @figcap = ""
      @position = 50
      markup = markup.to_s.strip
      path_match = markup.match(PATH_PATTERN)
      if path_match
        @light = path_match[1]
        @light = @light.sub(%r{^/}, "")
        @light = "/#{@light}" unless @light =~ %r{^https?://}i
        before = (markup[0...path_match.begin(0)] || "").strip
        after = (markup[path_match.end(0)..] || "").strip
        parse_before_tokens(before)
        parse_after_tail(after)
      end
      super
    end

    def clamp_position(n)
      [[n.to_i, 0].max, 100].min
    end

    def parse_position_token(tok)
      return unless tok =~ /^\d{1,3}$/

      @position = clamp_position(tok)
    end

    def parse_before_tokens(before)
      return if before.nil? || before.empty?

      before.split(/\s+/).each do |tok|
        if tok =~ /^\d{1,3}$/
          parse_position_token(tok)
        else
          @classes = [@classes, tok].reject(&:empty?).join(" ")
        end
      end
    end

    def parse_after_tail(after)
      return if after.nil? || after.empty?

      if after =~ /^(\d{1,3})\s*(.*)\z/m
        parse_position_token(Regexp.last_match(1))
        after = Regexp.last_match(2).to_s.strip
      end
      return if after.empty?

      if after =~ /^"(.*?)"\s*(.*)\z/m
        @alt = Regexp.last_match(1)
        rest = Regexp.last_match(2).to_s.strip
        unless rest.empty?
          caption = rest.sub(/^"(.*?)"$/, '\1')
          @figcap = %(<figcaption>#{caption}</figcaption>) if caption.length > 0
        end
      end
    end

    def render(context)
      return syntax_error unless @light

      site = context.registers[:site]
      light_url = @light.dup
      dark_url = DarkSliderAssets.dark_path(light_url)

      if DarkSliderAssets.local_image?(light_url)
        source_dir = File.expand_path(site.source)
        light_file = DarkSliderAssets.source_path(light_url, source_dir)
        dark_file = DarkSliderAssets.source_path(dark_url, source_dir)

        unless File.exist?(light_file)
          return %(<p class="dark-slider-error">dark_slider: light image not found: #{light_file}</p>)
        end
        unless File.exist?(dark_file)
          Jekyll.logger.warn "dark_slider:",
            "Dark image not found: #{dark_file} (expected alongside light image)"
        end
      end

      alt = @alt.empty? ? "Light and dark comparison" : @alt
      figclass = ["dark-slider", @classes].reject(&:empty?).join(" ")

      light_sources = DarkSliderAssets.build_sources(light_url, context)
      dark_sources = DarkSliderAssets.build_sources(dark_url, context)

      light_picture = DarkSliderAssets.picture_html(light_sources, alt)
      dark_picture = DarkSliderAssets.picture_html(dark_sources, alt)
      noscript_light = light_picture

      if light_picture.empty?
        light_picture = %(<img src="#{light_url}" alt="#{alt}" loading="lazy" decoding="async">)
        dark_picture = %(<img src="#{dark_url}" alt="#{alt}" loading="lazy" decoding="async">)
        noscript_light = light_picture
      end

      pos = @position
      %(<figure class="#{figclass}" style="--pos: #{pos}%" data-dark-slider>
          <div class="dark-slider__dark">#{dark_picture}</div>
          <div class="dark-slider__light">#{light_picture}</div>
          <div class="dark-slider__handle" aria-hidden="true"></div>
          <input type="range" class="dark-slider__range" min="0" max="100" value="#{pos}"
            aria-label="Compare light and dark appearance"
            aria-valuemin="0" aria-valuemax="100" aria-valuenow="#{pos}">
          #{@figcap}
          <noscript>#{noscript_light}</noscript>
        </figure>)
    end

    def syntax_error
      "Error processing input, expected syntax: " \
        '{% dark_slider [classes] [position] /path/to/light.jpg ["alt" ["caption"]] %} ' \
        "(position: 0–100, 0=dark, 100=light)"
    end
  end
end

Liquid::Template.register_tag("dark_slider", Jekyll::DarkSliderTag)
