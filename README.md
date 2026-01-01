# 🌾 AgriSupply Farm Connect System

<p align="center">
  <img src="assets/logo.png" alt="AgriSupply Logo" width="200"/>
</p>

<p align="center">
  <strong>Connecting Ugandan Farmers with Buyers - From Farm to Table</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#tech-stack">Tech Stack</a> •
  <a href="#getting-started">Getting Started</a> •
  <a href="#documentation">Documentation</a>
</p>

---

## 📱 About

AgriSupply is a comprehensive digital agriculture marketplace designed specifically for Uganda. It connects farmers directly with buyers, eliminating middlemen and ensuring fair prices for both parties.

### 🎯 Mission
To empower Ugandan farmers with technology that increases their income, reduces post-harvest losses, and provides access to a wider market.

### 🌍 Impact
- **5,000+** Registered Farmers
- **20,000+** Active Buyers
- **UGX 2B+** Monthly Transactions
- **4 Regions** Covered Across Uganda

## ✨ Features

### For Farmers 👨‍🌾
- **Easy Product Listing** - List products with photos, descriptions, and pricing
- **Order Management** - Receive and manage orders from your phone
- **Direct Payments** - Get paid directly via Mobile Money
- **AI Farming Assistant** - Get personalized farming tips and advice
- **Market Insights** - Access price trends and demand forecasts
- **Premium Features** - Boost listings and get verified badge

### For Buyers 🛒
- **Browse Products** - Explore fresh produce from verified farmers
- **Search & Filter** - Find exactly what you need by category, region, or price
- **Secure Payments** - Pay via MTN/Airtel Mobile Money or Card
- **Order Tracking** - Track your order from farm to delivery
- **Reviews & Ratings** - Make informed decisions with community reviews
- **Favorites** - Save products and follow favorite farmers

### For Admins 👔
- **Dashboard Analytics** - Real-time insights on platform performance
- **User Management** - Verify farmers, manage suspensions
- **Product Moderation** - Approve/reject product listings
- **Order Oversight** - Monitor and resolve order issues
- **Financial Reports** - Track revenue, payments, and payouts
- **System Configuration** - Manage platform settings

### AI-Powered Features 🤖
- **Farming Chatbot** - 24/7 agricultural advice in local context
- **Crop Analysis** - Upload images for plant health assessment
- **Pest Identification** - Identify pests and get treatment advice
- **Disease Diagnosis** - Diagnose plant diseases from photos
- **Market Predictions** - AI-powered price forecasting
- **Weather Tips** - Weather-based farming recommendations

## 📸 Screenshots

<p align="center">
  <img src="assets/screenshots/home.png" width="200" />
  <img src="assets/screenshots/products.png" width="200" />
  <img src="assets/screenshots/cart.png" width="200" />
  <img src="assets/screenshots/orders.png" width="200" />
</p>

## 🛠 Tech Stack

### Mobile App (Flutter)
- **Framework:** Flutter 3.16+
- **State Management:** Provider
- **Backend:** Supabase
- **Maps:** Google Maps Flutter
- **Payments:** MTN MoMo, Airtel Money, Flutterwave
- **AI:** OpenAI GPT-4
- **Push Notifications:** Firebase Cloud Messaging

### Backend API (Node.js)
- **Runtime:** Node.js 18+
- **Framework:** Express.js
- **Database:** PostgreSQL (Supabase)
- **Authentication:** Supabase Auth + JWT
- **File Storage:** Supabase Storage
- **Logging:** Winston
- **Validation:** Express Validator

### Infrastructure
- **Database:** Supabase (PostgreSQL)
- **Hosting:** Railway / Render
- **CDN:** Supabase Storage
- **Monitoring:** Sentry
- **Analytics:** Mixpanel

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.16+
- Node.js 18+
- Supabase Account
- Firebase Project (for push notifications)

### Mobile App Setup

