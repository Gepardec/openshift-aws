#!/bin/bash

rm secrets.tar

tar cvf secrets.tar \
        .aws/config \
        .aws/credentials \
        clientID \
        clientSecret \
        admins \
        cluster-admins \
        $(ls -d -t install-config-* | head -n 1)/install-config.yaml \
        openshift-client-linux-4.3.1.tar.gz \
        openshift-install-linux-4.3.1.tar.gz

travis encrypt-file secrets.tar \
                    secrets.tar.enc \
                    --pro \
                    --force

rm secrets.tar