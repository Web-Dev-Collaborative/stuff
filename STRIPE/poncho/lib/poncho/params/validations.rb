module Poncho
  module Validations
    class ParamValidator < EachValidator
      def check_validity!
        unless options[:param]
          raise ArgumentError, ':param option required'
        end
      end

      def validate_each(record, attribute, value)
        if record.param_for_validation?(attribute)
          options[:param].validate_each(record, attribute, value)
        end
      end
    end

    module HelperMethods
      def validates_param(*attr_names)
        options = attr_names.last.is_a?(::Hash) ? attr_names.pop : {}
        validates_with ParamValidator, options.merge(:attributes => attr_names)
      end
    end
  end
end