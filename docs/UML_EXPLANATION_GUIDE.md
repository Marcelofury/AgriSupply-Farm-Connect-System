# AgriSupply UML Explanation Guide

## Overview
This document explains the UML and related diagrams prepared for the AgriSupply project. It is designed to help presenters and student teams explain the system architecture, behavior, data model, and user flows in a clear and defendable way.

## Why These Diagrams Matter
Each diagram answers a different question:
- DFD Level 0: What are the external actors and major data flows?
- Use Case Diagram: What can each role do in the system?
- ERD: How is data structured and connected?
- Sequence Diagrams: How do components interact step-by-step during key processes?
- Flowchart (Post-login): How do Buyer and Farmer operations branch and interact?
- Wireframe (Login): What the entry UI looks like and how role routing begins.

---

## 1. DFD Level 0 (Context Diagram)
### Purpose
Shows the system boundary and interactions between:
- Buyer
- Farmer
- Admin
- External services (payment, auth, storage, AI where applicable)

### How to Explain
- Start with the central process: AgriSupply System.
- Explain incoming flows (requests/actions) and outgoing flows (responses/notifications).
- Emphasize that this is a high-level context, not internal processing logic.

### Key Talking Points
- Buyers send search, order, payment, and review data.
- Farmers send product and fulfillment updates.
- Admins send moderation and management actions.
- System responds with confirmations, statuses, and alerts.

---

## 2. Use Case Diagram
### Purpose
Defines role-based capabilities for:
- Buyer
- Farmer
- Admin

### How to Explain
- Walk role by role.
- Map each use case to real app screens and backend operations.
- Highlight access control (not all users can perform all actions).

### Key Talking Points
- Buyer: browse, cart, checkout, payment, tracking, reviews.
- Farmer: list products, manage orders, monitor analytics, profile updates.
- Admin: user/product moderation, order oversight, analytics and system controls.

---

## 3. ERD (Entity Relationship Diagram)
### Purpose
Represents core database entities and relationships.

### Core Entities
- users
- products
- orders
- order_items
- payments
- product_reviews
- notifications (and related preference/device tables where applicable)

### How to Explain
- Start from users and role behavior.
- Show how an order links buyer and farmer through order_items.
- Show payment and status tracking as separate but related concerns.

### Key Talking Points
- One buyer can create many orders.
- One order has many order_items.
- Each order_item references a product and farmer.
- Payments attach to orders and users for traceability.
- Reviews connect users and products (optionally tied to order).

---

## 4. Sequence Diagrams (Behavioral Flow)
### Purpose
Describe runtime interactions between UI, API, DB, and external services.

### Sequence Set Covered
- Register
- Login
- Browse/Search Products
- Add to Cart and Checkout
- Place Order
- Payment Initiation + Webhook Callback
- Order Tracking
- Submit Review
- Farmer Product Listing
- Farmer Order Fulfillment
- Admin Moderation

### How to Explain
For each sequence:
1. Trigger (who starts it)
2. Request path (screen -> API)
3. Business logic and validation
4. DB updates
5. External callback (if any)
6. Response back to UI

### Key Talking Points
- Payment sequence must include asynchronous webhook callback.
- Order creation includes stock validation and status initialization.
- Role-specific sequences prove separation of responsibility.

---

## 5. Post-login Flowchart (Buyer Right, Farmer Left)
### Purpose
Visualizes branching operations after authentication.

### How to Explain
- Show role-based split immediately after login.
- Follow Farmer flow (product and order fulfillment path).
- Follow Buyer flow (discovery to payment to review path).
- Explain decision nodes (product found, payment success, order delivered).

### Key Talking Points
- Not every path is linear; decision points are central to business rules.
- Interaction happens through system updates and notifications.

---

## 6. Login Wireframe (PlantUML Wireframe/Salt)
### Purpose
Shows the structure of the login UI and role selection entry point.

### How to Explain
- Identify fields and actions: email/phone, password, remember me, forgot password.
- Role selector (Buyer/Farmer) informs post-login routing.
- This wireframe is structural, not final visual design.

---

## 7. Recommended Presentation Order
1. Problem and actors (short context)
2. DFD Level 0
3. Use Case Diagram
4. Mobile and backend architecture overview
5. ERD
6. Key sequence diagrams (login, order, payment, fulfillment)
7. Post-login flowchart
8. Login wireframe
9. Limitations and future improvements

---

## 8. Common Defense Questions and How the UMLs Help
- "How do users interact with the system at high level?"
  - Use DFD Level 0.
- "What can each role do?"
  - Use Use Case Diagram.
- "What happens technically when placing an order?"
  - Use Place Order sequence diagram.
- "How is payment confirmed?"
  - Use Payment sequence with callback/webhook.
- "How is your database normalized and connected?"
  - Use ERD.

---

## 9. Scope and Assumptions
- Diagrams model current architecture and major production flows.
- Minor UI variants and edge-case error screens may be omitted for clarity.
- Sequence diagrams focus on the main happy path plus key asynchronous steps.

---

## 10. Conclusion
Together, these diagrams provide a complete technical narrative:
- Structural view (DFD, ERD)
- Functional view (Use Cases)
- Behavioral view (Sequences, Flowchart)
- UI entry view (Wireframe)

Use them as a connected story, not as isolated artifacts.