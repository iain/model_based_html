module ModelBasedHtml
  
  class DefinitionList < ModelBasedHtml::Base

    def dt(method_or_value = nil, options = {}, &block)
      name_tag(:dt, method_or_value, options, &block)
    end

    def dd(method_or_value = nil, options = {}, &block)
      value_tag(:dd, method_or_value, options, &block)
    end

    def dd_h(method_or_value = nil, options = {}, &block)
      value_tag_h(:dd, method_or_value, options, &block)
    end

    def dt_and_dd(method_or_value = nil, options = {}, &block)
      dt(method_or_value, options)
      dd(method_or_value, options, &block)
    end

    def dt_and_dd_h
      dt(method_or_value, options)
      dd_h(method_or_value, options, &block)
    end

  end
  
end
