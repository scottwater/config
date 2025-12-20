# Inertia.js Reference for Rails + React

Use this skill when working with Inertia.js in a Ruby on Rails application with React frontend. This provides comprehensive reference documentation for implementing server-driven single-page applications.

## When to Use

- Implementing Inertia page components in React
- Setting up forms with useForm hook or Form component
- Configuring Rails controllers to render Inertia responses
- Managing shared data and props
- Handling navigation with Link components or router
- Implementing partial reloads and deferred props
- Setting up authentication and authorization patterns
- Handling errors and validation

## Reference Documents

- **API.md** - Complete API reference for Rails adapter and React components
- **EXAMPLES.md** - Code examples for common patterns
- **BEST-PRACTICES.md** - Recommended patterns and conventions
- **INTEGRATION.md** - Rails + React integration patterns

## Quick Reference

### Rails Controller Response
```ruby
render inertia: 'Users/Index', props: { users: User.all }
```

### React Page Component
```jsx
export default function Index({ users }) {
  return <div>{users.map(u => <div key={u.id}>{u.name}</div>)}</div>
}
```

### Form Submission
```jsx
const form = useForm({ name: '', email: '' })
form.post('/users')
```

### Navigation
```jsx
<Link href="/users">Users</Link>
// or
router.visit('/users')
```
