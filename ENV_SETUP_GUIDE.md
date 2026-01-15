# 🔐 Environment Variables Setup Guide

**Your API keys are stored in `assets/.env` file - NOT hardcoded!**

---

## ✅ **How to Configure**

### **Step 1: Open the .env file**

Open: `assets/.env`

### **Step 2: Add your Supabase credentials**

```env
# Supabase Configuration (REQUIRED)
SUPABASE_URL=https://your-actual-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.your-actual-key-here
```

### **Step 3: Get your Supabase credentials**

1. Go to: https://supabase.com
2. Open your project
3. Go to: **Settings** → **API**
4. Copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon public key** → `SUPABASE_ANON_KEY`

### **Step 4: (Optional) Add other API keys**

```env
# Paystack (for payments)
PAYSTACK_PUBLIC_KEY=pk_test_xxxxx
PAYSTACK_SECRET_KEY=sk_test_xxxxx

# Groq AI (for smart search)
GROQ_API_KEY=gsk_xxxxx
```

---

## 📱 **For Local Development**

1. Edit `assets/.env` with your keys
2. Run: `flutter run`
3. App will work!

---

## 🤖 **For GitHub Actions Build**

### **Option 1: Use GitHub Secrets (Recommended)**

1. Go to your repo: https://github.com/sibby-killer/Letaapp_v1
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Add these secrets:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `PAYSTACK_PUBLIC_KEY` (optional)
   - `GROQ_API_KEY` (optional)

4. The workflow will automatically create the .env file during build

### **Option 2: Edit .env directly (Less secure)**

Edit `assets/.env` and push to GitHub. 

⚠️ **Warning**: This exposes your keys in the repo!

---

## 📊 **File Structure**

```
assets/
  └── .env          ← Your API keys go here

lib/
  └── core/
      └── config/
          └── app_config.dart  ← Reads from .env file
```

---

## 🔐 **Security Notes**

### **DO:**
✅ Use `.env` file for local development  
✅ Use GitHub Secrets for CI/CD builds  
✅ Add `.env` to `.gitignore` if using real keys  

### **DON'T:**
❌ Commit real API keys to GitHub  
❌ Share your `.env` file  
❌ Use production keys in development  

---

## 🚀 **Quick Start**

### **1. Get Supabase Keys**
- Go to: https://supabase.com
- Open your project
- Settings → API
- Copy URL and anon key

### **2. Edit .env**
```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xxxxx
```

### **3. Build & Run**
```bash
flutter run
```

---

## 🐛 **Troubleshooting**

### **"Configuration Required" screen**

Your Supabase keys are missing or invalid. Check:
1. `assets/.env` file exists
2. `SUPABASE_URL` is correct
3. `SUPABASE_ANON_KEY` is correct

### **"No host specified in URL" error**

Your `SUPABASE_URL` is empty. Add your URL to `assets/.env`

### **"Invalid API key" error**

Your `SUPABASE_ANON_KEY` is wrong. Get the correct key from Supabase dashboard.

---

## ✅ **Example .env File**

```env
# Supabase (REQUIRED)
SUPABASE_URL=https://abcdefghijk.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprIiwicm9sZSI6ImFub24iLCJpYXQiOjE2MzA1MjQwMDAsImV4cCI6MTk0NjEwMDAwMH0.xxxxxxxxxxxxxxxxxxxxxx

# Paystack (optional - for payments)
PAYSTACK_PUBLIC_KEY=pk_test_xxxxxxxxxxxxxxxx
PAYSTACK_SECRET_KEY=sk_test_xxxxxxxxxxxxxxxx

# Groq AI (optional - for smart search)
GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

**Now your API keys are safe and configurable!** 🔐
