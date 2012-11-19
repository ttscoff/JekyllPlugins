# Title: PayPal donation tag
# Author: Brett Terpstra http://brettterpstra.com
# Description: Add a paypal donate button.
#
# Set your default text and paypal id in _config.yaml:
# # Donation Button
# donate_text: "All donations are greatly appreciated!"
# donate_id: "A9KK2MTU7QSJU"
#
# You can pass a 1-time ID and/or alternate text for the button
#
# 1. If there's an ID passed first or alone, it will be used.
# 2. If there's a string passed after the ID, it will be used as alt text.
# 3. If there's only one argument and it doesn't match the regex for an id, it will be used as alt text.
#
# Syntax {% donate [alternate id] [optional text] %}
#
# Example:
#
# {% donate 78YFVY22AWW42 "Buy me coffee" %}
#
# Output:
# <form class="paypalform" action="https://www.paypal.com/cgi-bin/webscr" method="post">
#   <input type="hidden" name="cmd" value="_s-xclick">
#   <input type="hidden" name="hosted_button_id" value="78YFVY22AWW42">
#   <button class="paypalbutton" name="submit">
#     <span>Buy me coffee</span>
#   </button>
#   <img alt="" border="0" src="https://www.paypal.com/en_US/i/scr/pixel.gif" width="1" height="1">
# </form>
#

module Jekyll

  class DonateTag < Liquid::Tag
    @id = nil
    @text = nil

    def initialize(tag_name, markup, tokens)
      if markup =~ /^([A-Z0-9]{12,16})?(.*)?/i
        @id    = $1 unless $1.nil? || $1.strip == ''
        @text  = $2.strip.gsub(/(^["']|["']$)/,'') unless $2.nil? || $2.strip == ''
      end
      super
    end

    def render(context)
      output = super
      @text ||= context.registers[:site].config['donate_text'] || "Your donations are appreciated!"
      @id ||= context.registers[:site].config['donate_id'] || "UNCONFIGURED"
      donate =  %Q{<form class="paypalform" action="https://www.paypal.com/cgi-bin/webscr" method="post"><input type="hidden" name="cmd" value="_s-xclick"><input type="hidden" name="hosted_button_id" value="#{@id}"><button class="paypalbutton" name="submit"><span>#{@text}</span></button><img alt="" border="0" src="https://www.paypal.com/en_US/i/scr/pixel.gif" width="1" height="1"></form>}
    end
  end
end

Liquid::Template.register_tag('donate', Jekyll::DonateTag)

