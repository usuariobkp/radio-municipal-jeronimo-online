echo " ******************************** "
echo "Cargar los valores de configuración ..."
echo " ******************************** "

source compiler-cfg.sh
# REFERENCIA
# export APPNAME=jeronimo
# export MKEY="xxxxxxxxxx"
# export MYSDKPATH=/home/user/android-sdk-linux
echo "Importado"
echo " -- APPNAME=${APPNAME}"
echo " -- MKEY=${MKEY}"
echo " -- MYSDKPATH=${MYSDKPATH}"


echo " ******************************** "
echo "Identificando la versión en config.xml ..."
echo " ******************************** "

# llevar la versión que definí en el config.xml a una variable de javascript
echo "/*AUTOGENERADO POR EL COMPILADOR*/" > www/version.js
cat config.xml \
    | grep '^<widget' \
    | sed 's|^.*version="\([^"]\+\)".*|var cordova_app_version = "\1";|' \
    >> www/version.js

export ANDROID_HOME=$MYSDKPATH
export PATH=${PATH}:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

echo " ******************************** "
echo "Compilando local ..."
echo " ******************************** "
cordova build android --release

# Solo una vez, crear la llave
# keytool -genkey -v -keystore ${APPNAME}.keystore -alias ${APPNAME} -keyalg RSA -keysize 2048 -validity 10000
# queda en platforms/android/build/outputs/apk/android-release-unsigned.apk

echo " ******************************** "
echo "Compilando con key ..."
echo " ******************************** "

jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore ${APPNAME}.keystore platforms/android/build/outputs/apk/android-release-unsigned.apk ${APPNAME} <<< $MKEY


echo " ******************************** "
echo "Alineado y balanceado"
echo " ******************************** "

rm platforms/android/build/outputs/apk/android-release-unsigned-aligned.apk

${MYSDKPATH}/build-tools/24.0.3/zipalign -v -p 4 \
  platforms/android/build/outputs/apk/android-release-unsigned.apk \
  platforms/android/build/outputs/apk/android-release-unsigned-aligned.apk

echo " ******************************** "
echo "Firmando ando"
echo " ******************************** "

# borrar el anterior comppilado
rm platforms/android/build/outputs/apk/${APPNAME}-singned.apk


${MYSDKPATH}/build-tools/24.0.3/apksigner sign \
    --ks ${APPNAME}.keystore \
    --ks-pass env:MKEY \
    --out platforms/android/build/outputs/apk/${APPNAME}-singned.apk \
    platforms/android/build/outputs/apk/android-release-unsigned-aligned.apk
