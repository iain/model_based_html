module ModelBasedHtml

  class Base

    # The initialize method just passes everything to <tt>default</tt>.
    # Please override in inherited classes for more complex logic.
    def initialize(type, object, template, options = {}, &block)
      default(type, object, template, options => {}, &block)
    end

    # Makes an html-tag with a value in it. If the value is a symbol it
    # will send it to the object. If you specify a block, it will yield
    # with the value of the attribute specified.
    def value_tag(tag, method_or_value, options, &block)
      open_tag(start_tag(tag, attributes(method_or_value, options)))
      concat_or_yield(value(method_or_value), "</#{tag}>", &block)
    end

    # Same as <tt>value_tag</tt>, but escapes method_or_value.
    def value_tag_h(tag, method_or_value, options, &block)
      open_tag(start_tag(tag, attributes(method_or_value, options)))
      concat_or_yield(h(value(method_or_value)), "</#{tag}>", &block)
    end

    # Similar to value_tag, this will render a tag, but instead of
    # getting the value of the attribute specified it will try to
    # get the human_attribute_name, if a Symbol is specified. Pass a
    # block to modify the resulting value.
    def name_tag(tag, method_or_value, options, &block)
      open_tag(start_tag(tag, attributes(method_or_value, options)))
      concat_or_yield(name(method_or_value), "</#{tag}>", &block)
    end

    private

    # Sets all the defaults and stuff. Pass :object_html to an object or
    # collection for automatic class and id.
    def default(type, object, template, options = {}, &block)
      object = object.to_s.camelize.constantize.new if object.is_a?(Symbol)
      @object = object
      @template = template
      options = { :object_html => @object }.merge(options)
      open_tag(start_tag(type, options))
      yield self
      close_tag("</#{type}>")
    end


    # Returns a normal start_tag.
    def start_tag(type, options = {})
      options = html_attrs(options) if options[:object_html]
      @template.content_tag(type, '', options).sub(/<\/#{type}>$/, '')
    end

    # Returns a class and id for the object specified.
    # Similar to haml: %tag[object]
    def html_attrs_for_object(object)
      id = object_name(object)
      id = object.new_record? ? "new_#{id}" : "#{id}_#{object.id}"
      { :class => object_name(object), :id => id }
    end

    # Returns a class for a collection. Actually just the class name pluralized.
    def html_attrs_for_collection(collection)
      { :class => object_name(collection.first).pluralize }
    end

    # Switches approriately based on a collection or single object
    # to return html attributes.
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

    # A lowercased and underscored version of the current object
    def object_name(object = @object)
      @object_name ||= object.class.to_s.underscore.gsub('/','_')
    end

    # Provides a class name for html tags coupled to an attribute.
    # This will make it possible to use css per attribute.
    def attributes(method, options = {})
      (method.is_a?(Symbol) ? { :class => method.to_s } : {}).merge(options)
    end

    # Switcher for name and value tags. The first argument gets passed
    # to the block, the others will be concatted after that.
    def concat_or_yield(*args, &block)
      str = args.shift
      if block_given?
        yield str
      else
        concat(str)
      end
      close_tag(args.join) unless args.empty?
    end

    # Performs the actual check on the object to get the value of an attribute.
    def value(method_or_value)
      return method_or_value unless method_or_value.is_a?(Symbol)
      @object.send(method_or_value)
    end

    # Performs the actual check on the object to get the human_attribute_name.
    def name(method_or_value)
      return method_or_value unless method_or_value.is_a?(Symbol)
      @object.class.human_attribute_name(method_or_value.to_s)
    end

    # Returns an empty string so it doesn't matter if you
    # echo it in your views.
    # <% dl.dd :name %> will be the same as <%= dl.dd :name %>
    def concat(*args)
      args[0] = args.at(0).to_s
      @tags_opened ||= 0
      @template.concat("\n")
      @template.concat("  " * (@tags_opened))
      @template.concat(*args)
      ""
    end

    # Use this to open a tag to get some sort of failing indentation...
    def open_tag(*args)
      @tags_opened ||= 0
      concat(*args)
      @tags_opened += 1
    end

    # Use this to close a tag to get some sort of failing indentation...
    def close_tag(*args)
      @tags_opened ||= 1
      @tags_opened = (@tags_opened - 1).abs
      concat(*args)
    end

    # escapes html shortcut
    def h(string)
      @template.send(:h, string)
    end


  end

end
