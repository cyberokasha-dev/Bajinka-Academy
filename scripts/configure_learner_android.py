from pathlib import Path
root = Path(__file__).resolve().parents[1] / 'apps' / 'learner' / 'android'
gradle = root / 'app' / 'build.gradle.kts'
text = gradle.read_text()
text = text.replace('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true')
text += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
gradle.write_text(text)
manifest = root / 'app' / 'src' / 'main' / 'AndroidManifest.xml'
text = manifest.read_text().replace('<application', '<uses-permission android:name="android.permission.INTERNET" />\n    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />\n    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />\n    <application', 1)
text = text.replace('android:label="bajinka_academy"', 'android:label="Bajinka Academy"')
text = text.replace('</application>', '''<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter><action android:name="android.intent.action.BOOT_COMPLETED" /><action android:name="android.intent.action.MY_PACKAGE_REPLACED" /></intent-filter>
        </receiver>
    </application>''')
manifest.write_text(text)
