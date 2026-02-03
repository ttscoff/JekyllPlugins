# Title: Biner (Karabiner-Elements) Import Button Tag
# Author: Brett Terpstra <https://brettterpstra.com>
# Description: Output an "Import to Karabiner" split button with dropdown (Show JSON, Copy JSON URL)
#
# Syntax {% biner name %}
#
# Example:
# {% biner home-row-app-switcher %}
# {% biner /uploads/2024/02/my-modification.json %}
#
# If name starts with /, it is treated as a path and used verbatim with the site url.
# Otherwise the name becomes [base_directory]/[name].json (base_directory from _config.yml biner.base_directory, or default below)
# Main button opens karabiner://karabiner/assets/complex_modifications/import?url=[json URL]
# Dropdown: Show JSON (opens json URL), Copy JSON URL (copies to clipboard)
#
# Optional in _config.yml:
#   biner:
#     base_directory: https://brettterpstra.com/karabiner/modifications
#
# Example CSS

# .biner-wrap {
#   position: relative;
#   display: inline-block;
# }
# .biner-btn-group {
#   display: inline-flex;
#   align-items: stretch;
#   border-radius: 6px;
#   overflow: hidden;
#   box-shadow: 0 1px 3px rgba(0, 0, 0, 0.15);
# }
# .biner-btn-main {
#   display: inline-flex;
#   align-items: center;
#   padding: 8px 16px;
#   background: #007aff;
#   color: #fff;
#   text-decoration: none;
#   font-weight: 500;
# }
# .biner-btn-main:hover {
#   background: #0056b3;
#   color: #fff;
# }
# .biner-btn-dropdown-toggle {
#   display: inline-flex;
#   align-items: center;
#   justify-content: center;
#   padding: 8px 10px;
#   background: #007aff;
#   border: none;
#   border-left: 1px solid rgba(255, 255, 255, 0.3);
#   color: #fff;
#   cursor: pointer;
# }
# .biner-btn-dropdown-toggle:hover {
#   background: #0056b3;
# }
# .biner-chevron {
#   font-size: 10px;
#   line-height: 1;
# }
# .biner-dropdown-menu {
#   position: absolute;
#   top: 100%;
#   left: 0;
#   margin-top: 4px;
#   min-width: 160px;
#   background: #fff;
#   border: 1px solid #ddd;
#   border-radius: 6px;
#   box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
#   padding: 4px 0;
#   z-index: 100;
# }
# .biner-dropdown-menu[hidden] {
#   display: none !important;
# }
# .biner-dropdown-item {
#   display: block;
#   width: 100%;
#   padding: 8px 16px;
#   text-align: left;
#   background: none;
#   border: none;
#   font: inherit;
#   color: #333;
#   text-decoration: none;
#   cursor: pointer;
# }
# .biner-dropdown-item:hover {
#   background: #f5f5f5;
# }

require 'cgi'

module Jekyll
  class BinerTag < Liquid::Tag
    DEFAULT_BASE_URL = 'https://brettterpstra.com/karabiner/modifications'
    KARABINER_SCHEME = 'karabiner://karabiner/assets/complex_modifications/import'

    def initialize(tag_name, markup, tokens)
      super
      @name = markup.to_s.strip
    end

    def render(context)
      return '' if @name.empty?

      json_url = if @name.start_with?('/')
                   site_url = (context.registers[:site].config['url'] || '').to_s.strip.chomp('/')
                   "#{site_url}#{@name}"
                 else
                   base = (context.registers[:site].config['biner'] || {}).fetch('base_directory',
                                                                                 DEFAULT_BASE_URL).to_s.strip
                   base = base.chomp('/')
                   "#{base}/#{@name}.json"
                 end
      import_url = "#{KARABINER_SCHEME}?url=#{CGI.escape(json_url)}"

      <<~HTML
        <div class="biner-wrap" data-json-url="#{CGI.escapeHTML(json_url)}">
          <div class="biner-btn-group">
            <a href="#{CGI.escapeHTML(import_url)}" class="biner-btn-main">Import to Karabiner</a>
            <button type="button" class="biner-btn-dropdown-toggle" aria-expanded="false" aria-haspopup="true" title="More options">
              <span class="biner-chevron" aria-hidden="true">&#9660;</span>
            </button>
          </div>
          <div class="biner-dropdown-menu" role="menu" hidden>
            <a href="#{CGI.escapeHTML(json_url)}" target="_blank" rel="noopener" class="biner-dropdown-item" role="menuitem">Show JSON</a>
            <button type="button" class="biner-dropdown-item biner-copy-url" role="menuitem">Copy JSON URL</button>
          </div>
        </div>
        <script>
        (function(){
          var wrap = document.currentScript.previousElementSibling;
          var toggle = wrap.querySelector('.biner-btn-dropdown-toggle');
          var menu = wrap.querySelector('.biner-dropdown-menu');
          var jsonUrl = wrap.getAttribute('data-json-url');
          function closeMenu(){ menu.hidden = true; toggle.setAttribute('aria-expanded', 'false'); }
          function openMenu(){ menu.hidden = false; toggle.setAttribute('aria-expanded', 'true'); }
          toggle.addEventListener('click', function(e){
            e.preventDefault();
            e.stopPropagation();
            menu.hidden ? openMenu() : closeMenu();
          });
          wrap.querySelector('.biner-copy-url').addEventListener('click', function(){
            if (navigator.clipboard && navigator.clipboard.writeText) {
              navigator.clipboard.writeText(jsonUrl).then(closeMenu);
            } else {
              var ta = document.createElement('textarea');
              ta.value = jsonUrl;
              ta.setAttribute('readonly', '');
              ta.style.position = 'absolute';
              ta.style.left = '-9999px';
              document.body.appendChild(ta);
              ta.select();
              try { document.execCommand('copy'); closeMenu(); } catch (err) {}
              document.body.removeChild(ta);
            }
          });
          document.addEventListener('click', function(e){
            if (!wrap.contains(e.target)) closeMenu();
          });
        })();
        </script>
      HTML
    end
  end
end

Liquid::Template.register_tag('biner', Jekyll::BinerTag)
