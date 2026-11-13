"""flutter create sonrası Android ayarları: uygulama adı, sabit imza, kamera/galeri izinleri, arm64."""
import pathlib
import re

manifest = pathlib.Path('android/app/src/main/AndroidManifest.xml')
s = manifest.read_text(encoding='utf-8')
s = re.sub(r'android:label="[^"]*"', 'android:label="Rehber MBSTS"', s, count=1)
if 'android.permission.CAMERA' not in s:
    s = s.replace('<application', '<uses-permission android:name="android.permission.CAMERA" />\n    <application', 1)
manifest.write_text(s, encoding='utf-8')

kts = pathlib.Path('android/app/build.gradle.kts')
groovy = pathlib.Path('android/app/build.gradle')
if kts.exists():
    g = kts.read_text(encoding='utf-8')
    block = '''
    signingConfigs {
        create("rehber") {
            storeFile = file("../../tool/rehber.keystore")
            storePassword = "rehber2026"
            keyAlias = "rehber"
            keyPassword = "rehber2026"
        }
    }

    buildTypes {'''
    if 'create("rehber")' not in g:
        g = g.replace('\n    buildTypes {', block, 1)
        g = g.replace('signingConfig = signingConfigs.getByName("debug")', 'signingConfig = signingConfigs.getByName("rehber")')
    if 'abiFilters' not in g:
        g = g.replace('    defaultConfig {', '    defaultConfig {\n        ndk { abiFilters += listOf("arm64-v8a") }', 1)
    kts.write_text(g, encoding='utf-8')
    print(g)
elif groovy.exists():
    g = groovy.read_text(encoding='utf-8')
    block = '''
    signingConfigs {
        rehber {
            storeFile file("../../tool/rehber.keystore")
            storePassword "rehber2026"
            keyAlias "rehber"
            keyPassword "rehber2026"
        }
    }

    buildTypes {'''
    if 'rehber {' not in g:
        g = g.replace('\n    buildTypes {', block, 1)
        g = g.replace('signingConfig = signingConfigs.debug', 'signingConfig = signingConfigs.rehber')
        g = g.replace('signingConfig signingConfigs.debug', 'signingConfig signingConfigs.rehber')
    if 'abiFilters' not in g:
        g = g.replace('    defaultConfig {', "    defaultConfig {\n        ndk { abiFilters 'arm64-v8a' }", 1)
    groovy.write_text(g, encoding='utf-8')
    print(g)

# ---- Eklentilerin compileSdk değerini 36'ya yükselt (eski eklentiler AAR denetiminde takılmasın) ----
root_kts = pathlib.Path('android/build.gradle.kts')
root_groovy = pathlib.Path('android/build.gradle')
if root_kts.exists():
    r = root_kts.read_text(encoding='utf-8')
    fix = '''subprojects {
    val rehberFix: Project.() -> Unit = {
        extensions.findByName("android")?.withGroovyBuilder { setProperty("compileSdk", 36) }
    }
    if (state.executed) rehberFix() else afterEvaluate { rehberFix() }
}

'''
    if 'rehberFix' not in r:
        root_kts.write_text(fix + r, encoding='utf-8')
elif root_groovy.exists():
    r = root_groovy.read_text(encoding='utf-8')
    fix = '''subprojects {
    def rehberFix = { p -> if (p.extensions.findByName("android") != null) { p.android.compileSdkVersion 36 } }
    if (state.executed) { rehberFix(project) } else { afterEvaluate { rehberFix(project) } }
}

'''
    if 'rehberFix' not in r:
        root_groovy.write_text(fix + r, encoding='utf-8')

# ---- Android 11+ için metin okuma (TTS) ve web bağlantısı sorguları ----
s = manifest.read_text(encoding='utf-8')
if 'TTS_SERVICE' not in s:
    q = '''    <queries>
        <intent>
            <action android:name="android.intent.action.TTS_SERVICE" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
    </queries>
'''
    if '<queries>' in s:
        s = s.replace('<queries>', q.strip().replace('</queries>', '').rstrip() + '\n', 1)
    else:
        s = s.replace('</manifest>', q + '</manifest>', 1)
    manifest.write_text(s, encoding='utf-8')

# ---- Günlük hatırlatma (flutter_local_notifications): izinler, alıcılar, desugaring ----
s = manifest.read_text(encoding='utf-8')
for perm in ['android.permission.POST_NOTIFICATIONS', 'android.permission.RECEIVE_BOOT_COMPLETED']:
    if perm not in s:
        s = s.replace('<application', f'<uses-permission android:name="{perm}" />\n    <application', 1)
if 'ScheduledNotificationReceiver' not in s:
    rec = """        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
"""
    s = s.replace('</application>', rec + '    </application>', 1)
manifest.write_text(s, encoding='utf-8')

if kts.exists():
    g = kts.read_text(encoding='utf-8')
    if 'isCoreLibraryDesugaringEnabled' not in g:
        g = g.replace('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', 1)
        g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    kts.write_text(g, encoding='utf-8')
elif groovy.exists():
    g = groovy.read_text(encoding='utf-8')
    if 'coreLibraryDesugaringEnabled' not in g:
        g = g.replace('compileOptions {', 'compileOptions {\n        coreLibraryDesugaringEnabled true', 1)
        g += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
    groovy.write_text(g, encoding='utf-8')
print(manifest.read_text(encoding='utf-8'))

# ---- Sürüm derlemesinde Android lint'i kapat (JDK 17'de lint aracı çöküyor) ----
if kts.exists():
    g = kts.read_text(encoding='utf-8')
    if 'checkReleaseBuilds' not in g:
        g = g.replace('android {', 'android {\n    lint {\n        checkReleaseBuilds = false\n        abortOnError = false\n    }', 1)
        kts.write_text(g, encoding='utf-8')
    print(g)
elif groovy.exists():
    g = groovy.read_text(encoding='utf-8')
    if 'checkReleaseBuilds' not in g:
        g = g.replace('android {', 'android {\n    lintOptions {\n        checkReleaseBuilds false\n        abortOnError false\n    }', 1)
        groovy.write_text(g, encoding='utf-8')

# ---- Sesle not alma (speech_to_text): mikrofon izni ve ses tanıma servisine erişim ----
s = manifest.read_text(encoding='utf-8')
for perm in ['android.permission.RECORD_AUDIO', 'android.permission.INTERNET']:
    if perm not in s:
        s = s.replace('<application', f'<uses-permission android:name="{perm}" />\n    <application', 1)
if 'android.speech.RecognitionService' not in s:
    q = '<intent><action android:name="android.speech.RecognitionService" /></intent>'
    if '<queries>' in s:
        s = s.replace('<queries>', '<queries>\n        ' + q, 1)
    else:
        s = s.replace('</manifest>', '    <queries>' + q + '</queries>\n</manifest>', 1)
manifest.write_text(s, encoding='utf-8')
