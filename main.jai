#import "Basic";
soclib :: #import "Socket";
#import "String";

#import "Command_Line";

main :: () {
    ping_logger :: (message: string, data: *void, info: Log_Info) {
        if info.common_flags & .ERROR {
            write_string("ERROR: ", to_standard_error = true);
            write_string(message, to_standard_error = true);
            if message[message.count - 1] != #char "\n"
                write_string("\n", to_standard_error = true);
            return;
        }

        if context.log_level == .NORMAL && (info.common_flags & .VERBOSE_ONLY) return;

        write_string(message);
        if message[message.count - 1] != #char "\n" write_string("\n");
    }

    context.logger = ping_logger;
    args: = get_command_line_arguments();
    defer free(args.data);

    // log("% \n", args);
    if (args.count < 2) {
        log("Incorrect usage.\n", flags = .ERROR);
        exit(67);
    }
    Options :: struct {
        quiet: bool = false; @"Print only the IP address."
        url: string = "null"; @"Host name or IP to resolve."
    }
    oke, options := parse_arguments(Options, args = args);
    if !oke {
        show_help(Options, Default_Argument_Flags, .["help"]);
        return;
    }
    if options.url.count == 0 || options.url == "null" {
        log("Url not given\n\n");
        show_help(Options, Default_Argument_Flags, .["help"]);
        return;
    }
    // log("% \n", options);
    https_header := to_lower_copy(slice(options.url, 0, 8));
    http_header := to_lower_copy(slice(options.url, 0, 7));
    if (https_header == "https://") {
        //  log("Cannot use https:// prefix links use normal links like 'google.com'\n");
        options.url = to_lower_copy(slice(options.url, 8, options.url.count - 8));
        // log("New Options URL: % \n", options.url);
        // exit(67);
    }
    if (http_header == "http://") {
        //  log("Cannot use http:// prefix links use normal links like 'google.com'\n");
        options.url = to_lower_copy(slice(options.url, 7, options.url.count - 7));
        //     log("New Options URL: % \n", options.url);
        //
        //     exit(68);
    }

    log("URL: % \n", options.url);
    result: *soclib.addrinfo;
    hints: soclib.addrinfo;

    hints.ai_family = cast(s32) soclib.AF_INET;
    hints.ai_socktype = .STREAM;
    hints.ai_protocol = .TCP;

    host := to_c_string(options.url); // C_string is just adding null terminator at end.
    status := to_c_string("https");

    defer free(host);
    defer free(status);

    ok: int = soclib.getaddrinfo(host, status, *hints, *result);
    if (ok != 0) {
        if ok == -2 log("URL unknown or not found.\n", flags = .ERROR);
        else if ok == -4 log("Permanent DNS failure.\n", flags = .ERROR);
        else if ok == -10 log("Out of memory.\n", flags = .ERROR);
        else if ok == -12 log("Overflow occured.\n", flags = .ERROR);
        else if ok == -5 log("Host exists but no address records.\n", flags = .ERROR);
        else log("Unknown % \n", ok, flags = .ERROR);
        exit(34);
    }
    defer soclib.freeaddrinfo(result);

    addr: *soclib.sockaddr_in = xx (result.ai_addr);
    ip: [soclib.INET_ADDRSTRLEN] u8;
    soclib.inet_ntop(soclib.AF_INET, *addr.sin_addr, ip, size_of(ip));

    ip_str: string = xx (ip);
    log("IP: % \n", ip_str);

    // // ICMP req
    // sock: s32 = soclib.socket(soclib.AF_INET, .SOCK_DGRAM, .IPPROTO_ICMP);
    // if (sock == -1) {
    //     log("Socket creation failed: % \n", errno());
    //     return;
    // }
    // defer close(sock);
    //
    // icmp_addr: soclib.sockaddr_in;
    // icmp_addr.sin_family = soclib.AF_INET;
    // log("Socket created sucessfully\n");
    // ok = soclib.inet_pton(soclib.AF_INET, ip, *icmp_addr.sin_addr);
    // if (ok != 1) {
    //     log("Error occured.\n");
    //     return;
    // }
    // log("Ok: % \n", ok);
    //
    // Icmp_Header :: struct {
    //     type: u8;
    //     code: u8;
    //     checksum: u16;
    //     identifier: u16;
    //     sequence: u16;
    // }
    // #assert size_of(Icmp_Header) == 8;
    //
    // swap16 :: (x: u16) -> u16 {
    //     return (x << 8) | (x >> 8);
    // }
    //
    // checksum :: (data: *u8, len: int) -> u16 {
    //     sum: u32 = 0;
    //     i := 0;
    //     while i + 1 < len {
    //         sum += ((cast(u32) data[i]) << 8) | cast(u32) data[i + 1];
    //         i += 2;
    //     }
    //     if len % 2 == 1 sum += (cast(u32) data[len - 1]) << 8;
    //
    //     while (sum >> 16) != 0 sum = (sum & 0xFFFF) + (sum >> 16);
    //     return cast(u16) ~sum;
    // }
    //
    //
    // Command line parsing later on implement
}
