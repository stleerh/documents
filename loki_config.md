# Custom Loki Configuration for NetObserv

Grafana Loki is configured in a YAML file which contains information on the Loki server and its individual components.

Some of these need to be tweaked for network observability according to your cluster size, number of flows and sampling.

## Wide time range queries - too many outstanding requests

> The query frontend splits larger queries into multiple smaller queries, executing these queries in parallel on downstream queriers and stitching the results back together again. This prevents large (multi-day, etc) queries from causing out of memory issues in a single querier and helps to execute them faster.

Check [Grafana official documentation](https://grafana.com/docs/loki/latest/fundamentals/architecture/components/#splitting)

Some queries may be limited by the query scheduler. You will need to update the following configuration:

```yaml
    query_range:
      parallelise_shardable_queries: true
    query_scheduler:
      max_outstanding_requests_per_tenant: 100 
```

Ensure `parallelise_shardable_queries` is set to `true` and increase `max_outstanding_requests_per_tenant` following your needs (default = 100). It's reasonable to put a high value here as `2048` for example, however it will decrease multi-users queries performance. 

Check [query_scheduler](https://grafana.com/docs/loki/latest/configuration/#query_scheduler) configuration for more details.

## Bulk messages - gRPC received message larger than max

The messages containing bulks of records received by Loki distributor and exchanged between components have a maximum size in bytes set by the following parameters: 

```yaml
    server:
      grpc_server_max_recv_msg_size: 4194304
      grpc_server_max_send_msg_size: 4194304 
```

By default the size is `4194304` = `4Mb`. It's reasonable to increase it to `8388608` = `8Mb`.

## Delay - Entry too far behind for stream

While collecting flows and enriching them, a latency appears between the current time and records. This particularly applies when using Kafka on large clusters.

Loki can be configured to reject old samples using the following configuration:

```yaml
    limits_config:
      reject_old_samples_max_age: 168h
```

On top of that, Loki logs are written in chunks in order by time. If a message received is too old than the most recent one, it will be `out-of-order`.

To accept messages within a specific time range, use the following configuration:

```yaml
    ingester:
      max_chunk_age: 2h
```

Be careful, Loki calculates the earliest time that out-of-order entries may have and be accepted with:
```
time_of_most_recent_line - (max_chunk_age / 2)
```

Check [accept out-of-order writes documentation](https://grafana.com/docs/loki/latest/configuration/#accept-out-of-order-writes) for more info.

## Maximum active stream limit exceeded

The number of active streams can be limited per user per ingester (unlimited by default) or per user across the cluster (default = 5000).

To update these limits, you can tweak the following values:

```yaml
    limits_config:
      max_streams_per_user: 0
      max_global_streams_per_user: 5000
```

It's not recommended to disable both using `0`. You may set `max_streams_per_user` to `5000` using multiple ingesters and disable `max_global_streams_per_user` or increase `max_global_streams_per_user` value instead.

Check [limits_config](https://grafana.com/docs/loki/latest/configuration/#limits_config) for more details.

## Ingestion rate limit exceeded

Ingestion is limited in terms of sample size per second as `ingestion_rate_mb` and per distributor local rate as `ingestion_burst_size_mb`:

```yaml
    limits_config:
      ingestion_rate_mb: 4
      ingestion_burst_size_mb: 6
```

It's common to put more than `10Mb` on each. You can safely increase these two values but keep an eye on your ingester performances and on your storage size.

Check [limits_config](https://grafana.com/docs/loki/latest/configuration/#limits_config) for more details.