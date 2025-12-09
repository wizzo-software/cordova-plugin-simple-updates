var exec = require('cordova/exec');

var SimpleUpdates = {
	/**
	 * Check for update and prompt user automatically
	 * 
	 * Android: Uses Google Play In-App Updates (Immediate)
	 * iOS: Shows full-screen mandatory update overlay
	 * 
	 * @param {Function} success - callback(status):
	 *   - "NO_UPDATE" - No update available
	 *   - "UPDATE_STARTED" - Android: Update flow started
	 *   - "UPDATE_CANCELLED" - Android: User cancelled update
	 *   - "UPDATE_SHOWN" - iOS: Update screen displayed
	 * @param {Function} error - callback(error)
	 * @param {String} appStoreId - (iOS only, optional) App Store ID. Can also be set via APP_STORE_ID preference in config.xml
	 */
	checkAndUpdate: function(success, error, appStoreId) {
		var args = appStoreId ? [appStoreId] : [];
		exec(success, error, 'SimpleUpdates', 'checkAndUpdate', args);
	}
};

module.exports = SimpleUpdates;

