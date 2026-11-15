# mewip

A small command-line tool that resolves a host name to its IP address and shows where that IP is registered: country, region, city, timezone, ISP and AS.

Written in Jai (built with the Jacket compiler - Unofficial Jai toolchain). The release binary has no runtime dependencies.Only GNU libc(v2.34 or higher) which is in almost all new linux distros.

```
$ mewip -url https://github.com

	    github.com
-----------------------------------
IP                  4.187.247.160
Country             India
Country Code        IN
Region              MH
City                Pune
Zip                 411001
Timezone            Asia/Kolkata
ISP                 Microsoft Corporation
Organisation        Microsoft Azure Cloud (centralindia)
AS                  AS8075 Microsoft Corporation
```

## Install

Download the binary for your system from the Releases page, check it against `sha256sums.txt`, and make it executable:

```
sha256sum -c sha256sums.txt # Optional to verify downloads
chmod +x mewip-v0.1.0-linux-x64
./mewip-v0.1.0-linux-x64 -url github.com
```

| File                        | System              |
| --------------------------- | ------------------- |
| `mewip-v0.1.0-linux-x64`    | Linux, x86_64       |
| `mewip-v0.1.0-linux-arm64`  | Linux, ARM64        |

Other systems are not supported yet.

## Usage

```
mewip -url <host>      look up a host name or IP address
mewip -quiet -url <host>   print only the IP address
mewip -help            show all options
mewip -version         show the version
```

| Flag       | Description                                    |
| ---------- | ---------------------------------------------- |
| `-url`     | Host name or IP to resolve. A leading `http://` or `https://`, and any path, is ignored. |
| `-quiet`   | Print only the IP address, for use in scripts. |
| `-help`    | Show the help text.                            |
| `-version` | Print the version.                             |

## How it works

1. The host name is resolved to an IPv4 address with `getaddrinfo` - a native linux socket.
2. The address is sent to [ip-api.com](https://ip-api.com) over HTTP using Jai-lang Extensions.
3. The JSON reply is parsed and printed as a table.

PS:= It might sound simple ik but learning a language with no documentation and seeing how certain things work at a compiler level was genuinely mind-bogling and interesting.I might have spent countless hours with Jai compiler to build it.

## Limitations

- **IPv4 only.** Hosts that only have an IPv6 address will fail to resolve.
- A host with several addresses may show a different one each time.

## Build from source

The source is in `main.jai`. Building needs the [Jacket - Unoffical Jai Compiler](https://github.com/matteopolak/jacket/tree/main) compiler (`jaic` 0.35.2 was used), which is not included in this repository.

```
jaic main.jai -o -os linux -cpu x64   -exe mewip-linux-x64
jaic main.jai -o -os linux -cpu arm64 -exe mewip-linux-arm64
```

