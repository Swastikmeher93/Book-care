class AuthConfig {
  /// The Web Client ID from your Google Cloud Console.
  ///
  /// This is REQUIRED by Supabase to verify the ID token. You must also
  /// enable the Google provider in your Supabase Dashboard and paste this
  /// Web Client ID and its client secret there.
  static const String googleWebClientId =
      '445697676714-cu5f51fs6ebck7o44bu17i5i1vce1d89.apps.googleusercontent.com';

  /// The Android Client ID from your Google Cloud Console.
  ///
  /// This is required to trigger the native Android sign-in prompt on the device.
  /// Ensure you have registered your SHA-1 certificate fingerprint in GCP console.
  static const String googleAndroidClientId =
      '445697676714-n7lu8482aof8vskii1qkeacgvpr28b3q.apps.googleusercontent.com';
}
