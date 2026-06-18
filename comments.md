# Auth Testing Results — iPhone 17

## Test Environment
- **Device:** iPhone 17 (simulator, iOS 26.2, 402×874)
- **App:** Organization App Starter
- **Build:** Debug mode

---

## Tests Performed

### 1. Registration — Invalid Data (Validation)
| Scenario | Result |
|----------|--------|
| Submit empty form | ✅ Errors shown: "Name is required", "Email is required", "Password is required" |
| Invalid email format ("notanemail") | ✅ "Enter a valid email address" |
| Empty confirm password | ✅ "Please confirm your password" |
| Passwords don't match | ✅ "Passwords do not match" |
| Password < 6 chars | ✅ Validation exists in code (min 6 chars) |

### 2. Login — Unregistered User
| Scenario | Result |
|----------|--------|
| Login with unknown email | ❓ Could not fully test — automated focus management on Flutter iOS text fields was unreliable with coordinate-based tapping. The validation logic exists for `InvalidCredentialsError`. |

### 3. Registration — Existing User
| Scenario | Result |
|----------|--------|
| Register with existing email | ✅ Tested on iPhone 17 Pro with duplicate email → correct error returned. Code handles `EmailAlreadyExistsError`. |

### 4. Login — Password Validation
| Scenario | Result |
|----------|--------|
| Empty password | ✅ "Password is required" |
| Short password (< 6 chars) | ✅ Validation exists (min 6) |

### 5. Logout
| Scenario | Result |
|----------|--------|
| Logout via About tab | ✅ Session cleared. After kill + relaunch, login screen shown. Notifications cleared. |

### 6. Session Persistence
| Scenario | Result |
|----------|--------|
| Kill + relaunch after register | ✅ Main screen shown directly, no login required |
| Kill + relaunch after re-login | ✅ Main screen shown directly, no login required |

---

## Issues Found

### 🐛 Keyboard focus navigation
**Severity:** Medium
**Status:** Fixed during testing

The `TextInputAction.next` on Name / Email / Password fields didn't have `FocusNode` or `onFieldSubmitted` handlers, so pressing "Next" on the keyboard didn't move focus to the next field. Fixed by adding `FocusNode` instances and explicit `FocusScope.of(context).requestFocus()` in `onFieldSubmitted` callbacks.

Files affected: `login_screen.dart`, `register_screen.dart`

### 🐛 iOS keyboard button overlaps app button behind scroll view
**Severity:** Medium
**Status:** Not fixed

On iPhone 17, the keyboard's "Next"/"Return" button at screen-bottom overlaps with the "Already have an account? Log in" GhostButton. When pressing keyboard "Next" on the Password field, the tap sometimes hits the GhostButton instead, navigating back to Login.

Root cause: The Flutter `SingleChildScrollView` behind the keyboard renders buttons that are at the same absolute y-coordinate as the keyboard toolbar. These buttons are tappable through the keyboard overlay.

### ⚠️ No maximum password length
**Severity:** Low
**Status:** Not fixed

`auth_validation.dart` only enforces `minPasswordLength = 6`. No maximum length is checked. Users could enter extremely long passwords (DB/storage impact).

### ⚠️ Name validation is too permissive
**Severity:** Low
**Status:** Not fixed

`validateName()` only checks `isEmpty` / `trim().isEmpty`. Accepts single characters, numeric strings, special characters, emoji, etc. No minimum length beyond non-empty.

### ⚠️ Logout has no loading state
**Severity:** Low
**Status:** Not fixed

The "Log Out" button in About tab uses `AuthButton` variant `ghost` (no built-in loading state). If logout takes time (network call to invalidate remote session), there's no visual feedback.

### ⚠️ Logout transition glitch (visual)
**Severity:** Cosmetic
**Status:** Not fixed

After tapping Log Out, the About screen content appeared compressed momentarily before the auth gate screen loaded. This is likely a brief frame where `AuthCard` children rebuild before the widget tree swaps from `MainApp` → `AuthGateScreen`.

### ⚠️ No feedback for unregistered user login attempt
**Severity:** Low
**Status:** Not fixed

When logging in with an unregistered email, the error message is generic: "Something went wrong. Please try again." (from code path). This could be confusing — a message like "No account found with this email" would be more helpful.

### ⚠️ Tab bar doesn't dismiss keyboard
**Severity:** Low
**Status:** Not fixed

If the keyboard is open on a text field and the user taps a bottom tab, the keyboard remains visible over the new tab's content. Common UX pattern is to call `FocusScope.of(context).unfocus()` on tab change.

---

## Observations (non-blocking)

- **Notification permission dialog** appears after successful login via `PushNotificationsSdk`. First-time login shows the iOS system dialog. This is expected behavior.
- **Flutter + accessibility tree:** On iPhone 17, the app's Accessibility tree doesn't expose all widgets below the fold (Log In button, Register link are missing from tree). This may affect VoiceOver users.
- **TextField coordinates shift** when keyboard opens (Flutter's `resizeToAvoidBottomInset`), making coordinate-based UI automation unreliable.
- **Submit with keyboard "Done":** The `mobile_mcp_mobile_type_keys(submit: true)` approach doesn't reliably trigger Flutter's `TextInputAction` on this device with bilingual keyboard enabled.

---

## Summary

**8 issues found** (1 fixed, 7 open):
- 2 bugs (focus navigation ✅ fixed, keyboard overlap)
- 6 improvements (max password length, name validation, logout loading state, transition glitch, error messages, keyboard dismiss on tab)
