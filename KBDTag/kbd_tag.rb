# Title: Keyboard markup tag
# Author: Brett Terpstra <https://brettterpstra.com>
# Description: Apply HTML markup for keyboard shortcuts
#
# See Readme for syntax help and configuration details.
#
# Configuration options:
#
#   kbd:
#     use_modifier_symbols: true
#     use_key_symbols: true
#     use_plus_sign: true
#
# example:
#
# Input:
#
#      {% kbd ^~@r %}
#
# Output:
#      <span class="keycombo" title="Control-Option-Command-R">
#          <kbd class="mod">&#8963;</kbd>+<kbd class="mod">&#8997;</kbd>+<kbd class="mod">&#8984;</kbd>+<kbd class="key">R</kbd>
#      </span>

# String Helpers
class String
  # Convert natural language combo to shorcut symbols
  # ctrl-cmd-f => ^@f
  def clean_combo
    # Only remove hyphens preced and followed by non-space character
    # to avoid removing hyphen from 'option-shift--' or 'command -'
    gsub!(/(?<=\S)-(?=\S)/, ' ')
    gsub!(/\b(comm(and)?|cmd|clover)\b/i, '@')
    gsub!(/\b(cont(rol)?|ctl|ctrl)\b/i, '^')
    gsub!(/\b(opt(ion)?|alt)\b/i, '~')
    gsub!(/\bshift\b/i, '$')
    gsub!(/\b(func(tion)?|fn)\b/i, '*')
    self
  end

  # For combos containing shift key, use upper symbol for keys with two characters
  # Shift-/ should be Shift-?
  def lower_to_upper
    doubles = [
      [',', '<'],
      ['.', '>'],
      ['/', '?'],
      [';', ':'],
      ["'", '"'],
      ['[', '{'],
      [']', '}'],
      ['\\', '|'],
      ## Inconsistently, Apple doesn't use upper keys with numbers
      # ['1', '!'],
      # ['2', '@'],
      # ['3', '#'],
      # ['4', '$'],
      # ['5', '%'],
      # ['6', '^'],
      # ['7', '&'],
      # ['8', '*'],
      # ['9', '('],
      # ['0', ')'],
      ['-', '_'],
      ['=', '+']
    ]

    lowers = []
    uppers = []
    doubles.each do |dbl|
      lowers.push(dbl[0])
      uppers.push(dbl[1])
    end

    lowers.include?(self) ? uppers[lowers.index(self)] : self
  end

  # Detect combos using upper character of double
  # Command-? should be Command-Shift-?
  def upper?
    uppers = %w(< > ? : " { } | ! @ # $ % ^ & * \( \) _ +)
    uppers.include?(self)
  end

  def clean_combo!
    replace clean_combo
  end

  # Convert modifier shortcut symbols to unicode
  def to_mod
    characters = {
      '^' => '⌃',
      '~' => '⌥',
      '$' => '⇧',
      '@' => '⌘',
      '*' => 'Fn'
    }
    characters.key?(self) ? characters[self] : self
  end

  # Convert unicode modifiers to HTML entities
  def mod_to_ent(use_symbol)
    entities = {
      '⌃' => '&#8963;',
      '⌥' => '&#8997;',
      '⇧' => '&#8679;',
      '⌘' => '&#8984;',
      'Fn' => 'Fn'
    }
    names = {
      '⌃' => 'Control',
      '⌥' => 'Option',
      '⇧' => 'Shift',
      '⌘' => 'Command',
      'Fn' => 'Function'
    }
    if entities.key?(self)
      use_symbol ? entities[self] : names[self]
    else
      self
    end
  end

  # Spell out modifier symbols for titles
  def mod_to_title
    entities = {
      '⌃' => 'Control',
      '⌥' => 'Option',
      '⇧' => 'Shift',
      '⌘' => 'Command',
      'Fn' => 'Function'
    }
    entities.key?(self) ? entities[self] : self
  end

  # Spell out some characters that might be
  # indiscernable or easily confused
  def clarify_characters
    unclear_characters = {
      ',' => 'Comma (,)',
      '.' => 'Period (.)',
      ';' => 'Semicolon (;)',
      ':' => 'Colon (:)',
      '`' => 'Backtick (`)',
      '-' => 'Minus Sign (-)',
      '+' => 'Plus Sign (+)',
      '=' => 'Equals Sign (=)',
      '_' => 'Underscore (_)',
      '~' => 'Tilde (~)'
    }
    unclear_characters.key?(self) ? unclear_characters[self] : self
  end

  def name_to_ent(use_symbol)
    k =
      case strip.downcase
      when /^f(\d{1,2})$/
        num = Regexp.last_match(1)
        ["F#{num}", "F#{num}", "F#{num} Key"]
      when /^apple$/
        ['Apple', '&#63743;', 'Apple menu']
      when /^tab$/
        ['', '&#8677;', 'Tab Key']
      when /^caps(lock)?$/
        ['Caps Lock', '&#8682;', 'Caps Lock Key']
      when /^eject$/
        ['Eject', '&#9167;', 'Eject Key']
      when /^return$/
        ['Return', '&#9166;', 'Return Key']
      when /^enter$/
        ['Enter', '&#8996;', 'Enter (Fn Return) Key']
      when /^(del(ete)?|back(space)?)$/
        ['Del', '&#9003;', 'Delete']
      when /^fwddel(ete)?$/
        ['Fwd Del', '&#8998;', 'Forward Delete (Fn Delete)']
      when /^(esc(ape)?)$/
        ['Esc', '&#9099;', 'Escape Key']
      when /^right?$/
        ['Right Arrow', '&#8594;', 'Right Arrow Key']
      when /^left$/
        ['Left Arrow', '&#8592;', 'Left Arrow Key']
      when /^up?$/
        ['Up Arrow', '&#8593;', 'Up Arrow Key']
      when /^down$/
        ['Down Arrow', '&#8595;', 'Down Arrow Key']
      when /^pgup$/
        ['PgUp', '&#8670;', 'Page Up Key']
      when /^pgdn$/
        ['PgDn', '&#8671;', 'Page Down Key']
      when /^home$/
        ['Home', '&#8598;', 'Home Key']
      when /^end$/
        ['End', '&#8600;', 'End Key']
      when /^click$/
        ['click', '<i class="fas fa-mouse-pointer"></i>', 'left click']
      else
        [self, self, capitalize]
      end
    use_symbol ? [k[1], k[2]] : [k[0], k[2]]
  end
end

module Jekyll
  # kbd tag class
  class KBDTag < Liquid::Tag
    @combos = nil

    def initialize(tag_name, markup, tokens)
      @combos = []

      markup.split(%r{ / }).each do |combo|
        mods = []
        key = ''
        combo.clean_combo!
        combo.strip.split(//).each do |char|
          next if char == ' '

          case char
          when /[⌃⇧⌥⌘]/
            mods.push(char)
          when /[*\^$@~]/
            mods.push(char.to_mod)
          else
            key += char
          end
        end
        mods = sort_mods(mods)
        title = ''
        if key.length == 1
          if mods.empty? && (key =~ /[A-Z]/ || key.upper?)
            # If there are no modifiers, convert uppercase letter
            # to "Shift-[Uppercase Letter]", uppercase lowercase keys
            mods.push('$'.to_mod)
          end
          key = key.lower_to_upper if mods.include?('$'.to_mod)
          key.upcase!
          title = key.clarify_characters
        elsif mods.include?('$'.to_mod)
          key = key.lower_to_upper
        end
        key.gsub!(/"/, '&quot;')
        @combos.push({ mods: mods, key: key, title: title })
      end
      super
    end

    def sort_mods(mods)
      order = ['Fn', '⌃', '⌥', '⇧', '⌘']
      mods.uniq!
      mods.sort { |a, b| order.index(a) < order.index(b) ? -1 : 1 }
    end

    def render(context)
      config = context.registers[:site].config
      use_key_symbol = config['kbd']['use_key_symbols'] rescue true
      use_mod_symbol = config['kbd']['use_modifier_symbols'] rescue true
      use_plus = config['kbd']['use_plus_sign'] rescue true

      output = []

      @combos.each do |combo|
        next unless combo[:mods].length || combo[:key].length

        kbds = []
        title = []
        combo[:mods].each do |mod|
          mod_class = use_mod_symbol ? 'mod symbol' : 'mod'
          kbds.push(%(<kbd class="#{mod_class}">#{mod.mod_to_ent(use_mod_symbol)}</kbd>))
          title.push(mod.mod_to_title)
        end
        unless combo[:key].empty?
          key, keytitle = combo[:key].name_to_ent(use_key_symbol)
          key_class = use_key_symbol ? 'key symbol' : 'key'
          keytitle = keytitle.clarify_characters if keytitle.length == 1
          kbds.push(%(<kbd class="#{key_class}">#{key}</kbd>))
          title.push(keytitle)
        end
        kbd = if use_mod_symbol
                use_plus ? kbds.join('+') : kbds.join
              else
                kbds.join('-')
              end
        span_class = "keycombo #{use_mod_symbol && !use_plus ? 'combined' : 'separated'}"
        kbd = %(<span class="#{span_class}" title="#{title.join('-')}">#{kbd}</span>)
        output.push(kbd)
      end

      output.join('/')
    end

    Liquid::Template.register_tag('kbd', self)
  end
end
