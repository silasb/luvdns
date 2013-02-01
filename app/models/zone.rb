class Zone
  def initialize(id, zone)

    domain = Domain.find_or_create(name: id)

    domain.records_dataset.delete

    zone.each do |type, records|
      records.each do |record|

        new_record = Record.new({type: type, domain_id: domain.id}.merge(record))

        new_record.save
      end
    end
  end
end
