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


I put the stylesheet for my own button in this gist, but you can do whatever you like for the appearance via CSS. The image for my version is [here](http://assets.brettterpstra.com/donation2.png).
