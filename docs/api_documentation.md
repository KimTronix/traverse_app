# Traverse Flutter App - Backend API Documentation

## Overview
This document outlines the current backend architecture, API endpoints, and data flow patterns in the Traverse Flutter application. The app uses Supabase as the primary backend service with real-time capabilities.

## Backend Architecture

### Core Services
1. **SupabaseService** - Main database operations and real-time subscriptions
2. **AuthService** - Authentication and user management
3. **UploadService** - File upload and storage management
4. **OpenAIService** - AI-powered travel recommendations
5. **StatisticsService** - Analytics and reporting
6. **ServiceProviderService** - Business service management
7. **AttractionsService** - Attraction and destination management
8. **ReportsService** - Data export and reporting
9. **ClaimsService** - Business claims and verification
10. **NavigationService** - App routing and navigation

### Database Tables
- `users` - User profiles and authentication data
- `destinations` - Travel destinations and locations
- `posts` - Social media posts and content
- `stories` - Temporary story content
- `bookings` - Travel bookings and reservations
- `user_interactions` - User engagement tracking
- `conversations` - Chat conversations
- `messages` - Chat messages
- `user_wallets` - User reward points and earnings
- `wallet_transactions` - Transaction history
- `user_visits` - Visit tracking for analytics
- `registered_places` - Business location registrations
- `service_providers` - Business service providers
- `user_statuses` - User status updates
- `status_likes` - Status interaction tracking

## API Endpoints

### Authentication Endpoints

#### Sign In with Email
- **Method**: POST
- **Service**: `SupabaseService.signInWithEmail()`
- **Parameters**: `email`, `password`
- **Returns**: `AuthResponse`

#### Sign Up with Email
- **Method**: POST
- **Service**: `SupabaseService.signUpWithEmail()`
- **Parameters**: `email`, `password`
- **Returns**: `AuthResponse`

#### Sign In with Google
- **Method**: POST
- **Service**: `AuthService.signInWithGoogle()`
- **Returns**: `User` object
- **Features**: Auto-creates user profile if new account

#### Sign Out
- **Method**: POST
- **Service**: `SupabaseService.signOut()`
- **Returns**: `void`

### User Management Endpoints

#### Get Users
- **Method**: GET
- **Service**: `SupabaseService.getUsers()`
- **Returns**: `List<Map<String, dynamic>>`
- **Ordering**: By creation date (newest first)

#### Get User by ID
- **Method**: GET
- **Service**: `SupabaseService.getUserById(userId)`
- **Parameters**: `userId`
- **Returns**: `Map<String, dynamic>?`

#### Insert User
- **Method**: POST
- **Service**: `SupabaseService.insertUser(user)`
- **Parameters**: `Map<String, dynamic> user`
- **Returns**: `bool`

#### Update User Profile
- **Method**: PUT
- **Service**: `SupabaseService.updateUserProfile(updates)`
- **Parameters**: `Map<String, dynamic> updates`
- **Returns**: `bool`
- **Authentication**: Required

### Destination Management Endpoints

#### Get Destinations
- **Method**: GET
- **Service**: `SupabaseService.getDestinations()`
- **Returns**: `List<Map<String, dynamic>>`
- **Fallback**: Sample data if database unavailable
- **Ordering**: By creation date (newest first)

#### Insert Destination
- **Method**: POST
- **Service**: `SupabaseService.insertDestination(destination)`
- **Parameters**: `Map<String, dynamic> destination`
- **Returns**: `bool`

#### Search Destinations
- **Method**: GET
- **Service**: `TravelProvider.searchDestinations(query)`
- **Parameters**: `String query`
- **Returns**: `List<Map<String, dynamic>>`
- **Features**: Local search by name, location, description

### Post Management Endpoints

#### Get Posts
- **Method**: GET
- **Service**: `SupabaseService.getPosts()`
- **Returns**: `List<Map<String, dynamic>>`
- **Fallback**: Sample data if database unavailable
- **Ordering**: By creation date (newest first)

#### Insert Post
- **Method**: POST
- **Service**: `SupabaseService.insertPost(post)`
- **Parameters**: `Map<String, dynamic> post`
- **Returns**: `bool`

#### Update Post
- **Method**: PUT
- **Service**: `SupabaseService.updatePost(postId, updates)`
- **Parameters**: `postId`, `Map<String, dynamic> updates`
- **Returns**: `bool`

### Story Management Endpoints

#### Get Stories
- **Method**: GET
- **Service**: `SupabaseService.getStories()`
- **Returns**: `List<Map<String, dynamic>>`
- **Fallback**: Sample data if database unavailable
- **Ordering**: By creation date (newest first)

#### Insert Story
- **Method**: POST
- **Service**: `SupabaseService.insertStory(story)`
- **Parameters**: `Map<String, dynamic> story`
- **Returns**: `bool`

