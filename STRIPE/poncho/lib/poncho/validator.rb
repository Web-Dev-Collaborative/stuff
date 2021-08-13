module Poncho
  #
  #   class Person
  #     include Poncho::Validations
  #     validates_with MyValidator
  #   end
  #
  #   class MyValidator < Poncho::Validator
  #     def validate(record)
  #       if some_complex_logic
  #         record.errors[:base] = "This record is invalid"
  #       end
  #     end
  #
  #     private
  #       def some_complex_logic
  #         # ...
  #       end
  #   end
  #
  # Any class that inherits from Poncho::Validator must implement a method
  # called <tt>validate</tt> which accepts a <tt>record</tt>.
  #
  #   class Person
  #     include Poncho::Validations
  #     validates_with MyValidator
  #   end
  #
  #   class MyValidator < Poncho::Validator
  #     def validate(record)
  #       record # => The person instance being validated
  #       options # => Any non-standard options passed to validates_with
  #     end
  #   end
  #
  # To cause a validation error, you must add to the <tt>record</tt>'s errors directly
  # from within the validators message
  #
  #   class MyValidator < Poncho::Validator
  #     def validate(record)
  #       record.errors.add :base, "This is some custom error message"
  #       record.errors.add :first_name, "This is some complex validation"
  #       # etc...
  #     end
  #   end
  #
  # To add behavior to the initialize method, use the following signature:
  #
  #   class MyValidator < Poncho::Validator
  #     def initialize(options)
  #       super
  #       @my_custom_field = options[:field_name] || :first_name
  #     end
  #   end
  #
  # The easiest way to add custom validators for validating individual attributes
  # is with the convenient <tt>Poncho::EachValidator</tt>. For example:
  #
  #   class TitleValidator < Poncho::EachValidator
  #     def validate_each(record, attribute, value)
  #       record.errors.add attribute, 'must be Mr. Mrs. or Dr.' unless value.in?(['Mr.', 'Mrs.', 'Dr.'])
  #     end
  #   end
  #
  # This can now be used in combination with the +validates+ method
  # (see <tt>Poncho::Validations::ClassMethods.validates</tt> for more on this)
  #
  #   class Person
  #     include Poncho::Validations
  #     attr_accessor :title
  #
  #     validates :title, :presence => true
  #   end
  #
  # Validator may also define a +setup+ instance method which will get called
  # with the class that using that validator as its argument. This can be
  # useful when there are prerequisites such as an +attr_accessor+ being present
  # for example:
  #
  #   class MyValidator < Poncho::Validator
  #     def setup(klass)
  #       klass.send :attr_accessor, :custom_attribute
  #     end
  #   end
  #
  # This setup method is only called when used with validation macros or the
  # class level <tt>validates_with</tt> method.
  #
  class Validator
    def self.kind
      @kind ||= begin
        full_name = name.split('::').last
        full_name = full_name.gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase
        full_name.sub(/_validator$/, '').to_sym
      end
    end

    attr_reader :options

    # Accepts options that will be made available through the +options+ reader.
    def initialize(options)
      @options = options.freeze
    end

    # Override this method in subclasses with validation logic, adding errors
    # to the records +errors+ array where necessary.
    def validate(record)
      raise NotImplementedError, "Subclasses must implement a validate(record) method."
    end

    def kind
      self.class.kind
    end
  end

  # +EachValidator+ is a validator which iterates through the attributes given
  # in the options hash invoking the <tt>validate_each</tt> method passing in the
  # record, attribute and value.
  #
  # All Poncho validations are built on top of this validator.
  class EachValidator < Validator
    attr_reader :attributes

    # Returns a new validator instance. All options will be available via the
    # +options+ reader, however the <tt>:attributes</tt> option will be removed
    # and instead be made available through the +attributes+ reader.
    def initialize(options)
      @attributes = Array(options.delete(:attributes))
      raise ':attributes cannot be blank' if @attributes.empty?
      super
      check_validity!
    end

    # Performs validation on the supplied record. By default this will call
    # +validates_each+ to determine validity therefore subclasses should
    # override +validates_each+ with validation logic.
    def validate(record)
      attributes.each do |attribute|
        value = record.read_attribute_for_validation(attribute)
        next if (value.nil? && options[:allow_nil]) || (value == "" && options[:allow_blank])
        validate_each(record, attribute, value)
      end
    end

    # Override this method in subclasses with the validation logic, adding
    # errors to the records +errors+ array where necessary.
    def validate_each(record, attribute, value)
      raise NotImplementedError, 'Subclasses must implement a validate_each(record, attribute, value) method'
    end

    # Hook method that gets called by the initializer allowing verification
    # that the arguments supplied are valid. You could for example raise an
    # +ArgumentError+ when invalid options are supplied.
    def check_validity!
    end
  end

  # +BlockValidator+ is a special +EachValidator+ which receives a block on initialization
  # and call this block for each attribute being validated. +validates_each+ uses this validator.
  class BlockValidator < EachValidator
    def initialize(options, &block)
      @block = block
      super
    end

    private

    def validate_each(record, attribute, value)
      @block.call(record, attribute, value)
    end
  end
end