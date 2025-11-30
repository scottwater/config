# frozen_string_literal: true

# Finds and removes broken symlinks in ~/.config and all subfolders

require 'find'

config_path = File.join(Dir.home, '.config')

unless Dir.exist?(config_path)
  puts "#{config_path} does not exist"
  exit 0
end

broken_symlinks = []

Find.find(config_path) do |path|
  broken_symlinks << path if File.symlink?(path) && !File.exist?(path)
end

if broken_symlinks.empty?
  puts "No broken symlinks found in #{config_path}"
  exit 0
end

puts "Found #{broken_symlinks.length} broken symlink(s):\n\n"

broken_symlinks.each do |symlink|
  target = File.readlink(symlink)
  puts "  #{symlink} -> #{target}"
end

print "\nRemove these symlinks? [y/N] "
response = gets&.strip&.downcase

if response == 'y'
  broken_symlinks.each do |symlink|
    File.unlink(symlink)
    puts "Removed #{symlink}"
  end
  puts "\nDone! Removed #{broken_symlinks.length} broken symlink(s)."
else
  puts 'Aborted.'
end
