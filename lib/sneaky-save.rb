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
  def sneaky_save(avoid_insert_conflict: nil)
    begin
      sneaky_create_or_update(avoid_insert_conflict: avoid_insert_conflict)
    rescue ActiveRecord::StatementInvalid
      false
    end
  end

  # Saves record without running callbacks/validations.
  # @see ActiveRecord::Base#sneaky_save
  # @return [true] if save was successful.
  # @raise [ActiveRecord::StatementInvalid] if saving failed.
  def sneaky_save!(avoid_insert_conflict: nil)
    sneaky_create_or_update(avoid_insert_conflict: avoid_insert_conflict)
  end

  protected

  def sneaky_create_or_update(avoid_insert_conflict: nil)
    new_record? ? sneaky_create(avoid_insert_conflict: avoid_insert_conflict) : sneaky_update
  end

  # Performs INSERT query without running any callbacks
  # @return [false, true]
  def sneaky_create(avoid_insert_conflict: nil)
    sneaky_attributes_without_id = sneaky_attributes_values
                                   .except { |key| key.name == "id" }

    column_keys = sneaky_attributes_without_id.keys.map(&:name).join(", ")
    dynamic_keys = sneaky_attributes_without_id.keys
                   .map { |key| ":#{key.name}" }
                   .join(", ")

    constraint = if avoid_insert_conflict.present?
                   "ON CONFLICT (#{[avoid_insert_conflict].flatten.join(', ')}) "\
                   "DO UPDATE SET (#{column_keys}) = (#{dynamic_keys})"
                 end

    sql = <<~SQL
      INSERT INTO #{self.class.table_name} ( #{column_keys} )
      VALUES (#{dynamic_keys})
      #{constraint}
      RETURNING *
    SQL

    mapping = generate_insert_mapping(sneaky_attributes_without_id)
    data = self.class.unscoped.find_by_sql([sql.squish, mapping.to_h]).first

    copy_internal(data, self, "@attributes")
    copy_internal(data, self, "@mutations_from_database")
    copy_internal(data, self, "@changed_attributes")
    copy_internal(data, self, "@new_record")
    copy_internal(data, self, "@destroyed")

    !!id
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

  def copy_internal(source, target, key)
    target.instance_variable_set(key, source.instance_variable_get(key))
  end

  def generate_insert_mapping(attributes)
    attributes.map do |definition, value|
      if definition.able_to_type_cast?
        result = definition.type_cast_for_database(value)
        if result.is_a?(Struct)
          if result.respond_to?(:encoder)
            [definition.name.to_sym, result.encoder.encode(value)]
          else
            raise RuntimeError.new('Unknown Type Casted Struct')
          end
        else
          [definition.name.to_sym, result]
        end
      else
        [definition.name.to_sym, value]
      end
    end
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
