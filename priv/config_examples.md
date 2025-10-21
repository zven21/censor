# Censor Configuration Examples

This directory contains configuration examples for Censor.

## Configuration Methods

### 1. Application Config (config/config.exs)

```elixir
# config/config.exs
config :censor,
  words: ["badword1", "badword2"],
  words_file: "priv/sensitive_words.txt",
  auto_reload: true,
  case_sensitive: false,
  replacement: "***",
  detection_mode: :detect,
  cache_ttl: 3600
```

### 2. Environment Variables

```bash
# Set words file
export CENSOR_WORDS_FILE="priv/sensitive_words.txt"

# Enable auto reload
export CENSOR_AUTO_RELOAD="true"

# Case sensitive matching
export CENSOR_CASE_SENSITIVE="false"

# Default replacement
export CENSOR_REPLACEMENT="***"

# Reload interval (milliseconds)
export CENSOR_RELOAD_INTERVAL="5000"

# Cache TTL (seconds)
export CENSOR_CACHE_TTL="3600"
```

### 3. Runtime Options

```elixir
# Start with runtime options
Censor.start_link([
  words: ["badword1", "badword2"],
  auto_reload: true,
  case_sensitive: false
])
```

## Configuration Precedence

Configuration values are merged in the following order (later values override earlier ones):

1. Default values
2. Application config
3. Environment variables  
4. Runtime options

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `words` | `[String.t()]` | `[]` | List of sensitive words |
| `words_file` | `String.t()` | `nil` | Path to words file |
| `auto_reload` | `boolean()` | `false` | Enable file watching |
| `reload_interval` | `integer()` | `5000` | Check interval in ms |
| `case_sensitive` | `boolean()` | `false` | Case sensitive matching |
| `replacement` | `String.t()` | `"***"` | Default replacement string |
| `detection_mode` | `atom()` | `:detect` | Mode: `:detect`, `:replace`, `:highlight` |
| `cache_ttl` | `integer()` | `3600` | Cache TTL in seconds |

## Usage Examples

### Basic Setup

```elixir
# config/config.exs
config :censor,
  words: ["spam", "scam", "badword"]
```

### File-based Setup with Auto Reload

```elixir
# config/config.exs
config :censor,
  words_file: "priv/sensitive_words.txt",
  auto_reload: true,
  reload_interval: 3000
```

### Production Setup

```elixir
# config/prod.exs
config :censor,
  words_file: System.get_env("CENSOR_WORDS_FILE", "priv/sensitive_words.txt"),
  auto_reload: System.get_env("CENSOR_AUTO_RELOAD", "false") == "true",
  case_sensitive: false,
  replacement: "***",
  cache_ttl: 7200
```

### Development Setup

```elixir
# config/dev.exs
config :censor,
  words_file: "priv/sensitive_words_dev.txt",
  auto_reload: true,
  reload_interval: 1000
```

## Words File Format

The words file should contain one word per line:

```
# Comments start with #
# Empty lines are ignored

# English words
spam
scam
badword
offensive

# Chinese words
敏感词
违禁词
```

## Validation

Censor validates configuration on startup:

- `words` must be a list of strings
- `words_file` must be a valid file path (if provided)
- `reload_interval` must be a positive integer
- `cache_ttl` must be a positive integer
- `detection_mode` must be one of `[:detect, :replace, :highlight]`

Invalid configuration will log warnings and fall back to default values.
