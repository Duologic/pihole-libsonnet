local k = import 'ksonnet-util/kausal.libsonnet';
local pihole = import 'pihole/pihole.libsonnet';

{
  pihole: pihole {
    _config+:: {
      pihole+: {
        name: 'play',
      },
    },
  },

  local ingress = k.extensions.v1beta1.ingress,
  ingress: ingress.new() +
           ingress.mixin.metadata.withName('ingress')
           + ingress.mixin.metadata.withAnnotationsMixin({
             'ingress.kubernetes.io/ssl-redirect': 'false',
           })
           + ingress.mixin.spec.withRules([
             ingress.mixin.specType.rulesType.mixin.http.withPaths(
               ingress.mixin.spec.rulesType.mixin.httpType.pathsType.withPath('/') +
               ingress.mixin.specType.mixin.backend.withServiceName('pihole-play') +
               ingress.mixin.specType.mixin.backend.withServicePort(80)
             ),
           ]),
}
