class IndexSynonymIdOnTaxonConceptNames < EOL::DataMigration

  def self.up
    add_index :taxon_concept_names, :synonym_id, :name => 'index_taxon_concept_names_on_synonym_id'
  end

  def self.down
    remove_index :taxon_concept_names, :name => 'index_taxon_concept_names_on_synonym_id'
  end
end
