/**
 * Service class to handle OAuth 2.0 authentication with Salesforce
 * STUDENT VERSION - Complete the method implementations
 */
public class SFAuthenticationManager {
	// Endpoint for token requests
	private static final String TOKEN_ENDPOINT = '/services/oauth2/token';
	private static final String AUTHORIZE_ENDPOINT = '/services/oauth2/authorize';
	private static final String PKCE_GENERATOR_ENDPOINT = '/services/oauth2/pkce/generator';
	private static final String GRANT_TYPE_PASSWORD = 'password';
	private static final String GRANT_TYPE_CLIENT_CREDENTIALS = 'client_credentials';
	private static final String GRANT_TYPE_AUTHORIZATION_CODE = 'authorization_code';
	private static final String GRANT_TYPE_REFRESH_TOKEN = 'refresh_token';
	private static final String RESPONSE_TYPE = 'code';
	// Configuration values
	private static Credentials__mdt creds = Credentials__mdt.getInstance('DestinationOrg');
	public static final String DEFAULT_CLIENT_ID = creds.DEFAULT_CLIENT_ID__c;
	public static final String DEFAULT_CLIENT_SECRET = creds.DEFAULT_CLIENT_SECRET__c;
	public static final String DEFAULT_LOGIN_URL = 'https://orgfarm-9eac12ad16-dev-ed.develop.my.salesforce.com';
	public static final String DEFAULT_REDIRECT_URL = 'https://orgfarm-de1c4366c8-dev-ed.develop.my.site.com/callback';

	/**
	 * Central method to make OAuth token requests
	 * TODO: Complete this method implementation
	 * @param params Map of parameters to include in the request
	 * @param tokenUrl The full URL to the token endpoint
	 * @return Authentication response with token details or error
	 */
	private static AuthResponse makeTokenRequest(Map<String, String> params, String tokenUrl) {
		// TODO: Create HTTP request
		HttpRequest req = new HttpRequest();
		// TODO: Set endpoint, method, and headers
		req.setEndpoint(tokenUrl);
		req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
		req.setHeader('Accept', 'application/json');
		req.setMethod('POST');
		// TODO: Convert parameters to URL encoded string
		String requestBody = '';
		for (String key : params.keySet()) {
			requestBody += key;
			requestBody += params.get(key);
		}
		System.debug('requestbody: ' + requestBody);
		// TODO: Set request body
		req.setBody(requestBody);
		// TODO: Send the request and handle response
		Http http = new Http();
		// TODO: Parse success and error responses
		HttpResponse res;
		AuthResponse authResp = new AuthResponse();
		try {
			res = http.send(req);
			System.debug('res: ' + res);
			String respBody = res.getBody().toString();
			System.debug('respBody: ' + respBody);
			Map<String, Object> payload = (Map<String, Object>)JSON.deserializeUntyped(respBody);
			if (res.getStatusCode() == 200) {
				authResp.isSuccess = true;
				String token = (String)payload.get('access_token');
				authResp.accessToken = token;
				String instUrl = (String)payload.get('instance_url');
				authResp.instanceUrl = instUrl;
				String tokType = (String)payload.get('token_type');
				authResp.tokenType = tokType;
				String refreshToken = (String)payload.get('refresh_token');
				if (String.isNotBlank(refreshToken)) {
					authResp.refreshToken = refreshToken;
				} 				
			} else {
				authResp.isSuccess = false;
				String error = (String)payload.get('error');
				authResp.errorMessage = error;
				String errorDescription = (String)payload.get('error_description');
				authResp.errorDetails = errorDescription;
			}
			System.debug('authResp: ' + authResp);
		} catch (Exception ex) {
			System.debug('Exception occured with the following error: ' + ex.getMessage());
		}
		return authResp;
	}

