#!/bin/bash -e
#vars
SQL_LINK_MS=https://download.microsoft.com/download/c/a/3/ca30f71c-4942-46c2-9bd9-ea47e8c7659c/
SQL_LINK_ZIP=sqlpackage-linux-x64-en-16.1.8089.0.zip
SQL_INS_DIR=sqlpackage_bin
SQL_BACPAC_FILE="sqlexport-last.bacpac"
#KeyVault vars
KV_SUBSCRIPTION="ca8cc99b-384a-4c88-8314-e2c22bdc7d5b"
KV_NAME="westeuropestg1optkv"

install_sqlpackage() {
    wget --directory-prefix=${SQL_INS_DIR}/  ${SQL_LINK_MS}${SQL_LINK_ZIP}
    unzip ${SQL_INS_DIR}/${SQL_LINK_ZIP} -d ${SQL_INS_DIR}
    rm ${SQL_INS_DIR}/${SQL_LINK_ZIP}
    chmod a+x ${SQL_INS_DIR}/sqlpackage
    ln -s ${PWD}/${SQL_INS_DIR}/sqlpackage $HOME/bin/
    echo "sqlpackage installed"
}

sql_bkp () {
    SQL_DB_SERVER=$(az keyvault secret show --vault-name "${KV_NAME}" --name sql-server-database-url --query "value" -o tsv)
    SQL_DB_NAME=$(az keyvault secret show --vault-name "${KV_NAME}" --name sql-server-database-db-name --query "value" -o tsv)
    SQL_DB_USER=$(az keyvault secret show --vault-name "${KV_NAME}" --name sql-server-database-username --query "value" -o tsv)
    SQL_DB_PWD=$(az keyvault secret show --vault-name "${KV_NAME}" --name sql-server-database-password --query "value" -o tsv)
    sqlpackage \
        /Action:Export \
        /TargetFile:"${SQL_BACPAC_FILE}" \
        /SourceConnectionString:"Server=tcp:"${SQL_DB_SERVER}",1433; \
                                Initial Catalog="${SQL_DB_NAME}"; \
                                Persist Security Info=True; \
                                User ID="${SQL_DB_USER}"; \
                                Password="${SQL_DB_PWD}"; \
                                MultipleActiveResultSets=True; \
                                Encrypt=False; \
                                TrustServerCertificate=True; \
                                Connection Timeout=30;"
}

keyvault_bkp () {
    az login 
    az account set --subscription "${KV_SUBSCRIPTION}"
    az provider register -n Microsoft.KeyVault
    
    KV_SECRET_ID_LIST=($(az keyvault secret list --vault-name "${KV_NAME}" | jq '.[] | .id ' | tr -d '"'))
    for KV_SECRET_ID in "${KV_SECRET_ID_LIST[@]}"
    do
        echo "Backuping $(basename "${KV_SECRET_ID}")"
        az keyvault secret backup --id "${KV_SECRET_ID}" --file $(basename "${KV_SECRET_ID}").kv
    done
}
if ! sqlpackage -? > /dev/null 2>&1
then
    install_sqlpackage
fi
#keyvault_bkp
#sql_bkp
