module.exports = {
  gateway: {
    fqdn: 'gateway.' + process.env.DOMAIN_SUFFIX + 'thoughtdata.thoughtworks.net',
    redirectInsecure: true,
    useHsts: true,
    useCsp: true,
    default: true,
    upstreams: {
      gateway: 'gateway.thoughtdata.svc.cluster.local:9000'
    },
    paths: {
      '/': 'gateway'
    }
  },
  dashboard: {
    fqdn: 'dashboard.' + process.env.DOMAIN_SUFFIX + 'thoughtdata.thoughtworks.net',
    redirectInsecure: true,
    useHsts: true,
    useCsp: true,
    upstreams: {
      dashboard: 'dashboard.thoughtdata.svc.cluster.local:9001'
    },
    paths: {
      '/': 'dashboard'
    }
  },
  rabbitmq: {
    fqdn: 'rabbitmq.' + process.env.DOMAIN_SUFFIX + 'thoughtdata.thoughtworks.net',
    redirectInsecure: true,
    useHsts: true,
    useCsp: true,
    upstreams: {
      rabbitmq: 'rabbitmq.thoughtdata.svc.cluster.local:15672'
    },
    paths: {
      '/': 'rabbitmq'
    }
  }
};
