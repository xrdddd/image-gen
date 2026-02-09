# Monetization Guide: Charging Users for API Usage

## Overview

When using a paid API service (like Qwen3 from Alibaba), you need to:
1. **Track usage** - Monitor how many API calls each user makes
2. **Charge users** - Implement a payment system
3. **Manage costs** - Ensure you're profitable (user pays > API cost)
4. **Provide good UX** - Make pricing clear and fair

## Monetization Models

### 1. Subscription Model (Recommended) ✅

**How it works:**
- Users pay monthly/yearly subscription
- Get X images per month included
- Overage charges or hard limits

**Pros:**
- Predictable revenue
- Better user experience
- Easier to manage

**Cons:**
- Need to estimate usage
- Risk if users exceed limits

**Example Pricing:**
- **Free Tier**: 10 images/month
- **Basic ($4.99/month)**: 100 images/month
- **Pro ($9.99/month)**: 500 images/month
- **Unlimited ($19.99/month)**: Unlimited images

### 2. Pay-Per-Use (Credits System) 💰

**How it works:**
- Users buy credits/packs
- Each image costs X credits
- Credits never expire (or expire after X months)

**Pros:**
- Users only pay for what they use
- No subscription commitment
- Clear value proposition

**Cons:**
- Less predictable revenue
- More complex to implement

**Example Pricing:**
- **10 Credits**: $0.99 (1 credit = 1 image)
- **50 Credits**: $3.99 (20% discount)
- **200 Credits**: $9.99 (50% discount)
- **1000 Credits**: $29.99 (70% discount)

### 3. Freemium Model 🆓

**How it works:**
- Free tier with limited usage
- Paid tiers for more features/usage
- Upsell to premium features

**Example:**
- **Free**: 5 images/day, watermarked
- **Premium ($9.99/month)**: Unlimited, no watermark, HD quality

### 4. Hybrid Model 🔄

**How it works:**
- Free tier + subscription + pay-per-use
- Users can subscribe OR buy credits
- Best of both worlds

## Implementation Options

### Option 1: RevenueCat (Recommended for Subscriptions) ⭐

**Best for:** Subscription-based apps

**Setup:**
1. Install RevenueCat SDK
2. Configure products in App Store Connect / Google Play Console
3. Track usage and enforce limits
4. RevenueCat handles payments, receipts, subscriptions

**Code Example:**
```typescript
import Purchases from 'react-native-purchases';

// Initialize RevenueCat
await Purchases.configure({
  apiKey: 'your_revenuecat_key',
  appUserID: userId,
});

// Check subscription status
const customerInfo = await Purchases.getCustomerInfo();
const isPro = customerInfo.entitlements.active['pro'] !== undefined;

// Track usage
async function generateImageWithLimit(prompt: string) {
  const usage = await getUserUsageThisMonth(userId);
  const limit = await getUserLimit(userId);
  
  if (usage >= limit) {
    throw new Error('Monthly limit reached. Upgrade to Pro!');
  }
  
  // Generate image
  const image = await callQwen3API(prompt);
  
  // Increment usage
  await incrementUserUsage(userId);
  
  return image;
}
```

**Pros:**
- Handles all payment complexity
- Cross-platform (iOS + Android)
- Free up to $10k revenue/month
- Handles subscription management

**Cons:**
- Takes 1% of revenue (after free tier)
- Requires App Store/Play Store setup

### Option 2: Stripe (For Web + Custom Payments) 💳

**Best for:** Web apps or custom payment flows

**Setup:**
1. Create Stripe account
2. Set up payment intents
3. Track usage in your backend
4. Charge based on usage