### Booking Management Endpoints

#### Get Bookings
- **Method**: GET
- **Service**: `SupabaseService.getBookings()`
- **Returns**: `List<Map<String, dynamic>>`
- **Ordering**: By creation date (newest first)

#### Insert Booking
- **Method**: POST
- **Service**: `SupabaseService.insertBooking(booking)`
- **Parameters**: `Map<String, dynamic> booking`
- **Returns**: `bool`

### Messaging Endpoints

#### Get Messages
- **Method**: GET
- **Service**: `SupabaseService.getMessages(conversationId)`
- **Parameters**: `conversationId`
- **Returns**: `List<Map<String, dynamic>>`
- **Ordering**: By creation date (oldest first)

#### Insert Message
- **Method**: POST
- **Service**: `SupabaseService.insertMessage(message)`
- **Parameters**: `Map<String, dynamic> message`
- **Returns**: `bool`

#### Get Conversations
- **Method**: GET
- **Service**: `SupabaseService.getConversations(userId)`
- **Parameters**: `userId`
- **Returns**: `List<Map<String, dynamic>>`
- **Ordering**: By update date (newest first)

#### Create Conversation
- **Method**: POST
- **Service**: `SupabaseService.createConversation(conversationData)`
- **Parameters**: `Map<String, dynamic> conversationData`
- **Returns**: `void`

### File Upload Endpoints

#### Upload File
- **Method**: POST
- **Service**: `UploadService.uploadFile()`
- **Parameters**: `bucket`, `filePath`, `fileBytes`, `fileName?`, `metadata?`
- **Returns**: `String?` (public URL)
- **Authentication**: Required
- **Features**: User-specific paths, automatic filename generation

#### Upload Image File
- **Method**: POST
- **Service**: `UploadService.uploadImageFile()`
- **Parameters**: `bucket`, `imageFile`, `fileName?`
- **Returns**: `String?` (public URL)

#### Pick and Upload Image
- **Method**: POST
- **Service**: `UploadService.pickAndUploadImage()`
- **Parameters**: `bucket`, `source?`, `imageQuality?`
- **Returns**: `String?` (public URL)
- **Features**: Image picker integration, automatic compression

#### Upload Profile Image
- **Method**: POST
- **Service**: `SupabaseService.uploadProfileImage(imageFile)`
- **Parameters**: `File imageFile`
- **Returns**: `String` (public URL)
- **Storage**: `avatars` bucket

### Wallet and Rewards Endpoints

#### Get User Wallet
- **Method**: GET
- **Service**: `SupabaseService.getUserWallet(userId)`
- **Parameters**: `userId`
- **Returns**: `UserWallet?`

#### Create User Wallet
- **Method**: POST
- **Service**: `SupabaseService.createUserWallet(userId)`
- **Parameters**: `userId`
- **Returns**: `bool`
- **Default**: Bronze Explorer level, 0 points

#### Add Wallet Transaction
- **Method**: POST
- **Service**: `SupabaseService.addWalletTransaction(transaction)`
- **Parameters**: `WalletTransaction transaction`
- **Returns**: `bool`
- **Features**: Auto-updates wallet totals and levels

### Statistics and Analytics Endpoints

#### Track Visit
- **Method**: POST
- **Service**: `StatisticsService.trackVisit(userId, location)`
- **Parameters**: `userId`, `location?`
- **Returns**: `void`

#### Get Total Visits
- **Method**: GET
- **Service**: `StatisticsService.getTotalVisits()`
- **Returns**: `int`

#### Get Total Active Users
- **Method**: GET
- **Service**: `StatisticsService.getTotalActiveUsers()`
- **Returns**: `int`
- **Period**: Last 30 days

#### Get Total Service Providers
- **Method**: GET
- **Service**: `StatisticsService.getTotalServiceProviders()`
- **Returns**: `int`
- **Filter**: Approved providers only

### Service Provider Endpoints

#### Get All Service Providers
- **Method**: GET
- **Service**: `ServiceProviderService.getAllServiceProviders()`
- **Returns**: `List<Map<String, dynamic>>`
- **Ordering**: By creation date (newest first)

#### Get Service Providers by Category
- **Method**: GET
- **Service**: `ServiceProviderService.getServiceProvidersByCategory(category)`
- **Parameters**: `category`
- **Returns**: `List<Map<String, dynamic>>`

#### Search Service Providers
- **Method**: GET
- **Service**: `ServiceProviderService.searchServiceProviders(query)`
- **Parameters**: `query`
- **Returns**: `List<Map<String, dynamic>>`
- **Search Fields**: name, description, location

#### Add Service Provider
- **Method**: POST
- **Service**: `ServiceProviderService.addServiceProvider()`
- **Parameters**: Multiple provider details
- **Returns**: `Map<String, dynamic>`
- **Status**: Pending approval by default

