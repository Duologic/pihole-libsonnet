# Pi-hole jsonnet library

Jsonnet library for https://pi-hole.net/

## Usage

Install it with jsonnet-bundler:

```console
jb install https://github.com/Duologic/pihole-libsonnet`
```

Import into your jsonnet:

```jsonnet
local pihole = import 'github.com/Duologic/pihole-libsonnet/main.libsonnet';

{
  pihole: pihole.new('pihole-play'),
}
```