**Backend Example (Node.js):**
```javascript
// Track usage
async function trackImageGeneration(userId, prompt) {
  // Check user's credit balance
  const user = await db.users.findOne({ id: userId });
  
  if (user.credits < 1) {
    throw new Error('Insufficient credits');
  }
  
  // Call Qwen3 API
  const image = await callQwen3API(prompt);
  const apiCost = 0.01; // $0.01 per image (example)
  
  // Deduct credits
  await db.users.update(
    { id: userId },
    { credits: user.credits - 1 }
  );
  
  // Track for billing
  await db.usageLogs.insert({
    userId,
    type: 'image_generation',
    cost: apiCost,
    timestamp: new Date(),
  });
  
  return image;
}

// Charge user for credits
async function purchaseCredits(userId, amount, paymentMethodId) {
  const price = amount * 0.10; // $0.10 per credit
  
  const paymentIntent = await stripe.paymentIntents.create({
    amount: price * 100, // in cents
    currency: 'usd',
    payment_method: paymentMethodId,
    customer: userId,
  });
  
  // Add credits to user account
  await db.users.update(
    { id: userId },
    { $inc: { credits: amount } }
  );
}
```

### Option 3: In-App Purchases (Native) 📱

**Best for:** iOS/Android apps with simple credit packs

**Setup:**
1. Configure products in App Store Connect / Google Play
2. Use `react-native-iap` or native SDKs
3. Track usage locally or on backend

**Code Example:**
```typescript
import RNIap from 'react-native-iap';

// Purchase credits
async function purchaseCredits(productId: string) {
  try {
    await RNIap.requestPurchase(productId);
    // Handle purchase completion
    // Add credits to user account
  } catch (error) {
    console.error('Purchase failed:', error);
  }
}

// Check available products
const products = await RNIap.getProducts(['credit_pack_10', 'credit_pack_50']);
```

## Architecture: Backend Required

You'll need a backend to:
1. **Track usage** - Count API calls per user
2. **Enforce limits** - Check before allowing generation
3. **Manage payments** - Process subscriptions/credits
4. **Store API keys** - Keep Qwen3 API key secure (never in app)

### Recommended Architecture

```
┌─────────────┐
│   Mobile    │
│     App     │
└──────┬──────┘
       │
       │ API Calls
       ▼
┌─────────────┐      ┌─────────────┐
│   Your      │─────▶│   Qwen3     │
│  Backend    │      │   API       │
│  Server     │      │  (Alibaba)  │
└─────────────┘      └─────────────┘
       │
       │
       ▼
┌─────────────┐
│  Database   │
│ (Usage,     │
│  Credits,   │
│  Users)     │
└─────────────┘
```

### Backend Responsibilities

1. **User Management**
   - User accounts
   - Subscription status
   - Credit balance

2. **Usage Tracking**
   - Log every API call
   - Track costs
   - Enforce limits

3. **Payment Processing**
   - Handle subscriptions (RevenueCat webhooks)
   - Process credit purchases
   - Manage billing

4. **API Proxy**
   - Keep Qwen3 API key secure
   - Rate limiting
   - Error handling

## Implementation Steps

### Step 1: Set Up Backend

**Tech Stack Options:**
- **Node.js + Express** (Easy, JavaScript)
- **Python + FastAPI** (Good for ML/AI)
- **Firebase Functions** (Serverless, easy)
- **AWS Lambda** (Serverless, scalable)

**Example Backend Endpoint:**
```javascript
// POST /api/generate-image
app.post('/api/generate-image', async (req, res) => {
  const { userId, prompt } = req.body;
  
  // 1. Check user's subscription/credits
  const user = await getUser(userId);
  if (!hasCredits(user)) {
    return res.status(402).json({ error: 'Insufficient credits' });
  }
  
  // 2. Call Qwen3 API
  const imageUrl = await callQwen3API(prompt);
  const apiCost = 0.01; // Your cost from Alibaba
  
  // 3. Deduct credits
  await deductCredits(userId, 1);
  
  // 4. Track usage
  await logUsage(userId, apiCost);
  
  // 5. Return image
  res.json({ imageUrl });
});
```

### Step 2: Update Mobile App

