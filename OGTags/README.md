# Plugins for generating Open Graph and other meta

## Describe

Define a section of text to be used as the OpenGraph description meta tag by surrounding it with the `{% describe %}` and `{% enddescribe %}` tags.

    Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
    tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
    quis nostrud exercitation {% describe %}ullamco laboris nisi ut aliquip ex ea commodo consequat.{% enddescribe %} Duis aute irure dolor in reprehenderit in voluptate velit esse.

Tag should only be used once per post/page. The last occurrence of the tag in the post/page will be what shows up in meta.

The plugin places the description text with all markup removed into the page data. It can be accessed in a template using `{{ page.description }}` for use in meta tags.

    {% if page.description %}
    {% capture desc %}{{ page.description }}{% endcapture %}

    <meta name="description" content="{{ desc }}">
    <meta name="twitter:description" content="{{ desc }}">
    <meta property="og:description" content="{{ desc }}">
    {% endif %}
