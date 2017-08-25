#/bin/bash

version=$1

major=`echo $version | cut -d. -f1`
minor=`echo $version | cut -d. -f2`
revision=`echo $version | cut -d. -f3`
# revision=`expr $revision + 1`

echo "$major.$minor.$revision"

if [[ $major == 7 || ($major == 8 && $minor -le 2) ]]
then
    echo "ok"
else
    echo "no"
fi
