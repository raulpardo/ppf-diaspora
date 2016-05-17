desc "Start the server listenning from larva"
task :larva_thread => :environment do
     LarvaThread.new.perform
     puts "done."
end