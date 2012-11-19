## Donate button tag for Jekyll

A Liquid tag plugin for Jekyll that creates a PayPal donate button on a page or post.

![My donate button](https://github.com/ttscoff/JekyllPlugins/blob/master/Donation/DonateButton.gif?raw=true)

### Examples

Default button:

	{% donate %}

*Creates markup based on the default settings in your `_config.yaml`. You need to set `donate_text` (for default button text) and `donate_id` (default PayPal button ID).*

Create a button using an ID different from the config, with default text:

	{% donate A9KK2MTU7QSJU %}


Create a button with custom text:

	{% donate Buy me some coffee %}

Custom ID and text:

	{% donate A9KK2MTU7QSJU "Buy me some coffee, ok?" %}

### Markup ###

The tag will create something like:

```html
<form class="paypalform" action="https://www.paypal.com/cgi-bin/webscr" method="post">
  <input type="hidden" name="cmd" value="_s-xclick">
  <input type="hidden" name="hosted_button_id" value="A9KK2MTU7QSJU">
  <button class="paypalbutton" name="submit">
    <span>Buy me coffee</span>
  </button>
  <img alt="" border="0" src="https://www.paypal.com/en_US/i/scr/pixel.gif" width="1" height="1">
</form>
```

I put the stylesheet for my own button in this gist, but you can do whatever you like for the appearance via CSS. The image for my version is [here](https://raw.github.com/ttscoff/JekyllPlugins/master/Donation/donation2.png).
