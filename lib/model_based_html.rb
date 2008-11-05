module ModelBasedHtml
  
  module Helpers

    def table_for(collection, options = {}, &block)
      ModelBasedHtml::Table.new(:table, collection, self, options, &block)
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

    # Sets all the defaults and stuff
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
      id = object_name(object)
      id = object.new_record? ? "new_#{id}" : "#{id}_#{object.id}"
      { :class => object_name(object), :id => id }
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
      @object.send(method_or_value)
    end

    def name(method_or_value)
      return method_or_value unless method_or_value.is_a?(Symbol)
      @object.class.human_attribute_name(method_or_value.to_s)
    end

    # Returns an empty string so it doesn't matter if you
    # echo it in your views.
    # <% dl.dd :name %> will be the same as <%= dl.dd :name %>
    def concat(*args)
      @template.concat("\n")
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

    attr_accessor :table_width

    def initialize(type, collection, template, options = {}, &block)
      @force = options.delete(:force)
      reset_cell_count
      if collection.empty?
        if @force
          object = @force.new
        else
          object = nil
        end
      else
        object = collection.first
      end
      @collection = collection
      default(:table, object, template, &block)
    end

    def thead(options = {}, &block)
      return "" if @collection.empty? and not @force
      reset_cell_count
      concat(start_tag(:thead, options))
      @inside_thead = true
      yield
      @inside_thead = false
      concat("</thead>")
    end

    def tbody(options = {}, &block)
      return "" if @collection.empty? and not @force
      reset_cell_count
      sanitize = options.delete(:sanitize) or false
      concat(start_tag(:tbody, options))
  
      if @collection.empty? and @force
        tr(@object) do
          td(empty_collection_message, :colspan => table_width)
        end
      else
        if block_given?
          @collection.each do |object|
            @object = object
            yield object
          end
        else
          raise ArgumentError, "No columns defined for automatic table making" if @columns.nil? or @columns.empty?
          @collection.each do |o|
            tr(o) do
              @columns.each do |column|
                sanitize ? td_h(o.send(column)) : td(o.send(column))
              end
            end
          end
        end
      end
      concat("</tbody>")
    end

    def td(method_or_value = nil, options = {}, &block)
      count_cell
      value_tag(:td, method_or_value, options, &block)
    end

    def td_h(method_or_value = nil, options = {}, &block)
      count_cell
      value_tag_h(:td, method_or_value, options, &block)
    end

    def th(method_or_value = nil, options = {}, &block)
      count_cell
      @columns ||= []
      @columns << method_or_value if @inside_thead
      name_tag(:th, method_or_value, options, &block)
    end

    def tr(object = @object, &block)
      reset_cell_count
      concat(start_tag(:tr, :class => odd_or_even, :object_html => object))
      yield
      concat("</tr>")
    end

    def odd_or_even
      @template.cycle("odd", "even", :name => "table_#{@object.object_id}")
    end

    def empty(&block)
      if @collection.empty?
        if @force
          tr do
            td(:colspan => table_width) do
              yield empty_collection_message
            end
          end
        else
          yield empty_collection_message
        end
      end
    end

    private

    def empty_collection_message
      translate_options = { 
        :scope => :tables, 
        :default => "No #{@object.class.human_name(:count => 0)} found.", 
        :model => @object.class.human_name, 
        :count => 0 }
      if @template.respond_to?(:view_translate)
        translate_method = :view_translate
        translate_options.delete(:scope)
      else
        translate_method = :translate
      end
      
      @template.send(translate_method, :"#{object_name}.empty_list", translate_options)
    end

    def count_cell
      @temporary_table_width += 1
      @table_width ||= 0
      @table_width = @temporary_table_width if @temporary_table_width > @table_width
    end

    def reset_cell_count
      @temporary_table_width = 0
    end

  end
end
