require 'json'

module Papers
  class BowerComponent < DependencySpecification
    def pretty_hash
      {
        name: name_without_version,
        license: license,
        license_url: @license_url,
        project_url: @project_url
      }
    end

    def self.introspected
      full_introspected_entries.map { |e| e['name'] }
    end

    def self.full_introspected_entries
      whitelisted_license = Papers.config.version_whitelisted_license
      bower_json_entries.map do |entry|
        name =
          if whitelisted_license != nil && whitelisted_license == entry['license']
            entry['name']
          else
            "#{entry['name']}-#{entry['_release']}"
          end
        {
          'name' => name,
          'homepage' => entry['homepage']
        }
      end
    end

    def self.bower_json_entries
      json_files = Dir["#{Papers.config.bower_components_path}/*/.bower.json"]
      json_files.map do |path|
        JSON.parse File.read(path)
      end
    end

    def self.asset_type_name
      'Bower component'
    end

    def self.manifest_key
      "bower_components"
    end
  end
end
