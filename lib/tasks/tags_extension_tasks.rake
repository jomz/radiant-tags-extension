namespace :radiant do
  namespace :extensions do
    namespace :tags do
      
      desc "Runs the migration of the Tags extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          TagsExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          TagsExtension.migrator.migrate
        end
      end
      
      desc "Copy needed files to public dir"
      task :install => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        Dir[TagsExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(TagsExtension.root, '')
          directory = File.dirname(path)
          puts "Copying #{path}..."
          mkdir_p RAILS_ROOT + directory
          cp file, RAILS_ROOT + path
        end
      end
      
    end
  end
end