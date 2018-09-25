# docker-on-reith
For Ubuntu 16,04 on Reith (VM or h/w), builds a pkg that deploys docker-ce with appropriate on-Reith network and proxy settings.

## Installation
```
$ sudo apt install bbc-newslabs-docker-on-reith
```

## What does it do?
The package will install docker-ce, and configure it appropriately for the BBC Reith network. Specifically, it will configure the internal docker "lan" to run on `192.168.0.0/24`, enable **swarm** mode, and configure the two required swarm networks (ingress and overlay) to run on `192.168.1.0/24` and `192.168.2.0/24` respectively.

It will also configure environment variables that allow the docker daemon to connect through the BBC's outbound proxy server infrastructure (www-cache.reith.bbc.co.uk) to permit `docker pull` to work against the public Docker Hub registry.

For hosts built from the **BBC NPF Ubuntu** distro, it will add the user `bbcadmin` to the `docker` group.

Other, personal, account holders wishing to use the `docker` command will require additional configuration: `sudo usermod -aG docker <username>`. Once completed, the user concerned will need to logout and back in again before being able to execute the docker command itself.

The pkg also installs the https://github.com/bbc/eng-bsd-ssl package, which allows the docker daemon to connect to **BBC CA** certificate-protected on-Reith docker registry servers such as https://registry.pod.jupiter.bbc.co.uk/v2/_catalog.
