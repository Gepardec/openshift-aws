#!/bin/bash

rm secrets.tar

tar cvf secrets.tar \
        .aws/config \
        .aws/credentials \
        clientID \
        clientSecret \
        cluster-admins \
        $(ls -d -t install-config-* | head -n 1)/install-config.yaml \
        openshift-client-linux-4.2.2.tar.gz \
        openshift-install-linux-4.2.2.tar.gz

travis encrypt-file secrets.tar \
                    secrets.tar.enc \
                    --pro \
                    --force

rm secrets.tar