require "netzke/active_record/data_accessor"
require "searchlogic"

module Netzke
  # This module is included into such data-driven widgets as GridPanel, FormPanel, etc.
  module DataAccessor
    # This method should be called from the constructor of the widget.
    def apply_helpers
      # Generic extensions to the data model
      if data_class # because some widgets, like FormPanel, may have it optional
        data_class.send(:include, Netzke::ActiveRecord::DataAccessor) if !data_class.include?(Netzke::ActiveRecord::DataAccessor)
      end
    end
    
    # Returns options for comboboxes in grids/forms
    def combobox_options_for_column(column, method_options = {})
      assoc, assoc_method = assoc_and_assoc_method_for_column(column)
      
      options = if assoc
        # Options for an asssociation attribute
        
        search = assoc.klass.searchlogic
      
        # apply scopes
        method_options[:scopes] && method_options[:scopes].each do |s|
          if s.is_a?(Array)
            scope_name, *args = s
            search.send(scope_name, *args)
          else
            search.send(s, true)
          end
        end
        
        # apply query
        search.send("#{assoc_method}_like", "#{method_options[:query]}%") if method_options[:query]
        
        search.all.map{ |r| [r.send(assoc_method)] }
      else
        # Options for a non-association attribute
        data_class.options_for(column[:name], query).map{|s| [s]}
      end
      
    end
    
    # [:col1, "col2", {:name => :col3}] =>
    #   [{:name => "col1"}, {:name => "col2"}, {:name => "col3"}]
    def normalize_attr_config(cols)
      cols.map do |c|
        c.is_a?(Symbol) || c.is_a?(String) ? {:name => c.to_s} : c.merge(:name => c[:name].to_s)
      end
    end
    
    # Returns association and association method for a column
    def assoc_and_assoc_method_for_column(c)
      assoc_name, assoc_method = c[:name].split('__')
      assoc = data_class.reflect_on_association(assoc_name.to_sym) if assoc_method
      [assoc, assoc_method]
    end
   
    def association_attr?(name)
      !!name.to_s.index("__")
    end
    
  end
end