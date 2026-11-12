#import "Basic";
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
