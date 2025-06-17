# Tool to connect to EC2 instances via SSM

## Prerequisites

- The whiptail OS package is installed.
- EC2 instances are named, i.e. they have a tag with the key `Name`.

## Usage

### No parameters

A menu is displayed with the available EC2 instances that can be reached via SSM:

```Bash
ssm-connect
```

### Instance name as parameter

Connects directly to the instance with the name tag specified as parameter.

```Bash
ssm-connect instancename
```

## Quick install for all users

```
curl -sSLo - https://raw.githubusercontent.com/mtnemeth/dev-env/refs/heads/main/aws/ssm-connect/install.sh | sudo bash
```
