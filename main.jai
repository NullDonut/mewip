#import "Basic";
soclib :: #import "Socket";
#import "String";

#import "Command_Line";
#import "Extensions/Http";
#import "Extensions/Json";
#import "Print_Color";


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

    Options :: struct {
        quiet: bool = false; @"Print only the IP address."
        url: string = "null"; @"Host name or IP to resolve."
    }
    // log("% \n", args);
    if (args.count < 2) {
        log("Incorrect usage.\n", flags = .ERROR);
        show_help(Options, Default_Argument_Flags, .["help"]);
        return;
    }
    oke, options := parse_arguments(Options, args = args);
    if !oke {
        if !asked_for_help(args) {
            log("Invalid arguments.\n", flags = .ERROR);
            show_help(Options, Default_Argument_Flags, .["help"]);
        }
        return;
    }
    if options.url.count == 0 || options.url == "null" {
        log("Url not given\n\n", flags = .ERROR);
        show_help(Options, Default_Argument_Flags, .["help"]);
        return;
    }
    // // log("% \n", options);
    // https_header := to_lower_copy(slice(options.url, 0, 8));
    // http_header := to_lower_copy(slice(options.url, 0, 7));
    // if (https_header == "https://") {
    //     //  log("Cannot use https:// prefix links use normal links like 'google.com'\n");
    //     options.url = to_lower_copy(slice(options.url, 8, options.url.count - 8));
    //     // log("New Options URL: % \n", options.url);
    //     // exit(67);
    // }
    // if (http_header == "http://") {
    //     //  log("Cannot use http:// prefix links use normal links like 'google.com'\n");
    //     options.url = to_lower_copy(slice(options.url, 7, options.url.count - 7));
    //     //     log("New Options URL: % \n", options.url);
    //     //
    //     //     exit(68);
    // }
    //

    options.url = to_lower_copy(extract_host(options.url));
    log("URL: % \n", options.url, flags = .VERBOSE_ONLY);
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
    log("IP: % \n", ip_str, flags = .VERBOSE_ONLY);
    if (options.quiet) {
        print("% \n", ip_str);
        return;
    }

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

    if response.status != 200 {
        log("Lookup service returned status %.\n", response.status, flags = .ERROR);
        return;
    }
    ip_addr, error2 := read_json(*response, Ip);
    if error2.kind != .NONE {
        print("% \n", response);
        log("JSON parsing failed: %\n", error_text(error2), flags = .ERROR);
        return;
    }
    defer free_json(*ip_addr);
    // log("% \n", ip_addr);

    // Todo: Error handling and better printing ui;

    // Better printing ui;
    row :: (label: string, value: string) {
        print_color("%", label, color = .WHITE, style = .BOLD);
        for 1..(20 - label.count) print(" ");
        print("%\n", value);
    }

    show_info :: (ip: Ip, host: string) {
        print("\n\t    \e[1m%\e[0m\n", host);
        print("-----------------------------------\n");
        row("IP", ip.query);
        row("Country", ip.country);
        row("Country Code", ip.countryCode);
        row("Region", ip.region);
        row("City", ip.city);
        row("Zip", ip.zip);
        row("Timezone", ip.timezone);
        row("ISP", ip.isp);
        row("Organisation", ip.org);
        row("AS", ip.as);
    }
    if ip_addr.status != "success" {
        log("Lookup failed: %\n", ip_addr, flags = .ERROR);
        return;
    }
    show_info(ip_addr, options.url);
}

extract_host :: (input: string) -> string {
    s := input;
    if begins_with_nocase(s, "https://") s = advance(s, 8);
    else if begins_with_nocase(s, "http://") s = advance(s, 7);

    i := 0;
    while i < s.count {
        c := s[i];
        if c == #char "/" || c == #char "?" || c == #char ":" || c == #char "#" {
            s.count = i;
            break;
        }
        i += 1;
    }
    return s;
}

asked_for_help :: (args: [] string) -> bool {
    for i: 1..args.count - 1 {
        if args[i] == "-help" || args[i] == "-HELP" || args[i] == "-?" return true;
    }
    return false;
}
