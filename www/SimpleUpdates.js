var exec = require('cordova/exec');

var SimpleUpdates = {
	/**
	 * Check for update and prompt user automatically
	 * 
	 * Android: Uses Google Play In-App Updates (Immediate)
	 * iOS: Shows full-screen mandatory update overlay with app icon
	 * 
	 * @param {Function} success - callback(status):
	 *   - "NO_UPDATE" - No update available
	 *   - "UPDATE_STARTED" - Android: Update flow started
	 *   - "UPDATE_CANCELLED" - Android: User cancelled update
	 *   - "UPDATE_SHOWN" - iOS: Update screen displayed
	 * @param {Function} error - callback(error)
	 * @param {Object} options - (optional) Configuration options:
	 *   - appStoreId (String): (iOS only) App Store ID
	 *   - fakeVersion (String): (iOS only, for testing) Fake current version to test update flow (e.g., "1.0.0")
	 *   - message (String): (iOS only) Custom message text. Use {version} placeholder for store version
	 *   - buttonText (String): (iOS only) Custom button text
	 */
	checkAndUpdate: function(success, error, options) {
		options = options || {};
		
		var args = [
			options.appStoreId || null,
			options.fakeVersion || null,
			options.message || null,
			options.buttonText || null
		];
		
		console.log('🔵 JS DEBUG: Calling exec with args:', JSON.stringify(args, null, 2));
		
		exec(success, error, 'SimpleUpdates', 'checkAndUpdate', args);
	}
};

module.exports = SimpleUpdates;