**Add Usage Tracking:**
```typescript
// services/apiImageGenerationService.ts
export async function generateImageWithAPI(
  prompt: string,
  userId: string
): Promise<string> {
  // Check credits before calling
  const userStatus = await checkUserCredits(userId);
  
  if (!userStatus.hasCredits) {
    throw new Error('Insufficient credits. Please purchase more.');
  }
  
  // Call your backend (not Qwen3 directly)
  const response = await fetch('https://your-backend.com/api/generate-image', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${userToken}`,
    },
    body: JSON.stringify({ userId, prompt }),
  });
  
  if (response.status === 402) {
    throw new Error('Payment required. Please purchase credits.');
  }
  
  const data = await response.json();
  return data.imageUrl;
}
```

### Step 3: Add Payment UI

**Subscription Screen:**
```typescript
// screens/SubscriptionScreen.tsx
import Purchases from 'react-native-purchases';

export function SubscriptionScreen() {
  const [packages, setPackages] = useState([]);
  
  useEffect(() => {
    loadPackages();
  }, []);
  
  async function loadPackages() {
    const offerings = await Purchases.getOfferings();
    setPackages(offerings.current.availablePackages);
  }
  
  async function purchase(pkg: Package) {
    try {
      const { customerInfo } = await Purchases.purchasePackage(pkg);
      // Handle success
    } catch (error) {
      // Handle error
    }
  }
  
  return (
    <View>
      {packages.map(pkg => (
        <TouchableOpacity onPress={() => purchase(pkg)}>
          <Text>{pkg.product.title}</Text>
          <Text>{pkg.product.priceString}</Text>
        </TouchableOpacity>
      ))}
    </View>
  );
}
```

## Pricing Strategy

### Cost Analysis

**Qwen3 API Costs (Example):**
- Per image: $0.01 - $0.05 (depends on resolution/complexity)
- Your margin: Charge 2-5x your cost

**Recommended Pricing:**

| Tier | Price | Images/Month | Cost/Image | Your Margin |
|------|-------|--------------|------------|-------------|
| Free | $0 | 10 | - | - |
| Basic | $4.99 | 100 | $0.05 | 5x |
| Pro | $9.99 | 500 | $0.02 | 2x |
| Unlimited | $19.99 | Unlimited | - | Volume discount |

### Break-Even Analysis

**Example:**
- Qwen3 cost: $0.02/image
- You charge: $0.10/image (5x markup)
- User buys 50 credits for $4.99
- Your cost: 50 × $0.02 = $1.00
- Your profit: $4.99 - $1.00 = $3.99 (80% margin)

## Best Practices

### 1. Transparent Pricing
- Show cost per image clearly
- Display remaining credits/usage
- Warn before limits reached

### 2. Fair Usage
- Don't overcharge
- Provide value
- Consider free tier for marketing

### 3. Cost Management
- Monitor API costs
- Set spending limits
- Alert on unusual usage

### 4. User Experience
- Fast generation
- Clear error messages
- Easy payment flow

### 5. Security
- Never expose API keys in app
- Use backend proxy
- Validate user permissions

## Quick Start: RevenueCat + Backend

1. **Set up RevenueCat:**
   ```bash
   npm install react-native-purchases
   ```

2. **Create backend:**
   - Track usage in database
   - Enforce limits
   - Proxy Qwen3 API calls

3. **Update app:**
   - Add subscription screen
   - Check credits before generation
   - Show usage/limits

4. **Test:**
   - Test payment flow
   - Verify usage tracking
   - Check cost margins

## Cost Monitoring

**Track these metrics:**
- API calls per user
- Cost per user
- Revenue per user
- Profit margins
- Popular features

**Set up alerts:**
- High API usage
- Low profit margins
- Payment failures
- API errors

## Legal Considerations

1. **Terms of Service** - Define usage limits
2. **Privacy Policy** - Explain data usage
3. **Refund Policy** - Handle disputes
4. **API Usage** - Comply with Qwen3 terms

## Summary

**Recommended Approach:**
1. ✅ Use **RevenueCat** for subscriptions (easiest)
2. ✅ Build **backend** to track usage and proxy API
3. ✅ Implement **credit system** or **subscription tiers**
4. ✅ Charge **2-5x** your API cost
5. ✅ Provide **free tier** for user acquisition

**Estimated Setup Time:**
- Backend: 1-2 days
- Payment integration: 1 day
- Testing: 1 day
- **Total: 3-4 days**

This gives you a complete monetization system that's profitable and user-friendly!
