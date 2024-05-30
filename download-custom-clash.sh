#!/bin/bash

cd Xboard/
docker-compose exec -it xboard sh << EOF
cd resources/rules/
wget https://gist.githubusercontent.com/danielzi/5dc31457f5f0b1b64814b14028b1c0cb/raw/custom.clash.yaml
exit
EOF
