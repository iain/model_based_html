module ModelBasedHtml
  
  class DefinitionList < ModelBasedHtml::Base

    # Renders a dt-element. Specify a block to alter it's contents.
    # When method_or_value is a symbol, it will look up human_attribute_name.
    def dt(method_or_value = nil, options = {}, &block)
      name_tag(:dt, method_or_value, options, &block)
    end

    # Renders a dd-element. Specify a block to alter it's contents.
    # When method_or_value is a symbol, it will look up the value of the object.
    def dd(method_or_value = nil, options = {}, &block)
      value_tag(:dd, method_or_value, options, &block)
    end

    # Same as dd, but escapes the html in method_or_value.
    def dd_h(method_or_value = nil, options = {}, &block)
      value_tag_h(:dd, method_or_value, options, &block)
    end

    # Perform both dt and dd, the block applies to dd.
    def dt_and_dd(method_or_value = nil, options = {}, &block)
      dt(method_or_value, options)
      dd(method_or_value, options, &block)
    end
    alias_method :show, :dt_and_dd

    # Same as dt_and_dd, but escapes the html in method_or_value.
    def dt_and_dd_h(method_or_value = nil, options = {}, &block)
      dt(method_or_value, options)
      dd_h(method_or_value, options, &block)
    end
    alias_method :show_h, :dt_and_dd_h

  end
  
end
