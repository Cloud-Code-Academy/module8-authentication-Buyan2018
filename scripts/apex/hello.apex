/**
 * Simple Testing Script for SFAuthenticationManager
 *
 * INSTRUCTIONS:
 * 1. Update your credentials below
 * 2. Update configuration values in SFAuthenticationManager.cls
 * 3. Run this script in Developer Console
 * 4. Check debug logs for results
 */

// =============================================================================
// UPDATE YOUR CREDENTIALS HERE
// =============================================================================
String username = 'test@test.com';
String password = 'test';
String securityToken = 'test';

// =============================================================================
// SIMPLE AUTHENTICATION TESTING
// =============================================================================
System.debug('🚀 Starting Authentication Testing...\n');

SFAuthenticationManager.AuthResponse authResponse = null;
Map<String, Object> limits = null;
SFExternalCalloutWithToken.CreateAccountResult createAccountResult = null;

// --- JWT FLOW TEST ---
System.debug('\n🔑 Testing JWT Flow...');
authResponse = SFAuthenticationManager.authenticateWithJWT(username);

if (authResponse != null && authResponse.isSuccess) {
	System.debug('✅ JWT authentication successful!');
	System.debug('Instance URL: ' + authResponse.instanceUrl);

	// Test getting org limits
	limits = SFExternalCalloutWithToken.getLimits(
		authResponse.accessToken,
		authResponse.instanceUrl
	);
	System.debug(
		'📊 Org limits retrieved: ' + (limits.containsKey('error') ? 'FAILED' : 'SUCCESS')
	);

	// Test creating an account
	createAccountResult = SFExternalCalloutWithToken.createAccount(
		'JWT Test Account ' + DateTime.now().getTime(),
		authResponse.accessToken,
		authResponse.instanceUrl
	);
	System.debug(
		'👤 Account creation: ' +
		(createAccountResult.isSuccess
			? 'SUCCESS (ID: ' + createAccountResult.accountId + ')'
			: 'FAILED')
	);
} else {
	System.debug('❌ JWT authentication failed');
	System.debug('Error: ' + (authResponse != null ? authResponse.errorMessage : 'No response'));
}

System.debug('\n🏁 Authentication testing complete! Check results above.');
