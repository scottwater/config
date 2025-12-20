# Inertia.js Best Practices - Rails + React

## Controller Patterns

### Use a Base InertiaController

Create a dedicated base controller for Inertia responses:

```ruby
# app/controllers/inertia_controller.rb
class InertiaController < ApplicationController
  inertia_share(
    flash: -> { flash.to_hash },
    auth: -> { { user: current_user&.as_json(only: [:id, :name, :email]) } }
  )
end
```

### Keep Props Minimal

Only send data the component needs. Avoid sending entire ActiveRecord objects:

```ruby
# Bad - sends everything
render inertia: 'Users/Show', props: { user: @user }

# Good - explicit, minimal data
render inertia: 'Users/Show', props: {
  user: @user.as_json(only: [:id, :name, :email, :created_at])
}
```

### Use Lazy Props for Expensive Data

Wrap expensive operations in lambdas so they're only evaluated when needed:

```ruby
render inertia: 'Dashboard', props: {
  user: current_user,                    # Always evaluated
  stats: -> { Stats.expensive_query },   # Only when requested
  reports: -> { Report.generate_all }    # Only when requested
}
```

### Use Deferred Props for Non-Critical Data

Load secondary data after initial render for better perceived performance:

```ruby
render inertia: 'Posts/Show', props: {
  post: @post.as_json,                                    # Immediate
  comments: InertiaRails.defer { @post.comments.recent }, # After render
  related: InertiaRails.defer(group: 'sidebar') { @post.related }
}
```

---

## Component Patterns

### Type Your Props

Always define TypeScript interfaces for component props:

```tsx
interface User {
  id: number
  name: string
  email: string
}

interface Props {
  user: User
  can: {
    edit: boolean
    delete: boolean
  }
}

export default function Show({ user, can }: Props) {
  // ...
}
```

### Separate Concerns with Layouts

Use layouts for shared UI (navigation, flash messages), pages for content:

```tsx
// Layout handles chrome
function Layout({ children }: { children: ReactNode }) {
  return (
    <div>
      <Navigation />
      <FlashMessages />
      <main>{children}</main>
    </div>
  )
}

// Page focuses on content
function Dashboard({ stats }: Props) {
  return (
    <section>
      <h1>Dashboard</h1>
      <StatsGrid stats={stats} />
    </section>
  )
}

Dashboard.layout = (page: ReactNode) => <Layout>{page}</Layout>
```

### Handle Loading States

Show appropriate feedback during form submissions:

```tsx
const { post, processing } = useForm({ name: '' })

<button disabled={processing}>
  {processing ? 'Saving...' : 'Save'}
</button>
```

### Use Controlled Inputs with useForm

Let useForm manage all form state:

```tsx
const { data, setData, errors } = useForm({ name: '', email: '' })

<input
  value={data.name}
  onChange={e => setData('name', e.target.value)}
  className={errors.name ? 'error' : ''}
/>
{errors.name && <span>{errors.name}</span>}
```

---

## Navigation Patterns

### Prefer Link Over router.visit

Use `<Link>` for declarative navigation, `router` for programmatic:

```tsx
// Declarative - preferred for UI elements
<Link href="/users">Users</Link>

// Programmatic - for callbacks and conditional logic
const handleSuccess = () => {
  router.visit('/dashboard')
}
```

### Use Partial Reloads for Updates

Avoid full page loads when only some data changed:

```tsx
// Refresh only notifications
router.reload({ only: ['notifications'] })

// Refresh everything except user
router.reload({ except: ['user'] })
```

### Preserve State During Navigation

Keep component state when navigating to the same component:

```tsx
<Link href="/users?page=2" preserveState>
  Next Page
</Link>

// Or programmatically
router.get('/users', { page: 2 }, { preserveState: true })
```

### Handle Scroll Position

Control scroll behavior based on UX needs:

```tsx
// Keep scroll position (e.g., for inline updates)
<Link href="/users" preserveScroll>Refresh</Link>

// Scroll to top (default for new pages)
<Link href="/users/new">New User</Link>
```

---

## Form Patterns

### Reset Forms on Success

Clear sensitive data after submission:

```tsx
form.post('/login', {
  onSuccess: () => form.reset('password'),
})
```

### Use Transform for Data Manipulation

Modify data before sending without changing form state:

```tsx
const { data, setData, transform, post } = useForm({
  price: '10.00',
})

// Convert string to cents before sending
transform(data => ({
  ...data,
  price: Math.round(parseFloat(data.price) * 100),
}))
```