```bash
# Clone the repository
git clone https://github.com/agrisupply/agrisupply-app.git
cd agrisupply-app

# Install Flutter dependencies
flutter pub get

# Configure environment
cp lib/config/env.example.dart lib/config/env.dart
# Edit env.dart with your API keys

# Run the app
flutter run
```

### Backend Setup

```bash
# Navigate to backend
cd backend

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your credentials

# Run database migrations
# Execute database/schema.sql in Supabase SQL Editor

# Start development server
npm run dev
```

## 📁 Project Structure

```
agrisupply/
├── lib/                          # Flutter mobile app
│   ├── config/                   # App configuration
│   ├── models/                   # Data models
│   ├── providers/                # State management
│   ├── screens/                  # UI screens
│   │   ├── auth/                 # Authentication screens
│   │   ├── buyer/                # Buyer screens
│   │   ├── farmer/               # Farmer screens
│   │   ├── admin/                # Admin screens
│   │   └── common/               # Shared screens
│   ├── services/                 # API services
│   ├── widgets/                  # Reusable widgets
│   └── main.dart                 # App entry point
│
├── backend/                      # Node.js API
│   ├── database/                 # SQL schemas
│   ├── src/
│   │   ├── config/               # Configuration
│   │   ├── controllers/          # Request handlers
│   │   ├── middleware/           # Express middleware
│   │   ├── routes/               # API routes
│   │   └── utils/                # Utilities
│   └── index.js                  # Server entry point
│
├── assets/                       # Images, icons, fonts
├── android/                      # Android configuration
├── ios/                          # iOS configuration
└── README.md                     # This file
```

## 📖 Documentation

- [Mobile App Documentation](./docs/mobile.md)
- [Backend API Documentation](./backend/README.md)
- [Database Schema](./backend/database/schema.sql)
- [Deployment Guide](./docs/deployment.md)
- [Contributing Guide](./CONTRIBUTING.md)

## 🔐 Security

- All API endpoints are protected with JWT authentication
- Passwords are hashed using bcrypt
- Row Level Security (RLS) enforced at database level
- HTTPS enforced in production
- Rate limiting on all endpoints
- Input validation and sanitization

## 🌐 API Endpoints

| Category | Endpoints | Description |
|----------|-----------|-------------|
| Auth | 9 | Registration, login, OAuth, OTP |
| Users | 14 | Profile, farmers, following |
| Products | 18 | CRUD, search, reviews, favorites |
| Orders | 13 | Lifecycle, tracking, statistics |
| Payments | 10 | Mobile money, cards, refunds |
| AI | 12 | Chat, analysis, predictions |
| Admin | 22 | Dashboard, management, analytics |
| Notifications | 11 | CRUD, preferences, devices |

## 📊 Database Schema

### Core Tables
- `users` - User accounts and profiles
- `products` - Product listings
- `orders` - Customer orders
- `order_items` - Order line items
- `payments` - Payment transactions

### Supporting Tables
- `notifications` - User notifications
- `product_reviews` - Product ratings
- `product_favorites` - User wishlists
- `farmer_followers` - Social connections
- `ai_chat_sessions` - AI conversation history

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- **Product Owner:** AgriSupply Team
- **Lead Developer:** AgriSupply Engineering
- **Design:** AgriSupply Design Team

## 📞 Support

- **Email:** support@agrisupply.ug
- **Phone:** +256 700 000 000
- **WhatsApp:** +256 700 000 000
- **Twitter:** [@AgriSupplyUG](https://twitter.com/AgriSupplyUG)

## 🙏 Acknowledgments

- Uganda Ministry of Agriculture
- Local farmer cooperatives
- Our beta testers and early adopters
- Open source community

---

<p align="center">
  Made with ❤️ in Uganda 🇺🇬
</p>

<p align="center">
  <a href="https://agrisupply.ug">Website</a> •
  <a href="https://play.google.com/store/apps/details?id=ug.agrisupply.app">Play Store</a> •
  <a href="https://apps.apple.com/app/agrisupply">App Store</a>
</p>
