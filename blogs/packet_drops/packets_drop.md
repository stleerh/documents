# Network Observability Real-Time Per Flow Packets Drop

<p align="center">
  <img src="packets_drop_logo.png" alt="logo" width="25%"/>
</p>

By: Amogh RD, Julien Pinsonneau and Mohamed S. Mahmoud

In OCP ensuring efficient packet delivery is crucial for maintaining smooth
communication between applications. However, due to various factors such
as network congestion, misconfigured systems, or hardware limitations,
packets might occasionally get dropped. Detecting and diagnosing these
packet drops is essential for optimizing network performance and
maintaining a high quality of service.
This is where eBPF (extended Berkeley Packet Filter) comes into play
as a powerful tool for real-time network performance analysis.
In this blog, we'll take a detailed look at how network observability
using eBPF can help in detecting and understanding packet drops,
enabling network administrators and engineers to proactively
address network issues.

## Detecting Packet Drops with eBPF

eBPF enables developers to set up tracepoints at key points within the network
stack. These tracepoints can help intercept packets at specific events,
such as when they are received, forwarded, or transmitted.
By analyzing the events around packet drops, you can gain insight into the
reasons behind them.
In network observability we are using `tracepoint/skb/kfree_skb` tracepoint hook
to detect when packets are dropped, the reason for packets drop and reconstruct
the flow and enrich it with drop metadata such as packets and bytes statistics,
for TCP only the latest TCP connection state as well as the TCP connection flags
are added.
Packets drop ebpf hook supports TCP, UDP, SCTP, ICMPv4 and ICMPv6 protocols.
There are two main categories for packet drops, core subsystem drops which cover
most of the host drop reasons for the complete list please refer to
https://github.com/torvalds/linux/blob/master/include/net/dropreason-core.h
The other category is for OVS based drops which is very recent kernel enhancement
and for reference please checkout the following link
https://git.kernel.org/pub/scm/linux/kernel/git/netdev/net-next.git/tree/net/openvswitch/drop.h.

## Kernel support

The drop cause tracepoint API is a very recent kernel feature so to be able
to use it we need rhel9.2 kernel or above. older kernel will ignore
this feature if its configured.

## How to enable packet drops

By default packets drop detection is disabled because it requires
`privileged` access, to enable this feature we need to create a flow
collector object with the following fields enabled in eBPF config
section

```yaml
  agent:
    type: EBPF
    ebpf:
      privileged: true
      enablePktDrop: true
```
