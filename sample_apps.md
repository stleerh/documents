# Sample applications

This page lists sample applications that are useful to generate traffic for show-casing or [stress-]testing NetObserv.

## Hey-Ho

Repo: https://github.com/jotak/hey-ho

A simple bash script on top of [Hey](https://github.com/rakyll/hey) that deploys any number of Pods sending load to each other, for a given period.

```bash
git clone github.com/jotak/hey-ho
cd hey-ho
./hey-ho.sh -h
```

## Kube Traffic Generator

Repo: https://github.com/wiggzz/kube-traffic-generator

Another traffic generator. See [traffic.yaml](./examples/kube-traffic-generator/traffic.yaml).

```bash
kubectl apply -f https://raw.githubusercontent.com/netobserv/documents/main/examples/kube-traffic-generator/traffic.yaml
```

## Mesh Arena

Repo: https://github.com/jotak/demo-mesh-arena

A tiny "soccer simulation" as microservices, running on Kube, that self-generates traffic.

```bash
kubectl create namespace mesh-arena && kubectl apply -f https://raw.githubusercontent.com/jotak/demo-mesh-arena/zizou/quickstart-naked.yml -n mesh-arena
```
