# plugins/iterm.rb
# Jekyll Liquid tag: render a terminal command with a "Run in iTerm" link/button.
#
# Usage examples:
#   Simple string form:
#     {% iterm "gem install ruby-progress" %}
#
#   Key/value form (order doesn't matter):
#     {% iterm command:"ls -la" directory:"~/Desktop" text:"List in iTerm" language:"zsh" %}
#
# Options:
#   command   - The command to display and run (required unless using the short quoted form)
#   directory - Optional. When present it is appended to the iTerm URL as `&d=PATH` (URL-encoded).
#               Note: the command is NOT prefixed with `cd` — iTerm will receive the directory separately.
#   text      - Optional. Link text for the run button. Defaults to "Run in iTerm".
#   language  - Optional. The value is used as the fence language for the emitted fenced code block
#               (default: `bash`). If you explicitly set `language:""` the opening fence will include
#               no language (i.e. just ``````) which can be useful to avoid highlighting.
#
# Output:
#   Produces a div.iterm-command containing a <pre><code class="language-...">...</code></pre>
#   and an <a href="iterm2://command?c=...&d=..." class="iterm-run-button"> link.
#
# Styling:
#   Include the SCSS partial at `sass/_iterm.scss`. This project imports it via `@import "iterm"` in
#   `sass/screen.scss` so styles should be applied site-wide after recompilation.
#
# Security/Notes:
#   Commands are URL-encoded for the iTerm URL and HTML-escaped for display. Avoid rendering untrusted
#   input through this tag as it will produce links that trigger local applications.
#
# Place this file in your `_plugins/` or `plugins/` directory so Jekyll loads it.
require 'cgi'
require 'uri'

module Jekyll
  class ItermTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      @attrs = {}
      markup = markup.strip

      # If the user passed a single quoted string: {% iterm "gem install..." %}
      if markup =~ /^['"](.*)['"]\s*$/m
        @attrs['command'] = Regexp.last_match(1)
      else
        # Parse key:"value" pairs and key:'value' and key:value (no spaces in unquoted)
        markup.scan(/(\w+)\s*:\s*("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|[^\s]+)/).each do |key, raw|
          v = raw.strip
          if v.start_with?('"') || v.start_with?("'")
            v = v[1..-2]
          end
          # Unescape simple escaped quotes
          v = v.gsub(/\\"/, '"').gsub(/\\'/, "'")
          @attrs[key] = v
        end
      end

  # defaults
  @attrs['text'] ||= 'Run in iTerm'
  @attrs['language'] ||= 'bash'
    end

  def render(_context)
      command = @attrs['command'] || ''
      directory = @attrs['directory']

      # Build the iTerm2 URL. Encode the command and, if present, add the directory as &d=PATH
      # encode_www_form_component uses + for spaces; iTerm expects %20, so convert + -> %20
      encoded_cmd = URI.encode_www_form_component(command).gsub('+', '%20')
      iterm_url = "iterm2:/command?c=#{encoded_cmd}"
      if directory && !directory.empty?
        encoded_dir = URI.encode_www_form_component(directory).gsub('+', '%20')
        iterm_url += "&d=#{encoded_dir}"
      end

      # Always emit a fenced code block so the site's Markdown/highlighter sees it at build time.
      fence_lang = @attrs['language'] || 'bash'
      opening_fence = fence_lang.to_s.empty? ? "```" : "```#{fence_lang}"

      "#{opening_fence}\n#{command}\n```\n\n<div class=\"iterm-command\"><a href=\"#{iterm_url}\" class=\"iterm-run-button\">#{CGI.escapeHTML(@attrs['text'])}</a></div>"
    end
  end
end

Liquid::Template.register_tag('iterm', Jekyll::ItermTag)
