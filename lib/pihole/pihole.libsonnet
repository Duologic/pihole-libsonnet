local k = import 'ksonnet-util/kausal.libsonnet';

{
  _config:: {
    pihole: {
      name: error 'must provide pihole name',
      replicas: 1,
    },
  },

  _images+:: {
    pihole: 'pihole/pihole:v5.0',
  },

  local container = k.core.v1.container,
  local containerPort = k.core.v1.containerPort,
  container::
    container.new('pihole-%s' % $._config.pihole.name, self._images.pihole)
    + k.util.resourcesLimits('150m', '30Mi')
    + container.withPorts([
      containerPort.new('http', 80),
      containerPort.new('https', 443),
      containerPort.new('dns-tcp', 53),
      containerPort.newUDP('dns-udp', 53),
    ])
    + container.mixin.livenessProbe.httpGet.withPath('/')
    + container.mixin.livenessProbe.httpGet.withPort(80)
    + container.mixin.livenessProbe.httpGet.withScheme('HTTP')
    + container.mixin.livenessProbe
      .withPeriodSeconds(10)
      .withSuccessThreshold(1)
      .withFailureThreshold(10)
      .withInitialDelaySeconds(30)
      .withTimeoutSeconds(1)
    + container.mixin.readinessProbe.httpGet.withPath('/')
    + container.mixin.readinessProbe.httpGet.withPort(80)
    + container.mixin.readinessProbe.httpGet.withScheme('HTTP')
    + container.mixin.readinessProbe
      .withPeriodSeconds(10)
      .withSuccessThreshold(1)
      .withFailureThreshold(10)
      .withInitialDelaySeconds(30)
      .withTimeoutSeconds(1)
  ,

  local deployment = k.apps.v1.deployment,
  deployment:
    deployment.new('pihole-%s' % $._config.pihole.name, $._config.pihole.replicas, [$.container]),

  local service = k.core.v1.service,
  services: {
    http:
      service.new(
        'pihole-%s' % $._config.pihole.name,
        { name: 'pihole-%s' % $._config.pihole.name },
        [
          {
            name: 'http',
            port: 80,
            protocol: 'TCP',
          },
          {
            name: 'https',
            port: 443,
            protocol: 'TCP',
          },
        ]
      )
      + service.mixin.spec.withType('ClusterIP'),

    tcp:
      service.new(
        'pihole-%s-dns-tcp' % $._config.pihole.name,
        { name: 'pihole-%s' % $._config.pihole.name },
        [{
          port: 53,
          protocol: 'TCP',
        }]
      )
      + service.mixin.spec.withType('LoadBalancer'),

    udp:
      service.new(
        'pihole-%s-dns-udp' % $._config.pihole.name,
        { name: 'pihole-%s' % $._config.pihole.name },
        [{
          port: 53,
          protocol: 'UDP',
        }]
      )
      + service.mixin.spec.withType('LoadBalancer'),
  },
}
