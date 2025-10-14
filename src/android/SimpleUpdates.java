package com.wizzo.simpleupdates;

import android.app.Activity;
import android.content.Intent;
import android.util.Log;

import com.google.android.play.core.appupdate.AppUpdateInfo;
import com.google.android.play.core.appupdate.AppUpdateManager;
import com.google.android.play.core.appupdate.AppUpdateManagerFactory;
import com.google.android.play.core.install.model.AppUpdateType;
import com.google.android.play.core.install.model.UpdateAvailability;
import com.google.android.gms.tasks.Task;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;

/**
 * Simple Updates Plugin
 * One function: check and prompt for update if available
 */
public class SimpleUpdates extends CordovaPlugin {

	private static final String TAG = "SimpleUpdates";
	private static final int UPDATE_REQUEST_CODE = 0xA12E; // 41262 - unique code
	
	private AppUpdateManager updateManager;
	private CallbackContext updateCallback;

	@Override
	public boolean execute(String action, JSONArray args, CallbackContext callbackContext) {
		
		if ("checkAndUpdate".equals(action)) {
			checkAndUpdate(callbackContext);
			return true;
		}
		
		return false;
	}

	/**
	 * Check for update and prompt user automatically
	 */
	private void checkAndUpdate(CallbackContext callbackContext) {
		this.updateCallback = callbackContext;
		
		cordova.getThreadPool().execute(() -> {
			try {
				updateManager = AppUpdateManagerFactory.create(cordova.getContext());
				Task<AppUpdateInfo> infoTask = updateManager.getAppUpdateInfo();
				
				infoTask.addOnSuccessListener(info -> {
					if (info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
						info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)) {
						
						Log.i(TAG, "Update available - starting update flow");
						startUpdate(info);
					} else {
						Log.i(TAG, "No update available");
						callbackContext.success("NO_UPDATE");
					}
				}).addOnFailureListener(e -> {
					Log.e(TAG, "Check failed: " + e.getMessage());
					callbackContext.error("CHECK_FAILED: " + e.getMessage());
				});
				
			} catch (Exception e) {
				Log.e(TAG, "Error: " + e.getMessage());
				callbackContext.error("ERROR: " + e.getMessage());
			}
		});
	}

	/**
	 * Start immediate update
	 */
	private void startUpdate(AppUpdateInfo info) {
		try {
			cordova.setActivityResultCallback(this);
			updateManager.startUpdateFlowForResult(
				info,
				AppUpdateType.IMMEDIATE,
				cordova.getActivity(),
				UPDATE_REQUEST_CODE
			);
			Log.i(TAG, "Update dialog shown");
		} catch (Exception e) {
			Log.e(TAG, "Start update error: " + e.getMessage());
			if (updateCallback != null) {
				updateCallback.error("START_FAILED: " + e.getMessage());
			}
		}
	}

	@Override
	public void onActivityResult(int requestCode, int resultCode, Intent data) {
		Log.d(TAG, String.format("onActivityResult: req=%d, expected=%d, result=%d", 
			requestCode, UPDATE_REQUEST_CODE, resultCode));
		
		// Only handle our update request
		if (requestCode != UPDATE_REQUEST_CODE) {
			super.onActivityResult(requestCode, resultCode, data);
			return;
		}

		// Handle update result
		if (updateCallback != null) {
			switch (resultCode) {
				case Activity.RESULT_OK:
					Log.i(TAG, "Update accepted");
					updateCallback.success("UPDATE_STARTED");
					break;
					
				case Activity.RESULT_CANCELED:
					Log.i(TAG, "Update cancelled by user");
					updateCallback.success("UPDATE_CANCELLED");
					break;
					
				default:
					Log.w(TAG, "Unknown result: " + resultCode);
					updateCallback.error("UNKNOWN_RESULT");
			}
			updateCallback = null;
		}
	}
}

