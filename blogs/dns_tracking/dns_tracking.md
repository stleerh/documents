# Network Observability Per Flow DNS tracking

![logo](./images/dns_tracking_logo.png)

By: Julien Pinsonneau, Mehul Modi and Mohamed S. Mahmoud

In today's interconnected digital landscape, Domain Name System (DNS) tracking
plays a crucial role in networking and security.
DNS resolution is a fundamental process that translates human-readable domain
names into IP addresses, enabling communication between devices and servers.
However, this process also presents opportunities for monitoring and analysis,
which can be achieved through innovative technologies like
eBPF (extended Berkeley Packet Filter).
In this blog post, we'll delve into the world of DNS tracking using eBPF
tracepoint hooks, exploring how this powerful combination can be used for
various purposes, including network monitoring and security enhancement.

## Understanding DNS Resolution

Before diving into the specifics of eBPF tracepoint hooks, let's briefly
recap how DNS resolution works.
When you enter a website's domain name (e.g., www.example.com) in your
browser, your computer needs to find the corresponding IP address.
This process involves multiple steps, including querying DNS servers,
caching responses, and ultimately obtaining the IP address for
establishing a connection.

## Utilizing Tracepoint Hooks for DNS Tracking

Tracepoint hooks are predefined points in the Linux kernel where eBPF
programs can be attached to capture and analyze specific events.
For DNS tracking, we leveraged tracepoint hooks associated with DNS
resolution processes specifically `tracepoint/net/net_dev_queue` tracepoint,
Then we parse the DNS header to determine if its query or response, attempt
to correlate query and response for specific DNS transaction and then record the
elapsed time as well as enrich the flow with DNS header's information like DNS Id
and DNS flags to help UI filtering.

## Potential Use Cases

DNS tracking with eBPF tracepoint hooks can serve various purposes:

- Network Monitoring: Gain insights into DNS queries and responses,
helping network administrators identify unusual patterns,
potential bottlenecks, or performance issues.

- Security Analysis: Detect suspicious DNS activities, such as domain
name generation algorithms (DGA) used by malware,
or identify unauthorized DNS resolutions that might indicate a security breach.

- Troubleshooting: Debug DNS-related issues by tracing DNS resolution steps,
tracking latency, and identifying misconfigurations.

## How to enable DNS tracking

By default DNS tracking is disabled because it requires
`privileged` access, to enable this feature we need to create a flow
collector object with the following fields enabled in eBPF config
section

```yaml
apiVersion: flows.netobserv.io/v1beta1
kind: FlowCollector
metadata:
  name: cluster
spec:
  agent:
    type: EBPF
    ebpf:
      privileged: true
      features:
        - DnsTacking
```

## A quick tour in the UI

Once `DnsTacking` feature enabled, the Console plugin will automatically adapt to provide
additionnal filters and show informations across views.

Open your OCP Console and move to 
`Administrator view` -> `Observe` -> `Network Traffic` page as usual.

Three new filters, `DNS Id`, `DNS Latency` and `DNS Response Code` will be available 
in the common section:

![dns filters](./images/dns_filters.png)

The first one will allow you to filter on a specific DNS Id to correlate with your query.

![dns id](./images/dns_id.png)

The second one helps to identify potential performance issues by looking at DNS resolution latency.

![dns latency more than](./images/dns_latency_more_than.png)

The third filter surfaces DNS response codes, which can help detect errors or unauthorized resolutions.

![dns rcode](./images/dns_response_code.png)

### Overview
New graphs will be introduced in the `advanced options` -> `manage panels` popup:

![advanced options 1](./images/advanced_options1.png)

- Top 5 average DNS latencies
- Top 5 DNS response code
- Top 5 DNS response code stacked with total

![dns graphs 1](./images/dns_graphs1.png)
![dns graphs 2](./images/dns_graphs2.png)


### Traffic flows
The table view will get the new DNS related columns `Id`, `Latency` and `Response code` available from 
the `advanced options` -> `manage columns` popup

![advanced options 2](./images/advanced_options2.png)

The DNS related flows will show these informations in both table and side panel:

![dns table](./images/dns_table.png)

## Future support

- looking at adding mDNS

- Adding support to DNS over TCP

- Investigating options to handle DNS over TLS where the DNS header is fully encrypted.

