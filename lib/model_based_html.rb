module ModelBasedHtml
  
  module Helpers

    def table_for(collection, options = {}, &block)
      ModelBasedHtml::Table.new(:table, collection, self, options, &block)
    end
    
    def definition_list_for(object, &block)
      ModelBasedHtml::DefinitionList.new(:dl, object, self, &block)
    end

  end

end
