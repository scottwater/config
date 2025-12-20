# Inertia.js Examples - Rails + React

## Basic Page Component

### Rails Controller
```ruby
# app/controllers/users_controller.rb
class UsersController < InertiaController
  def index
    render inertia: 'Users/Index', props: {
      users: User.all.map { |u| u.as_json(only: [:id, :name, :email]) }
    }
  end

  def show
    render inertia: 'Users/Show', props: {
      user: @user.as_json(only: [:id, :name, :email, :created_at])
    }
  end
end
```

### React Page
```tsx
// app/frontend/pages/Users/Index.tsx
import { Link, Head } from '@inertiajs/react'

interface User {
  id: number
  name: string
  email: string
}

interface Props {
  users: User[]
}

export default function Index({ users }: Props) {
  return (
    <>
      <Head title="Users" />
      <h1>Users</h1>
      <ul>
        {users.map(user => (
          <li key={user.id}>
            <Link href={`/users/${user.id}`}>{user.name}</Link>
          </li>
        ))}
      </ul>
      <Link href="/users/new">Create User</Link>
    </>
  )
}
```

---

## Form with useForm Hook

### Rails Controller
```ruby
# app/controllers/users_controller.rb
class UsersController < InertiaController
  def new
    render inertia: 'Users/New'
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to users_path, notice: 'User created successfully'
    else
      redirect_to new_user_path, inertia: { errors: @user.errors }
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password)
  end
end
```

### React Form Component
```tsx
// app/frontend/pages/Users/New.tsx
import { useForm, Head } from '@inertiajs/react'
import { FormEvent } from 'react'

export default function New() {
  const { data, setData, post, processing, errors, reset } = useForm({
    name: '',
    email: '',
    password: '',
  })

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault()
    post('/users', {
      preserveScroll: true,
      onSuccess: () => reset('password'),
    })
  }

  return (
    <>
      <Head title="Create User" />
      <h1>Create User</h1>
      <form onSubmit={handleSubmit}>
        <div>
          <label htmlFor="name">Name</label>
          <input
            id="name"
            type="text"
            value={data.name}
            onChange={e => setData('name', e.target.value)}
          />
          {errors.name && <span className="error">{errors.name}</span>}
        </div>

        <div>
          <label htmlFor="email">Email</label>
          <input
            id="email"
            type="email"
            value={data.email}
            onChange={e => setData('email', e.target.value)}
          />
          {errors.email && <span className="error">{errors.email}</span>}
        </div>

        <div>
          <label htmlFor="password">Password</label>
          <input
            id="password"
            type="password"
            value={data.password}
            onChange={e => setData('password', e.target.value)}
          />
          {errors.password && <span className="error">{errors.password}</span>}
        </div>

        <button type="submit" disabled={processing}>
          {processing ? 'Creating...' : 'Create User'}
        </button>
      </form>
    </>
  )
}
```

---

## Edit Form with Existing Data

### Rails Controller
```ruby
# app/controllers/users_controller.rb
class UsersController < InertiaController
  before_action :set_user, only: [:edit, :update]

  def edit
    render inertia: 'Users/Edit', props: {
      user: @user.as_json(only: [:id, :name, :email])
    }
  end

  def update
    if @user.update(user_params)
      redirect_to user_path(@user), notice: 'User updated'
    else
      redirect_to edit_user_path(@user), inertia: { errors: @user.errors }
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
```

### React Edit Component
```tsx
// app/frontend/pages/Users/Edit.tsx
import { useForm, Head, Link } from '@inertiajs/react'
import { FormEvent } from 'react'

interface User {
  id: number
  name: string
  email: string
}

interface Props {
  user: User
}

export default function Edit({ user }: Props) {
  const { data, setData, put, processing, errors, isDirty } = useForm({
    name: user.name,
    email: user.email,
  })

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault()
    put(`/users/${user.id}`)
  }

  return (
    <>
      <Head title={`Edit ${user.name}`} />
      <h1>Edit User</h1>
      <form onSubmit={handleSubmit}>
        <div>
          <label htmlFor="name">Name</label>
          <input
            id="name"
            type="text"
            value={data.name}
            onChange={e => setData('name', e.target.value)}
          />
          {errors.name && <span className="error">{errors.name}</span>}
        </div>

        <div>
          <label htmlFor="email">Email</label>
          <input
            id="email"
            type="email"
            value={data.email}
            onChange={e => setData('email', e.target.value)}
          />
          {errors.email && <span className="error">{errors.email}</span>}
        </div>

        <button type="submit" disabled={processing || !isDirty}>
          {processing ? 'Saving...' : 'Save Changes'}
        </button>
        <Link href={`/users/${user.id}`}>Cancel</Link>
      </form>
    </>
  )
}
```

