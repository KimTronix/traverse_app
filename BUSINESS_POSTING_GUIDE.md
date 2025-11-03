# Business Owner Posting Guide

## Overview
Business owners in the Traverse app can post and manage their **places/businesses** and **events**. All data is stored in Supabase and filtered by `owner_id`.

---

## What Business Owners Can Post

### 1. Places/Businesses (Attractions) ✅
Already fully implemented in [BusinessDashboardScreen](lib/screens/business_dashboard_screen.dart)

**Categories:**
- Restaurants
- Hotels
- Activities
- Transport

**What they can do:**
- ✅ Add new business
- ✅ Edit business details
- ✅ Delete business
- ✅ View only THEIR businesses
- ✅ Track approval status (Pending/Approved/Rejected)

**Database Table:** `attractions`

**Fields:**
```dart
- name (required)
- category (restaurant/hotel/activity/transport)
- description (required)
- location (required)
- contact_phone
- contact_email
- website
- owner_id (automatically set to current user)
- status (pending/approved/rejected)
```

---

## How to Access Business Dashboard

### For Business Owners:

1. **Sign up as Business Owner:**
   - During signup, select **"Business Owner"** role
   - Create account

2. **Access Dashboard:**
   ```dart
   // Navigate to business dashboard
   Navigator.push(
     context,
     MaterialPageRoute(
       builder: (context) => BusinessDashboardScreen(),
     ),
   );
   ```

3. **Or add to routing:**
   ```dart
   // In main.dart routes
   if (userRole == 'business') {
     context.go('/business-dashboard');
   }
   ```

---

## Business Dashboard Features

### Current Features (Places/Attractions):

**Stats Overview:**
- Total businesses count
- Active (approved) count
- Pending (awaiting approval) count

**Category Tabs:**
- All
- Restaurants
- Hotels
- Activities
- Transport

**Search:**
- Search by name
- Search by description
- Search by location
- Real-time filtering

**CRUD Operations:**
- Create new business
- Edit existing business
- Delete business
- View business details

**Status Management:**
- New businesses: `status='pending'`
- Awaits admin approval
- Visual status badges:
  - 🟠 Pending
  - 🟢 Approved
  - 🔴 Rejected

---

## Adding a Business (Step-by-Step)

### 1. Click "Add Business" Button

### 2. Fill in the Form:
```
Business Name: My Restaurant
Category: Restaurants
Description: Amazing local cuisine with traditional dishes
Location: Harare, Zimbabwe
Phone Number: +263123456789
Email: info@myrestaurant.com
Website: https://myrestaurant.com
```

### 3. Submit:
- Click "Add"
- Business created with `status='pending'`
- Linked to your user via `owner_id`

### 4. Wait for Admin Approval:
- Admin reviews in admin dashboard
- Admin approves → `status='approved'`
- Business becomes visible to travelers

---

## Business Dashboard UI

### Stats Cards:
```
┌─────────┬─────────┬─────────┐
│  Total  │ Active  │ Pending │
│    5    │    3    │    2    │
└─────────┴─────────┴─────────┘
```

### Search Bar:
```
🔍 Search your businesses...
```

### Business Cards:
```
┌────────────────────────────────────┐
│ My Restaurant              [PENDING]│
│ Amazing local cuisine...            │
│ 📍 Harare, Zimbabwe    ⭐ 4.5 (23) │
│                                     │
│ [Edit]              [Delete]        │
└────────────────────────────────────┘
```

---

## Database Flow

### Creating a Business:
```
User clicks "Add Business"
    ↓
Fills in form
    ↓
Submits
    ↓
AttractionsService.addAttraction(
  name: "My Restaurant",
  category: "restaurant",
  ownerId: currentUserId,  ← Auto-set
  status: "pending"        ← Auto-set
)
    ↓
Saved to `attractions` table
    ↓
Appears in business dashboard
    ↓
Awaits admin approval
```

### Admin Approval:
```
Admin views pending attractions
    ↓
Reviews "My Restaurant"
    ↓
Clicks "Approve"
    ↓
UPDATE attractions
SET status='approved'
WHERE id=<attraction-id>
    ↓
Business visible to travelers
```

---

## Code References

### Business Dashboard:
- **File:** [lib/screens/business_dashboard_screen.dart](lib/screens/business_dashboard_screen.dart)
- **Service:** [lib/services/attractions_service.dart](lib/services/attractions_service.dart)

### Key Methods:

