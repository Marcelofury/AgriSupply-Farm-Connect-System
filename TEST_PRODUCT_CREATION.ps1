# Test Product Creation API
Write-Host "Testing Product Creation..." -ForegroundColor Cyan

# Login first
Write-Host "`n1. Logging in..." -ForegroundColor Yellow
$loginResp = Invoke-RestMethod -Uri "https://agrisupply-farm-connect-system.onrender.com/api/v1/auth/login" -Method POST -Body '{"email":"agrisupply.demo794@gmail.com","password":"SecurePass123!"}' -ContentType "application/json"
$token = $loginResp.data.token
Write-Host "  ✓ Logged in as: $($loginResp.data.user.full_name)" -ForegroundColor Green

# Try to create a product (without images first to test validation)
Write-Host "`n2. Testing product creation (no images)..." -ForegroundColor Yellow
try {
    $productData = @{
        name = "Test Tomatoes $(Get-Date -Format 'HHmmss')"
        description = "Fresh organic tomatoes from Western Uganda"
        category = "vegetables"
        price = "5000"
        unit = "kg"
        quantity = "100"
        isOrganic = "true"
        harvestDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.000Z")
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "https://agrisupply-farm-connect-system.onrender.com/api/v1/products" -Method POST -Headers @{Authorization="Bearer $token"} -Body $productData -ContentType "application/json"
    Write-Host "  ✓ Product created successfully!" -ForegroundColor Green
    Write-Host "  Product ID: $($response.data.id)" -ForegroundColor Cyan
    $response.data | ConvertTo-Json -Depth 3
}
catch {
    Write-Host "  ✗ Product creation failed!" -ForegroundColor Red
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "  Status Code: $statusCode" -ForegroundColor Yellow
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $responseBody = $reader.ReadToEnd()
        Write-Host "  Error Response:" -ForegroundColor Yellow
        $responseBody | Write-Host
    } else {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`nDone!" -ForegroundColor Green
