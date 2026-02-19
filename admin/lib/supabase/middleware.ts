import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

type CookieToSet = {
  name: string
  value: string
  options?: Record<string, unknown>
}

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({
    request,
  })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet: CookieToSet[]) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value))
          supabaseResponse = NextResponse.next({
            request,
          })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  const {
    data: { user },
  } = await supabase.auth.getUser()

  const protectedPaths = ['/', '/orders', '/agents', '/apps', '/records']
  const isProtectedPath = protectedPaths.some(path => 
    request.nextUrl.pathname === path || request.nextUrl.pathname.startsWith(path + '/')
  )

  const isApiRoute = request.nextUrl.pathname.startsWith('/api/')
  const publicApiRoutes = [
    '/api/health',
    '/api/v1/auth',
    '/api/v1/order',        // External app creates orders
    '/api/v1/records',      // Agent posts records
    '/api/v1/agents',       // Agent registration
    '/api/v1/agent/prepare', // Agent prepare
    '/api/v1/apps',         // App management (dev mode)
    '/api/v1/app',          // App detail/update (dev mode)
  ]
  const isPublicApi = publicApiRoutes.some(path => 
    request.nextUrl.pathname === path || request.nextUrl.pathname.startsWith(path)
  )
  
  // Agent API routes (authenticated by ticket/uid, not user session)
  const agentApiPatterns = [
    /^\/api\/v1\/agent\/[^/]+\/heartbeat$/,
    /^\/api\/v1\/agent\/[^/]+$/,
  ]
  const isAgentApi = agentApiPatterns.some(pattern => pattern.test(request.nextUrl.pathname))

  if (!user && isProtectedPath) {
    const url = request.nextUrl.clone()
    url.pathname = '/login'
    return NextResponse.redirect(url)
  }

  if (!user && isApiRoute && !isPublicApi && !isAgentApi) {
    return NextResponse.json(
      { error: 'Unauthorized', message: 'Authentication required' },
      { status: 401 }
    )
  }

  if (user && request.nextUrl.pathname === '/login') {
    const url = request.nextUrl.clone()
    url.pathname = '/'
    return NextResponse.redirect(url)
  }

  return supabaseResponse
}
