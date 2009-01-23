module ModelBasedHtml

  class Table < ModelBasedHtml::Base

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
      @columns = []
      default(:table, object, template, { :object_html => collection }, &block)
    end

    # Renders a thead. You need this to register th's for automatic
    # rendering using <tt>body</tt> without a block.
    def head(options = {}, &block)
      return "" if @collection.empty? and not @force
      reset_cell_count
      open_tag(start_tag(:thead, options))
      @inside_head = true
      tr(:class => "thead", :object_html => nil) do
        yield
      end
      @inside_head = false
      close_tag("</thead>")
    end

    # Renders a tfoot.
    def foot(options = {}, &block)
      return "" if @collection.empty?
      reset_cell_count
      open_tag(start_tag(:tfoot, options))
      yield
      close_tag("</tfoot>")
    end

    # Loops your collection inside a tbody tag. If you don't specify a block
    # it will try to render a tbody-element based on the columns specified in
    # the thead.
    def body(options = {}, &block)
      when_not_empty do
        reset_cell_count
        sanitize = options.delete(:sanitize) or false
        open_tag(start_tag(:tbody, options))
    
        @collection.each do |object|
          if block_given?
            @object = object
            yield object
          else
            raise ArgumentError, "No columns defined. Make a head with at least 1 th." if @columns.nil? or @columns.empty?
            tr(:object_html => object) do
              @columns.each do |column|
                if column.is_a?(Symbol)
                  sanitize ? td_h(object.send(column)) : td(object.send(column))
                else
                  td('&nbsp;', :class => 'empty_cell')
                end
              end
            end
          end
        end
        close_tag("</tbody>")
      end
    end

    # Renders a td. When method or value is a symbol, it will try
    # to get the value from the object, if you're currently in a
    # <tt>body</tt>
    def td(method_or_value = nil, options = {}, &block)
      count_cell
      value_tag(:td, method_or_value, options, &block)
    end

    # Renders a td while escaping method_or_value.
    def td_h(method_or_value = nil, options = {}, &block)
      count_cell
      value_tag_h(:td, method_or_value, options, &block)
    end

    # Render a th as a name_tag, so it calls human_attribute_name if
    # a symbol has been specified. You will need to do this for <tt>head</tt>
    # to render automatically.
    def th(method_or_value = nil, options = {}, &block)
      count_cell
      @columns ||= []
      @columns << method_or_value if @inside_head
      name_tag(:th, method_or_value, options, &block)
    end

    # Render a tr-block. Specify :object_html to bind it to an object.
    def tr(options = {}, &block)
      reset_cell_count
      options = {:object_html => @object}.merge(options)
      options.update(:class => odd_or_even) unless options[:class]
      open_tag(start_tag(:tr, options))
      yield
      close_tag("</tr>")
    end

    # Returns odd or even
    def odd_or_even
      @template.cycle("odd", "even", :name => "table_#{self.object_id}")
    end

    # Resets the odd or even cycle
    def reset_odd_or_even
      @template.reset_cycle("table_#{self.object_id}")
    end

    # Yields or displays a message when the collection is not empty.
    # When no message has been specified, it'll try to translate a message.
    # If a forcing class has been specified in table_for, it will automatically
    # render a td with a colspan to cover the entire row.
    def when_empty(message = nil, &block)
      if @collection.empty?
        if @force
          tr(:class => "empty_collection_message", :object_html => nil) do
            td('', :colspan => @table_width) do
              yield_or_return_empty_collection_message(message, &block)
            end
          end
        else
          yield_or_return_empty_collection_message(message, &block)
        end
      end
    end

    # Yields only when the collection specified is not empty.
    def when_not_empty(&block)
      yield unless @collection.empty?
    end

    # Returns the maximum amount of cells used in one row.
    def width
      @table_width
    end

    private

    def yield_or_return_empty_collection_message(message = nil, &block)
      if block_given?
        yield empty_collection_message
      else
        concat(message || empty_collection_message)
      end
    end

    def empty_collection_message
      if @object.nil?
        if @force
          model_name = @force.human_name(:count => 0)
        else
          model_name = @template.translate(@template.params[:controller].to_sym, :default => [ :common, "entries"], :scope => :entries)
        end
      else
        model_name = @object.class.human_name(:count => 0)
      end
      translate_options = { 
        :scope => :tables,
        :default => "No #{model_name} found.",
        :model => model_name,
        :count => 0 }
      if @template.respond_to?(:view_translate)
        translate_method = :view_translate
        translate_options.delete(:scope)
      else
        translate_method = :translate
      end
      
      @template.send(translate_method, :"#{object_name}.empty_table", translate_options)
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
