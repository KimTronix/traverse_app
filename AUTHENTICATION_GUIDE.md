# Authentication Guide - How Passwords Work

## Important: Understanding Supabase Authentication

### 🔐 Where Passwords Are Stored

**Your app uses Supabase Auth**, which is the **correct and secure approach**. Here's how it works:

```
┌─────────────────────────────────────────────────┐
│  Supabase Auth (auth.users table)              │
│  - Stores: email, encrypted_password, id       │
│  - Managed by: Supabase (secure)                │
│  - You CAN'T see passwords (encrypted)          │
└─────────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────┐
│  Your Custom Users Table (public.users)         │
│  - Stores: id, email, username, full_name, role │
│  - NO password field (correct!)                 │
│  - Links to auth.users via id                   │
└─────────────────────────────────────────────────┘
```

### ✅ This is CORRECT!
- Passwords are stored in `auth.users` (encrypted by Supabase)
- Your custom `users` table does NOT store passwords
- This follows security best practices

---

## Why You're Getting "Invalid Credentials" Error

### Common Causes:

#### 1. **User Doesn't Exist in Supabase Auth**
You may have users in your `public.users` table but NOT in `auth.users`.

**Check in Supabase Dashboard:**
```
1. Go to: Authentication > Users
2. Look for your email address
3. If not there → User doesn't exist in auth
```

#### 2. **Wrong Password**
The password you're entering doesn't match what's stored in Supabase Auth.

#### 3. **Email Not Confirmed**
Supabase may require email confirmation before login (depends on settings).

---

## How to Fix the Login Issue

### Solution 1: Create a New User (Recommended)

**Step 1: Run the App**
```bash
flutter run
```

**Step 2: Sign Up (Create New Account)**
```dart
1. Click "Create Account" / "Sign Up"
2. Fill in the form:
   - Full Name: Test User
   - Username: testuser
   - Email: test@example.com
   - Password: Test123!
   - Role: traveler (or business/admin)
3. Click "Create Account"
```

**Step 3: What Happens:**
```
✅ User created in auth.users (with encrypted password)
✅ User profile created in public.users (with id, email, username, etc.)
✅ Both tables linked via id
```

**Step 4: Sign In**
```dart
1. Use the SAME email and password
2. Email: test@example.com
3. Password: Test123!
4. Click "Sign In"
```

---

### Solution 2: Check Existing Users in Supabase

**Go to Supabase Dashboard:**
```
1. Open: https://supabasekong-rwkgssg8css8s84occsk0c0k.xdots.co.zw
2. Navigate to: Authentication > Users
3. Check if your email exists
4. If exists, use the password you set during signup
```

---

### Solution 3: Reset Password (If User Exists)

If you forgot the password for an existing user:

**Option A: Use Supabase Dashboard**
```
1. Go to: Authentication > Users
2. Find the user
3. Click "..." menu
4. Select "Send password recovery email"
5. Check email for reset link
```

**Option B: Delete and Recreate**
```
1. Go to: Authentication > Users
2. Find the user
3. Click "..." menu
4. Delete user
5. Sign up again with same email
```

---

### Solution 4: Disable Email Confirmation (For Testing)

**In Supabase Dashboard:**
```
1. Go to: Authentication > Settings
2. Scroll to "Email Auth"
3. Toggle OFF "Enable email confirmations"
4. Save changes
5. Try signing up again
```

---

## How Authentication Works in Your App

### Sign Up Flow:
```
User enters email + password
    ↓
AuthService.signUpWithEmail() called
    ↓
Supabase Auth creates user in auth.users (encrypted password)
    ↓
User profile created in public.users (NO password)
    ↓
Success! User can now sign in
```

### Sign In Flow:
```
User enters email + password
    ↓
AuthService.signInWithEmail() called
    ↓
Supabase Auth checks auth.users (encrypted password)
    ↓
If valid → Returns user + session token
    ↓
Profile synced to public.users (if doesn't exist)
    ↓
Success! User is logged in
```

### Code Reference:

