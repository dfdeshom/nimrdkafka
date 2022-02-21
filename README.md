# nimrdkafka

Low-level Nim wrapper for `librdkafka`. Since this is a wrapper, you need to
have `librdkafka` installed and accessible in `LD_LIBRARY_PATH`.

## Example
See the `example.nim` file

## librdkafka compatibility
```
library: librdkafka
version: 1.6.2
commit: 4483be32ba833e0a2a9129e2510bd63a40655b43
```

Please install `librdkafka 1.6.2` from source before installing this nim package:

https://github.com/edenhill/librdkafka

### Installing librdkafka

```
git clone https://github.com/edenhill/librdkafka
cd librdkafka
git checkout v1.6.2
```

Read `README.md` file in `librdkafka` project for building and installing.

### Troubleshooting

1. Make sure your topic name and partition number is correct in your code.
2. If using docker for your kafka runtime, make sure the exposed port and hostname is correct.
