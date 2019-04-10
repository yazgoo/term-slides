#!/usr/bin/env ruby
require 'term-slides'

TermSlides::Slides.new(ARGV) do
  slide("a slide with just text") do
    text "text in the first slide"
    text ""
    t "t is an alias for text"
  end
  slide("code (requires vimcat)") do
    code :rb, """
      def example_code(a, b)
        p a
      end
    """
  end
  slide("table") do
    table("first column name", "second column name") do
      row 1, 2
      row "a", "b"
      row :sym1, :sym2
    end
  end
  slide("diagram (requires dot (graphviz), terminal must support it)") do
    diagram "digraph {
      a -> b
    }"
  end
  slide("image (terminal must support it)") do
    image "#{File.dirname(__FILE__)}/cat.jpg"
  end
end.run
