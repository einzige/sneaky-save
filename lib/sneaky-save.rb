#--
# Copyright (c) 2011 {PartyEarth LLC}[http://partyearth.com]
# mailto:kgoslar@partyearth.com
#++
module SneakySave

  class NonEnumerableRange < Range
    undef :map
  end

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

    column_keys = sneaky_attributes_without_id.keys
                  .map { |key| "\"#{key.name}\"" } # to avoid conflicts with column names
                  .join(", ")

    dynamic_keys = sneaky_attributes_without_id.keys
                   .map { |key| ":#{key.name}" }
                   .join(", ")

    constraint = generate_constraint(
      avoid_insert_conflict,
      column_keys,
      dynamic_keys
    )

    sql = <<~SQL
      INSERT INTO #{self.class.table_name} ( #{column_keys} )
      VALUES (#{dynamic_keys})
      #{constraint}
      RETURNING *
    SQL

    mapping = generate_insert_mapping(sneaky_attributes_without_id)
    data = self.class.unscoped.find_by_sql([sql.squish, mapping.to_h]).first

    # To trigger generation of @mutations_from_database variable
    # which is necessary for id_in_database
    data.send(:mutations_from_database)

    copy_internal(data, "@attributes")
    copy_internal(data, "@mutations_from_database")
    copy_internal(data, "@changed_attributes")
    copy_internal(data, "@new_record")
    copy_internal(data, "@destroyed")

    !!id
  end

  # Performs update query without running callbacks
  # @return [false, true]
  def sneaky_update
    return true if changes.empty?

    pk = self.class.primary_key
    original_id = changed_attributes.key?(pk) ? changes[pk].first : send(pk)

    changed_attributes = sneaky_update_fields

    !self.class.where(pk => original_id).
      update_all(changed_attributes).zero?
  end

  def copy_internal(source, key)
    instance_variable_set(key, source.instance_variable_get(key))
  end

  def generate_constraint(avoid_insert_conflict, column_keys, dynamic_keys)
    options = avoid_insert_conflict&.extract_options!
    return unless avoid_insert_conflict.present?

    on_conflict = "ON CONFLICT (#{[avoid_insert_conflict].flatten.join(', ')}) "
    if options&.dig(:where).present?
      on_conflict += "WHERE #{options[:where]} "
    end
    on_conflict += "DO UPDATE SET (#{column_keys}) = (#{dynamic_keys})"
    on_conflict
  end

  def generate_insert_mapping(attributes)
    attributes.map do |definition, value|
      if definition.able_to_type_cast?
        result = definition.type_cast_for_database(value)
        if result.is_a?(Struct)
          if result.respond_to?(:encoder)
            [definition.name.to_sym, quote(result.encoder.encode(value))]
          else
            raise RuntimeError.new('Unknown Type Casted Struct')
          end
        else
          [definition.name.to_sym, quote(result)]
        end
      else
        [definition.name.to_sym, quote(value)]
      end
    end
  end

  def sneaky_attributes_values
    attributes_for_create = send :attributes_for_create, attribute_names
    attributes_with_values = send :attributes_with_values, attributes_for_create
    attributes_with_values.each_with_object({}) do |attribute_value, hash|
      hash[self.class.arel_table[attribute_value[0]]] = attribute_value[1]
    end
  end

  def quote(value)
    # The built-in Sanitization of Rails does not handle time ranges very well. We work around this
    # by manipulating ranges so that they are not seen as iterable and will be properly handled by
    # ActiveRecord::Sanitization.quote_bound_value
    # https://github.com/rails/rails/issues/36682
    if value.is_a?(Range)
      # Ranges are frozen in Ruby 3. We construct a new Range that isn't enumerable.
      return NonEnumerableRange.new(value.first, value.end)
    end
    value
  end

  def sneaky_update_fields
    changes.keys.each_with_object({}) do |field, result|
      result[field] = read_attribute(field)
    end
  end

  def sneaky_connection
    self.class.connection
  end
end

ActiveRecord::Base.send :include, SneakySave
