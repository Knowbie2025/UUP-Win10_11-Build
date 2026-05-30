#!/bin/bash
UUP_ID=7cb3bf8e-cba4-4e21-a089-5787a76fd839
curl -Ls https://uupdump.net/get.php?id=${UUP_ID}&pack=esd&lang=zh-cn&edition=all > aria2.txt
aria2c -x16 -s16 -j8 -c -i aria2.txt
