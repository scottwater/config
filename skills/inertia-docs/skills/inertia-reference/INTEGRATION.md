# Inertia.js Integration - Rails + React

## Project Setup

### Required Gems

```ruby
# Gemfile
gem 'inertia_rails'
gem 'vite_rails'
```

### Required NPM Packages

```json
{
  "dependencies": {
    "@inertiajs/react": "^2.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  }
}
```

---

## Rails Configuration

### Inertia Initializer

```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  # Asset versioning - force full reload on asset changes
  config.version = ViteRuby.digest

  # Optional: Transform props to camelCase for JavaScript
  config.prop_transformer = ->(props:) {
    props.deep_transform_keys { |key| key.to_s.camelize(:lower) }
  }
end
```

### Application Layout

```erb
<%# app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= vite_client_tag %>
    <%= vite_stylesheet_tag 'application', data: { "turbo-track": "reload" } %>
    <%= vite_typescript_tag 'inertia' %>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
```

### Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Standard RESTful routes work with Inertia
  resources :users
  resources :posts do
    resources :comments, only: [:create, :destroy]
  end

  # Root route
  root 'dashboard#show'
end
```

---

## React Configuration

### Inertia Entry Point

```tsx
// app/frontend/entrypoints/inertia.ts
import { createInertiaApp } from '@inertiajs/react'
import { createRoot } from 'react-dom/client'
import { ReactNode } from 'react'
import PersistentLayout from '@/layouts/PersistentLayout'

createInertiaApp({
  // Page component resolution
  resolve: name => {
    const pages = import.meta.glob('../pages/**/*.tsx', { eager: true })
    const page = pages[`../pages/${name}.tsx`] as {
      default: { layout?: (page: ReactNode) => ReactNode }
    }

    // Apply default layout if none specified
    if (!page.default.layout) {
      page.default.layout = (p: ReactNode) => (
        <PersistentLayout>{p}</PersistentLayout>
      )
    }

    return page
  },

  // Mount the app
  setup({ el, App, props }) {
    createRoot(el).render(<App {...props} />)
  },

  // Optional: Title template
  title: title => (title ? `${title} - My App` : 'My App'),
})
```

### TypeScript Configuration

```json
// tsconfig.app.json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["app/frontend/*"]
    },
    "jsx": "react-jsx",
    "strict": true
  },
  "include": ["app/frontend/**/*"]
}
```

### Vite Configuration

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import RubyPlugin from 'vite-plugin-ruby'
import path from 'path'

export default defineConfig({
  plugins: [react(), RubyPlugin()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'app/frontend'),
    },
  },
})
```

---

## Directory Structure

```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── inertia_controller.rb      # Base controller for Inertia
│   └── users_controller.rb
├── frontend/
│   ├── components/
│   │   ├── ui/                    # shadcn/ui components
│   │   └── FlashMessages.tsx
│   ├── entrypoints/
│   │   └── inertia.ts             # Inertia app entry
│   ├── hooks/
│   │   └── useDebounce.ts
│   ├── layouts/
│   │   └── PersistentLayout.tsx
│   ├── pages/
│   │   ├── Dashboard.tsx
│   │   ├── Users/
│   │   │   ├── Index.tsx
│   │   │   ├── Show.tsx
│   │   │   ├── New.tsx
│   │   │   └── Edit.tsx
│   │   └── Error.tsx
│   └── lib/
│       └── utils.ts
├── models/
└── views/
    └── layouts/
        └── application.html.erb
```

---

## Controller Integration

### Base Inertia Controller

```ruby
# app/controllers/inertia_controller.rb
class InertiaController < ApplicationController
  # Share common data with all pages
  inertia_share(
    # Flash messages
    flash: -> { flash.to_hash },

    # Authentication state
    auth: -> {
      {
        user: current_user&.as_json(only: [:id, :name, :email]),
        signed_in: user_signed_in?
      }
    }
  )
end
```

### RESTful Controller Example

```ruby
# app/controllers/users_controller.rb
class UsersController < InertiaController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!, except: [:index, :show]

  def index
    render inertia: 'Users/Index', props: {
      users: User.all.map { |u| serialize_user(u) },
      can: { create: can?(:create, User) }
    }
  end

  def show
    render inertia: 'Users/Show', props: {
      user: serialize_user(@user, detailed: true),
      can: {
        edit: can?(:edit, @user),
        delete: can?(:delete, @user)
      }
    }
  end

  def new
    render inertia: 'Users/New'
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to @user, notice: 'User created successfully.'
    else
      redirect_to new_user_path, inertia: { errors: @user.errors }
    end
  end

  def edit
    render inertia: 'Users/Edit', props: {
      user: serialize_user(@user)
    }
  end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: 'User updated successfully.'
    else
      redirect_to edit_user_path(@user), inertia: { errors: @user.errors }
    end
  end

  def destroy
    @user.destroy
    redirect_to users_path, notice: 'User deleted.'
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def serialize_user(user, detailed: false)
    attrs = [:id, :name, :email]
    attrs += [:created_at, :updated_at] if detailed
    user.as_json(only: attrs)
  end
end
```

---

## Shared Types

Create shared TypeScript types for your application:

