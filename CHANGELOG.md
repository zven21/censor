# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-27

### Added
- Initial release of Censor library
- High-performance DFA-based sensitive word filtering
- Multiple detection modes: detect, replace, highlight, extract
- Hot reload functionality for word lists
- Multi-language support (Chinese, English, etc.)
- Flexible configuration options
- Framework integrations:
  - Plug middleware for web applications
  - Absinthe middleware for GraphQL APIs
  - Ecto integration for database operations
- Comprehensive documentation and examples
- Performance benchmarks showing microsecond-level detection
- File-based word list loading with auto-reload
- Custom replacement strategies
- Case-sensitive/insensitive detection options

### Features
- **Performance**: DFA algorithm with O(n) time complexity
- **Hot Reload**: Update word lists without application restart
- **Multiple Modes**: Detect, replace, highlight, or extract sensitive words
- **Flexible Config**: Runtime options, environment variables, and application config
- **Framework Support**: Plug, Absinthe, and Ecto integrations
- **Multi-language**: Support for various character sets and languages

### Technical Details
- Built with Elixir/OTP for reliability and concurrency
- Uses Cachex for efficient caching
- File system monitoring for hot reload
- Comprehensive test coverage
- MIT licensed
