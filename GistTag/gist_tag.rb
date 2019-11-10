# Title: Gists with pygments tag for Jekyll
# Author: Brett Terpstra <http://brettterpstra.com>
# Description: A Liquid tag for Jekyll that fetches and caches gist code samples locally, highlighted with pygments
#   Does not use the script embed, which allows for better highlighting (pygments) and static loading.
#   Includes `gistnocache` tag to prevent caching, and `gistbust` to skip loading the cache but update the
#   result (for one-off usage)
#
# Syntax {% gist gist_id optional_filename %}
#
# Example:
# {% gist d9719a4f53ec3ffd62ebb89359058529 %}
#
# or
#
# {% gist d9719a4f53ec3ffd62ebb89359058529 fish_prompt.fish %}
#
# Based on code by Brandon Tilly <http://brandontilley.com/2011/01/31/gist-tag-for-jekyll.html>
# Source URL: https://gist.github.com/1027674

require 'cgi'
require 'digest/md5'
require 'net/https'
require 'uri'
require 'json'

module Jekyll
  class GistTag < Liquid::Tag
    include HighlightCode
    include TemplateWrapper
    def initialize(tag_name, text, token)
      super
      @filetype       = nil
      @file           = nil
      @gist           = nil
      @text           = text
      @cache_disabled = false
      @bust_cache     = false
      @cache_folder   = File.expand_path "../.gist-cache", File.dirname(__FILE__)
      FileUtils.mkdir_p @cache_folder
    end

    def render(context)
      begin
        if parts = @text.match(/([a-z0-9]+)( .+)?/i)
          @gist = parts[1].strip
          @file = parts[2] ? parts[2].strip : ''
          $stderr.puts "Render gist #{@gist}"
          data  = get_cached_gist || get_gist_from_api
          if data
            html_for_data(data)
          else
            $stderr.puts "Error rendering #{@gist}"
            "Error loading gist #{@gist}"
          end
        else
          ""
        end
      rescue Exception => e
        $stderr.puts e
        $stderr.puts e.backtrace
      end
    end

    def html_for_data(data)
      html = [%Q{<figure class="code">}]
      html.push %Q{<figcaption><span>#{data['name']}</span><a href="#{data['raw_url']}">raw</a></figcaption>}
      html.push data['highlighted']
      html.push %Q{</figure>}
      html.join("\n")
    end

    def cache_data(data)
      cache_file = get_cache_file
      File.open(cache_file, "w") do |io|
        io.puts JSON.dump(data)
      end
    end

    def get_cached_gist
      if @cache_disabled or @bust_cache
        $stderr.puts "Skipping cache"
        return nil
      end
      cache_file = get_cache_file
      if File.exist? cache_file
        content = IO.read(cache_file)
        $stderr.puts "Loading from cache"
        return JSON.parse(content)
      else
        return nil
      end
    end

    def get_cache_file
      bad_chars = /[^a-zA-Z0-9\-_.]/
      cleangist = @gist.gsub bad_chars, ''
      cleanfile = @file.gsub bad_chars, ''
      md5       = Digest::MD5.hexdigest "#{cleangist}-#{cleanfile}"
      File.join @cache_folder, "#{cleangist}-#{cleanfile}-#{md5}.cachedata"
    end

    def get_raw_gist(gist_url)
      raw_uri           = URI.parse gist_url
      proxy             = ENV['http_proxy']
      if proxy
        proxy_uri       = URI.parse(proxy)
        https           = Net::HTTP::Proxy(proxy_uri.host, proxy_uri.port).new raw_uri.host, raw_uri.port
      else
        https           = Net::HTTP.new raw_uri.host, raw_uri.port
      end
      https.use_ssl     = true
      https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request           = Net::HTTP::Get.new raw_uri.request_uri
      data              = https.request request
      data.body
    end

    def get_gist_from_api
      api_url           = %Q{https://api.github.com/gists/#{@gist}}
      raw_uri           = URI.parse api_url
      proxy             = ENV['http_proxy']
      if proxy
        proxy_uri       = URI.parse(proxy)
        https           = Net::HTTP::Proxy(proxy_uri.host, proxy_uri.port).new raw_uri.host, raw_uri.port
      else
        https           = Net::HTTP.new raw_uri.host, raw_uri.port
      end
      https.use_ssl     = true
      https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request           = Net::HTTP::Get.new raw_uri.request_uri
      data              = https.request request
      data              = data.body
      json = JSON.parse(data)

      files = json['files']
      unless files
        return nil
      end
      res = {'gist' => @gist}

      if ! @file.empty? && files.key?(@file)
        f = files[@file]
      else
        k, f = files.first
      end
      res['name'] = f['filename']

      res['raw_url'] = f['raw_url']

      if f['truncated']
        res['raw'] = get_raw_gist(f['raw_url'])
      else
        res['raw'] = f['content']
      end

      unless f['language'].nil?
        res['lang'] = f['language'].downcase
        source = highlight(res['raw'], res['lang'])
      else
        res['lang'] = ''
        source = tableize_code(res['raw'].lstrip.rstrip.gsub(/</,'&lt;'))
      end
      # source = safe_wrap(source)

      res['highlighted'] = source
      $stderr.puts "Loading from API"
      cache_data res unless @cache_disabled
      res
    end
  end

  class GistTagNoCache < GistTag
    def initialize(tag_name, text, token)
      super
      @cache_disabled = true
    end
  end

  class GistTagBustCache < GistTag
    def initialize(tag_name, text, token)
      super
      @bust_cache = true
    end
  end
end

Liquid::Template.register_tag('gist', Jekyll::GistTag)
Liquid::Template.register_tag('gistnocache', Jekyll::GistTagNoCache)
Liquid::Template.register_tag('gistbust', Jekyll::GistTagBustCache)
