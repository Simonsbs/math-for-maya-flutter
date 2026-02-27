# Math For Maya - Play Store Upload Pack

This folder contains everything needed for the **Google Play Internal Testing** upload.

## Release Artifact
- AAB: `play_store/release/math_for_maya_v1_0_0+1_internal.aab`

## Signing
- Upload certificate: `play_store/release/upload_certificate.pem`
- Fingerprints: `play_store/release/upload_key_fingerprints.txt`
- Keystore location (local machine): `/home/simon/math_for_maya_flutter/android/upload-keystore.jks`

## Store Listing Content
- Short description: `play_store/content/short_description.txt`
- Full description: `play_store/content/full_description.txt`
- Release notes: `play_store/content/release_notes_en-US.txt`
- Contact details: `play_store/content/contact_details.txt`

## Policy/Compliance Content
- Privacy policy (markdown): `play_store/content/privacy_policy.md`
- Privacy policy (html): `play_store/content/privacy_policy.html`
- Data safety answers: `play_store/content/data_safety_answers.md`
- Content rating guidance: `play_store/content/content_rating_guidance.md`
- Target audience guidance: `play_store/content/target_audience_and_content.md`
- App access statement: `play_store/content/app_access.txt`

## Graphics
- App icon 512x512: `play_store/assets/graphics/app_icon_512.png`
- Feature graphic 1024x500: `play_store/assets/graphics/feature_graphic_1024x500.png`
- Phone screenshots: `play_store/assets/screenshots/*.png`

## Console Choices (as requested)
- Distribution: Global
- Price: Free
- Track: Internal testing
- Google Play App Signing: Enabled (recommended)

## Manual Steps in Play Console
1. Create app (if not already created):
   - App name: `Math For Maya`
   - Default language: English (United States)
   - App or game: App
   - Free or paid: Free
2. Setup > App signing:
   - Choose Google Play App Signing.
   - Upload the generated signed AAB when creating release.
3. Grow/Store Presence > Main store listing:
   - Paste text from `play_store/content` files.
   - Upload icon, feature graphic, screenshots.
4. Policy pages:
   - App content > Privacy policy: host `privacy_policy.html` publicly and paste URL.
   - Complete Data safety and Content rating using provided guidance files.
   - Audience: children-focused selections.
5. Testing > Internal testing:
   - Create release and upload `math_for_maya_v1_0_0+1_internal.aab`.
   - Add release notes from `release_notes_en-US.txt`.
   - Add tester emails/groups.
   - Roll out to internal testing.

## Important
A public **Privacy Policy URL** is required in Play Console. Current policy file is ready, but must be hosted at a public URL (e.g. under `https://bestdev.co.il/...`).
