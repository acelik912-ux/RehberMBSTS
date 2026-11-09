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
