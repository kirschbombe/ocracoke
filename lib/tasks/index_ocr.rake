namespace :iiifsi do
  desc "Index all the OCR into Solr"
  task :index_ocr, [:resources_file] => :environment do |t, args|
    include DirectoryFileHelpers

    solr = RSolr.connect url: Rails.configuration.iiifsi['solr_url']

    resources_file = args[:resources_file]

    resources_file_json = File.read resources_file
    resource_documents = JSON.parse resources_file_json
    # iterate over each resource
    resource_documents.each do |resource_document|
      resource_document['images'].each do |image_identifier|
        text = File.read final_txt_filepath(image_identifier)
        # FIXME: For some reason the context field cannot have any dashes in it.
        # http://lucene.472066.n3.nabble.com/Suggester-Issue-td4285670.html
        # TODO: Could resource_context_field be multiValued so that we could either make suggestions based on a resource or based on a page image?
        resource_context_field = resource_document['resource'].gsub('-','_')
        # FIXME: Does suggest_txt need to match JSON word boundaries file?
        suggest_txt = text.split.map{|word| word.gsub(/[^a-zA-Z]/, "").downcase }
        suggest_txt = suggest_txt.uniq
        page = {
          id: image_identifier,
          resource: resource_document['resource'],
          resource_context_field: resource_context_field,
          txt: text,
          suggest_txt: suggest_txt
        }
        add = solr.add page
        puts "add #{image_identifier}: #{add}"
        # puts page
        # puts
      end
    end
    commit = solr.commit
    puts "commit: #{commit}"
  end
end
