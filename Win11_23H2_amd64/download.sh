#!/bin/bash
UUP_ID=7f6836ae-9517-4e27-9f76-5823e0b6744c
curl -Ls https://uupdump.net/get.php?id=${UUP_ID}&pack=esd&lang=zh-cn&edition=all > aria2.txt
aria2c -x16 -s16 -j8 -c -i aria2.txt
