module ModelBasedHtml

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
      open_tag(start_tag(type, :object_html => @object))
      yield self
      close_tag("</#{type}>")
    end

    def start_tag(type, options = {})
      options = html_attrs(options) if options[:object_html]
      @template.content_tag(type, '', options).sub(/<\/#{type}>$/, '')
    end

    def h(string)
      @template.send(:h, string)
    end

    def value_tag(tag, method_or_value, options, &block)
      open_tag(start_tag(tag, attributes(method_or_value, options)))
      concat_or_yield(value(method_or_value), "</#{tag}>", &block)
    end

    def value_tag_h(tag, method_or_value, options, &block)
      open_tag(start_tag(tag, attributes(method_or_value, options)))
      concat_or_yield(h(value(method_or_value)), "</#{tag}>", &block)
    end

    def name_tag(tag, method_or_value, options, &block)
      open_tag(start_tag(tag, attributes(method_or_value, options)))
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
      close_tag(args.join) unless args.empty?
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
      @tags_opened ||= 0
      @template.concat("\n")
      @template.concat("  " * (@tags_opened))
      @template.concat(*args)
      ""
    end

    def open_tag(*args)
      @tags_opened ||= 0
      concat(*args)
      @tags_opened += 1
    end

    def close_tag(*args)
      @tags_opened ||= 1
      @tags_opened = (@tags_opened - 1).abs
      concat(*args)
    end

  end

end
