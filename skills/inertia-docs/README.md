# Inertia.js Documentation Plugin

A comprehensive documentation plugin for Inertia.js with Ruby on Rails and React. This plugin provides quick reference documentation, code examples, best practices, and integration patterns for building server-driven single-page applications.

## Skills

### `inertia-reference`

Reference documentation for Inertia.js with Rails + React stack.

**Usage:**
```
/skill inertia-docs:inertia-reference
```

Or invoke the skill when working on Inertia-related tasks.

## Contents

The skill includes the following reference documents:

| Document | Description |
|----------|-------------|
| `API.md` | Complete API reference for Rails adapter and React components |
| `EXAMPLES.md` | Code examples for common patterns and use cases |
| `BEST-PRACTICES.md` | Recommended patterns, conventions, and performance tips |
| `INTEGRATION.md` | Rails + React integration patterns and project setup |

## Topics Covered

### Rails Adapter (inertia_rails)
- Controller methods (`render inertia:`, `inertia_share`, `inertia_config`)
- Global configuration options
- Deferred and lazy props
- Error handling

### React Adapter (@inertiajs/react)
- `createInertiaApp` setup
- `Link` component for navigation
- `Head` component for document head
- `usePage` hook for accessing page data
- `useForm` hook for form handling
- `Form` component for declarative forms
- `router` for programmatic navigation
- `Deferred` component for lazy-loaded data

### Patterns & Best Practices
- Authentication and authorization
- Form validation and error handling
- Partial reloads and performance optimization
- File uploads with progress tracking
- Flash messages and shared data
- Persistent layouts
- TypeScript integration

## Source Documentation

This plugin was generated from:
- [Inertia Rails Documentation](https://inertia-rails.dev/llms-full.txt)
- [Inertia.js Official Documentation](https://inertiajs.com/docs/v2/)

## Stack Focus

This documentation is specifically focused on:
- **Backend:** Ruby on Rails with `inertia_rails` gem
- **Frontend:** React with `@inertiajs/react`

Vue.js and Svelte examples have been intentionally excluded.
