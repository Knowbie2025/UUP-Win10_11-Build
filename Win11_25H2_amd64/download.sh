#!/bin/bash
UUP_ID=b4d8466a-0024-4453-a0ed-1e0b9f7793d3
curl -Ls https://uupdump.net/get.php?id=${UUP_ID}&pack=esd&lang=zh-cn&edition=all > aria2.txt
aria2c -x16 -s16 -j8 -c -i aria2.txt
