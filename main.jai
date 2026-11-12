#import "Basic";
soclib :: #import "Socket";
#import "String";

// #import "Command_Line";

main :: () {
    args: = get_command_line_arguments();
    defer free(args.data);

    // print("% \n", args);
    if (args.count != 2) {
        print("Incorrect usage.\n");
        exit(67);
    }
    https_header := slice(args[1], 0, 8);
    if (https_header == "https://") {
        print("Cannot use https:// prefix links use normal links like 'google.com'\n");
        exit(67);
    }

    print("Url: % \n", args[1]);
    result: *soclib.addrinfo;
    hints: soclib.addrinfo;

    hints.ai_family = cast(s32) soclib.AF_INET;
    hints.ai_socktype = .STREAM;
    hints.ai_protocol = .TCP;

    host := to_c_string(args[1]);
    status := to_c_string("https");

    defer free(host);
    defer free(status);

    ok: int = soclib.getaddrinfo(host, status, *hints, *result);
    if (ok != 0) {
        print("Error occured\n");
        exit(34);
    }
    defer soclib.freeaddrinfo(result);

    addr: *soclib.sockaddr_in = xx (result.ai_addr);
    ip: [soclib.INET_ADDRSTRLEN] u8;
    soclib.inet_ntop(soclib.AF_INET, *addr.sin_addr, ip, size_of(ip));

    ip_str: string = xx (ip);
    print("IP: % \n", ip_str);


    // Command line parsing later on implement
    /**
        Options :: struct {
            quite: bool = false;
            level := 2;
            url: string = "null";
        }
    **/
    /**
    ok, options := parse_arguments(Options, args = args);
    assert(ok);
    print("% \n", options); **/
}
