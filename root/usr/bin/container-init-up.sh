#!/command/with-contenv bash

shopt -s globstar
for i in /usr/bin/container-init-up-*.sh; do # Whitespace-safe and recursive
    echo "*** Process file ""$i"" ***"
    sh -c "$i"
done
