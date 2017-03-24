#!/bin/sh

touch /usr/local/apache2/passwords

REQUIRE=""

# create passwd file if auth data was provided
if [ ! -z "$AUTH_USER" ] && [ ! -z "$AUTH_PASS" ]
then
	htpasswd -cb /usr/local/apache2/passwords $AUTH_USER $AUTH_PASS
	REQUIRE="$REQUIRE $AUTH_USER "
fi


if [ ! -z "$AUTH_LDAP_ALLOWED_USERS" ]
then
	REQUIRE="$REQUIRE $AUTH_LDAP_ALLOWED_USERS"
fi

if [ ! -z "$REQUIRE" ]
then
	REQUIRE="Require user $REQUIRE"
fi

# store auth config + proxy in apache conf
export REPL="<Location "/">\n\t\n\tAuthName \"$AUTH_NAME\"\n\tAuthType Basic\n\tAuthBasicProvider file ldap\n\tAuthUserFile \"/usr/local/apache2/passwords\"\n\tAuthLDAPURL "$AUTH_LDAP_HOST"\n\tAuthLDAPBindDN \"$AUTH_LDAP_BINDDN\"\n\tAuthLDAPBindPassword \"$AUTH_LDAP_BINDPASS\"\n\t$REQUIRE\n\tProxyPass \"$PROXY_URL\"\n\tProxyPassReverse \"$PROXY_URL\"\n\tSetEnv proxy-sendcl\n</Location>\nLDAPVerifyServerCert Off\n\n"
perl -i~ -0777 -pe 's/(<Directory "\/usr\/local\/apache2\/htdocs">[^<]+<\/Directory>)/\1\n\n$ENV{REPL}/g' /usr/local/apache2/conf/httpd.conf

perl -i~ -0777 -pe 's/\\t/\t/g' /usr/local/apache2/conf/httpd.conf
perl -i~ -0777 -pe 's/\\n/\n/g' /usr/local/apache2/conf/httpd.conf

# enable modules: ldap, authnz_ldap, proxy, proxy_http
perl -i~ -0777 -pe 's/#(LoadModule authnz_ldap_module modules\/mod_authnz_ldap.so)/\1/g' /usr/local/apache2/conf/httpd.conf
perl -i~ -0777 -pe 's/#(LoadModule ldap_module modules\/mod_ldap.so)/\1/g' /usr/local/apache2/conf/httpd.conf
perl -i~ -0777 -pe 's/#(LoadModule proxy_module modules\/mod_proxy.so)/\1/g' /usr/local/apache2/conf/httpd.conf
perl -i~ -0777 -pe 's/#(LoadModule proxy_http_module modules\/mod_proxy_http.so)/\1/g' /usr/local/apache2/conf/httpd.conf

# start httpd service
httpd-foreground