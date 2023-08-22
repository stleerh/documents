# Network Observability Per Flow DNS tracking

<p align="center">
  <img src="dns_tracking_logo.png" alt="logo" width="25%"/>
</p>

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
  agent:
    type: EBPF
    ebpf:
      privileged: true
      enableDNSTracking: true
```

## Future support

- looking at adding mDNS

- Adding support to DNS over TCP

- Investigating options to handle DNS over TLS where the DNS header is fully encrypted.

