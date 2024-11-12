require 'pathname'
home_path = Dir.home
script_dir = File.dirname(File.expand_path(__FILE__))

dots = %w[gitconfig gitignore_global zshrc zprofile gemrc]
puts "Installing dotfiles: #{dots.join(', ')}"

dots.each do |dot|
  symlink = File.join(home_path, ".#{dot}")
  if File.symlink?(symlink)
    puts "#{symlink} is already a symlink"
    next
  elsif File.exist?(symlink)
    puts "#{symlink} already exists, skipping"
  else
    puts "Creating symlink for #{dot}"
    dot_path = File.join(script_dir, dot)
    system("ln -s #{dot_path} #{symlink}")
  end
end

puts "\n\n"

config_files = %w[Brewfile]
puts "Installing config_files: #{config_files.join(', ')}"
config_files.each do |config|
  symlink = File.join(home_path, config)
  if File.symlink?(symlink)
    puts "#{symlink} is already a symlink"
    next
  elsif File.exist?(symlink)
    puts "#{symlink} already exists, skipping"
  else
    puts "Creating symlink for #{config}"
    config_path = File.join(script_dir, config)
    system("ln -s #{config_path} #{symlink}")
  end
end

puts "\n\n"

configs = %w[atuin kitty]
puts "Installing configs: #{configs.join(', ')}"
config_path = File.join(home_path, ".config")
configs.each do |config|
  symlink = File.join(config_path, config)
  if File.symlink?(symlink)
    puts "#{symlink} is already a symlink"
    next
  elsif File.exist?(symlink)
    puts "#{symlink} already exists, skipping"
  else
    puts "Creating symlink for #{config}"
    source_path = File.join(script_dir, "config", config)
    # system("ln -s #{source_path} #{symlink}")
    File.symlink(source_path, symlink)
  end
end