```typescript
// app/frontend/types/index.ts

// Shared page props (from inertia_share)
export interface SharedProps {
  flash: {
    notice?: string
    alert?: string
  }
  auth: {
    user: User | null
    signed_in: boolean
  }
}

// Common models
export interface User {
  id: number
  name: string
  email: string
  created_at?: string
  updated_at?: string
}

// Form error structure
export interface FormErrors {
  [key: string]: string
}

// Pagination
export interface PaginatedResponse<T> {
  data: T[]
  meta: {
    current_page: number
    total_pages: number
    total_count: number
  }
}
```

### Using Shared Types

```tsx
// app/frontend/pages/Users/Index.tsx
import { usePage } from '@inertiajs/react'
import type { SharedProps, User } from '@/types'

interface Props extends SharedProps {
  users: User[]
  can: { create: boolean }
}

export default function Index({ users, can }: Props) {
  const { auth } = usePage<SharedProps>().props

  return (
    <div>
      <h1>Users</h1>
      {auth.signed_in && can.create && (
        <Link href="/users/new">New User</Link>
      )}
      {/* ... */}
    </div>
  )
}
```

---

## Authentication Integration

### Session Controller

```ruby
# app/controllers/sessions_controller.rb
class SessionsController < InertiaController
  def new
    render inertia: 'Auth/Login'
  end

  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_path, notice: 'Logged in successfully.'
    else
      redirect_to login_path, inertia: {
        errors: { email: 'Invalid email or password' }
      }
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: 'Logged out.'
  end
end
```

### Login Page Component

```tsx
// app/frontend/pages/Auth/Login.tsx
import { useForm, Head, Link } from '@inertiajs/react'
import { FormEvent } from 'react'

export default function Login() {
  const { data, setData, post, processing, errors } = useForm({
    email: '',
    password: '',
    remember: false,
  })

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault()
    post('/login', {
      onSuccess: () => {
        // Redirect handled by server
      },
    })
  }

  return (
    <>
      <Head title="Login" />
      <form onSubmit={handleSubmit}>
        <div>
          <label htmlFor="email">Email</label>
          <input
            id="email"
            type="email"
            value={data.email}
            onChange={e => setData('email', e.target.value)}
          />
          {errors.email && <span>{errors.email}</span>}
        </div>

        <div>
          <label htmlFor="password">Password</label>
          <input
            id="password"
            type="password"
            value={data.password}
            onChange={e => setData('password', e.target.value)}
          />
        </div>

        <div>
          <label>
            <input
              type="checkbox"
              checked={data.remember}
              onChange={e => setData('remember', e.target.checked)}
            />
            Remember me
          </label>
        </div>

        <button type="submit" disabled={processing}>
          {processing ? 'Logging in...' : 'Login'}
        </button>

        <Link href="/register">Create account</Link>
        <Link href="/forgot-password">Forgot password?</Link>
      </form>
    </>
  )
}
```

---

## Error Page Integration

### Rails Error Handling

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  rescue_from StandardError, with: :inertia_error_page
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::InvalidAuthenticityToken, with: :session_expired

  private

  def inertia_error_page(exception)
    raise exception if Rails.env.local?

    status = ActionDispatch::ExceptionWrapper.new(nil, exception).status_code
    render inertia: 'Error', props: { status: status }, status: status
  end

  def not_found
    render inertia: 'Error', props: { status: 404 }, status: :not_found
  end

  def session_expired
    redirect_back_or_to root_path, alert: 'Session expired. Please try again.'
  end
end
```

### Error Page Component

```tsx
// app/frontend/pages/Error.tsx
import { Head, Link } from '@inertiajs/react'

interface Props {
  status: number
}

const messages: Record<number, { title: string; description: string }> = {
  404: {
    title: 'Page Not Found',
    description: "The page you're looking for doesn't exist.",
  },
  500: {
    title: 'Server Error',
    description: 'Something went wrong on our end.',
  },
  503: {
    title: 'Service Unavailable',
    description: "We're temporarily offline for maintenance.",
  },
}

export default function Error({ status }: Props) {
  const { title, description } = messages[status] || messages[500]

  return (
    <>
      <Head title={title} />
      <div className="error-page">
        <h1>{status}</h1>
        <h2>{title}</h2>
        <p>{description}</p>
        <Link href="/">Go Home</Link>
      </div>
    </>
  )
}

// No layout for error pages
Error.layout = (page: ReactNode) => page
```

---

## Testing Setup

### RSpec Configuration

```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  config.include InertiaRails::TestHelper, type: :request
end
```

### Request Spec Example

```ruby
# spec/requests/users_spec.rb
require 'rails_helper'

RSpec.describe 'Users', type: :request do
  describe 'GET /users' do
    it 'renders the Users/Index component' do
      get users_path

      expect(response).to have_http_status(:ok)
      expect(inertia.component).to eq('Users/Index')
    end

    it 'includes users in props' do
      users = create_list(:user, 3)
      get users_path

      expect(inertia.props[:users].length).to eq(3)
    end
  end

  describe 'POST /users' do
    context 'with valid params' do
      it 'creates user and redirects' do
        post users_path, params: {
          user: { name: 'John', email: 'john@example.com', password: 'password' }
        }

        expect(response).to redirect_to(user_path(User.last))
        expect(User.count).to eq(1)
      end
    end

    context 'with invalid params' do
      it 'returns validation errors' do
        post users_path, params: { user: { name: '', email: '' } }

        expect(response).to redirect_to(new_user_path)
        follow_redirect!
        expect(inertia.props[:errors]).to be_present
      end
    end
  end
end
```