### Track Dirty State

Prevent unnecessary submissions:

```tsx
const { isDirty, put, processing } = useForm({ name: user.name })

<button disabled={processing || !isDirty}>
  Save Changes
</button>
```

### Handle File Uploads Properly

Inertia handles FormData conversion automatically:

```tsx
const { data, setData, post, progress } = useForm<{
  name: string
  avatar: File | null
}>({ name: '', avatar: null })

// Progress tracking is automatic
{progress && <progress value={progress.percentage} max="100" />}
```

---

## Error Handling

### Display Validation Errors Inline

Show errors next to the relevant fields:

```tsx
<input
  value={data.email}
  onChange={e => setData('email', e.target.value)}
  aria-invalid={!!errors.email}
  aria-describedby={errors.email ? 'email-error' : undefined}
/>
{errors.email && (
  <span id="email-error" role="alert">{errors.email}</span>
)}
```

### Handle Server Errors Gracefully

Create an error boundary for unexpected errors:

```ruby
# Rails controller
class ApplicationController < ActionController::Base
  rescue_from StandardError, with: :inertia_error_page

  private

  def inertia_error_page(exception)
    raise exception if Rails.env.local?
    status = ActionDispatch::ExceptionWrapper.new(nil, exception).status_code
    render inertia: 'Error', props: { status: status }, status: status
  end
end
```

### Handle CSRF Token Expiration

Redirect gracefully when tokens expire:

```ruby
class ApplicationController < ActionController::Base
  rescue_from ActionController::InvalidAuthenticityToken do
    redirect_back_or_to('/', notice: 'Session expired, please try again.')
  end
end
```

---

## Performance Patterns

### Code Split Large Pages

Use dynamic imports for large page components:

```tsx
// vite.config.ts - pages are auto-split
createInertiaApp({
  resolve: name => {
    const pages = import.meta.glob('./pages/**/*.tsx')
    return pages[`./pages/${name}.tsx`]() // Dynamic import
  },
})
```

### Avoid Over-Sharing

Only share data that's truly needed on every page:

```ruby
# Bad - shares everything always
inertia_share(
  user: -> { current_user },
  settings: -> { Settings.all },
  permissions: -> { Permission.all }
)

# Good - minimal shared data
inertia_share(
  auth: -> { { user: current_user&.slice(:id, :name) } },
  flash: -> { flash.to_hash }
)
```

### Use Memoization for Expensive Operations

Cache expensive computations in controllers:

```ruby
def index
  render inertia: 'Dashboard', props: {
    stats: -> { Rails.cache.fetch('stats', expires_in: 5.minutes) { Stats.calculate } }
  }
end
```

---

## Security Patterns

### Never Trust Client Data

Always validate and authorize on the server:

```ruby
def update
  @user = User.find(params[:id])
  authorize @user  # Policy-based authorization

  if @user.update(user_params)
    redirect_to @user
  else
    redirect_to edit_user_path(@user), inertia: { errors: @user.errors }
  end
end
```

### Pass Authorization as Props

Send authorization results, not rules:

```ruby
render inertia: 'Posts/Show', props: {
  post: @post.as_json,
  can: {
    edit: current_user&.can?(:edit, @post),
    delete: current_user&.can?(:delete, @post)
  }
}
```

### Sanitize User Input

Always sanitize before rendering:

```ruby
# In serializer or controller
{
  content: sanitize(@post.content),
  title: @post.title  # Plain text, no HTML
}
```

---

## Testing Patterns

### Test Controllers Like Standard Rails

Inertia controllers work with normal Rails testing:

```ruby
# spec/requests/users_spec.rb
RSpec.describe 'Users', type: :request do
  describe 'GET /users' do
    it 'returns users' do
      create_list(:user, 3)
      get users_path
      expect(response).to have_http_status(:ok)
    end
  end
end
```

### Test Inertia Props

Verify the data being sent to components:

```ruby
it 'includes user data' do
  user = create(:user)
  get user_path(user)

  expect(inertia.component).to eq('Users/Show')
  expect(inertia.props[:user][:id]).to eq(user.id)
end
```

### Test React Components in Isolation

Use React Testing Library for component tests:

```tsx
import { render, screen } from '@testing-library/react'
import UserCard from './UserCard'

test('displays user name', () => {
  render(<UserCard user={{ id: 1, name: 'John' }} />)
  expect(screen.getByText('John')).toBeInTheDocument()
})
```
