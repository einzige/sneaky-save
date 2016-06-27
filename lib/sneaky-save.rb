#--
# Copyright (c) 2011 {PartyEarth LLC}[http://partyearth.com]
# mailto:kgoslar@partyearth.com
#++
module SneakySave

  # Saves record without running callbacks/validations.
  # Returns true if any record is changed.
  # @note - Does not reload updated record by default.
  #       - Does not save associated collections.
  #       - Saves only belongs_to relations.
  #
  # @return [false, true]
  def sneaky_save
    begin
      sneaky_create_or_update
    rescue ActiveRecord::StatementInvalid
      false
    end
  end

  # Saves the record raising an exception if it fails.
  # @return [true] if save was successful.
  # @raise [ActiveRecord::StatementInvalid] if save failed.
  def sneaky_save!
    sneaky_create_or_update
  end

  protected

    def sneaky_create_or_update
      new_record? ? sneaky_create : sneaky_update
    end

    # Makes INSERT query in database without running any callbacks
    # @return [false, true]
    def sneaky_create
      if self.id.nil? && sneaky_connection.prefetch_primary_key?(self.class.table_name)
        self.id = sneaky_connection.next_sequence_value(self.class.sequence_name)
      end

      attributes_values = skeaky_attributes_values

      # Remove the id field for databases like Postgres which will raise an error on id being NULL
      if self.id.nil? && !sneaky_connection.prefetch_primary_key?(self.class.table_name)
        attributes_values.reject! { |key,_| key.name == 'id' }
      end

      new_id = if attributes_values.empty?
        self.class.unscoped.insert sneaky_connection.empty_insert_statement_value
      else
        self.class.unscoped.insert attributes_values
      end

      @new_record = false
      !!(self.id ||= new_id)
    end

    # Makes update query without running callbacks
    # @return [false, true]
    def sneaky_update

      # Handle no changes.
      return true if changes.empty?

      # Here we have changes --> save them.
      pk = self.class.primary_key
      original_id = changed_attributes.has_key?(pk) ? changes[pk].first : send(pk)

      serialized_fields = self.class.serialized_attributes.keys
      changed_values = sneaky_update_fields
      
      (serialized_fields & changed_values.keys).each_with_object(changed_values) { |key, attr| 
        attr[key] = @attributes[key].serialized_value
      } unless rails4?

      !self.class.where(pk => original_id).update_all(changed_values).zero?
    end

    def skeaky_attributes_values
      rails4? ? send(:arel_attributes_with_values_for_create, attribute_names) : send(:arel_attributes_values)
    end

    def sneaky_update_fields
      changes.keys.each_with_object({}) { |field, value|
        value[field] = changes[field].last
      }
    end

    def sneaky_connection
      rails4? ? self.class.connection : connection
    end

    def rails4?
      ActiveRecord::VERSION::STRING.to_i > 3
    end
end

ActiveRecord::Base.send :include, SneakySave
