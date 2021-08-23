require 'nokogiri'
require 'erb'
=begin
title: Feature Availability
author: Brett Terpstra <https://brettterpstra.com>
description: Adds markup based on whether the described
             feature is available in the current release.

Build numbers are retrieved from Sparkle appcasts using the
`sparkle:version` attribute of the most recent enclosure's
link. The path to the local appcasts files are defined
in _config.yml (see configuration).

- If the specified version is less than or equal to current
  release build, no markup is added.
- If it's greater than the stable release and less than or
  equal to the current beta build, the tag content is
  considered "beta."
- If it's greater than the current beta build, the tag
  content is considered "upcoming."

## Configuration

Appcast paths should be to local files.

Templates are ERB format. <%= content => gets block tag
contents, <%= min_version => gets the build number. If you
want to use the default templates, leave the key(s) out.

In _config.yml:

    availability:
      appcast:
        release: /path/to/appcast.xml
        beta: /path/to/appcast.xml
      templates:
        beta:
          inline: <i class="betafeature"><span title="The following feature is only available in the preview build (build <%=min_version%>)" class="notification">(Beta only)</span> <%=content%></i>
          block: |+
            <div class="betafeature" markdown=1>

            > ___Beta Feature___: this feature is currently in development and is only available to those using the preview build. If you want to help test new features, feel free to [download and run the beta release](/download/).
            {:.alert}

            <%=content%>

            </div>
          notification: ...
        upcoming:
          inline: ...
          block: ...
          notification: ...

## Block Tag

Syntax:

    {% available BUILD %}[...]{% endavailable %}

Define the build number at which the feature described in
the block is available.

Can be used inline around text in a paragraph or around a
block containing newlines. If the content is multi-line, a
div wrapper surrounds the block.

If the first text in a multi-line block is a level 2 or
higher header and the feature is unavailable in the stable
release, the headline has "(Upcoming)" or "(Beta)" appended
to it in a span with the class
"tag". This also appears in any Kramdown-generated TOC.

### Example:

    {% available 193 %}
    ## Brand New Feature

    Description
    {% endavailable %}

If the current version's build number is less than 193, this
outputs:

    <div class="betafeature" markdown=1>

    > ___Beta Feature___: this feature is currently in
    development and is only available to those using
    Bunch Beta. If you want to help test new features,
    feel free to [download the beta](/download).
    {:.alert}

    ## Brand New Feature <span class="tag">(Beta)</span>

    Description

    </div>

(The `markdown=1` causes Kramdown to render Markdown
formatting inside the block tag. The `{:.alert}` is a
Kramdown IAL to apply the class "alert" to the blockquote.)

If the current release build is 193 or greater, the content
of the block is output without any wrapper.

## Regular Tag

Syntax:

    {% availablenotif BUILD %}

Regular Jekyll tag that inserts a blockquote with the
class "alert" notifying the reader that the feature
described is only available in beta/upcoming release.

### Example

    {% availablenotif 119 %}

If the current release build is less than 119, this will
output:

    > ___Beta Feature___: this feature is currently in
    development and is only available to those using
    Bunch Beta. If you want to help test new features,
    feel free to [download the beta](/download).
    {:.alert}
=end

