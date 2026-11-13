#import "Basic";
soclib :: #import "Socket";
#import "String";

#import "Command_Line";
#import "Extensions/Http";
#import "Extensions/Json";

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
        log("Url not given\n\n", flags = .ERROR);
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

    ip_str: string = to_string((ip.data));
    log("IP: % \n", ip_str);

    Ip :: struct {
        query: string;
        status: string;
        country: string;
        countryCode: string;
        region: string;
        city: string;
        zip: string;
        lat: float;
        lon: float;
        timezone: string;
        isp: string;
        org: string;
        as: string;
    }

    api: Client;
    api.base_url = tprint("http://ip-api.com/json/%", ip_str);

    response, error := get(*api, "");
    if error.kind != .NONE {
        log("%", error_text(error), flags = .ERROR);
        return;
    }
    defer close(*response);

    if response.status != 200 return;
    ip_addr, error2 := read_json(*response, Ip);
    defer free_json(*ip_addr);
    if error2.kind != .NONE {
        print("the answer was not a note: %\n", error_text(error2));
        return;
    }

    log("% \n", ip_addr);

}
