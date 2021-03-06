# Gists with pygments tag for Jekyll

A Liquid tag for Jekyll that fetches and caches gist code samples locally, highlighted with pygments. It does not use the Gist Javascript embed, which allows for better highlighting (pygments) and static loading.

## Why

First, I wanted to use Gist for saving and sharing snippets, but I didn't like the embed script. I wanted it to look more like my local code snippets. Hours of hacking later I had them close, but realized that due to the highlighting method that GitHub uses, the Gist embeds would never line up with my Pygments output.

This method treats gist contents like a local code embed. You get the exact same markup as using code fences or a code block tag.


## Syntax 

    {% gist gist_id optional_filename %}

## Example

    {% gist d9719a4f53ec3ffd62ebb89359058529 %}

or

    {% gist d9719a4f53ec3ffd62ebb89359058529 fish_prompt.fish %}

## Caching and busting

Here's the downside.

Loading from Javascript has the benefit of allowing changes to the gist to show up immediately on the page. This plugin downloads and caches the gist contents. Once a gist is loaded once, it becomes static.

### Manually Deleting

The fastest way to bust the cache and update a gist is to delete the cache file. Cache files are named with the gist id and filename in the folder `.gist-cache` in your site root. If you find the offending file and remove it, the gist will be re-fetched on next render. ALL of these solutions require a re-render of the site.

### Automatic change checking

The first option is to just check the updated date every time a gist is rendered. This means an API call for every gist, on every build, but it's not terribly resource/time expensive. Pygments is only called if the updated date is different from the stored date. To enable this, add `gist_check_update: true` in _config.yml.

If you have a lot of gists, you'll quickly run up against GitHub's API limit. You'll need to create an oAuth app and get an id and secret. Add these to your _config.yml:

```yaml
github_api:
  id: xxxxxxxxxxxxxxxxxx
  secret: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Having those will allow the plugin to get an increased rate limit.

### Forced cache skip/bust

This plugin includes a `gistnocache` tag to bypass caching, and `gistbust` to skip loading from the cache but update it with the result (for one-off usage and forced updates).

This would never cache the file:

    {% gistnocache d9719a4f53ec3ffd62ebb89359058529 %}

This would load the gist fresh from the API, but then cache the results for when the tag is changed back to `gist`:

    {% gistbust d9719a4f53ec3ffd62ebb89359058529 %}

If you just always use the `gistnocache` tag, you'd get a fresh load on every render, but it would probably slow down your site build. And seriously, you have to re-build every time anyway...


By [Brett Terpstra](http://brettterpstra.com), based on code by [Brandon Tilly](http://brandontilley.com/2011/01/31/gist-tag-for-jekyll.html).
