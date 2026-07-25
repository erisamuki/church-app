#!/bin/bash
BASE_URL="http://localhost:3000/api"

echo "=== GraceHub API Tests ==="

echo ""
echo "1. Health Check"
curl -s $BASE_URL/health | jq .

echo ""
echo "2. Login"
LOGIN_RESPONSE=$(curl -s -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"pastor@gracehub.app","password":"admin123"}')
echo $LOGIN_RESPONSE | jq .
TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.token')

echo ""
echo "3. Get Current User"
curl -s $BASE_URL/auth/me -H "Authorization: Bearer $TOKEN" | jq .

echo ""
echo "4. Dashboard Stats"
curl -s $BASE_URL/dashboard/stats -H "Authorization: Bearer $TOKEN" | jq .

echo ""
echo "5. Upcoming Events"
curl -s $BASE_URL/dashboard/upcoming-events -H "Authorization: Bearer $TOKEN" | jq .

echo ""
echo "6. List Members"
curl -s "$BASE_URL/members?page=1&limit=5" -H "Authorization: Bearer $TOKEN" | jq .

echo ""
echo "7. Search Members 'john'"
curl -s "$BASE_URL/members?search=john" -H "Authorization: Bearer $TOKEN" | jq .

echo ""
echo "8. List Events"
curl -s "$BASE_URL/events?page=1&limit=5" -H "Authorization: Bearer $TOKEN" | jq .

echo ""
echo "9. Giving Categories"
curl -s "$BASE_URL/giving/categories" -H "Authorization: Bearer $TOKEN" | jq .

echo ""
echo "10. Groups"
curl -s "$BASE_URL/groups" -H "Authorization: Bearer $TOKEN" | jq .

echo ""
echo "=== All tests completed ==="