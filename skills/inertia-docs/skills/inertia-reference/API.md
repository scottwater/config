# Inertia.js API Reference - Rails + React

## Rails Adapter (inertia_rails gem)

### Controller Methods

#### `render inertia:`
Renders an Inertia response with component and props.

```ruby
render inertia: 'ComponentName', props: { key: value }

# With status code
render inertia: 'Users/Show', props: { user: @user }, status: :ok
```

#### `inertia_share`
Share data across all Inertia responses in a controller.

```ruby
class ApplicationController < ActionController::Base
  inertia_share(
    auth: -> { { user: current_user } },
    flash: -> { flash.to_hash },
  )
end
```

#### `inertia_config`
Configure Inertia settings at the controller level.

```ruby
class EventsController < ApplicationController
  inertia_config(
    version: "events-#{InertiaRails.configuration.version}",
    ssr_enabled: -> { action_name == "index" },
  )
end
```

### Global Configuration

Place in `config/initializers/inertia.rb`:

```ruby
InertiaRails.configure do |config|
  # Asset versioning (forces full page reload on asset changes)
  config.version = ViteRuby.digest
  config.version = -> { ViteRuby.digest }  # Lazy evaluation

  # Server-side rendering
  config.ssr_enabled = false
  config.ssr_url = "http://localhost:13714"

  # Props behavior
  config.deep_merge_shared_data = false
  config.default_render = false

  # History encryption
  config.encrypt_history = false

  # Always include errors hash (even when empty)
  config.always_include_errors_hash = nil

  # Custom component path resolution
  config.component_path_resolver = ->(path:, action:) { "#{path}/#{action}" }

  # Transform props (e.g., snake_case to camelCase)
  config.prop_transformer = ->(props:) {
    props.deep_transform_keys { |key| key.to_s.camelize(:lower) }
  }
end
```

### Configuration Options Table

| Option | Default | Description |
|--------|---------|-------------|
| `version` | `nil` | Asset version for cache busting |
| `ssr_enabled` | `false` | Enable server-side rendering |
| `ssr_url` | `"http://localhost:13714"` | SSR server URL |
| `deep_merge_shared_data` | `false` | Deep merge shared data with props |
| `default_render` | `false` | Render Inertia by default |
| `encrypt_history` | `false` | Encrypt page data in history |
| `always_include_errors_hash` | `nil` | Include empty errors object |
| `component_path_resolver` | Auto | Custom component resolution |
| `prop_transformer` | Identity | Transform props before sending |

### Deferred Props

Load data after initial page render:

```ruby
class UsersController < ApplicationController
  def index
    render inertia: 'Users/Index', props: {
      users: -> { User.all },  # Lazy evaluation
      permissions: InertiaRails.defer { Permission.all },
      teams: InertiaRails.defer(group: 'attributes') { Team.all },
    }
  end
end
```

---

## React Adapter (@inertiajs/react)

### createInertiaApp

Initialize the Inertia application:

```jsx
import { createInertiaApp } from '@inertiajs/react'
import { createRoot } from 'react-dom/client'

createInertiaApp({
  resolve: name => {
    const pages = import.meta.glob('./pages/**/*.tsx', { eager: true })
    return pages[`./pages/${name}.tsx`]
  },
  setup({ el, App, props }) {
    createRoot(el).render(<App {...props} />)
  },
  // Optional configuration
  title: title => `${title} - My App`,
  defaults: {
    form: {
      recentlySuccessfulDuration: 5000,
    },
    prefetch: {
      cacheFor: '1m',
      hoverDelay: 150,
    },
    visitOptions: (href, options) => ({
      headers: { ...options.headers, 'X-Custom': 'value' },
    }),
  },
})
```

### Link Component

```jsx
import { Link } from '@inertiajs/react'

// Basic link
<Link href="/users">Users</Link>

// With HTTP method
<Link href="/logout" method="post" as="button">Logout</Link>

// With data
<Link href="/users" method="post" data={{ name: 'John' }}>Create</Link>

// Preserve state/scroll
<Link href="/users" preserveState preserveScroll>Users</Link>

// Partial reloads
<Link href="/users" only={['users']}>Refresh Users</Link>
```

#### Link Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `href` | string | required | Target URL |
| `method` | string | `'get'` | HTTP method |
| `as` | string | `'a'` | HTML element to render |
| `data` | object | `{}` | Request data |
| `headers` | object | `{}` | Custom headers |
| `replace` | boolean | `false` | Replace history state |
| `preserveState` | boolean | `false` | Preserve component state |
| `preserveScroll` | boolean/string | `false` | Preserve scroll position |
| `only` | string[] | `[]` | Props to reload (partial) |
| `except` | string[] | `[]` | Props to exclude |

### Head Component

```jsx
import { Head } from '@inertiajs/react'

// Full head management
<Head>
  <title>Page Title</title>
  <meta name="description" content="Page description" />
</Head>

// Title shorthand
<Head title="Page Title" />
```

### usePage Hook

