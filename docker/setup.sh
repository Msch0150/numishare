#!/bin/bash

# Variables
# At least numishare is required in the list below
MAIN="../numishare"
COLLECTIONS="alpen auctions cf cfa cfm ch cohen countermarks dinslaken dlt dt gdbz hmfamm koeln literature lvr-lmb megen moers nnc_dnb private_collections rct rgmk scheers srm stmsm uva"
DATA_DIR=${HOME}/data


# preparations
sudo apt install unzip

# Initial setup
mkdir -p "${DATA_DIR}/docker-loris-data/images"
mkdir -p "${DATA_DIR}/docker-solr-data"
sudo chown -R 8983:8983 "${DATA_DIR}/docker-solr-data"
mkdir -p "${DATA_DIR}/docker-fuseki-data"

# Cleanup
cd ${HOME} && \
sudo docker stop $(sudo docker ps -a -q) && \
sudo docker rm $(sudo docker ps -a -q) && \
sudo rm -rf numishare

# setup
export TARGET_DIR=${HOME}/numishare && \
mkdir -p ${TARGET_DIR} && cd ${TARGET_DIR} && \
wget https://github.com/Msch0150/numishare/archive/master.zip && \
unzip master.zip && sudo chown -R 8983:8983 numishare-master/solr-home/ && \
sudo chown 8983:8983 numishare-master/docker/core.properties && \
cd numishare-master && \
sudo ln -s ui default

if [ ! -d "${MAIN}" ]; then
  mkdir -p "${MAIN}"
  cp -rp $(pwd)/* "${MAIN}/"
  cp docker/exist-config.xml "${MAIN}/"
fi

# Adjust german translations ("dirty" workaround and local changes until changes are done in master branch)
sed "/Übergeordneter Typ/q" ui/xslt/functions.xsl > "${MAIN}/ui/xslt/functions.xsl"
cat docker/functions.addendum.de >> "${MAIN}/ui/xslt/functions.xsl"
sed -n -e "/Übergeordneter Typ/,$ p" ui/xslt/functions.xsl >> "${MAIN}/ui/xslt/functions.xsl"

# Adjust ordering base on the availability of an image, here obvThumb. First the item with obvThumb then without obvThumb.
sed "s/ASC(?publisher) ASC(?datasetTitle)/DESC(?obvThumb) ASC(?publisher) ASC(?datasetTitle)/g" ui/sparql/type-examples.sparql > "${MAIN}/ui/sparql/type-examples.sparql"
sed "s/ASC(?publisher) ASC(?datasetTitle)/DESC(?obvThumb) ASC(?publisher) ASC(?datasetTitle)/g" ui/sparql/hoard-examples.sparql > "${MAIN}/ui/sparql/hoard-examples.sparql"

for COLLECTION in ${COLLECTIONS}; do
  if [ ! -d "${DATA_DIR}/docker-numishare-data/${COLLECTION}" ]; then
    mkdir -p "${DATA_DIR}/docker-numishare-data/${COLLECTION}"
    mkdir -p "${DATA_DIR}/docker-numishare-data/${COLLECTION}/ui/xslt/pages"
    mkdir -p "${DATA_DIR}/docker-numishare-data/${COLLECTION}/ui/css"
    mkdir -p "${DATA_DIR}/docker-numishare-data/${COLLECTION}/ui/images/project"
    cp -p "${MAIN}/ui/css/style.css" "${DATA_DIR}/docker-numishare-data/${COLLECTION}/ui/css/style.css"
    cat "${MAIN}/docker/ulpia.style.css" >> "${DATA_DIR}/docker-numishare-data/${COLLECTION}/ui/css/style.css"
    cp -p "${MAIN}/ui/xslt/pages/index.xsl" "${DATA_DIR}/docker-numishare-data/${COLLECTION}/ui/xslt/pages/"
  fi
  # To integrate the collections
  echo '      - "../ui:/usr/local/tomcat/webapps/orbeon/WEB-INF/resources/apps/themes/'${COLLECTION}'"' >> "${MAIN}/docker/docker-compose.yml"
  echo '      - "../:/usr/local/tomcat/webapps/orbeon/WEB-INF/resources/numishare-projects/'${COLLECTION}'"' >> "${MAIN}/docker/docker-compose.yml"
  echo '      - "'${DATA_DIR}'/docker-numishare-data/'${COLLECTION}'/ui/xslt/pages/index.xsl:/usr/local/tomcat/webapps/orbeon/WEB-INF/resources/numishare-projects/'${COLLECTION}'/ui/xslt/pages/index.xsl"'  >> "${MAIN}/docker/docker-compose.yml"
  echo '      - "'${DATA_DIR}'/docker-numishare-data/'${COLLECTION}'/ui/css/style.css:/usr/local/tomcat/webapps/orbeon/WEB-INF/resources/apps/themes/'${COLLECTION}'/css/style.css"' >> "${MAIN}/docker/docker-compose.yml"
  echo '      - "'${DATA_DIR}'/docker-numishare-data/'${COLLECTION}'/ui/images/project:/usr/local/tomcat/webapps/orbeon/WEB-INF/resources/apps/themes/'${COLLECTION}'/images/project"' >> "${MAIN}/docker/docker-compose.yml"
  # to avoid data access via admin
  echo 'ProxyPass /'${COLLECTION}'/ http://orbeon:8080/orbeon/numishare/'${COLLECTION}'/' >> "${MAIN}/docker/httpd.conf"
  echo 'ProxyPassReverse /'${COLLECTION}'/ http://orbeon:8080/orbeon/numishare/'${COLLECTION}'/' >> "${MAIN}/docker/httpd.conf"
done

if [ -f "${DATA_DIR}/docker-numishare-data/page-flow.xml" ]; then
    echo '      - "'${DATA_DIR}'/docker-numishare-data/page-flow.xml:/usr/local/tomcat/webapps/orbeon/WEB-INF/resources/apps/numishare/page-flow.xml"' >> "${MAIN}/docker/docker-compose.yml"
fi

cd "${MAIN}/docker"

echo "Use $(pwd) for docker startup and shutdown"

# docker compose up

# Using the current docker-compose.xml you might want to try:
#
# Numishare: http://localhost:10200/orbeon/numishare/admin/
# Solr     : http://localhost:10202/
# Exist DB : http://localhost:10204
# Loris    : http://localhost:10206/
# Fuseki   : http://localhost:10208/  (username:password displayed in console of Docker or in /fuseki/shiro.ini in section [users])
# Apache   : http://localhost

