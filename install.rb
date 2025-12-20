require 'pathname'
require 'fileutils'

def system!(*args)
  system(*args, exception: true)
end

def link_if_needed(symlink, source)
  raise "Source file #{source} does not exist" unless File.exist?(source)

  if File.symlink?(symlink)
    current_target = File.readlink(symlink)
    if File.expand_path(current_target) == File.expand_path(source)
      puts "#{symlink} is already correctly symlinked, skipping"
    else
      puts "#{symlink} is symlinked to #{current_target} (expected: #{source})"
    end
  elsif File.exist?(symlink)
    puts "#{symlink} already exists and is not a symlink, skipping"
  else
    puts "Creating symlink for #{source}"
    system("ln -s #{source} #{symlink}")
  end
end

def install_links(items, source_dir, target_dir, prefix: '.')
  puts "Installing #{items.join(', ')}"
  items.each do |item|
    symlink = File.join(target_dir, "#{prefix}#{item}")
    source = File.join(source_dir, item)
    link_if_needed(symlink, source)
  end
  puts "\n"
end

home_path = Dir.home
script_dir = File.dirname(File.expand_path(__FILE__))
config_path = File.join(home_path, '.config')

# Dotfiles
dotfiles = %w[gitconfig gitignore_global zshrc zprofile gemrc]
install_links(dotfiles, script_dir, home_path)

# Config files
config_files = %w[Brewfile zsh]
install_links(config_files, script_dir, home_path, prefix: '')

# Starship config file
starship_source = File.join(script_dir, 'config', 'starship.toml')
starship_target = File.join(config_path, 'starship.toml')
link_if_needed(starship_target, starship_source)
puts "\n"

# Config directory files
configs = %w[atuin kitty nvim ghostty delta lazygit]
install_links(configs, File.join(script_dir, 'config'), config_path, prefix: '')

# Zed config files - symlink individual files
zed_config_dir = File.join(config_path, 'zed')
zed_source_dir = File.join(script_dir, 'config', 'zed')

if File.exist?(zed_source_dir)
  puts 'Installing Zed config files'

  # Ensure ~/.config/zed directory exists
  unless Dir.exist?(zed_config_dir)
    puts "Creating #{zed_config_dir} directory"
    FileUtils.mkdir_p(zed_config_dir)
  end

  # Symlink each file in the zed config directory
  Dir.glob(File.join(zed_source_dir, '*')).each do |source_file|
    next if File.directory?(source_file)

    filename = File.basename(source_file)
    target = File.join(zed_config_dir, filename)
    link_if_needed(target, source_file)
  end

  # Symlink theme files in zed/themes subdirectory
  zed_themes_source_dir = File.join(zed_source_dir, 'themes')
  if File.exist?(zed_themes_source_dir)
    zed_themes_target_dir = File.join(zed_config_dir, 'themes')
    unless Dir.exist?(zed_themes_target_dir)
      puts "Creating #{zed_themes_target_dir} directory"
      FileUtils.mkdir_p(zed_themes_target_dir)
    end

    Dir.glob(File.join(zed_themes_source_dir, '*')).each do |source_file|
      next if File.directory?(source_file)

      filename = File.basename(source_file)
      target = File.join(zed_themes_target_dir, filename)
      link_if_needed(target, source_file)
    end
  end
  puts "\n"
end

# Opencode config files - symlink individual files and subdirectories
opencode_config_dir = File.join(config_path, 'opencode')
opencode_source_dir = File.join(script_dir, 'config', 'opencode')

if File.exist?(opencode_source_dir)
  puts 'Installing Opencode config files'

  # Ensure ~/.config/opencode directory exists
  unless Dir.exist?(opencode_config_dir)
    puts "Creating #{opencode_config_dir} directory"
    FileUtils.mkdir_p(opencode_config_dir)
  end

  # Symlink each file and subdirectory in the opencode config directory
  Dir.glob(File.join(opencode_source_dir, '*')).each do |source_item|
    item_name = File.basename(source_item)
    target = File.join(opencode_config_dir, item_name)
    link_if_needed(target, source_item)
  end
  puts "\n"
end

# Amp config files - symlink command files
amp_config_dir = File.join(config_path, 'amp')
amp_commands_dir = File.join(amp_config_dir, 'commands')
amp_source_dir = File.join(script_dir, 'config', 'amp')
amp_commands_source_dir = File.join(amp_source_dir, 'commands')

if File.exist?(amp_source_dir)
  puts 'Installing Amp config files'

  # Ensure ~/.config/amp directory exists
  unless Dir.exist?(amp_config_dir)
    puts "Creating #{amp_config_dir} directory"
    FileUtils.mkdir_p(amp_config_dir)
  end

  # Copy settings.json if it exists (not symlinked since Amp modifies it)
  amp_settings_source = File.join(amp_source_dir, 'settings.json')
  if File.exist?(amp_settings_source)
    amp_settings_target = File.join(amp_config_dir, 'settings.json')
    if File.exist?(amp_settings_target)
      puts "#{amp_settings_target} already exists, skipping"
    else
      puts "Copying #{amp_settings_source} to #{amp_settings_target}"
      FileUtils.cp(amp_settings_source, amp_settings_target)
    end
  end

  # Symlink each file in the amp commands directory
  if File.exist?(amp_commands_source_dir)
    unless Dir.exist?(amp_commands_dir)
      puts "Creating #{amp_commands_dir} directory"
      FileUtils.mkdir_p(amp_commands_dir)
    end

    Dir.glob(File.join(amp_commands_source_dir, '*')).each do |source_file|
      next if File.directory?(source_file)

      filename = File.basename(source_file)
      target = File.join(amp_commands_dir, filename)
      link_if_needed(target, source_file)
    end
  end
  puts "\n"
end

# Skills - symlink to both Amp and Claude skills directories
skills_source_dir = File.join(script_dir, 'skills')
amp_skills_dir = File.join(config_path, 'amp', 'skills')
claude_skills_dir = File.join(home_path, '.claude', 'skills')

if File.exist?(skills_source_dir)
  puts 'Installing skills'

  # Ensure skills directories exist
  [amp_skills_dir, claude_skills_dir].each do |skills_dir|
    unless Dir.exist?(skills_dir)
      puts "Creating #{skills_dir} directory"
      FileUtils.mkdir_p(skills_dir)
    end
  end

  # Symlink each skill folder to both directories
  Dir.glob(File.join(skills_source_dir, '*')).each do |source_skill|
    next unless File.directory?(source_skill)

    skill_name = File.basename(source_skill)

    # Symlink to Amp skills directory
    amp_target = File.join(amp_skills_dir, skill_name)
    link_if_needed(amp_target, source_skill)

    # Symlink to Claude skills directory
    claude_target = File.join(claude_skills_dir, skill_name)
    link_if_needed(claude_target, source_skill)
  end
  puts "\n"
end

# Install mise if not already installed
unless system('which mise > /dev/null 2>&1')
  puts 'Installing mise...'
  system! 'curl https://mise.run | sh'
end

# Install Homebrew if not already installed
unless system('which brew > /dev/null 2>&1')
  puts 'Installing Homebrew...'
  system! '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
end

# reload shell before continuing (brew command will not exist without)
system! 'exec zsh -l'

system! 'brew bundle --no-upgrade' if ENV['BREW']
