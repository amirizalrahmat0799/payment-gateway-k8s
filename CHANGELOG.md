# Changelog

All notable changes to this project. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Dependabot: weekly, grouped minor and patch updates for GitHub Actions, so CI checks them together. Major upgrades are left
  for deliberate, hand-made changes.

## [1.0.0] - 2026-09-30

### Added
- Kustomize deployment of the payment gateway and merchant dashboard to a 3-node kind cluster: Deployments,
  StatefulSets for PostgreSQL and Kafka, probes, HPA, PodDisruptionBudget and a settlement CronJob.
- Restricted Pod Security, default-deny NetworkPolicies, ResourceQuota and LimitRange.
- Prometheus, alert rules and a provisioned Grafana dashboard.
- CI that validates the manifests and deploys to a kind cluster with a smoke test through the Ingress.

[Unreleased]: https://github.com/amirizalrahmat0799/payment-gateway-k8s/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/amirizalrahmat0799/payment-gateway-k8s/releases/tag/v1.0.0
