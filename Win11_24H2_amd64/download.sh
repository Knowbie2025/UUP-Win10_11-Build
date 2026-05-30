#!/bin/bash
UUP_ID=15127f8d-75c8-4150-98d1-5020aa815a35
curl -Ls https://uupdump.net/get.php?id=${UUP_ID}&pack=esd&lang=zh-cn&edition=all > aria2.txt
aria2c -x16 -s16 -j8 -c -i aria2.txt
