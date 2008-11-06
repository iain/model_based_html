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
      @columns << method_or_value if @inside_head
      name_tag(:th, method_or_value, options, &block)
    end

    def tr(options = {}, &block)
      reset_cell_count
      options = {:object_html => @object}.merge(options)
      options.update(:class => odd_or_even) unless options[:class]
      open_tag(start_tag(:tr, options))
      yield
      close_tag("</tr>")
    end

    def odd_or_even
      @template.cycle("odd", "even", :name => "table_#{self.object_id}")
    end

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

    def when_not_empty(&block)
      yield unless @collection.empty?
    end

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
