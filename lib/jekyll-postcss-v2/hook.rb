# frozen_string_literal: true

require "pathname"

module PostCssV2
  class Engine
    def initialize(source)
      @script = Pathname.new(source + "/node_modules/.bin/postcss")
      unless @script.exist?
        Jekyll.logger.error "PostCSS v2:",
                            "PostCSS not found.
                             Make sure postcss and postcss-cli
                             are installed in your Jekyll source."
        Jekyll.logger.error "PostCSS v2:",
                            "Couldn't find #{@script}"
        exit 1
      end

      @config = Pathname.new(source + "/postcss.config.js")
      unless @config.exist?
        Jekyll.logger.error "PostCSS v2:",
                            "postcss.config.js not found.
                             Make sure it exists in your Jekyll source."
        Jekyll.logger.error "PostCSS v2:",
                            "Couldn't find #{@config}"
        exit 1
      end
    end

    def process(page)
      file_path = Pathname.new(page.site.dest + page.url)
      postcss_command = `#{@script} #{file_path} -r --config #{@config}`
      Jekyll.logger.info "PostCSS v2:",
                         "Rewrote #{page.url} #{postcss_command}"
    end
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  site.pages do |page|
    if %r!\.css$! =~ page.url
      engine = PostCssV2::Engine.new(page.site.source)
      engine.process(page)
    end
  end
end



Jekyll::Hooks.register(:site, :post_write) do |site|
  if Jekyll.env == "production"
    raise PurgecssNotFoundError unless File.file?("./node_modules/.bin/purgecss")

    raise PurgecssRuntimeError unless system(
      "./node_modules/.bin/purgecss " \
      "--config ./purgecss.config.js " \
      "--output #{site.config.fetch("destination")}/#{site.config.fetch("css_dir", "css")}/"
    )
  end
end

class PurgecssNotFoundError < RuntimeError; end
class PurgecssRuntimeError < RuntimeError; end