module Jekyll
  module FeatureTagHelpers
    def get_defaults
      defaults = {
        'upcoming' => {},
        'beta' => {}
      }

      defaults['upcoming']['block'] = <<~'EOBLOCK'
                    <div class="betafeature" markdown=1>

                    > ___Upcoming Feature___: The following feature is currently in development and will be released in the next preview build. If you want to help test new features, you're welcome to [download and run the beta release](/download/).
                    {:.alert}

                    <%=content%>

                    </div>
                    EOBLOCK
      defaults['upcoming']['inline'] = %(<i class="betafeature"><span title="The following feature will be available soon in the preview build (build <%=min_version%>)" class="notification">(Coming soon)</span> <%=content%></i>)
      defaults['upcoming']['notification'] = <<~'EOBLOCK'
                    > ___Upcoming Feature___: this feature is currently in development and will be released in the next preview build. If you want to help test new features, you're welcome to [download and run the beta release](/download/).
                    {:.alert}
                    EOBLOCK
      defaults['beta']['block'] = <<~'EOBLOCK'
                    <div class="betafeature" markdown=1>

                    > ___Beta Feature___: this feature is currently in development and is only available to those using the preview build. If you want to help test new features, feel free to [download and run the beta release](/download/).
                    {:.alert}

                    <%=content%>

                    </div>
                    EOBLOCK
      defaults['beta']['inline'] = %(<i class="betafeature"><span title="The following feature is only available in the preview build (build <%=min_version%>)" class="notification">(Beta only)</span> <%=content%></i>)
      defaults['beta']['notification'] = <<~'EOBLOCK'
                    > ___Beta Feature___: this feature is currently in development and is only available to those using the preview build. If you want to help test new features, feel free to [download and run the beta release](/download/).
                    {:.alert}
                    EOBLOCK
      defaults
    end

    def merge_templates(config)
      defaults = get_defaults
      templates = {'upcoming' => {}, 'beta' => {}}
      if config['templates']&.is_a? Hash
        templates['upcoming'] = defaults['upcoming'].merge(config['templates']['upcoming'])
      else
        templates['upcoming'] = defaults['upcoming']
      end

      if config['beta']&.is_a? Hash
        templates['beta'] = defaults['beta'].merge(config['templates']['beta'])
      else
        templates['beta'] = defaults['beta']
      end

      templates
    end

    def get_sparkle_build(url)
      return url if url.to_s =~ /^[0-9.]+$/
      xml = IO.read(File.expand_path(url))
      doc = Nokogiri::Slop(xml)
      enclosure = doc.root.channel.item.last.enclosure
      enclosure["sparkle:version"].to_s
    end

    def render_markdown(input)
      Kramdown::Document.new(input).to_html
    end

    def append_header(content, text)
      content.force_encoding('utf-8')
      content.strip.sub(/(?i-m)^(\s*)(?<=\n|\A)(\#{2,})([\s\S]*?)( \{#[\s\S]*?\})?(?= *\n)/, %(\\1\\2 \\3 <span class="tag">(#{text})</span>\\4))
    end
  end

  class FeatureVersionBlockTag < Liquid::Block
    include FeatureTagHelpers

    def initialize(tag_name, markup, tokens)
      @min_version = markup.strip.to_s
      super
    end

    def render(context)
      content = super
      multiline = content.split(/\n/).length > 1

      config = context.registers[:site].config['availability']

      templates = merge_templates(config)

      if config[:release_build]
        release_version = config[:release_build]
      else
        release_version = get_sparkle_build(config['appcast']['release'])
        config[:release_build] = release_version
      end

      if config[:beta_build]
        beta_version = config[:beta_build]
      else
        beta_version = get_sparkle_build(config['appcast']['beta'])
        config[:beta_build] = beta_version
      end

      min_version = @min_version
      if @min_version > release_version.to_s
        if @min_version > beta_version.to_s
          if multiline
            content = append_header(content, "Upcoming")
            template = ERB.new(templates['upcoming']['block'])
          else
            template = ERB.new(templates['upcoming']['inline'])
          end
        else
          if multiline
            content = append_header(content, "Beta")
            template = ERB.new(templates['beta']['block'])
          else
            template = ERB.new(templates['beta']['inline'])
          end
        end
        template.result(binding)
      else
        content
      end
    end

    Liquid::Template.register_tag('available', self)
  end
end

module Jekyll

  class FeatureVersionTag < Liquid::Tag
    include FeatureTagHelpers

    def initialize(tag_name, markup, tokens)
      @min_version = markup.to_s
      super
    end

    def render(context)
      config = context.registers[:site].config['availability']

      templates = merge_templates(config)

      if config[:release_build]
        release_version = config[:release_build]
      else
        release_version = get_sparkle_build(config['appcast']['release'])
        config[:release_build] = release_version
      end

      if config[:beta_build]
        beta_version = config[:beta_build]
      else
        beta_version = get_sparkle_build(config['appcast']['beta'])
        config[:beta_build] = beta_version
      end

      min_version = @min_version

      if @min_version > release_version.to_s
        if @min_version > beta_version.to_s
          template = ERB.new(templates['upcoming']['notification'])
        else
          template = ERB.new(templates['beta']['notification'])
        end
        template.result(binding)
      else
        ''
      end
    end

    Liquid::Template.register_tag('availablenotif', self)
  end
end




