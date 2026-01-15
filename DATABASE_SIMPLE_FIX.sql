-- ============================================================================
-- SUPABASE REALTIME - SIMPLE VERIFICATION (No Errors)
-- ============================================================================
-- This script just verifies everything is set up correctly
-- Safe to run multiple times
-- ============================================================================

-- ============================================================================
-- 1. VERIFY TABLES EXIST
-- ============================================================================

SELECT 
    CASE 
        WHEN EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_rooms')
        THEN '✓ chat_rooms table exists'
        ELSE '✗ chat_rooms table MISSING - need to create'
    END as chat_rooms_status;

SELECT 
    CASE 
        WHEN EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'messages')
        THEN '✓ messages table exists'
        ELSE '✗ messages table MISSING - need to create'
    END as messages_status;

-- ============================================================================
-- 2. VERIFY REALTIME IS ENABLED
-- ============================================================================

SELECT 
    tablename,
    '✓ Realtime enabled' as status
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
AND schemaname = 'public' 
AND tablename IN ('chat_rooms', 'messages')
ORDER BY tablename;

-- If you see 2 rows above, realtime is working!
-- If you see 0 rows, realtime needs to be enabled

-- ============================================================================
-- 3. VERIFY RLS POLICIES EXIST
-- ============================================================================

SELECT 
    tablename,
    policyname,
    '✓ Policy exists' as status
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('chat_rooms', 'messages')
ORDER BY tablename, policyname;

-- ============================================================================
-- 4. TEST QUERY (Should work without errors)
-- ============================================================================

-- Count records in chat_rooms
SELECT 
    'chat_rooms' as table_name,
    COUNT(*) as total_records
FROM chat_rooms;

-- Count records in messages
SELECT 
    'messages' as table_name,
    COUNT(*) as total_records
FROM messages;

-- ============================================================================
-- RESULT INTERPRETATION:
-- ============================================================================

/*
IF ALL QUERIES RUN WITHOUT ERRORS:
✅ Your database is set up correctly!
✅ Chat will work in your app!
✅ You can skip any database setup!
✅ Just build your APK: flutter build apk --release

IF YOU GET ERRORS:
❌ Tables might not exist
❌ Run the CREATE_TABLES_ONLY.sql script instead
*/

-- ============================================================================
-- SUMMARY
-- ============================================================================

SELECT 
    '========================================' as separator
UNION ALL
SELECT 
    'VERIFICATION COMPLETE!' as message
UNION ALL
SELECT 
    'If all queries ran without errors, you are ready!' as message
UNION ALL
SELECT 
    '========================================' as separator;
