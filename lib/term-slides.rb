require "version"

module TermSlides
  class Error < StandardError; end
  require 'colorize'
  require 'tty-table'
  require 'tty-command'
  require 'highline'
  require 'mkmf'
  require 'rouge'
  require 'tempfile'
  require 'os'
  require 'term-images'
  require 'tmpdir'

  module MakeMakefile::Logging
    @logfile = File::NULL
    @quiet = true
  end

  class TTYRenderer
    def render_code code
      puts center_block(code.content, ::Rouge.highlight(code.content, code.format, 'terminal256'))
    end
    def render_table table
      puts center(TTY::Table.new(table.headers, table.rows).render(:unicode))
    end
    def center text
      center_block text, text
    end
    def center_block text, text_to_display
      width = HighLine.new.output_cols
      max = text.split("\n").map { |x| x.size }.max
      text_to_display.split("\n").map { |x| " " * ((max > width ? 0 : (width - max))/2) + x }.join("\n")
    end
    def render_text text
      puts center(text.text)
    end
    def render_image_file path
      ::TermImages::Image.new(path).puts
    end
    def render_image image
      render_image_file image.src
    end
    def render_diagram diagram
      render_image_file diagram.build
    end
    def render_slide slide
      puts center(slide.name).colorize(:light_blue).bold
      puts
      slide.content.each { |c| c.render }
    end
  end

  class HovercraftRenderer
    def render_code code
      puts ".. code:: #{code.format}"
      puts
      puts code.content.gsub(/^/, "    ")
    end
    def render_table table
      puts
      puts ".. table::"
      puts
      a = TTY::Table.new(table.headers, table.rows).render(:ascii).split("\n")
      s = (a[0..2] + a[3..-1].map { |l| l += "\n#{a[0]}"}).join("\n")
      puts s.gsub(/^/, "    ")
      puts
    end
    def render_text text
      puts text.text
    end
    def render_image image
      puts ".. image:: #{image.src}"
    end
    def render_diagram diagram
      puts ".. image:: #{diagram.build}"
      puts "    :width: #{diagram.width}" if not diagram.width.nil?
      puts "    :height: #{diagram.height}" if not diagram.height.nil?
      puts
    end
    def render_slide slide
      puts "----"
      puts
      puts
      puts slide.name
      puts slide.name.gsub(/./, "=")
      puts
      slide.content.each { |c| c.render }
      puts
    end
  end

  class Code
    attr_reader :format, :content
    def initialize renderer, format, content
      @renderer = renderer
      @format = format
      @content = content
    end
    def render
      @renderer.render_code self
    end
  end

  class Table
    attr_reader :rows, :headers
    def row *r
      @rows << r
    end
    def initialize renderer, headers, &block
      @renderer = renderer
      @headers = headers
      @rows = []
      instance_eval &block
    end
    def render
      @renderer.render_table self
    end
  end

  class Text
    attr_reader :text
    def initialize renderer, text
      @renderer = renderer
      @text = text
    end

    def render
      @renderer.render_text self
    end
  end

  class Diagram
    attr_reader :dot, :width, :height
    def initialize renderer, dot, width = nil, height = nil
      @renderer = renderer
      @dot = dot
      @width = width
      @height = height
    end
    def build
      $i ||= 0
      path = "term_slide_graph#{$i}.png"
      dot = 'dot'
      if find_executable dot
        dot_contents = @dot.respond_to?(:call) ? @dot.call : @dot
        input_path = "/tmp/graphviz-term-slides"
        File.write(input_path, dot_contents)
        `#{dot} #{input_path} -Tpng > #{path}`
        $i += 1
      end
      path
    end
    def render
      @renderer.render_diagram self
    end
  end

  class Image
    attr_reader :src
    def initialize renderer, src
      @renderer = renderer
      @src = src
    end
    def render
      @renderer.render_image self
    end
  end

  class Slide
    attr_accessor :name, :content, :renderer
    def get_scaling_factor
      @slides.scaling_factor
    end
    def text s
      @content << Text.new(@renderer, s)
    end
    alias t text
    def code format, s
      @content << Code.new(@renderer, format, s)
    end
    def table *headers, &block
      @content << Table.new(@renderer, headers, &block)
    end
    def diagram dot
      @content << Diagram.new(@renderer, dot)
    end
    def image src
      @content << Image.new(@renderer, src)
    end
    def initialize renderer, name, slides, &block
      @slides = slides
      @renderer = renderer
      @name = name
      @content = []
      instance_eval &block
    end
    def render
      @renderer.render_slide self
    end
  end

  class Slides
    attr_accessor :scaling_factor
    def slide name, &block
      @slides << Slide.new(@renderer, name, self, &block)
    end
    def initialize args, &block
      @scaling_factor = 1
      @args = args
      if @args.size > 0 and @args[0] == "hovercraft"
        @renderer = HovercraftRenderer.new
      else
        @renderer = TTYRenderer.new
      end
      @slides = []
      instance_eval &block
    end
    def read_char
      STDIN.echo = false
      STDIN.raw!

      input = STDIN.getc.chr
      if input == "\e" then
        input << STDIN.read_nonblock(3) rescue nil
        input << STDIN.read_nonblock(2) rescue nil
      end
    ensure
      STDIN.echo = true
      STDIN.cooked!

      return input
    end
    def run
      i = 0
      if @args.size > 0
        if @args[0] == "hovercraft"
          @slides.each do |slide|
            slide.render
          end
        else
          print `clear`
          @slides[@args[0].to_i].render
        end
        return
      end
      print "\033[?25l"
      while true
        print `clear`

        puts "#{i + 1}/#{@slides.size}"
        @slides[i].render
        s = read_char
        if s == "q"
          break
        elsif ["+"].include?(s)
          @scaling_factor *= 1.1
        elsif ["-"].include?(s)
          @scaling_factor *=  0.9
        elsif ["p", "\e[D", "\e[A", "h", "k"].include?(s)
          i -= 1 if i > 0
        elsif ["n", "\e[C", "\e[B", "l", "j"].include?(s)
          i += 1 if i < (@slides.size - 1)
        end
      end
      print "\033[?25h"
    end
  end
end
