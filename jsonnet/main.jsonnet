local kp = (import 'kube-prometheus/kube-prometheus.libsonnet') +
           (import 'kube-prometheus/kube-prometheus-anti-affinity.libsonnet') +
           (import 'kube-prometheus/kube-prometheus-static-etcd.libsonnet') +
           {
             prometheus+:: {
               // Openshift 4.0 clusters already have an etcd service and endpoints.
               // Additionally, the etcd client certificates secret should not be embedded in the
               // Cluster Monitoring Operator binary.
               // Hide these fields so they are not rendered as files.
               serviceEtcd:: super.serviceEtcd,
               endpointsEtcd:: super.endpointsEtcd,
               secretEtcdCerts:: super.secretEtcdCerts,
             },
           } +
           (import 'telemeter-client/client.libsonnet') +
           {
             _config+:: {
               imageRepos+:: {
                 openshiftOauthProxy: 'openshift/oauth-proxy',
                 prometheus: 'openshift/prometheus',
                 alertmanager: 'openshift/prometheus-alertmanager',
                 nodeExporter: 'openshift/prometheus-node-exporter',
                 promLabelProxy: 'quay.io/coreos/prom-label-proxy',
                 kubeRbacProxy: 'quay.io/coreos/kube-rbac-proxy',
                 prometheusAdapter: 'quay.io/coreos/k8s-prometheus-adapter-amd64',
               },
               versions+:: {
                 // Because we build OpenShift images separately to upstream,
                 // we have to ensure these versions exist before upgrading.
                 openshiftOauthProxy: 'latest',
                 prometheus: 'v2.5.0',
                 alertmanager: 'v0.15.2',
                 nodeExporter: 'v0.16.0',
                 promLabelProxy: 'v0.1.0',
                 kubeRbacProxy: 'v0.4.1',
                 prometheusAdapter: 'v0.4.1',
               },
               prometheusAdapter+:: {
                 prometheusURL: 'https://prometheus-k8s.openshift-monitoring.svc:9091',
               },
               etcd+:: {
                 ips: [],
                 clientCA: '',
                 clientKey: '',
                 clientCert: '',
                 serverName: '',
               },
               prometheus+:: {
                 namespaces+: [
                   'openshift-cluster-version',
                   'openshift-apiserver',
                   'openshift-kube-scheduler',
                   'openshift-kube-controller-manager',
                 ],
               },
             },
           } +
           (import 'rules.jsonnet') +
           (import 'prometheus-operator.jsonnet') +
           (import 'node-exporter.jsonnet') +
           (import 'kube-state-metrics.jsonnet') +
           (import 'grafana.jsonnet') +
           (import 'alertmanager.jsonnet') +
           (import 'prometheus.jsonnet') +
           (import 'prometheus-adapter.jsonnet') +
           (import 'cluster-monitoring-operator.jsonnet') +
           (import 'remove_runbook.libsonnet') + {
  _config+:: {
    namespace: 'openshift-monitoring',

    hostNetworkInterfaceSelector: 'device!~"veth.+"',

    kubeSchedulerSelector: 'job="scheduler"',

    namespaceSelector: 'namespace=~"(openshift-.*|kube-.*|default|logging)"',
  },
} + {
  local d = super.grafanaDashboards,
  grafanaDashboards:: {
    [k]: d[k]
    for k in std.objectFields(d)
    if !std.setMember(k, ['nodes.json', 'persistentvolumesusage.json', 'pods.json', 'statefulset.json'])
  },
} + {
  _config+:: {
    local j = super.jobs,
    jobs: {
      [k]: j[k]
      for k in std.objectFields(j)
      if !std.setMember(k, ['CoreDNS'])
    },
  },
};

{ ['prometheus-operator/' + name]: kp.prometheusOperator[name] for name in std.objectFields(kp.prometheusOperator) } +
{ ['node-exporter/' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics/' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager/' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-k8s/' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter/' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ ['grafana/' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
{ ['telemeter-client/' + name]: kp.telemeterClient[name] for name in std.objectFields(kp.telemeterClient) } +
{ ['cluster-monitoring-operator/' + name]: kp.clusterMonitoringOperator[name] for name in std.objectFields(kp.clusterMonitoringOperator) }
