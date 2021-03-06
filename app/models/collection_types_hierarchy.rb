class CollectionTypesHierarchy < SpeciesSchemaModel
  belongs_to :hierarchy
  belongs_to :collection_type
  set_primary_keys :collection_type_id, :hierarchy_id
  # This is only here to help specs load things to the right database.  Ignore it.
end