**Sign Up** ([lib/services/auth_service.dart:198-265](lib/services/auth_service.dart#L198-L265)):
```dart
static Future<AuthResponse> signUpWithEmail({
  required String email,
  required String password,
  required String fullName,
  required String username,
  String role = 'traveler',
}) async {
  // Create user in Supabase Auth (with encrypted password)
  final response = await _client.auth.signUp(
    email: email,
    password: password,
    data: {
      'full_name': fullName,
      'username': username,
      'role': role,
    },
  );

  // Create profile in public.users (NO password)
  if (response.user != null) {
    final userData = {
      'id': response.user!.id,
      'email': email,
      'full_name': fullName,
      'username': username,
      'role': role,
      'email_verified': response.user!.emailConfirmedAt != null,
      'is_active': true,
      'provider': 'email',
    };
    await _client.from('users').insert(userData);
  }

  return response;
}
```

**Sign In** ([lib/services/auth_service.dart:98-120](lib/services/auth_service.dart#L98-L120)):
```dart
static Future<AuthResponse> signInWithEmail(String email, String password) async {
  // Check auth.users for encrypted password
  final response = await _client.auth.signInWithPassword(
    email: email,
    password: password,
  );

  // Sync to public.users if needed
  if (response.user != null) {
    await _syncUserToDatabase(response.user!);
  }

  return response;
}
```

---

## Debugging Login Issues

### Check Auth Users:
```sql
-- Run in Supabase SQL Editor
SELECT
  id,
  email,
  email_confirmed_at,
  created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 10;
```

### Check Custom Users:
```sql
-- Run in Supabase SQL Editor
SELECT
  id,
  email,
  username,
  full_name,
  role,
  created_at
FROM public.users
ORDER BY created_at DESC
LIMIT 10;
```

### Check If User Exists in Both:
```sql
-- Run in Supabase SQL Editor
SELECT
  a.id,
  a.email AS auth_email,
  a.email_confirmed_at,
  u.email AS custom_email,
  u.username,
  u.full_name,
  u.role
FROM auth.users a
LEFT JOIN public.users u ON a.id = u.id
ORDER BY a.created_at DESC
LIMIT 10;
```

---

## Common Errors and Solutions

### Error: "Invalid email or password"
**Cause**: Wrong credentials or user doesn't exist in auth.users
**Solution**: Create new account or verify password

### Error: "Email not confirmed"
**Cause**: Email confirmation required but not done
**Solution**: Check email for confirmation link OR disable email confirmation in Supabase settings

### Error: "User already registered"
**Cause**: Trying to sign up with existing email
**Solution**: Use sign in instead, or reset password

### Error: "Failed to create user profile"
**Cause**: RLS policy preventing insert into public.users
**Solution**: Check RLS policies allow insert where auth.uid() = id

---

## Testing Checklist

### ✅ Test Sign Up:
```dart
1. Open app
2. Go to Sign Up screen
3. Enter:
   - Full Name: Test User
   - Username: testuser
   - Email: test@example.com
   - Password: Test123!
   - Role: traveler
4. Click "Create Account"
5. Check for success message
6. Verify in Supabase Dashboard:
   - Authentication > Users (should see test@example.com)
   - Table Editor > users (should see matching record)
```

### ✅ Test Sign In:
```dart
1. Open app
2. Go to Sign In screen
3. Enter:
   - Email: test@example.com
   - Password: Test123!
4. Click "Sign In"
5. Should redirect to home screen
6. Check AuthProvider has user data
```

### ✅ Test Wrong Password:
```dart
1. Go to Sign In screen
2. Enter:
   - Email: test@example.com
   - Password: WrongPassword123!
3. Click "Sign In"
4. Should show error: "Invalid email or password"
```

---

## Quick Fix Steps

**If you're stuck and just want to test:**

1. **Delete all test users:**
   - Go to Supabase Dashboard
   - Authentication > Users
   - Delete all test users

2. **Run the app:**
   ```bash
   flutter run
   ```

3. **Sign up a fresh user:**
   - Email: demo@traverse.app
   - Password: Demo123!
   - Full Name: Demo User
   - Username: demouser
   - Role: traveler

4. **Sign in immediately:**
   - Email: demo@traverse.app
   - Password: Demo123!

5. **Success!** You should be logged in.

---

## Summary

### ✅ Passwords ARE stored (in auth.users)
- Encrypted by Supabase
- You can't see them (security!)
- Managed automatically

### ✅ Your custom users table does NOT have passwords
- This is correct!
- Only stores profile data
- Links to auth.users via id

### ✅ To fix login issues:
1. Create a new account (sign up)
2. Use the exact email and password
3. Or check existing users in Supabase Dashboard

### ✅ Your authentication is properly configured
- Real Supabase Auth ✅
- Automatic profile creation ✅
- Secure password handling ✅

**No bugs in your code - just need to create users through the sign-up flow!** 🎉