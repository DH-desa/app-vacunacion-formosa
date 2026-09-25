# Atajos para correr y buildear cada entorno con el --flavor y el -t
# correctos (ver docs/demo_guia.md). El flavor solo elige el APK; el -t elige
# el código: sin -t, "--flavor demo" corre lib/main.dart contra el backend real.
#
# Con más de un dispositivo conectado: make demo DEVICE=<id> (ver flutter devices).

DEVICE ?=
DEVICE_FLAG := $(if $(DEVICE),-d $(DEVICE),)

.PHONY: demo prod apk-demo apk-prod

demo:
	flutter run $(DEVICE_FLAG) --flavor demo -t lib/demo/main_demo.dart

prod:
	flutter run $(DEVICE_FLAG) --flavor prod -t lib/main.dart

apk-demo:
	dart run flutter_launcher_icons -f flutter_launcher_icons-demo.yaml
	flutter build apk --flavor demo -t lib/demo/main_demo.dart

apk-prod:
	dart run flutter_launcher_icons
	flutter build apk --flavor prod -t lib/main.dart