---

## Delete with Confirmation

```tsx
import { router } from '@inertiajs/react'

interface Props {
  user: { id: number; name: string }
}

export default function Show({ user }: Props) {
  const handleDelete = () => {
    if (confirm(`Delete ${user.name}?`)) {
      router.delete(`/users/${user.id}`)
    }
  }

  return (
    <div>
      <h1>{user.name}</h1>
      <button onClick={handleDelete}>Delete User</button>
    </div>
  )
}
```

---

## File Upload

### Rails Controller
```ruby
class AvatarsController < InertiaController
  def update
    current_user.avatar.attach(params[:avatar])
    redirect_to settings_path, notice: 'Avatar updated'
  end
end
```

### React Component
```tsx
import { useForm } from '@inertiajs/react'
import { ChangeEvent, FormEvent } from 'react'

export default function AvatarUpload() {
  const { data, setData, post, progress, processing } = useForm<{
    avatar: File | null
  }>({
    avatar: null,
  })

  const handleFileChange = (e: ChangeEvent<HTMLInputElement>) => {
    if (e.target.files?.[0]) {
      setData('avatar', e.target.files[0])
    }
  }

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault()
    post('/avatar')
  }

  return (
    <form onSubmit={handleSubmit}>
      <input type="file" onChange={handleFileChange} accept="image/*" />

      {progress && (
        <progress value={progress.percentage} max="100">
          {progress.percentage}%
        </progress>
      )}

      <button type="submit" disabled={processing || !data.avatar}>
        Upload
      </button>
    </form>
  )
}
```

---

## Shared Data (Flash Messages)

### Rails Application Controller
```ruby
class ApplicationController < ActionController::Base
  inertia_share(
    flash: -> { flash.to_hash },
    auth: -> {
      {
        user: current_user&.as_json(only: [:id, :name, :email])
      }
    }
  )
end
```

### React Flash Component
```tsx
// app/frontend/components/FlashMessages.tsx
import { usePage } from '@inertiajs/react'
import { useEffect, useState } from 'react'

export default function FlashMessages() {
  const { flash } = usePage<{ flash: { notice?: string; alert?: string } }>().props
  const [visible, setVisible] = useState(false)

  useEffect(() => {
    if (flash.notice || flash.alert) {
      setVisible(true)
      const timer = setTimeout(() => setVisible(false), 3000)
      return () => clearTimeout(timer)
    }
  }, [flash])

  if (!visible) return null

  return (
    <div className="flash-messages">
      {flash.notice && <div className="flash-notice">{flash.notice}</div>}
      {flash.alert && <div className="flash-alert">{flash.alert}</div>}
    </div>
  )
}
```

---

## Partial Reloads

### Rails Controller
```ruby
class DashboardController < InertiaController
  def show
    render inertia: 'Dashboard', props: {
      stats: -> { Stats.calculate },
      notifications: -> { current_user.notifications.recent },
      user: current_user.as_json(only: [:id, :name])
    }
  end
end
```

### React Component with Partial Reload
```tsx
import { router, usePage } from '@inertiajs/react'

interface Props {
  stats: { visits: number; sales: number }
  notifications: Array<{ id: number; message: string }>
}

export default function Dashboard({ stats, notifications }: Props) {
  const refreshNotifications = () => {
    router.reload({ only: ['notifications'] })
  }

  const refreshStats = () => {
    router.reload({ only: ['stats'] })
  }

  return (
    <div>
      <section>
        <h2>Stats</h2>
        <p>Visits: {stats.visits}</p>
        <p>Sales: {stats.sales}</p>
        <button onClick={refreshStats}>Refresh Stats</button>
      </section>

      <section>
        <h2>Notifications</h2>
        <ul>
          {notifications.map(n => (
            <li key={n.id}>{n.message}</li>
          ))}
        </ul>
        <button onClick={refreshNotifications}>Refresh</button>
      </section>
    </div>
  )
}
```

---

## Deferred Props

