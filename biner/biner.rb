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
# Dropdown: Show JSON (opens modal with JSON content, Copy and Download buttons), Copy JSON URL (copies to clipboard)
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
                   site = context.registers[:site].config
                   base = [(site['url'] || '').to_s.strip, (site['baseurl'] || '').to_s.strip].join.chomp('/')
                   "#{base}#{@name}"
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
            <button type="button" class="biner-dropdown-item biner-show-json" role="menuitem">Show JSON</button>
            <button type="button" class="biner-dropdown-item biner-copy-url" role="menuitem">Copy JSON URL</button>
          </div>
        </div>
        <script>
        (function(){
          if (!window.BinerModal) {
            window.BinerModal = (function(){
              var overlay, pre, currentText;
              function closeModal(){ if (overlay) { overlay.setAttribute("hidden", ""); overlay.setAttribute("aria-hidden", "true"); document.removeEventListener("keydown", escHandler); } }
              function escHandler(e){ if (e.key === "Escape") closeModal(); }
              function createModal() {
                overlay = document.createElement('div');
                overlay.className = 'biner-modal-overlay';
                overlay.setAttribute('aria-hidden', 'true');
                overlay.innerHTML = '<div class="biner-modal-box" role="dialog" aria-modal="true" aria-labelledby="biner-modal-title">' +
                  '<div class="biner-modal-header">' +
                    '<h2 id="biner-modal-title" class="biner-modal-title">Modification JSON</h2>' +
                    '<button type="button" class="biner-modal-close" aria-label="Close">&times;</button>' +
                  '</div>' +
                  '<div class="biner-modal-body">' +
                    '<pre class="biner-modal-pre"></pre>' +
                  '</div>' +
                  '<div class="biner-modal-footer">' +
                    '<button type="button" class="biner-modal-btn biner-modal-copy">Copy</button>' +
                    '<button type="button" class="biner-modal-btn biner-modal-download">Download</button>' +
                  '</div></div>';
                pre = overlay.querySelector('.biner-modal-pre');
                var style = document.createElement('style');
                style.textContent = '.biner-modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,0.5);display:flex;align-items:center;justify-content:center;z-index:10000;padding:20px;}.biner-modal-overlay[hidden]{display:none!important}.biner-modal-box{background:#fff;border-radius:8px;box-shadow:0 8px 32px rgba(0,0,0,0.2);max-width:90vw;max-height:85vh;display:flex;flex-direction:column;overflow:hidden}.biner-modal-header{display:flex;align-items:center;justify-content:space-between;padding:12px 16px;border-bottom:1px solid #eee}.biner-modal-title{margin:0;font-size:1.1rem;font-weight:600}.biner-modal-close{background:none;border:none;font-size:24px;line-height:1;cursor:pointer;color:#666;padding:0 4px}.biner-modal-close:hover{color:#000}.biner-modal-body{flex:1;overflow:auto;padding:16px}.biner-modal-pre{margin:0;font-family:monospace;font-size:13px;line-height:1.5;white-space:pre-wrap;word-break:break-all}.biner-modal-footer{padding:12px 16px;border-top:1px solid #eee;display:flex;gap:8px;justify-content:flex-end}.biner-modal-btn{padding:8px 16px;border-radius:6px;border:1px solid #ccc;background:#f5f5f5;cursor:pointer;font:inherit}.biner-modal-btn:hover{background:#e5e5e5}.biner-modal-copy:focus,.biner-modal-download:focus{outline:2px solid #007aff;outline-offset:2px}';
                document.head.appendChild(style);
                overlay.querySelector('.biner-modal-close').addEventListener('click', closeModal);
                overlay.addEventListener('click', function(e){ if (e.target === overlay) closeModal(); });
                overlay.querySelector('.biner-modal-copy').addEventListener('click', function(){
                  if (!currentText) return;
                  if (navigator.clipboard && navigator.clipboard.writeText) {
                    navigator.clipboard.writeText(currentText);
                  } else {
                    var ta = document.createElement('textarea'); ta.value = currentText; ta.setAttribute('readonly', ''); ta.style.position = 'absolute'; ta.style.left = '-9999px';
                    document.body.appendChild(ta); ta.select();
                    try { document.execCommand('copy'); } finally { document.body.removeChild(ta); }
                  }
                });
                overlay.querySelector('.biner-modal-download').addEventListener('click', function(){
                  if (!currentText) return;
                  var fn = (overlay.getAttribute('data-download-filename') || 'modification.json');
                  var blob = new Blob([currentText], { type: 'application/json' });
                  var url = URL.createObjectURL(blob);
                  var a = document.createElement('a'); a.href = url; a.download = fn; document.body.appendChild(a); a.click(); document.body.removeChild(a); URL.revokeObjectURL(url);
                });
                document.body.appendChild(overlay);
              }
                return {
                show: function(jsonUrl) {
                  if (!overlay) createModal();
                  overlay.removeAttribute('hidden');
                  overlay.setAttribute('aria-hidden', 'false');
                  document.addEventListener('keydown', escHandler);
                  pre.textContent = 'Loading…';
                  currentText = null;
                  overlay.setAttribute('data-download-filename', (jsonUrl.split('/').pop() || 'modification.json'));
                  fetch(jsonUrl).then(function(r){ if (!r.ok) throw new Error(r.status); return r.text(); }).then(function(text){
                    try { text = JSON.stringify(JSON.parse(text), null, 2); } catch (e) {}
                    currentText = text;
                    pre.textContent = text;
                  }).catch(function(){
                    pre.textContent = 'Failed to load JSON.';
                  });
                }
              };
            })();
          }
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
          wrap.querySelector('.biner-show-json').addEventListener('click', function(){
            closeMenu();
            window.BinerModal.show(jsonUrl);
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
