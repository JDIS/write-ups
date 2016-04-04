#!/bin/sh
for algo in aes-128-cbc aes-128-ecb aes-192-cbc aes-192-ecb aes-256-cbc aes-256-ecb base64 bf bf-cbc bf-cfb bf-ecb bf-ofb camellia-128-cbc camellia-128-ecb camellia-192-cbc camellia-192-       …ecb camellia-256-cbc camellia-256-ecb cast cast-cbc cast5-cbc cast5-cfb cast5-ecb cast5-ofb des des-cbc des-cfb des-ecb des-ede des-ede-cbc des-ede-cfb des-ede-ofb des-ede3 des-ede3-cbc       …des-ede3-cfb des-ede3-ofb des-ofb des3 desx idea idea-cbc idea-cfb idea-ecb idea-ofb rc2 rc2-40-cbc rc2-64-cbc rc2-cbc rc2-cfb rc2-ecb rc2-ofb rc4 rc4-40 seed seed-cbc seed-cfb
do
  openssl $algo -d -a -in encrypted -out "decrypted/$algo" -kfile key.bin
done

for file in decrypted/*
do
  file "$file"
done

for file in decrypted/*
do
 strings "$file" | grep -i "ndh"
done
