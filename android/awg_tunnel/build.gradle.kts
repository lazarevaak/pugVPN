import org.gradle.api.tasks.testing.logging.TestLogEvent

val awgPackageName = "org.amnezia.awg"
val cmakeAndroidPackageName: String =
    providers.environmentVariable("ANDROID_PACKAGE_NAME").getOrElse(awgPackageName)

plugins {
    id("com.android.library")
}

android {
    namespace = "$awgPackageName.tunnel"
    compileSdk = 35
    ndkVersion = "26.1.10909125"

    defaultConfig {
        minSdk = 24
    }

    sourceSets {
        getByName("main") {
            manifest.srcFile("../amneziawg-android/tunnel/src/main/AndroidManifest.xml")
            java.srcDirs("../amneziawg-android/tunnel/src/main/java")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    externalNativeBuild {
        cmake {
            path("../amneziawg-android/tunnel/tools/CMakeLists.txt")
        }
    }

    testOptions {
        unitTests.all {
            it.testLogging {
                events(
                    TestLogEvent.PASSED,
                    TestLogEvent.SKIPPED,
                    TestLogEvent.FAILED,
                )
            }
        }
    }

    buildTypes {
        all {
            externalNativeBuild {
                cmake {
                    targets("libwg-go.so", "libwg.so", "libwg-quick.so")
                    arguments("-DGRADLE_USER_HOME=${project.gradle.gradleUserHomeDir}")
                }
            }
        }
        getByName("release") {
            externalNativeBuild {
                cmake {
                    arguments("-DANDROID_PACKAGE_NAME=$cmakeAndroidPackageName")
                }
            }
        }
        getByName("debug") {
            externalNativeBuild {
                cmake {
                    arguments("-DANDROID_PACKAGE_NAME=$cmakeAndroidPackageName.debug")
                }
            }
        }
    }

    lint {
        disable += "LongLogTag"
        disable += "NewApi"
    }
}

dependencies {
    implementation("androidx.annotation:annotation:1.7.1")
    implementation("androidx.collection:collection:1.4.0")
    compileOnly("com.google.code.findbugs:jsr305:3.0.2")
    testImplementation("junit:junit:4.13.2")
}
