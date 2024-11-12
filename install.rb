require 'pathname'
home_path = Dir.home
script_dir = File.dirname(File.expand_path(__FILE__))

def link_if_needed(symlink, source)
  if File.symlink?(symlink)
    puts "#{symlink} is already a symlink"
    return
  elsif File.exist?(symlink)
    puts "#{symlink} already exists, skipping"
    return
  end

  puts "Creating symlink for #{source}"
  system("ln -s #{source} #{symlink}")
end

dots = %w[gitconfig gitignore_global zshrc zprofile gemrc]
puts "Installing dotfiles: #{dots.join(', ')}"

dots.each do |dot|
  symlink = File.join(home_path, ".#{dot}")
  source = File.join(script_dir, dot)
  link_if_needed(symlink, source)
end

puts "\n\n"

config_files = %w[Brewfile zsh]
puts "Installing config_files: #{config_files.join(', ')}"
config_files.each do |config|
  symlink = File.join(home_path, config)
  source = File.join(script_dir, config)
  raise "Source file #{source} does not exist" unless File.exist?(source)
  link_if_needed(symlink, source)
end

puts "\n\n"

configs = %w[atuin kitty mise nvim]
puts "Installing configs: #{configs.join(', ')}"
config_path = File.join(home_path, ".config")
configs.each do |config|
  symlink = File.join(config_path, config)
  source_path = File.join(script_dir, "config", config)
  link_if_needed(symlink, source_path)
end