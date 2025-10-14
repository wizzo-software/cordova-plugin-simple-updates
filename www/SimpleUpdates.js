var exec = require('cordova/exec');

var SimpleUpdates = {
	/**
	 * Check for update and prompt user automatically
	 * @param {Function} success - callback(status) - "NO_UPDATE", "UPDATE_STARTED", "UPDATE_CANCELLED"
	 * @param {Function} error - callback(error)
	 */
	checkAndUpdate: function(success, error) {
		exec(success, error, 'SimpleUpdates', 'checkAndUpdate', []);
	}
};

module.exports = SimpleUpdates;

