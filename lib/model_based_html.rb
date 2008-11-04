module ModelBasedHtml
  
  module Helpers

    def table_for(collection, &block)
      ModelBasedHtml::Table.new(:table, collection, self, &block)
    end
    
    def definition_list_for(object, &block)
      ModelBasedHtml::DefinitionList.new(:dl, object, self, &block)
    end

  end

  class Base

    # References the default method, for overriding purposes
    def initialize(type, object, template, &block)
      default(type, object, template, &block)
    end

    def default(type, object, template, &block)
      object = object.to_s.camelize.constantize.new if object.is_a?(Symbol)
      @object = object
      @template = template
      concat(start_tag(type, :object_html => @object))
      yield self
      concat("</#{type}>")
    end

    def start_tag(type, options = {})
      options = html_attrs(options) if options[:object_html]
      @template.content_tag(type, '', options).sub(/<\/#{type}>$/, '')
    end

    def h(string)
      @template.send(:h, string)
    end

    def value_tag(tag, method_or_value, options, &block)
      concat(start_tag(tag, attributes(method_or_value, options)))
      concat_or_yield(value(method_or_value), "</#{tag}>", &block)
    end

    def value_tag_h(tag, method_or_value, options, &block)
      concat(start_tag(tag, attributes(method_or_value, options)))
      concat_or_yield(h(value(method_or_value)), "</#{tag}>", &block)
    end

    def name_tag(tag, method_or_value, options, &block)
      concat(start_tag(tag, attributes(method_or_value, options)))
      concat_or_yield(name(method_or_value), "</#{tag}>", &block)
    end

    private

    def html_attrs_for_object(object)
      { :class => object_name(object), :id => "#{object_name(object)}_#{object.id}" }
    end

    def html_attrs_for_collection(collection)
      { :class => object_name(collection.first).pluralize }
    end

    def html_attrs(options = {})
      object = options.delete(:object_html) or @object
      if object.is_a?(Array)
        object_options = html_attrs_for_collection(object)
      else
        object_options = html_attrs_for_object(object)
      end
      options[:class] = ("%s %s" % [ object_options[:class], options[:class]]).strip
      object_options.merge(options)
    end

    def object_name(object = @object)
      @object_name ||= object.class.to_s.underscore.gsub('/','_')
    end

    def attributes(method, options = {})
      (method.is_a?(Symbol) ? { :class => method.to_s } : {}).merge(options)
    end

    def concat_or_yield(*args, &block)
      str = args.shift
      if block_given?
        yield str
      else
        concat(str)
      end
      concat(args.join) unless args.empty?
    end

    def value(method_or_value)
      return method_or_value unless method_or_value.is_a?(Symbol)
      real_object.send(method_or_value)
    end

    def name(method_or_value)
      return method_or_value unless method_or_value.is_a?(Symbol)
      real_object.class.human_attribute_name(method_or_value.to_s)
    end

    def real_object
      @object.is_a?(Array) ? @object.first : @object
    end

    # Returns an empty string so it doesn't matter if you
    # echo it in your views.
    # <% dl.dd :name %> will be the same as <%= dl.dd :name %>
    def concat(*args)
      @template.concat(*args)
      ""
    end

  
  end
  
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
  
  class Table < ModelBasedHtml::Base

    def thead(options = {}, &block)
      concat(start_tag(:thead, options))
      yield
      concat("</thead>")
    end

    def tbody(options = {}, &block)
      sanitize = options.delete(:sanitize) or false
      concat(start_tag(:tbody, options))
      collection = (@object.is_a?(Array) ? @object : [@object])
  
      if block_given?
        collection.each do |object|
          yield object
        end
      else
        raise ArgumentError, "No columns defined for automatic table making" if @columns.nil?
        collection.each do |o|
          @columns.each do |column|
            tr(o) do
              th(o.class.human_attribute_name(column.to_s))
              sanitize ? td_h(o.send(column)) : td(o.send(column))
            end
          end
        end
      end
      concat("</thead>")
    end

    def td(method_or_value = nil, options = {}, &block)
      value_tag(:td, method_or_value, options, &block)
    end

    def td_h(method_or_value = nil, options = {}, &block)
      value_tag_h(:td, method_or_value, options, &block)
    end

    def th(method_or_value = nil, options = {}, &block)
      @columns ||= []
      @columns << method_or_value
      name_tag(:th, method_or_value, options, &block)
    end

    def tr(object, &block)
      row = @template.cycle("odd", "even", :name => "table_#{@object.object_id}")
      concat(start_tag(:tr, :class => row, :object_html => object))
      yield
      concat("</tr>")
    end

  end
end
