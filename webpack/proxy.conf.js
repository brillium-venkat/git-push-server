function setupProxy() {
  const tls = process.env.TLS;
  const conf = [
    {
      context: [
        '/api',
        '/services',
        '/management',
        '/swagger-resources',
        '/v2/api-docs',
        '/v3/api-docs',
        '/h2-console',
        '/auth',
        '/health',
      ],
      // target: `http${tls ? 's' : ''}://localhost:8091`,
      target: `http${process.argv.includes('--ssl') ? 's' : ''}://localhost:8091`,
      secure: false,
      changeOrigin: false,
    },
  ];
  return conf;
}

module.exports = setupProxy();
