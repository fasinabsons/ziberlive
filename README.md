# DreamFlow Co-Living Management App

A comprehensive Flutter application for managing co-living spaces, designed to help residents coordinate schedules, manage bills, assign tasks, and build community.

## Features

- **User Management**: Add, edit, and manage users with different roles (admin, resident)
- **Apartment Management**: Track apartments, rooms, and beds with vacancy information
- **Bill Management**: Create and split bills among residents
- **Task Management**: Assign and track community tasks
- **Scheduling**: Manage shared resources like laundry and common spaces
- **Community Features**: Polls, announcements, and community tree visualization

## Platform Support

- **Web**: Fully functional with SharedPreferences-based storage
- **Mobile** (Android/iOS): Full functionality with SQLite storage
- **Desktop** (Windows/macOS/Linux): Full functionality with SQLite storage

## Technical Overview

- **Framework**: Flutter 3.19.0+
- **State Management**: Provider pattern
- **Storage**: Platform-agnostic LocalStorageService (SharedPreferences for web, SQLite for mobile/desktop)
- **UI**: Material Design with custom theming
- **Optional Firebase Integration**: For advanced features

## Getting Started

See the [INSTALLATION.md](INSTALLATION.md) file for detailed setup instructions.

For production deployment, refer to [PRODUCTION.md](PRODUCTION.md).

## Project Status

The app is approximately 75% complete with the following major components implemented:

- ✅ Cross-platform storage solution
- ✅ User interface framework
- ✅ Core data models
- ✅ Apartment management with rooms and beds
- ✅ Basic user management
- ✅ Schedule models and UI
- ✅ Task management framework

See [TODO.md](TODO.md) for the remaining tasks and future enhancements.

## Screenshots

(Screenshots will be added here)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- The Flutter team for the amazing framework
- All contributors who have helped build this application

```bash
DreamFlow is a comprehensive co-living management application designed to streamline community living through innovative features, offline-first architecture, and engaging gamification elements.

🌟 Key Features

Core Functionality
**Offline-First Architecture**: Works seamlessly offline with P2P sync across 100-200+ devices
**Multi-Admin Support**: Flexible roles for Owner-Admins (3+ apartments) and Roommate-Admins (1-2 apartments)
**Dynamic Bill Splitting**: Smart bill distribution based on user subscriptions
**Community Cooking**: Integrated meal management with grocery tracking
**Investment Groups**: Collaborative investment opportunities for passive income
**Vacancy Management**: Optimized room/apartment management system

Gamification Elements
**Community Tree**: Visual representation of community contributions
**Co-Living Credits**: Reward system for positive community participation
**Progress Tracking**: Real-time monitoring of bill payments and community goals
**Social Proof**: Anonymous leaderboards and performance metrics

🎯 Design Principles

Functional Psychology
Reward System: Co-Living Credits and Community Tree visualization
Progress Tracking: Bill payments, rent-free goals, vacancy reductions
Social Proof: Anonymous leaderboards and team performance metrics
FOMO Elements: Timely notifications for community engagement

UI/UX Philosophy
Clean, card-based interface with large buttons
Nature-inspired color palette (green for growth, blue for trust)
Customizable labels and personalization options
One-tap actions for common tasks

💼 Admin Roles

Owner-Admin
Manages 3+ apartments (configurable for 1-2)
Building-wide oversight and vacancy optimization
Employee management (cooks, cleaners)
Premium feature access

Roommate-Admin
Manages 1-2 apartments
Apartment-level coordination
Bill sharing and community management
Basic feature access

📱 Key Pages

1. Home Page
Quick stats dashboard
Action cards for key functions
Community Tree visualization
Forecast widgets
Notifications banner

2. Users Page
User management and profiles
Subscription customization
Guest mode (Owner-Admin)
Bulk import capabilities

3. Bills Page
Dynamic bill splitting
Community Cooking options
Payment tracking
Bill forecasting

4. Vacancy Page
Vacancy dashboard
Room/apartment management
Listing generation
Optimization suggestions

5. Community Cooking Page
Menu management
Chef system
Grocery team coordination
Spending tracking

6. Tasks Page
Task assignment and rotation
Completion tracking
Credit rewards
Analytics dashboard

7. Voting Page
Poll creation and management
Anonymous voting options
Real-time results
Export capabilities

8. Investment Page
Group management
Investment tracking
ROI visualization
Rent-free progress monitoring

9. Settings Page
Admin preferences
Backup options
Network configuration
Subscription management

💰 Premium Features

Cloud Services ($5-$20/month)
Cloud backups
Advanced analytics
User photos and documents
Public vacancy listings
Push notifications
Web dashboard (Owner-Admin)

Additional Tools
AI chore scheduler
Detailed report exports
Ad-free experience
Sponsored suggestions

🔧 Technical Stack

Core Technologies
Flutter for cross-platform development
SQLite for local storage
Nearby Connections for P2P sync
Firebase for premium features

Data Management
Offline-first architecture
P2P synchronization
Local backups
Cloud storage (premium)

🌐 Multi-Language Support
English
Arabic
Hindi

📱 Platform Support
iOS
Android
Web (premium)

🔒 Security Features
Local data encryption
Secure P2P connections
Role-based access control
Privacy-focused design

🚀 Getting Started

1. Clone the repository
2. Install dependencies
3. Configure Firebase (for premium features)
4. Run the app


---

🟡 Partial/Planned Features
OCR for grocery scanning: Manual entry is implemented; OCR (Google ML Kit) is planned.
Premium analytics and advanced forecasting: Structure present; full UI/logic needs completion.
Push notifications: Local notifications are free; Firebase Cloud Messaging is premium.
Web dashboard: Not implemented, but code structure supports future expansion.
🔴 Missing/Needs Refinement
Some UI polish for premium features (photo uploads, analytics, listings).
Bulk import/export UI.
Some admin toggles (e.g., "Include in bill splitting") may need explicit UI controls.
Ads SDK integration (AdMob).

---

📄 License
License details to be added

🤝 Contributing
Contribution guidelines to be added
```
