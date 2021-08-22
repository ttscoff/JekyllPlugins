# Feature Availability

Adds markup based on whether the described feature is available in the current release.

Build numbers are retrieved from Sparkle appcasts using the `sparkle:version` attribute of the most recent enclosure's link. The path to the local appcasts files are defined in _config.yml (see configuration).

- If the specified version is less than or equal to current   release build, no markup is added.
- If it's greater than the stable release and less than or   equal to the current beta build, the tag content is   considered "beta."
- If it's greater than the current beta build, the tag   content is considered "upcoming."

## Configuration

Appcast paths should be to local files.

Templates are ERB format. `<%= content =>` gets block tag contents, `<%= min_version =>` gets the build number. If you want to use the default templates, leave the key(s) out.

In _config.yml:

    availability:
      appcast:
        release: /path/to/appcast.xml
        beta: /path/to/appcast.xml
      templates:
        beta:
          inline: <i class="betafeature"><span title="The following feature is only available in the preview build (build <%=min_version%>)" class="notification">(Beta only)</span> <%=content%></i>
          block: |+
            <div class="betafeature" markdown=1>

            > ___Beta Feature___: this feature is currently in development and is only available to those using the preview build. If you want to help test new features, feel free to [download and run the beta release](/download/).
            {:.alert}

            <%=content%>

            </div>
          notification: ...
        upcoming:
          inline: ...
          block: ...
          notification: ...

## Block Tag

Syntax:

    {% available BUILD %}[...]{% endavailable %}

Define the build number at which the feature described in the block is available.

Can be used inline around text in a paragraph or around a block containing newlines. If the content is multi-line, a div wrapper surrounds the block.

If the first text in a multi-line block is a level 2 or higher header and the feature is unavailable in the stable release, the headline has "(Upcoming)" or "(Beta)" appended to it in a span with the class "tag". This also appears in any Kramdown-generated TOC.

### Example:

    {% available 193 %}
    ## Brand New Feature

    Description
    {% endavailable %}

If the current version's build number is less than 193, this
outputs:

    <div class="betafeature" markdown=1>

    > ___Beta Feature___: this feature is currently in
    development and is only available to those using
    Bunch Beta. If you want to help test new features,
    feel free to [download the beta](/download).
    {:.alert}

    ## Brand New Feature <span class="tag">(Beta)</span>

    Description

    </div>

(The `markdown=1` causes Kramdown to render Markdown
formatting inside the block tag. The `{:.alert}` is a
Kramdown IAL to apply the class "alert" to the blockquote.)

If the current release build is 193 or greater, the content
of the block is output without any wrapper.

## Regular Tag

Syntax:

    {% availablenotif BUILD %}

Regular Jekyll tag that inserts a blockquote with the
class "alert" notifying the reader that the feature
described is only available in beta/upcoming release.

### Example

    {% availablenotif 119 %}

If the current release build is less than 119, this will
output:

    > ___Beta Feature___: this feature is currently in
    development and is only available to those using
    Bunch Beta. If you want to help test new features,
    feel free to [download the beta](/download).
    {:.alert}
