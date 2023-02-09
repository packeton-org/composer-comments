#!/bin/bash
set -ex

curl https://getcomposer.org/composer.phar -o composer.phar
chmod +x composer.phar

if [[ -f ./phar-patcher ]]; then
  ./phar-patcher composer.phar
else
  ../phar-patcher composer.phar
fi

./composer.phar dump-autoload

echo "Finished Successfully"
