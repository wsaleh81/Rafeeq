# Play Console answers — Rihal

Copy these answers into Play Console under **Policy and programs → App content**. They match what the app does as of build `play-release`.

## Privacy policy
URL: `https://github.com/wsaleh81/Rihal/blob/main/PRIVACY.md`
(The URL works after the `play-release` branch is merged into `main`. The app's Settings → About → Privacy policy opens the same link.)

## App access
**All functionality is available without special access.** The app has no login.

## Ads
**No, my app does not contain ads.**

## Content rating (IARC questionnaire)
- Email: wael.m.abdullah@gmail.com
- Category: **All Other App Types**
- Violence, blood, fear: **No** for all
- Sexuality, nudity: **No** for all
- Language (profanity, crude humour): **No**
- Controlled substances (drugs, alcohol, tobacco): **No**
- Gambling or simulated gambling: **No**
- Does the app let users interact or exchange content with other users? **No**
- Does the app share the user's current physical location with other users? **No**
- Does the app allow users to purchase digital goods? **No**
- Is the app a web browser or search engine? **No**
- Expected rating: **Everyone / PEGI 3 / 3+**

## Target audience and content
- Target age groups: **13–15, 16–17, 18 and over**. Do not select ages under 13, because that brings in the Families policy requirements.
- Could the app unintentionally appeal to children? **No**

## News app
**No**

## Data safety
**Does your app collect or share any of the required user data types?** Yes. The app sends location to third-party services for mosque search, weather and the city name. Google counts that as collecting data, even though the developer never receives it.

**Is all user data encrypted in transit?** Yes. All requests use HTTPS.

**Do you provide a way for users to request that their data be deleted?** Choose the option that the app does not store data off the device. The data is processed ephemerally, nothing is retained, and uninstalling the app removes all local data.

Data types to declare:

| Data type | Collected | Shared | Processed ephemerally | Required or optional | Purpose |
|---|---|---|---|---|---|
| Location → Approximate location | Yes | Yes (OpenStreetMap, Open-Meteo) | Yes | Optional (users can pick a city) | App functionality |
| Location → Precise location | Yes | Yes | Yes | Optional | App functionality |

Precise location is declared because Google's definition of "approximate" is an area of 3 km² or more. Rounding to 2 decimals gives about 1 km², which Google counts as precise. Over-declaring here is safer than having the app rejected.

Do not declare any other data types (no personal info, contacts, photos, app activity, device IDs or diagnostics).

## Government app
**No**

## Financial features
**My app doesn't provide any financial features.**

## Health
**My app does not have any health features.**

## Advertising ID
**No.** The app does not use the advertising ID.

## Permissions declarations
None needed. `USE_EXACT_ALARM` was removed. The app uses `SCHEDULE_EXACT_ALARM`, which the user grants and which needs no declaration form. There is no background location and no foreground service.

## Store settings
- App category: **Travel & Local**
- Tags: Prayer times, Islam, Travel guides, Compass
- Contact email: wael.m.abdullah@gmail.com
- Price: **Free**
- Countries: all

## Release notes (first release)
**English:** First release of Rihal: Qibla compass, prayer times with adhan alerts, nearby mosques, Azkhar and the Mushaf, in 11 languages.
**Arabic:** الإصدار الأول من رحّال: بوصلة القبلة، ومواقيت الصلاة مع تنبيهات الأذان، والمساجد القريبة، والأذكار والمصحف، بإحدى عشرة لغة.
