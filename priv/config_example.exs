# Censor Configuration Example
#
# This file shows how to configure Censor in your application.
# Copy this to your config/config.exs and modify as needed.

# Basic configuration
config :censor,
  # List of sensitive words (alternative to words_file)
  words: ["spam", "scam", "badword", "offensive"],
  
  # Path to words file (alternative to words)
  # words_file: "priv/sensitive_words.txt",
  
  # Enable automatic file reloading
  auto_reload: true,
  
  # Check interval for file changes (milliseconds)
  reload_interval: 5000,
  
  # Case sensitive matching
  case_sensitive: false,
  
  # Default replacement string
  replacement: "***",
  
  # Detection mode: :detect, :replace, :highlight
  detection_mode: :detect,
  
  # Cache TTL in seconds
  cache_ttl: 3600

# Environment-specific overrides

# Development
if Mix.env() == :dev do
  config :censor,
    words_file: "priv/sensitive_words_dev.txt",
    auto_reload: true,
    reload_interval: 1000
end

# Test
if Mix.env() == :test do
  config :censor,
    words: ["testbadword"],
    auto_reload: false
end

# Production
if Mix.env() == :prod do
  config :censor,
    words_file: System.get_env("CENSOR_WORDS_FILE", "priv/sensitive_words.txt"),
    auto_reload: System.get_env("CENSOR_AUTO_RELOAD", "false") == "true",
    case_sensitive: false,
    replacement: "***",
    cache_ttl: 7200
end
