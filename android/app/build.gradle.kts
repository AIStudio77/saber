// 🤖 Generated wholly or partially with GPT-5.6 Sol; OpenAI Codex
import com.android.build.gradle.internal.api.ApkVariantOutputImpl
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localSigningProperties = Properties()
val localSigningPropertiesFile = rootProject.file("key.properties")
if (localSigningPropertiesFile.exists()) {
    localSigningPropertiesFile.inputStream().use(localSigningProperties::load)
}

fun signingValue(propertyName: String, vararg environmentNames: String): String? =
    providers.gradleProperty(propertyName).orNull
        ?: environmentNames.firstNotNullOfOrNull { System.getenv(it)?.takeIf(String::isNotBlank) }
        ?: localSigningProperties.getProperty(propertyName)?.takeIf(String::isNotBlank)

val releaseSigningValues = mapOf(
    "storeFile" to signingValue("storeFile", "SABER_SIGNING_STORE_FILE", "KEY_STORE_FILE"),
    "storePassword" to signingValue("storePassword", "SABER_SIGNING_STORE_PASSWORD", "KEY_STORE_PASSWORD"),
    "keyAlias" to signingValue("keyAlias", "SABER_SIGNING_KEY_ALIAS", "KEY_ALIAS", "ALIAS"),
    "keyPassword" to signingValue("keyPassword", "SABER_SIGNING_KEY_PASSWORD", "KEY_PASSWORD"),
)
val missingReleaseSigningValues = releaseSigningValues.filterValues { it == null }.keys
val releaseSigningConfig = if (missingReleaseSigningValues.isEmpty()) {
    android.signingConfigs.create("release") {
        keyAlias = releaseSigningValues.getValue("keyAlias")
        keyPassword = releaseSigningValues.getValue("keyPassword")
        storeFile = file(releaseSigningValues.getValue("storeFile")!!)
        storePassword = releaseSigningValues.getValue("storePassword")
    }
} else {
    null
}

android {
    namespace = "com.adilhanney.saber"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.adilhanney.saber"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = releaseSigningConfig
        }
    }

    packaging {
        jniLibs.pickFirsts.add("lib/*/libc++_shared.so")
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.2.10")
    implementation("com.google.android.material:material:1.14.0")
}

val abiCodes = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 3)
android.applicationVariants.configureEach {
    val variant = this
    variant.outputs.forEach { output ->
        val abiVersionCode = abiCodes[output.filters.find { it.filterType == "ABI" }?.identifier]
        if (abiVersionCode != null) {
            (output as ApkVariantOutputImpl).versionCodeOverride = variant.versionCode * 10 + abiVersionCode
        }
    }
}

gradle.taskGraph.whenReady {
    val buildsReleaseArtifact = allTasks.any {
        it.project == project && it.name.contains("Release", ignoreCase = true)
    }
    if (!buildsReleaseArtifact) return@whenReady

    if (missingReleaseSigningValues.isNotEmpty()) {
        throw GradleException(
            "Release signing is required. Missing: ${missingReleaseSigningValues.joinToString()}. " +
                "Set SABER_SIGNING_STORE_FILE, SABER_SIGNING_STORE_PASSWORD, " +
                "SABER_SIGNING_KEY_ALIAS, and SABER_SIGNING_KEY_PASSWORD (or their Gradle " +
                "properties), or add them to ignored android/key.properties. " +
                "Use a debug build for local development; release builds never use the debug key.",
        )
    }

    val signingStore = releaseSigningConfig?.storeFile
    if (signingStore?.isFile != true) {
        throw GradleException(
            "Release signing keystore does not exist at '${signingStore?.path}'. " +
                "Update storeFile or SABER_SIGNING_STORE_FILE to point to a readable keystore.",
        )
    }
}
