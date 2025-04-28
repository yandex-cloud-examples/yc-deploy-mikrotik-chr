/system identity set name=${CHR_NAME}
/user add name=${ADMIN_NAME} password="${ADMIN_PASS}" group=full
/user remove admin
/file add name=mykey type=file contents="${ADMIN_SSH_KEY}"
/user ssh-keys import user=${ADMIN_NAME} public-key-file=mykey
/ip ssh set always-allow-password-login=no
/ip service disable telnet,ftp,www,api,api-ssl
