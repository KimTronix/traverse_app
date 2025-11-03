# Attractions Table Setup Guide

## Overview
This guide explains how to set up the `attractions` table in your Supabase database to enable full CRUD functionality for business owners.

## What is the Attractions Table?
The attractions table stores:
- **Places**: Restaurants, Hotels, Activities, Transport services
- **Events**: Events created by business owners
- **Other Attractions**: Historical sites, nature spots, entertainment venues, etc.

## Features
- ✅ **Business Owner CRUD**: Create, Read, Update, Delete their own attractions
- ✅ **Admin Management**: Admins can manage all attractions
- ✅ **Approval Workflow**: New attractions start as 'pending' and require admin approval
- ✅ **Row Level Security**: Automatic filtering by owner_id
- ✅ **Full-text Search**: Indexed search on name and location
- ✅ **Status Tracking**: pending → approved → active/inactive

## Database Schema

### Table Structure
```sql
attractions (
    id UUID PRIMARY KEY,
    owner_id UUID → references users(id),
    name TEXT,
    category TEXT (restaurant, hotel, activity, transport, event, etc.),
    description TEXT,
    location TEXT,
    address TEXT,
    latitude DOUBLE,
    longitude DOUBLE,
    contact_email TEXT,
    contact_phone TEXT,
    website TEXT,
    images TEXT[],
    opening_hours JSONB,
    entry_fee DOUBLE,
    currency TEXT,
    rating DOUBLE DEFAULT 0.0,
    review_count INTEGER DEFAULT 0,
    status TEXT (pending, approved, rejected, inactive),
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
```

## Setup Instructions

### Step 1: Deploy to Supabase

**Option A: Using Supabase Dashboard (Recommended)**
1. Go to your Supabase project dashboard
2. Click on **SQL Editor** in the left sidebar
3. Click **New Query**
4. Copy the entire contents of `supabase_attractions_table.sql`
5. Paste into the SQL editor
6. Click **Run** (bottom right)
7. You should see "Success. No rows returned"

**Option B: Using Supabase CLI**
```bash
# If you have Supabase CLI installed
supabase db push supabase_attractions_table.sql
```

### Step 2: Verify Table Creation

Run this query in SQL Editor to verify:
```sql
SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'attractions'
ORDER BY ordinal_position;
```

You should see all 20+ columns listed.

### Step 3: Verify RLS Policies

Run this query to check Row Level Security policies:
```sql
SELECT
    tablename,
    policyname,
    permissive,
    cmd
FROM pg_policies
WHERE tablename = 'attractions';
```

You should see 8 policies:
- ✅ Users can view approved attractions
- ✅ Business owners can insert attractions
- ✅ Business owners can update own attractions
- ✅ Business owners can delete own attractions
- ✅ Admins can view all attractions
- ✅ Admins can update any attraction
- ✅ Admins can delete any attraction

### Step 4: Test the Table

**Insert a test attraction:**
```sql
INSERT INTO attractions (
    owner_id,
    name,
    category,
    description,
    location,
    status
) VALUES (
    'YOUR_USER_ID_HERE',  -- Replace with actual user ID
    'Test Restaurant',
    'restaurant',
    'A great place to eat',
    'Harare, Zimbabwe',
    'pending'
);
```

**Query it back:**
```sql
SELECT * FROM attractions;
```

## How It Works in the App

### For Business Owners

1. **Login** with role='business'
2. **Automatically redirected** to Business Dashboard (`/business-dashboard`)
3. **View their attractions** - Filtered by owner_id automatically
4. **Add New Attraction**:
   - Click "Add Business" floating button
   - Fill in: Name, Category, Description, Location, Contact info
   - Submit → Status = 'pending' (awaits admin approval)
5. **Edit Attraction**: Click "Edit" button on any card
6. **Delete Attraction**: Click "Delete" button (with confirmation)

### For Admins

Admins can:
- View ALL attractions (regardless of owner)
- Approve/Reject pending attractions
- Change status: pending → approved → active/inactive
- Edit any attraction
- Delete any attraction

### For Regular Users (Travelers)

Regular users can:
- View ONLY approved attractions
- Cannot create, edit, or delete
- Can search and filter attractions
- Can view attraction details

## Categories Supported

The business dashboard currently uses:
- **restaurant** - Restaurants & Dining
- **hotel** - Hotels & Accommodation
- **activity** - Activities & Tours
- **transport** - Transport Services
- **event** - Events & Happenings

Additional categories available in the schema:
- food, culture, sites, game_parks, recreation, nature, shopping, entertainment, religious, historical, other

## Status Workflow

```
New Attraction Created
        ↓
    [pending] ← Awaiting admin review
        ↓
Admin Reviews
        ↓
    [approved] ← Visible to all users
        ↓
Owner manages
        ↓
    [active/inactive] ← Toggle visibility
```

## API Examples

The Flutter app uses `AttractionsService` which provides:

```dart
// CREATE
await AttractionsService.instance.addAttraction(
  name: 'My Restaurant',
  category: 'restaurant',
  description: 'Great food',
  location: 'Harare',
  ownerId: currentUserId,
);

// READ (business owner's attractions)
final myAttractions = await AttractionsService.instance
    .getAttractionsByOwner(currentUserId);

// UPDATE
await AttractionsService.instance.updateAttraction(
  attractionId,
  {'name': 'Updated Name', 'description': 'New description'}
);

// DELETE
await AttractionsService.instance.deleteAttraction(attractionId);
```

## Security Features

### Row Level Security (RLS)
- ✅ Business owners can ONLY see/edit/delete their own attractions
- ✅ Users can ONLY see approved attractions
- ✅ Admins can see and manage ALL attractions
- ✅ Anonymous users cannot access the table

### Data Validation
- ✅ Category must be from predefined list
- ✅ Status must be: pending, approved, rejected, or inactive
- ✅ Owner_id must reference valid user
- ✅ Required fields: name, category, description, location

## Troubleshooting

### Error: "new row violates row-level security policy"
**Solution**: Make sure the `owner_id` matches the authenticated user's ID.

### Error: "relation 'attractions' does not exist"
**Solution**: Run the SQL schema file again in Supabase SQL Editor.

### Attractions not showing in app
**Solution**: Check the status field - only 'approved' attractions are visible to regular users.

### Business owner can't see their attractions
**Solution**: Verify `owner_id` matches their user ID. Check RLS policies are enabled.

## Next Steps

1. ✅ Run `supabase_attractions_table.sql` in Supabase Dashboard
2. ✅ Fix Gradle cache issue and run the Flutter app
3. ✅ Sign up as business owner (role='business')
4. ✅ Test adding an attraction
5. ✅ Verify it appears in "Pending" status
6. ✅ (As admin) Approve the attraction
7. ✅ Verify it's now visible to all users

## Database Maintenance

### View all pending attractions (Admin query)
```sql
SELECT name, category, owner_id, created_at
FROM attractions
WHERE status = 'pending'
ORDER BY created_at DESC;
```

### Approve multiple attractions at once
```sql
UPDATE attractions
SET status = 'approved'
WHERE status = 'pending'
AND created_at > '2025-01-01';
```

### Count attractions by owner
```sql
SELECT
    u.full_name,
    u.email,
    COUNT(a.id) as attraction_count
FROM users u
LEFT JOIN attractions a ON a.owner_id = u.id
WHERE u.role = 'business'
GROUP BY u.id, u.full_name, u.email
ORDER BY attraction_count DESC;
```

---

**Need Help?** Check the Supabase logs in Dashboard → Database → Logs for detailed error messages.