	/**
	 * Authenticate using username and password flow (grant_type=password)
	 * TODO: Complete this method implementation
	 * @param username Username for the org
	 * @param password Password + Security Token
	 * @param securityToken Security Token
	 * @return Authentication response with token details or error
	 */
	public static AuthResponse authenticateWithPassword(
		String username,
		String password,
		String securityToken
	) {
		// TODO: Prepare parameters map with:
		Map<String, String> params = new Map<String, String>();
		// - grant_type: 'password'
		params.put('grant_type=', GRANT_TYPE_PASSWORD);
		// - client_id: DEFAULT_CLIENT_ID
		params.put('&client_id=', DEFAULT_CLIENT_ID);
		// - client_secret: DEFAULT_CLIENT_SECRET
		params.put('&client_secret=', DEFAULT_CLIENT_SECRET);
		// - username: username
		params.put('&username=', username);
		// - password: password + securityToken
		params.put('&password=', password + securityToken);
		// TODO: Call makeTokenRequest with params and token URL
		AuthResponse response = makeTokenRequest(params, DEFAULT_LOGIN_URL + TOKEN_ENDPOINT);
		// STUB: Return empty response for now
		return response;
	}

	/**
	 * Authenticate using client credentials flow (grant_type=client_credentials)
	 * TODO: Complete this method implementation
	 * @return Authentication response with token details or error
	 */
	public static AuthResponse authenticateWithClientCredentials() {
		// TODO: Prepare parameters map with:
		Map<String, String> params = new Map<String, String>();
		// - grant_type: 'client_credentials'
		params.put('grant_type=', GRANT_TYPE_CLIENT_CREDENTIALS);
		// - client_id: DEFAULT_CLIENT_ID
		params.put('&client_id=', DEFAULT_CLIENT_ID);
		// - client_secret: DEFAULT_CLIENT_SECRET
		params.put('&client_secret=', DEFAULT_CLIENT_SECRET);
		// TODO: Call makeTokenRequest with params and token URL
		AuthResponse response = makeTokenRequest(params, DEFAULT_LOGIN_URL + TOKEN_ENDPOINT);
		// STUB: Return empty response for now
		return response;
	}

	/**
	 * JWT Bearer Token Flow authentication
	 * TODO: Complete this method implementation
	 * @param username Username for the org
	 * @return Authentication response with token details or error
	 */
	public static AuthResponse authenticateWithJWT(String username) {
		// TODO: Create JWT using Auth.JWT class
		Auth.JWT jwt = new Auth.JWT();
		// TODO: Set sub (username), aud (audience), and iss (client_id)
		jwt.setSub(username);
		jwt.setAud('https://login.salesforce.com');
		jwt.setIss(DEFAULT_CLIENT_ID);
		jwt.setValidityLength(300);  
		// TODO: Create JWS (JSON Web Signature) with the JWT
		AuthResponse authResponse = new AuthResponse();
		Auth.JWS jws = new Auth.JWS(jwt, 'jwtsource');
		System.debug('jws: ' + jws);
		System.debug('Certificate accessible!');
		// TODO: Get the compact serialization (token string)
		String token = jws.getCompactSerialization();
		String tokenEndpoint = DEFAULT_LOGIN_URL + '/services/oauth2/token';
		// TODO: Create JWTBearerTokenExchange and get access token
		Auth.JWTBearerTokenExchange bearer = new Auth.JWTBearerTokenExchange(tokenEndpoint, jws);
		String accessToken = bearer.getAccessToken();
		// STUB: Return empty response for now
		authResponse.isSuccess = true;
		authResponse.accessToken = accessToken;
		authResponse.instanceUrl = DEFAULT_LOGIN_URL;
		authResponse.tokenType = 'Bearer';
		authResponse.expiresIn = 3600;
		return authResponse;
	}