### AI Integration Endpoints

#### Generate Travel Response
- **Method**: POST
- **Service**: `OpenAIService.generateTravelResponse(userMessage, conversationHistory?)`
- **Parameters**: `userMessage`, `conversationHistory?`
- **Returns**: `String`
- **Model**: GPT-3.5-turbo
- **Features**: Travel-focused AI assistant

#### Generate Travel Recommendations
- **Method**: POST
- **Service**: `OpenAIService.generateTravelRecommendations()`
- **Parameters**: `destination`, `budget`, `interests`, `duration`
- **Returns**: `String`

### Status Management Endpoints

#### Get Statuses
- **Method**: GET
- **Service**: `SupabaseService.getStatuses()`
- **Returns**: `List<Map<String, dynamic>>`
- **Includes**: User profile data (name, avatar)
- **Ordering**: By timestamp (newest first)

#### Create Status
- **Method**: POST
- **Service**: `SupabaseService.createStatus(statusData)`
- **Parameters**: `Map<String, dynamic> statusData`
- **Returns**: `Map<String, dynamic>`

#### Toggle Status Like
- **Method**: POST/DELETE
- **Service**: `SupabaseService.toggleStatusLike(statusId, isLiked)`
- **Parameters**: `statusId`, `isLiked`
- **Returns**: `void`
- **Features**: Automatic like count management

## Real-time Features

### Real-time Subscriptions
- **Service**: `SupabaseService.subscribeToTable()`
- **Events**: INSERT, UPDATE, DELETE
- **Tables**: All major tables support real-time updates
- **Channels**: Table-specific channels (e.g., `public:posts`)

### Real-time Channels
- `posts_channel` - Post updates
- `stories_channel` - Story updates  
- `messages_channel` - Chat messages

## Data Flow Patterns

### Authentication Flow
1. User initiates sign-in (email/password or Google)
2. AuthService handles authentication
3. User profile created/updated automatically
4. Session management via Supabase Auth
5. Real-time auth state changes tracked

### Content Creation Flow
1. User creates content (post, story, etc.)
2. File uploads processed via UploadService
3. Content metadata stored in database
4. Real-time updates broadcast to subscribers
5. Analytics tracking via StatisticsService

### Booking Flow
1. User selects service/destination
2. Booking details collected
3. Payment processing (placeholder)
4. Booking record created
5. Confirmation and notifications

### Wallet/Rewards Flow
1. User performs rewarded action
2. Transaction recorded via addWalletTransaction
3. Wallet totals automatically updated
4. Level progression calculated
5. Real-time wallet updates

## Error Handling

### Standard Error Patterns
- All services use try-catch blocks
- Errors logged via Logger utility
- Graceful fallbacks to sample data
- User-friendly error messages
- Network error resilience

### Fallback Strategies
- Sample data for offline scenarios
- Cached data when available
- Progressive enhancement
- Retry mechanisms for critical operations

## Security Considerations

### Authentication
- Supabase Auth integration
- JWT token management
- Session persistence
- Automatic token refresh

### Data Access
- Row Level Security (RLS) policies
- User-specific data isolation
- Role-based access control
- API key protection via environment variables

### File Upload Security
- User-specific storage paths
- File type validation
- Size limitations
- Public URL generation

## Performance Optimizations

### Database Queries
- Proper indexing on frequently queried fields
- Pagination for large datasets
- Selective field querying
- Efficient ordering and filtering

### Caching Strategies
- Provider-based state management
- Local data persistence
- Smart cache invalidation
- Offline-first approach

### Real-time Optimization
- Selective subscriptions
- Channel-based filtering
- Efficient payload handling
- Connection management

## Configuration

### Environment Variables
- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_ANON_KEY` - Supabase anonymous key
- `OPENAI_API_KEY` - OpenAI API key

### Storage Buckets
- `avatars` - User profile images
- `posts` - Post media content
- `stories` - Story media content

### API Configuration
- Base URL: `https://api.traverse-visit.com`
- API Version: `/v1`
- Timeout settings: Configured per service
- Retry policies: Implemented for critical operations

## Future Enhancements

### Planned API Improvements
1. **Enhanced Caching**: Implement Redis for better performance
2. **API Rate Limiting**: Add request throttling
3. **Advanced Search**: Elasticsearch integration
4. **Push Notifications**: Real-time notification system
5. **Analytics Dashboard**: Enhanced reporting capabilities
6. **Microservices**: Service decomposition for scalability
7. **GraphQL**: Alternative query interface
8. **Webhook Support**: External service integrations

### Monitoring and Observability
- Request/response logging
- Performance metrics
- Error tracking and alerting
- Usage analytics
- Health check endpoints

This documentation provides a comprehensive overview of the current backend architecture and will be updated as new features are implemented.