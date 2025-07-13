require "pathname"

def system!(*args)
  system(*args, exception: true)
end

def link_if_needed(symlink, source)
  raise "Source file #{source} does not exist" unless File.exist?(source)

  if File.symlink?(symlink)
    puts "#{symlink} is already a symlink"
  elsif File.exist?(symlink)
    puts "#{symlink} already exists, skipping"
  else
    puts "Creating symlink for #{source}"
    system("ln -s #{source} #{symlink}")
  end
end

def install_links(items, source_dir, target_dir, prefix: ".")
  puts "Installing #{items.join(", ")}"
  items.each do |item|
    symlink = File.join(target_dir, "#{prefix}#{item}")
    source = File.join(source_dir, item)
    link_if_needed(symlink, source)
  end
  puts "\n"
end

home_path = Dir.home
script_dir = File.dirname(File.expand_path(__FILE__))
config_path = File.join(home_path, ".config")

# Dotfiles
dotfiles = %w[gitconfig gitignore_global zshrc zprofile gemrc]
install_links(dotfiles, script_dir, home_path)

# Config files
config_files = %w[Brewfile zsh]
install_links(config_files, script_dir, home_path, prefix: "")

# Starship config file
starship_source = File.join(script_dir, "config", "starship.toml")
starship_target = File.join(config_path, "starship.toml")
link_if_needed(starship_target, starship_source)
puts "\n"

# Config directory files
configs = %w[atuin kitty nvim ghostty]
install_links(configs, File.join(script_dir, "config"), config_path, prefix: "")

# Install Homebrew if not already installed
unless system("which brew > /dev/null 2>&1")
  puts "Installing Homebrew..."
  system! '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
end

system! "brew bundle --no-upgrade"