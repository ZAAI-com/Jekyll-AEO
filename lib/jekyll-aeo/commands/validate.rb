# frozen_string_literal: true

module JekyllAeo
  module Commands
    class Validate < Jekyll::Command
      class << self
        def init_with_program(prog)
          prog.command(:"aeo:validate") do |c|
            c.syntax "aeo:validate [options]"
            c.description "Validate AEO output files (llms.txt, llms-full.txt, and referenced .md files)"

            c.option "destination", "-d", "--destination DESTINATION",
                     "The destination directory to validate"
            c.option "source", "-s", "--source SOURCE", "Custom source directory"
            c.option "config", "--config CONFIG_FILE[,CONFIG_FILE2,...]", Array,
                     "Custom configuration file"

            c.action do |_args, options|
              JekyllAeo::Commands::Validate.process(options)
            end
          end
        end

        def process(options)
          options = configuration_from_options(options)
          dest = options["destination"]
          baseurl = options["baseurl"].to_s.chomp("/")
          errors, warnings = validate(dest, baseurl)
          report(errors, warnings)
        end

        def validate(dest, baseurl = "")
          errors = []
          warnings = []
          validate_llms_txt(dest, errors)
          validate_llms_full_txt(dest, errors)
          validate_md_references(dest, baseurl, errors)
          [errors, warnings]
        end

        private

        def validate_llms_txt(dest, errors)
          path = File.join(dest, "llms.txt")
          unless File.exist?(path)
            errors << "llms.txt not found at #{path}"
            return
          end

          content = File.read(path, encoding: "utf-8")
          return if content.start_with?("# ")

          errors << "llms.txt does not start with an H1 heading (# )"
        end

        def validate_llms_full_txt(dest, errors)
          path = File.join(dest, "llms-full.txt")
          unless File.exist?(path)
            errors << "llms-full.txt not found at #{path}"
            return
          end

          return unless File.empty?(path)

          errors << "llms-full.txt is empty"
        end

        def validate_md_references(dest, baseurl, errors)
          llms_path = File.join(dest, "llms.txt")
          return unless File.exist?(llms_path)

          content = File.read(llms_path, encoding: "utf-8")
          md_urls = content.scan(/\[.*?\]\(([^)]*\.md)\)/).flatten

          md_urls.each do |url|
            relative_url = if !baseurl.empty? && url.start_with?(baseurl)
                             url.delete_prefix(baseurl)
                           else
                             url
                           end
            file_path = File.join(dest, relative_url)
            errors << "Referenced file not found: #{url} (expected at #{file_path})" unless File.exist?(file_path)
          end
        end

        def report(errors, warnings)
          if errors.empty? && warnings.empty?
            Jekyll.logger.info "AEO Validate:", "All checks passed!"
            return
          end

          warnings.each do |warning|
            Jekyll.logger.warn "AEO Warning:", warning
          end

          errors.each do |error|
            Jekyll.logger.error "AEO Error:", error
          end

          summary_parts = []
          summary_parts << "#{errors.size} error(s)" unless errors.empty?
          summary_parts << "#{warnings.size} warning(s)" unless warnings.empty?
          Jekyll.logger.info "AEO Validate:", summary_parts.join(", ")

          abort if errors.any?
        end
      end
    end
  end
end
