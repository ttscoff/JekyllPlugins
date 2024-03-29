# Feature Availability

Adds markup based on whether the described feature is available in the current release.

Build numbers are retrieved from Sparkle appcasts using the `sparkle:version` attribute of the most recent enclosure's link. The path to the local appcast files are defined in `_config.yml` (see configuration).

This plugin was designed for the [Bunch.app documentation site](https://bunchapp.co). Bunch has two appcasts, one for the release version, and one for the beta version. The build numbers are synced between the two, with the beta build number always equal to or greater than the release build number.

When I add a new feature to the beta, this plugin allows me to include its documentation in the main site with a notice that it's a beta feature (or "upcoming," meaning I've documented but haven't yet pushed the build that includes it). I just mark a feature's documentation with a tag defining the build number the text applies to, and the plugin determines if it's part of the public release, the beta version, or unreleased.

- If the build number specified in the tag is less than or equal to current   release build, no markup is added.
- If it's greater than the stable release and less than or equal to the current beta build, the tag content is considered "beta."
- If it's greater than the current beta build, the tag content is considered "upcoming."

If you want to use only "beta" or "upcoming" with a single build number, a little modification will be required, but it shouldn't be too hard to decipher where the changes are needed.

The Sparkle appcasts are checked for the current build number the first time the plugin is called when the Jekyll builds the site. The plugin caches the result in the Jekyll site config object, so all subsequent calls to the plugin have the value available for that build without having to parse the appcast each time.

## Configuration

All configuration/customization happens in the site's `_config.yml`.

Appcast paths are required should be paths to local files. The plugin could be modified to pull in an appcast URL from the web, but I'll leave that up to you.

In _config.yml:

```yaml
availability:
  appcast:
    release: /path/to/appcast.xml
    beta: /path/to/beta/appcast.xml
```

You can optionally hardcode build numbers instead of file paths. Build numbers can be integers or any string containing only numbers and periods (so date-based build numbers like '2021.08.25.23562' will also work).

If you don't have a separate beta build, you can either set the beta path to a very large number to have everything higher than the release build marked as beta, or set beta to the same path as the release build and have everything higher than release marked as upcoming/unreleased.

### Template Customization

Templates are defined in ERB format. `<%= content =>` gets block tag contents, `<%= min_version =>` gets the build number. If you want to use the default template(s) for any type, leave the key(s) out entirely.

Templates can use Markdown or HTML (or both). Multiple lines should probably use a `|+` YAML block scalar, which will preserve newlines and not chomp trailing whitespace. Note that if you use HTML block tags like `div` or `aside` (as the default templates do), you'll need to include the attribute `markdown=1` in the opening tag to ensure that Markdown inside it is rendered properly.

Templates can be defined for both "beta" and "upcoming" output, including any of: single (inline) tag formatting used when the block tag contents have no line breaks, multi-line (block) formatting, and the one-off notification alert.

In _config.yml:

```yaml
availability:
  appcast:
    release: /path/to/appcast.xml
    beta: /path/to/beta/appcast.xml
  templates:
    beta:
      inline: [ERB TEMPLATE]
      block: [ERB TEMPLATE]
      notification: [ERB TEMPLATE]
    upcoming:
      inline: [ERB TEMPLATE]
      block: [ERB TEMPLATE]
      notification: [ERB TEMPLATE]
```

### Example Template Config

```yaml
availability:
  appcast:
    release: ~/Code/Bunch/updates/appcast.xml
    beta: ~/Code/Bunch/beta-updates/appcast.xml
  templates:
    beta:
      inline: <i class="betafeature"><span title="The following feature is only available in the Bunch Beta (build <%= min_version %>)" class="notification">(Beta only)</span> <%= content %></i>
      block: |+
        <div class="betafeature" markdown=1>

        > ___Beta Feature___: this feature is currently in development and is only available to those using Bunch Beta (build <%= min_version %>). If you want to help test new features, feel free to [download and run the beta release](/download/).
        {:.alert}

        <%= content %>

        </div>
```

### Removing Unreleased Features From Output

If you'd prefer to just have the plugin remove unreleased features from the output instead of marking them up, simply set the templates to empty strings. Sections marked with a build number greater than the public release or beta will be removed from output, including from table of contents generation.

The following would use default templates for beta features, but remove unreleased features from the rendered output until the build number catches up with them. Replicate this for the beta templates to remove all features marked with higher build numbers than the release.

```yaml
availability:
  templates:
    upcoming:
      inline: ''
      block: ''
      notification: ''
```

See the end of this README for some example styling.

## Usage

### Block Tag: available

Syntax:

    {% available BUILD %}[...]{% endavailable %}

Define the build number at which the feature described in the block is available.

Can be used inline around text in a paragraph or around a block containing newlines. If the content is multi-line, a div wrapper surrounds the block.

If the first text in a multi-line block is a level 2 or higher header and the feature is unavailable in the stable release, the headline has "(Upcoming)" or "(Beta)" appended to it in a span with the class "tag". This also appears in any Kramdown-generated TOC.

#### Example:

    {% available 193 %}
    ## Brand New Feature

    Description
    {% endavailable %}

If the public version's build number is less than 193, this
outputs:

    <div class="betafeature" markdown=1>

    > ___Beta Feature___: this feature is currently in
    development and is only available to those using
    the preview release. If you want to help test new 
    features, feel free to [download the beta](/download).
    {:.alert}

    ## Brand New Feature <span class="tag">(Beta)</span>

    Description

    </div>

(The `markdown=1` causes Kramdown to render Markdown
formatting inside the block tag. The `{:.alert}` is a
Kramdown IAL to apply the class "alert" to the blockquote.)

If the current release build is 193 or greater, the content
of the block is output without any wrapper.

### Tag: availablenotif

Syntax:

    {% availablenotif BUILD %}

Regular Jekyll tag that inserts a blockquote with the
class "alert" notifying the reader that the feature
described is only available in beta/upcoming release.

#### Example

    {% availablenotif 119 %}

If the current release build is less than 119, this will
output:

    > ___Beta Feature___: this feature is currently in
    development and is only available to those using
    Bunch Beta. If you want to help test new features,
    feel free to [download the beta](/download).
    {:.alert}

## Styling

Here's the relevant Sass excerpted from the Bunch documentation website, which will work with the default markup. Adjust as needed for your own templates.

This styling marks multi-line content blocks like this:

![Multi-line content with block tag](docs/availability_block.jpg)

The `availablenotif` tag generates a blockquote with an alert class:

![Notification tag](docs/availability_notif.jpg)

Styles are included for the markup inserted into the automatic table of contents:

![Tag in table of contents](docs/availability_toc.jpg)

```scss
@function bgify($color, $desat: 10%, $lighten: 30%) {
  @return lighten(desaturate($color, $desat), $lighten);
}

@function intensify($color, $sat: 10%, $darken: 5%) {
  @return darken(saturate($color, $sat), $darken);
}

$color-pop-yellow: #eccc87;
$color-alert-bg: bgify($color-pop-yellow, 20%, 25%);
$color-alert-border: intensify($color-pop-yellow, 2%, 2%);

blockquote {
  border-left: .5em solid;
  border-radius: 4px;
  clear: both;
  display: block;
  font-size: .85em;
  font-style: italic;
  margin: 1em 0 1em -1em;
  padding: 5px .75em 5px 1.25em;

  &.alert {
    background: $color-alert-bg;
    border-color: $color-alert-border;

    strong {
      background: $color-alert-border;
      text-decoration: underline;
    }

    a {
      color: darken($color-alert-border, 30%);
    }
  }
}

h2,
h3,
h4 {
  .tag {
    background: rgba($color-alert-border, .5);
    border-radius: 4px;
    display: inline-block;
    font-size: .6em;
    font-style: normal;
    padding: 2px;
    position: relative;
    top: -.2em;
  }
}

#markdown-toc {
  a {
    .tag {
      background: rgba($color-alert-border, .5);
      border-radius: 4px;
      display: inline-block;
      font-size: .7em;
      font-style: italic;
      padding: 0 2px;
      position: relative;
      top: -.1em;
    }
  }
}


div.betafeature {
  background: $color-alert-bg;
  border-radius: 4px;
  border: solid 2px $color-alert-border;
  left: -.6em;
  padding: 0 .5em;
  position: relative;

  .alert {
    font-size: .8em;
    left: -.5em;
    margin: 0 0 0 -1.1em;
    padding: 0 .5em;

    strong {
      background: rgba($color-alert-border, .5);
    }
  }
}

i.betafeature {
  background: $gray90;
  font-style: italic;
}

.betafeature {
  .notification {
    background: rgba($color-alert-bg, .5);
    color: darken($color-alert-border, 30%);
  }
}
```
