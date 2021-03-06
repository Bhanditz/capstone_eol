class ResourceStatus < SpeciesSchemaModel
  CACHE_ALL_ROWS = true
  uses_translations
  has_many :resources

  def self.being_processed
    cached_find_translated(:label, 'Being Processed')
  end

  def self.force_harvest
    cached_find_translated(:label, 'Force Harvest')
  end

  def self.moved_to_content_server
    cached_find_translated(:label, 'Moved to Content Server')
  end

  def self.processed
    cached_find_translated(:label, 'Processed')
  end

  def self.processing_failed
    cached_find_translated(:label, 'Processing Failed')
  end

  def self.uploading
    cached_find_translated(:label, 'Uploading')
  end

  def self.uploaded
    cached_find_translated(:label, 'Uploaded')
  end

  def self.upload_failed
    cached_find_translated(:label, 'Upload Failed')
  end

  def self.validated
    cached_find_translated(:label, 'Validated')
  end

  def self.validation_failed
    cached_find_translated(:label, 'Validation Failed')
  end

  # TODO: Remove the statuses published, publish pending and unpublish pending once migration
  # (20111014173215) has been executed to move ResourceStatus.publish_pending to
  # HarvestEvent.publish = true. ResourceStatus.publish is to be replaced by inferring from
  # HarvestEvent.published_at for the latest harvest event. ResourceStatus.unpublish_pending does
  # not currently do anything.
  def self.published
    cached_find_translated(:label, 'Published')
  end
  def self.publish_pending
    cached_find_translated(:label, 'Publish Pending')
  end
  def self.unpublish_pending
    cached_find_translated(:label, 'Unpublish Pending')
  end

end
