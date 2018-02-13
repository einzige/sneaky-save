#--
# Copyright (c) 2011 {PartyEarth LLC}[http://partyearth.com]
# mailto:kgoslar@partyearth.com
#++
module SneakySave

  # Saves the record without running callbacks/validations.
  # Returns true if the record is changed.
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

  # Saves record without running callbacks/validations.
  # @see ActiveRecord::Base#sneaky_save
  # @return [true] if save was successful.
  # @raise [ActiveRecord::StatementInvalid] if saving failed.
  def sneaky_save!
    sneaky_create_or_update
  end

  protected

  def sneaky_create_or_update
    new_record? ? sneaky_create : sneaky_update
  end

  # Performs INSERT query without running any callbacks
  # @return [false, true]
  def sneaky_create
    prefetch_pk_allowed = sneaky_connection.prefetch_primary_key?(self.class.table_name)

    if id.nil? && prefetch_pk_allowed
      self.id = sneaky_connection.next_sequence_value(self.class.sequence_name)
    end

    attributes_values = sneaky_attributes_values

    # Remove the id field for databases like Postgres
    # which fail with id passed as NULL
    if id.nil? && !prefetch_pk_allowed
      attributes_values.reject! { |key, _| key.name == 'id' }
    end

    if attributes_values.empty?
      new_id = self.class.unscoped.insert(sneaky_connection.empty_insert_statement_value)
    else
      new_id = self.class.unscoped.insert(attributes_values)
    end

    @new_record = false
    !!(self.id ||= new_id)
  end

  # Performs update query without running callbacks
  # @return [false, true]
  def sneaky_update
    return true if changes.empty?

    pk = self.class.primary_key
    original_id = changed_attributes.key?(pk) ? changes[pk].first : send(pk)

    changed_attributes = sneaky_update_fields

    # Serialize values for rails3 before updating
    unless sneaky_new_rails?
      serialized_fields = self.class.serialized_attributes.keys & changed_attributes.keys
      serialized_fields.each do |field|
        changed_attributes[field] = @attributes[field].serialized_value
      end
    end

    !self.class.where(pk => original_id).
      update_all(changed_attributes).zero?
  end

  def sneaky_attributes_values
    if sneaky_new_rails?
      send :arel_attributes_with_values_for_create, attribute_names
    else
      send :arel_attributes_values
    end
  end

  def sneaky_update_fields
    changes.keys.each_with_object({}) do |field, result|
      result[field] = read_attribute(field)
    end
  end

  def sneaky_connection
    if sneaky_new_rails?
      self.class.connection
    else
      connection
    end
  end

  def sneaky_new_rails?
    ActiveRecord::VERSION::STRING.to_i > 3
  end
end

ActiveRecord::Base.send :include, SneakySave