Access page data including props and shared data:

```jsx
import { usePage } from '@inertiajs/react'

function Component() {
  const { props, url, component } = usePage()
  const { auth, flash } = props

  return <div>Welcome, {auth.user.name}</div>
}
```

### useForm Hook

Form state management and submission:

```jsx
import { useForm } from '@inertiajs/react'

function CreateUser() {
  const { data, setData, post, processing, errors, reset } = useForm({
    name: '',
    email: '',
  })

  const submit = (e) => {
    e.preventDefault()
    post('/users', {
      preserveScroll: true,
      onSuccess: () => reset(),
    })
  }

  return (
    <form onSubmit={submit}>
      <input
        value={data.name}
        onChange={e => setData('name', e.target.value)}
      />
      {errors.name && <span>{errors.name}</span>}
      <button disabled={processing}>Create</button>
    </form>
  )
}
```

#### useForm Return Values

| Property | Type | Description |
|----------|------|-------------|
| `data` | object | Current form data |
| `setData` | function | Update form data |
| `errors` | object | Validation errors |
| `hasErrors` | boolean | Has validation errors |
| `processing` | boolean | Form is submitting |
| `progress` | object | Upload progress |
| `wasSuccessful` | boolean | Last submission succeeded |
| `recentlySuccessful` | boolean | Recently succeeded (5s) |
| `reset` | function | Reset form data |
| `clearErrors` | function | Clear validation errors |
| `setError` | function | Set validation error |
| `transform` | function | Transform data before submit |
| `defaults` | function | Update default values |
| `isDirty` | boolean | Data changed from defaults |
| `cancel` | function | Cancel submission |

#### useForm Methods

```jsx
// Submission methods
form.get(url, options)
form.post(url, options)
form.put(url, options)
form.patch(url, options)
form.delete(url, options)

// Error handling
form.setError('field', 'Error message')
form.setError({ foo: 'Error', bar: 'Error' })
form.clearErrors()
form.clearErrors('field')

// Reset
form.reset()
form.reset('field')
form.defaults({ name: 'New default' })
```

### Form Component

Declarative form handling:

```jsx
import { Form } from '@inertiajs/react'

<Form action="/users" method="post">
  {({ errors, processing }) => (
    <>
      <input type="text" name="name" />
      {errors.name && <span>{errors.name}</span>}
      <button disabled={processing}>Create</button>
    </>
  )}
</Form>
```

#### Form Props

| Prop | Type | Description |
|------|------|-------------|
| `action` | string | Form submission URL |
| `method` | string | HTTP method |
| `data` | object | Additional form data |
| `transform` | function | Transform data before submit |
| `preserveScroll` | boolean | Preserve scroll position |
| `preserveState` | boolean | Preserve component state |
| `resetOnSuccess` | boolean | Reset form on success |

### Router

Programmatic navigation:

```jsx
import { router } from '@inertiajs/react'

// Visit methods
router.visit(url, options)
router.get(url, data, options)
router.post(url, data, options)
router.put(url, data, options)
router.patch(url, data, options)
router.delete(url, options)
router.reload(options)

// Prop manipulation (no server request)
router.replaceProp('user.name', 'Jane')
router.appendToProp('messages', newMessage)
router.prependToProp('tags', 'urgent')
```

#### Router Visit Options

```jsx
router.visit(url, {
  method: 'get',
  data: {},
  replace: false,
  preserveState: false,
  preserveScroll: false,
  only: [],
  except: [],
  headers: {},
  errorBag: null,
  forceFormData: false,
  queryStringArrayFormat: 'brackets',
  async: false,
  showProgress: true,
  fresh: false,
  reset: [],
  preserveUrl: false,
  prefetch: false,
  // Callbacks
  onCancelToken: (token) => {},
  onCancel: () => {},
  onBefore: (visit) => {},
  onStart: (visit) => {},
  onProgress: (progress) => {},
  onSuccess: (page) => {},
  onError: (errors) => {},
  onFinish: (visit) => {},
})
```

### Event Listeners

```jsx
import { router } from '@inertiajs/react'

router.on('before', (event) => {
  // Return false to cancel navigation
  return confirm('Leave page?')
})

router.on('start', (event) => { /* Request started */ })
router.on('progress', (event) => { /* Upload progress */ })
router.on('success', (event) => { /* Navigation successful */ })
router.on('error', (errors) => { /* Validation errors */ })
router.on('invalid', (event) => { /* Non-Inertia response */ })
router.on('exception', (event) => { /* Unexpected error */ })
router.on('finish', (event) => { /* Request completed */ })
router.on('navigate', (event) => { /* Any navigation */ })
```

### Deferred Component

Handle deferred props on the client:

```jsx
import { Deferred } from '@inertiajs/react'

<Deferred data="permissions" fallback={<Loading />}>
  {permissions => (
    <ul>
      {permissions.map(p => <li key={p.id}>{p.name}</li>)}
    </ul>
  )}
</Deferred>
```