### Rails Controller
```ruby
class ReportsController < InertiaController
  def show
    render inertia: 'Reports/Show', props: {
      report: @report.as_json,
      # Deferred - loaded after initial render
      analytics: InertiaRails.defer { Analytics.calculate(@report) },
      recommendations: InertiaRails.defer(group: 'insights') {
        Recommendations.for(@report)
      }
    }
  end
end
```

### React Component
```tsx
import { Deferred } from '@inertiajs/react'

interface Props {
  report: { id: number; title: string }
}

export default function Show({ report }: Props) {
  return (
    <div>
      <h1>{report.title}</h1>

      <Deferred data="analytics" fallback={<div>Loading analytics...</div>}>
        {(analytics) => (
          <div>
            <h2>Analytics</h2>
            <p>Views: {analytics.views}</p>
          </div>
        )}
      </Deferred>

      <Deferred data="recommendations" fallback={<div>Loading recommendations...</div>}>
        {(recommendations) => (
          <ul>
            {recommendations.map((r: { id: number; text: string }) => (
              <li key={r.id}>{r.text}</li>
            ))}
          </ul>
        )}
      </Deferred>
    </div>
  )
}
```

---

## Authorization in Props

### Rails Controller
```ruby
class PostsController < InertiaController
  def index
    render inertia: 'Posts/Index', props: {
      can: {
        create: current_user&.can?(:create, Post)
      },
      posts: Post.published.map do |post|
        post.as_json(only: [:id, :title, :excerpt]).merge(
          can: {
            edit: current_user&.can?(:edit, post),
            delete: current_user&.can?(:delete, post)
          }
        )
      end
    }
  end
end
```

### React Component
```tsx
import { Link } from '@inertiajs/react'

interface Post {
  id: number
  title: string
  excerpt: string
  can: { edit: boolean; delete: boolean }
}

interface Props {
  can: { create: boolean }
  posts: Post[]
}

export default function Index({ can, posts }: Props) {
  return (
    <div>
      <h1>Posts</h1>
      {can.create && <Link href="/posts/new">New Post</Link>}

      {posts.map(post => (
        <article key={post.id}>
          <h2>{post.title}</h2>
          <p>{post.excerpt}</p>
          {post.can.edit && <Link href={`/posts/${post.id}/edit`}>Edit</Link>}
          {post.can.delete && <DeleteButton postId={post.id} />}
        </article>
      ))}
    </div>
  )
}
```

---

## Persistent Layout

### Layout Component
```tsx
// app/frontend/layouts/PersistentLayout.tsx
import { Link, usePage } from '@inertiajs/react'
import { ReactNode } from 'react'
import FlashMessages from '@/components/FlashMessages'

interface Props {
  children: ReactNode
}

export default function PersistentLayout({ children }: Props) {
  const { auth } = usePage<{ auth: { user: { name: string } | null } }>().props

  return (
    <div className="layout">
      <nav>
        <Link href="/">Home</Link>
        <Link href="/dashboard">Dashboard</Link>
        {auth.user ? (
          <Link href="/logout" method="post" as="button">Logout</Link>
        ) : (
          <Link href="/login">Login</Link>
        )}
      </nav>

      <FlashMessages />

      <main>{children}</main>
    </div>
  )
}
```

### Page with Layout
```tsx
// app/frontend/pages/Dashboard.tsx
import PersistentLayout from '@/layouts/PersistentLayout'

function Dashboard() {
  return <h1>Dashboard</h1>
}

Dashboard.layout = (page: ReactNode) => (
  <PersistentLayout>{page}</PersistentLayout>
)

export default Dashboard
```

---

## Search with Debounce

```tsx
import { router } from '@inertiajs/react'
import { useState, useEffect } from 'react'

interface Props {
  users: Array<{ id: number; name: string }>
  filters: { search: string }
}

export default function Index({ users, filters }: Props) {
  const [search, setSearch] = useState(filters.search || '')

  useEffect(() => {
    const timeout = setTimeout(() => {
      router.get('/users', { search }, {
        preserveState: true,
        preserveScroll: true,
        replace: true,
      })
    }, 300)

    return () => clearTimeout(timeout)
  }, [search])

  return (
    <div>
      <input
        type="text"
        value={search}
        onChange={e => setSearch(e.target.value)}
        placeholder="Search users..."
      />
      <ul>
        {users.map(user => (
          <li key={user.id}>{user.name}</li>
        ))}
      </ul>
    </div>
  )
}
```