	/**
	 * Generate the authorization URL for Web Server Flow
	 * TODO: Complete this method implementation
	 * @param state Optional state parameter for CSRF protection
	 * @return Full authorization URL
	 */
	@AuraEnabled
	public static String generateAuthorizationUrl(String state) {
		// TODO: Build authorization URL with:
		// - DEFAULT_LOGIN_URL + AUTHORIZE_ENDPOINT
		String url = DEFAULT_LOGIN_URL + AUTHORIZE_ENDPOINT +
		// - client_id parameter (URL encoded)
		'?client_id=' +
		EncodingUtil.urlEncode(DEFAULT_CLIENT_ID, 'UTF-8') +
		// - redirect_uri parameter (URL encoded)
		'&redirect_uri=' + 
		EncodingUtil.urlEncode(DEFAULT_REDIRECT_URL, 'UTF-8') +
		// - response_type=code
		'&response_type=' + EncodingUtil.urlEncode(RESPONSE_TYPE, 'UTF-8');
		// - state parameter if provided (URL encoded)
		if (String.isNotBlank(state)) {
			url += '&state=' + EncodingUtil.urlEncode(state, 'UTF-8');
		}
		// STUB: Return placeholder URL for now
		return url;
	}

	/**
	 * Generate PKCE data for OAuth 2.0 authorization
	 * TODO: Complete this method implementation
	 * @return PkceResponse containing code verifier and challenge
	 */
	@AuraEnabled
	public static PkceResponse generatePkceData() {
		// TODO: Create HTTP request to PKCE generator endpoint
		HttpRequest req = new HttpRequest();
		req.setEndpoint(DEFAULT_LOGIN_URL + PKCE_GENERATOR_ENDPOINT);
		// TODO: Set method to GET and content-type header
		req.setMethod('GET');
		req.setHeader('Content-Type', 'application/json');

		// TODO: Send request and handle response
		Http http = new Http();
		PkceResponse pkceResponse = new PkceResponse();
		// TODO: Parse response for code_verifier, code_challenge, and code_challenge_method
		try {
			HttpResponse res = http.send(req);
			if (res.getStatusCode() == 200) {
				Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
				pkceResponse.isSuccess = true;
				pkceResponse.codeVerifier = (String)responseMap.get('code_verifier');
				pkceResponse.codeChallenge = (String)responseMap.get('code_challenge');
				pkceResponse.codeChallengeMethod = (String)responseMap.get('code_challenge_method');
			} else {
				pkceResponse.isSuccess = false;
				pkceResponse.errorMessage = 'HTTP Error: ' + res.getStatusCode() + ' ' + res.getStatus();
			}
		} catch (Exception ex) {
			pkceResponse.isSuccess = false;
			pkceResponse.errorMessage = ex.getMessage();
		}
		// STUB: Return empty response for now
		return pkceResponse;
	}

	/**
	 * Generate authorization URL with PKCE support
	 * TODO: Complete this method implementation
	 * @param usePkce Whether to include PKCE parameters
	 * @param codeChallenge Code challenge from PKCE generation
	 * @param codeChallengeMethod Code challenge method from PKCE generation
	 * @return Full authorization URL with PKCE parameters if requested
	 */
	@AuraEnabled
	public static String generateAuthorizationUrlWithPkce(
		Boolean usePkce,
		String codeChallenge,
		String codeChallengeMethod
	) {
		// TODO: Build base authorization URL like generateAuthorizationUrl
		String url = 
					DEFAULT_LOGIN_URL +	AUTHORIZE_ENDPOINT +
					'?response_type=code' +
					'&client_id=' +
					EncodingUtil.urlEncode(DEFAULT_CLIENT_ID, 'UTF-8') +
					'&redirect_uri=' +
					EncodingUtil.urlEncode(DEFAULT_REDIRECT_URL, 'UTF-8');
		// TODO: Add PKCE parameters if usePkce is true:
		if (usePkce && String.isNotBlank(codeChallenge) && String.isNotBlank(codeChallengeMethod)) {
			url += 	
					// - code_challenge (URL encoded)
					'&code_challenge=' +
					EncodingUtil.urlEncode(codeChallenge, 'UTF-8') +
					// - code_challenge_method (URL encoded)
					'&code_challenge_method=' +
					EncodingUtil.urlEncode(codeChallengeMethod, 'UTF-8');
		}
		// STUB: Return placeholder URL for now
		return url;
	}

