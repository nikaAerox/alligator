# MediCare User Manual

## Apps Description
MediCare is a mobile application that helps users manage medication reminders, medication intake history, and basic health records. The app is designed for patients, especially busy working adults and elderly users who may forget to take their medicine on time. MediCare also provides simple reports, basic health suggestions, notification alerts, dark mode, and user profile management.

---

## System Requirements
Before using the app, make sure you have:
- An Android device connected by USB, or an emulator
- Flutter installed
- Android Studio installed
- Internet is not required for basic use

---

## System Features
Several main features:
- User Account
- Medication Management
- Reminder Management
- Notification Alert
- Medication Intake History
- Health Record Management
- Simple Health Suggestion

---

## Installation Guide
To install and run the MediCare project, follow these steps:

### 1. Install Flutter
- Download and install Flutter from the official Flutter website.
- Add Flutter to your system PATH so it can be used in the terminal.

### 2. Install Android Studio
- Download and install Android Studio.
- Install the Android SDK.
- Set up an Android emulator if needed.

### 3. Get the Project Files
- Open the MediCare project folder on your computer.

### 4. Open the Project
- Open the project using Visual Studio Code or Android Studio.

### 5. Get Dependencies
Run this command in the terminal:

```bash
flutter pub get
```

### 6. Connect a Device
You can use either:
- A physical Android phone connected by USB
- An Android emulator

### 7. Check Connected Devices
Run this command:

```bash
flutter devices
```

### 8. Run the App
Run this command with your device ID:

```bash
flutter run -d <device_id>
```

Example:

```bash
flutter run -d emulator-5554
```

### 9. First Launch
- Wait for the app to build.
- After the app starts, the welcome page will appear.

## User Guide
If you are running the project using Flutter, open the project folder in your code editor or terminal and run:

## 1.1 First Time Using the App
When the app is opened for the first time:
1. The welcome page will appear.
2. Tap **Get Started**.
3. You will go to the login page.
4. Register a new account if you do not have one.
5. After login, you will enter the main dashboard.

---

## 1.2 Login and Register
### Login
1. Enter your email and password.
2. Tap **Sign In**.
3. If the information is correct, you will be redirected to the home page.
### Register
1. Tap **Create Account**.
2. Fill in your name, email, password, and confirm password.
3. Tap **Register**.
4. After successful registration, log in using your registered account.

---

## 1.3 Home Page
The home page shows a summary of the user's health and medication information. It acts as the main dashboard of the app.

### Main Sections
- **Medication Adherence**: Shows how many medication reminders were taken, missed, or postponed.
- **Next Reminder**: Shows the next upcoming medication reminder.
- **Health Snapshot**: Shows BMI, blood sugar, and blood pressure readings.
- **Medication Intake History**: Shows medication intake records using a chart.
- **Suggestions**: Provides simple health and medication advice based on the user's records.

### History Filter
Users can switch between:
- **Today**
- **Week**
- **Month**
This helps users view medication intake history for different time periods.

---

## 1.4 Medication Page
The Medication page is used to manage the user's medicine list.

### Features
- Search medication by name, dosage, or quantity
- Add new medication
- Edit medication details
- Delete medication
- Add medicine image
- Set medication status as active or inactive

### How to Add Medication
1. Open the **Medication** page.
2. Tap **Add**.
3. Fill in the medication details such as medicine name, dosage, quantity, and notes.
4. Choose the medication status (Active/Inactive).
5. Add an image if needed.
6. Tap **Add Medication**.

### How to Edit Medication
1. Open the **Medication** page.
2. Tap the three-dot menu on the medication card.
3. Select **Edit**.
4. Change the details you want to update.
5. Tap **Save Changes**.

### How to Delete Medication
1. Open the **Medication** page.
2. Tap the three-dot menu on the medication card.
3. Select **Delete**.
4. Confirm the delete action.

---

## 1.5 Schedule Page
The Schedule page is used to manage medication reminders.

### Features
- Add reminder
- Select reminder
- Set selected reminders as daily
- Edit reminder time or medication
- Set reminder status to pending
- Delete reminder

### How to Add a Reminder
1. Open the **Schedule** page.
2. Tap **Reminder**.
3. Select the medication.
4. Choose the reminder time.
5. Tap **Add Reminder**.

### Reminder Status
Reminder status can be:
- **Pending**
- **Taken**
- **Postponed**
- **Missed**

### Daily Reminder
Users can select one or more reminders and tap **Remind Daily** to make them repeat daily.

---

## 1.6 Health Page
The Health page stores the user's basic health records.

### Health Records Included
- BMI
- Blood sugar
- Blood pressure

### How to Update Health Records
1. Open the **Health** page.
2. Tap **Edit** on the record you want to update.
3. Enter the correct values.
4. Tap **Calculate & Save**.

### BMI Calculation
BMI is calculated using:
- Weight in kilograms (kg)
- Height in centimeters (cm)

The system will display the BMI result and status after the values are saved.

---

## 1.7 Profile Page
The Profile page allows users to manage their account settings.

### Features
- View and edit name
- View and edit email
- Change password
- Enable or disable dark mode
- Logout

---

## 1.8 Dark Mode
MediCare supports dark mode to make the app more comfortable to use, especially in low-light environments.

### To Enable Dark Mode
1. Open the **Profile** page.
2. Turn on the **Dark Mode** switch.
3. The app interface will change to dark mode.

---

## 1.9 Notifications
MediCare can send reminder notifications when it is time to take medication.

### Notification Actions
Users can respond to a reminder using:
- **Taken**
- **Postponed**

If no action is taken for a while, the reminder may become **Missed** automatically.

---

## 1.10 Data Storage
The app saves user data locally in the database so that the information can be used again after login.

### Stored Data Includes
- User accounts
- Medication details
- Reminder schedules
- Medication intake history
- Health records

---

## 1.11 Common Problems
### 1. Reminder Not Showing
- Check if notifications are allowed on your phone.
- Make sure battery saver is not blocking the app.
- Check whether the reminder time is set correctly.

### 2. Data Not Saved
- Make sure you tap the correct save button.
- Check whether the app closed before saving.
- Try opening the page again to confirm the data.

### 3. Dark Mode Not Changing
- Go to the Profile page and turn on dark mode again.
- Restart the app if needed.

### 4. App Not Running in Flutter
- Run `flutter pub get` to install required packages.
- Make sure an emulator or Android device is connected.
- Run `flutter devices` to check available devices.

---

## Authors
- Abdul Rahman bin Sabaruddin
