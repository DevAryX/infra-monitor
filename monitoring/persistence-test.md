# Monitoring Persistence Test

## Purpose

This test checks that Prometheus and Grafana data survives normal Docker container recreation.

The monitoring stack uses named Docker volumes:

```text id="2v6gzt"
prometheus-data
grafana-data
```

So even if the containers are removed, the important data should still stay.

## Test

Before stopping the stack, I checked:

```text id="el2zhz"
Prometheus container ID
Grafana container ID
Docker volumes
existing Prometheus data
Grafana dashboard state
```

Then I stopped the containers with:

```bash id="wf3etp"
docker compose -f docker/docker-compose.yml down
```

I did **not** use `-v`, because that would remove the volumes as well.

Then I recreated the stack:

```bash id="fj29lv"
docker compose -f docker/docker-compose.yml up -d
```

## Prometheus Result

Prometheus came back with a new container ID, but it reattached to the same `prometheus-data` volume.

I checked old metric data from before the container was removed, and Prometheus still had it.

So yeah, the time-series data survived outside the original container.

## Grafana Result

Grafana also came back with a new container ID.

After recreation:

```text id="m34689"
my changed admin login still worked
Prometheus data source was still there
Infra Monitor — EC2 Overview dashboard was still there
all panels were still configured
```

So the `grafana-data` volume worked properly as well.

## Persistence vs Reproducibility

The monitoring stack now has persistent local state.

But persistence is not the same as full reproducibility.

If the whole EC2 host or Docker volumes were lost, the manually created Grafana dashboard and data source could not be rebuilt from Git yet.

So the next step is Grafana provisioning, where the data source and dashboard will be stored as version-controlled files.

## Result

Prometheus and Grafana both survived normal container recreation.

The containers changed, but the important monitoring data stayed.

That is exactly the point of using named volumes.
