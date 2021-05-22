local k = import 'ksonnet-util/kausal.libsonnet';

{
  new(
    name='pihole',
    replicas=1,
    image='pihole/pihole:v5.8.1',
  ):: {
    local this = self,
    name:: name,

    local container = k.core.v1.container,
    local containerPort = k.core.v1.containerPort,
    local live = container.livenessProbe,
    local ready = container.readinessProbe,
    container::
      container.new('pihole', [image])
      + k.util.resourcesLimits('150m', '30Mi')
      + container.withPorts([
        containerPort.new('http', 80),
        containerPort.new('https', 443),
        containerPort.new('dns-tcp', 53),
        containerPort.newUDP('dns-udp', 53),
      ])
      + live.httpGet.withPath('/')
      + live.httpGet.withPort(80)
      + live.withFailureThreshold(10)
      + live.withInitialDelaySeconds(30)
      + ready.httpGet.withPath('/')
      + ready.httpGet.withPort(80)
      + ready.withFailureThreshold(10)
      + ready.withInitialDelaySeconds(30)
    ,

    local deployment = k.apps.v1.deployment,
    deployment:
      deployment.new(name, replicas, [self.container]),

    local selector = {
      [x]: this.deployment.spec.template.metadata.labels[x]
      for x in std.objectFields(this.deployment.spec.template.metadata.labels)
    },

    local service = k.core.v1.service,
    local servicePort = k.core.v1.servicePort,
    services: {
      http:
        service.new(
          'pihole-%s' % name,
          selector,
          [
            servicePort.newNamed('http', 80, 80),
            servicePort.newNamed('https', 443, 443),
          ]
        ),

      tcp:
        service.new(
          'pihole-%s-dns-tcp' % name,
          selector,
          [servicePort.new(53, 53)]
        )
        + service.spec.withType('LoadBalancer'),

      udp:
        service.new(
          'pihole-%s-dns-udp' % name,
          selector,
          [
            servicePort.new(53, 53)
            + servicePort.withProtocol('UDP'),
          ]
        )
        + service.spec.withType('LoadBalancer'),
    },
  },
}
