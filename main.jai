#import "Basic";
soclib :: #import "Socket";
#import "Simple_Package";

// #import "Command_Line";

main :: () {
    args: = get_command_line_arguments();
    defer free(args.data);

    print("% \n", args);
    if (args.count != 2) {
        print("Incorrect usage.\n");
        exit(67);
    }

    print("URL: % \n", args[1]);
    ar: *soclib.addrinfo;
    hints: soclib.addrinfo;
    hints.ai_family = soclib.AF_INET;

    status: int = soclib.getaddrinfo("google.com", "https", *hints, *ar);
    if (status != 0) {
        print("Error occured\n");
        exit(34);
    }

    addr: *soclib.sockaddr_in = xx (ar.ai_addr);
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