	/**
	 * Exchange authorization code for access token (grant_type=authorization_code)
	 * TODO: Complete this method implementation
	 * @param code Authorization code received from the redirect
	 * @return Authentication response with token details or error
	 */
	@AuraEnabled
	public static AuthResponse exchangeCodeForToken(String code) {
		// TODO: Prepare parameters map with:
		Map<String, String> params = new Map<String, String>{
			// - grant_type: 'authorization_code'
			'grant_type=' => GRANT_TYPE_AUTHORIZATION_CODE,
			// - code: code
			'&code=' => code,
			// - client_id: DEFAULT_CLIENT_ID
			'&client_id=' => DEFAULT_CLIENT_ID,
			// - client_secret: DEFAULT_CLIENT_SECRET
			'&client_secret=' => DEFAULT_CLIENT_SECRET,
			// - redirect_uri: DEFAULT_REDIRECT_URL
			'&redirect_uri=' => DEFAULT_REDIRECT_URL
		};

		// TODO: Call makeTokenRequest with params and token URL
		return makeTokenRequest(params, DEFAULT_LOGIN_URL + TOKEN_ENDPOINT);
		// STUB: Return empty response for now
	}

	/**
	 * Exchange authorization code for access token with PKCE support
	 * TODO: Complete this method implementation
	 * @param code Authorization code received from the redirect
	 * @param codeVerifier Code verifier for PKCE
	 * @return Authentication response with token details or error
	 */
	@AuraEnabled
	public static AuthResponse exchangeCodeForTokenWithPkce(String code, String codeVerifier) {
		// TODO: Prepare parameters map like exchangeCodeForToken
		Map<String, String> params = new Map<String, String>{
			'grant_type=' => GRANT_TYPE_AUTHORIZATION_CODE,
			'&code=' => code,
			'&client_id=' => DEFAULT_CLIENT_ID,
			'&client_secret=' => DEFAULT_CLIENT_SECRET,
			'&redirect_uri=' => DEFAULT_REDIRECT_URL
		};
		// TODO: Add code_verifier parameter if provided
		if (String.isNotBlank(codeVerifier)) {
			params.put('&code_verifier=', codeVerifier);
		}
		// TODO: Call makeTokenRequest with params and token URL
		
		// STUB: Return empty response for now
		return makeTokenRequest(params, DEFAULT_LOGIN_URL + TOKEN_ENDPOINT);
	}

	/**
	 * Refresh an existing access token using a refresh token
	 * Extra Credit: Implement this method
	 * TODO: Complete this method implementation
	 * @param refreshToken The refresh token from a previous authentication
	 * @return Authentication response with new token details or error
	 */
	public static AuthResponse refreshToken(String refreshToken) {
		// TODO: Prepare parameters map with:
		Map<String, String> params = new Map<String, String>{
			// - grant_type: 'refresh_token'
			'grant_type=' => GRANT_TYPE_REFRESH_TOKEN,
			// - refresh_token: refreshToken
			'&refresh_token=' => refreshToken,
			// - client_id: DEFAULT_CLIENT_ID
			'&client_id=' => DEFAULT_CLIENT_ID,
			// - client_secret: DEFAULT_CLIENT_SECRET
			'&client_secret=' => DEFAULT_CLIENT_SECRET
		};
		// TODO: Call makeTokenRequest with params and token URL
		return makeTokenRequest(params, DEFAULT_LOGIN_URL + TOKEN_ENDPOINT);
	}

	/**
	 * Class to encapsulate authentication response
	 */
	public class AuthResponse {
		@AuraEnabled
		public Boolean isSuccess;
		@AuraEnabled
		public String accessToken;
		@AuraEnabled
		public String refreshToken;
		@AuraEnabled
		public String instanceUrl;
		@AuraEnabled
		public String tokenType;
		@AuraEnabled
		public Integer expiresIn;
		@AuraEnabled
		public String errorMessage;
		@AuraEnabled
		public String errorDetails;
	}

	/**
	 * Class to encapsulate PKCE response
	 */
	public class PkceResponse {
		@AuraEnabled
		public Boolean isSuccess;
		@AuraEnabled
		public String codeVerifier;
		@AuraEnabled
		public String codeChallenge;
		@AuraEnabled
		public String codeChallengeMethod;
		@AuraEnabled
		public String errorMessage;
		@AuraEnabled
		public String errorDetails;
	}
}
