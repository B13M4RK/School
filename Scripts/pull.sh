#!/bin/bash

cd
cd Developer/School
git pull
cd

# Zeigt eine Desktop-Benachrichtigung an
notify-send "Git Pull" "Documents/School wurde erfolgreich aktualisiert!"
cd