**Load Business Owner's Attractions:**
```dart
final attractions = await _attractionsService.getAttractionsByOwner(userId);
// Returns ONLY attractions where owner_id = userId
```

**Add New Attraction:**
```dart
await _attractionsService.addAttraction(
  name: name,
  category: category,
  description: description,
  location: location,
  ownerId: currentUserId,  // Required!
  contactPhone: phone,
  contactEmail: email,
  website: website,
);
```

**Update Attraction:**
```dart
await _attractionsService.updateAttraction(
  attractionId,
  {
    'name': newName,
    'description': newDescription,
    // ... other fields
  },
);
```

**Delete Attraction:**
```dart
await _attractionsService.deleteAttraction(attractionId);
```

---

## Database Security (RLS Policies)

### What Business Owners Can Do:

**✅ Can View:**
```sql
-- Only their own attractions
SELECT * FROM attractions
WHERE owner_id = auth.uid();
```

**✅ Can Create:**
```sql
-- Attractions linked to themselves
INSERT INTO attractions (owner_id, ...)
VALUES (auth.uid(), ...);
```

**✅ Can Update:**
```sql
-- Only their own attractions
UPDATE attractions
SET ...
WHERE owner_id = auth.uid();
```

**✅ Can Delete:**
```sql
-- Only their own attractions
DELETE FROM attractions
WHERE owner_id = auth.uid();
```

**❌ Cannot:**
- View other business owner's attractions
- Modify other business owner's attractions
- Approve their own attractions (admin only)
- See all attractions without owner_id filter

---

## Admin Dashboard (for approvals)

Admins can:
- View all pending attractions
- Approve attractions → `status='approved'`
- Reject attractions → `status='rejected'`
- View all attractions regardless of owner

**Admin SQL:**
```sql
-- View all pending attractions
SELECT * FROM attractions
WHERE status='pending'
ORDER BY created_at DESC;

-- Approve attraction
UPDATE attractions
SET status='approved'
WHERE id=<attraction-id>;
```

---

## Testing Business Posting

### 1. Sign Up as Business Owner:
```bash
flutter run

# Sign up:
- Email: business@test.com
- Password: Business123!
- Full Name: Business Owner
- Username: businessowner
- Role: business  ← Important!
```

### 2. Navigate to Business Dashboard:
```dart
// After login, navigate to:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BusinessDashboardScreen(),
  ),
);
```

### 3. Add a Business:
```
Click "Add Business"
Fill in form:
- Name: Test Restaurant
- Category: Restaurants
- Description: Great food
- Location: Harare
- Phone: +263123456789
- Email: test@restaurant.com

Click "Add"
```

### 4. Verify in Database:
```sql
-- Check in Supabase SQL Editor
SELECT
  id,
  name,
  category,
  owner_id,
  status,
  created_at
FROM attractions
WHERE owner_id = '<your-user-id>'
ORDER BY created_at DESC;
```

### 5. Check Status:
- Should see business in dashboard
- Status badge should show "PENDING"
- Only YOU can see it (filtered by owner_id)

---

## Empty States

### No Businesses Yet:
```
    🏪

No businesses yet

Add your first business to get started

    [Add Business]
```

### No Businesses in Category:
```
    🏪

No Restaurants yet

Add your first business to get started

    [Add Business]
```

---

## Troubleshooting

### Issue: "Can't see my business"
**Solution:** Check if you're logged in with the same account that created it

### Issue: "Business not showing to travelers"
**Cause:** Status is 'pending'
**Solution:** Wait for admin approval or check admin dashboard

### Issue: "Can't add business"
**Cause:** Not signed in or wrong role
**Solution:**
1. Sign in as business owner
2. Check userData['role'] == 'business'

### Issue: "Error creating business"
**Cause:** Missing required fields or RLS policy
**Solution:**
1. Check all required fields filled
2. Verify owner_id is set
3. Check RLS policies in Supabase

---

## Summary

Business owners have a **complete posting system** for managing their places:

✅ **Add** businesses (restaurants, hotels, activities, transport)
✅ **Edit** business details
✅ **Delete** businesses
✅ **View** only THEIR businesses (filtered by owner_id)
✅ **Track** approval status
✅ **Search** through their businesses
✅ **Categorize** businesses

**All data is:**
- ✅ Stored in Supabase `attractions` table
- ✅ Filtered by `owner_id` (secure)
- ✅ Subject to admin approval
- ✅ Real-time (no dummy data)

**Next Step:** Add **Events** posting functionality (bookings table) for business owners to post special events, tours, or experiences!