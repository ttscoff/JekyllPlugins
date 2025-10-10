# iTerm

Jekyll Liquid tag: render a terminal command with a "Run in iTerm" link/button.

## Usage examples:

Simple string form:

    {% iterm "gem install ruby-progress" %}


Key/value form (order doesn't matter):

    {% iterm command:"ls -la" directory:"~/Desktop" text:"List in iTerm"

## Parameters

- `command`   - The command to display and run (required unless using
    the short quoted form)
- `directory` - Optional. When present it is appended to the iTerm URL as `&d=PATH` (URL-encoded).
- `text` - Optional. Link text for the run button. Defaults to "Run in iTerm".
- `language`  - Optional. The value is used as the fence language for the emitted fenced code block.

    If you explicitly set `language:""` the opening fence will include no language (i.e. just backticks) which can be useful to avoid highlighting.

## Output

Produces a div.iterm-command containing a `<pre><code
class="language-...">...</code></pre>` and an `<a
href="iterm2://command?c=...&d=..." class="iterm-run-button">` link.

## Styling

Include the SCSS partial in `_iterm.scss`. This project imports it via `@import "iterm"` in `sass/screen.scss` so styles should be applied site-wide after recompilation.

## Security/Notes

Commands are URL-encoded for the iTerm URL and HTML-escaped for display.

Avoid rendering untrusted input through this tag as it will produce links that trigger local applications.
