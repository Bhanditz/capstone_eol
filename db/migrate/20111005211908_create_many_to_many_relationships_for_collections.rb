class CreateManyToManyRelationshipsForCollections < ActiveRecord::Migration
  def self.up
    create_table :collections_communities, :id => false do |t|
      t.integer :collection_id
      t.integer :community_id
    end
    create_table :collections_users, :id => false do |t|
      t.integer :collection_id
      t.integer :user_id
    end
    Collection.connection.execute("INSERT INTO collections_communities (collection_id, community_id)
                                   SELECT col.id, col.community_id
                                     FROM collections col WHERE col.community_id IS NOT NULL")
    Collection.connection.execute("INSERT INTO collections_users (collection_id, user_id)
                                   SELECT col.id, col.user_id FROM collections col
                                     WHERE col.user_id IS NOT NULL AND col.community_id IS NULL")
    remove_column :collections, :community_id
    remove_column :collections, :user_id
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
    # if you REALLY need to reverse this, you could *guess* at which value in each of the join tables to put as the
    # single user/community id on the collection entry.  ...but that would be expensive for me to write and the
    # chances that we'd need it are very low, so I don't think it's worth it until it becomes required.
  end
end
