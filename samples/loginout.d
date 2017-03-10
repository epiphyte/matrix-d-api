/**
 * Copyright 2017
 * MIT License
 * Login and logout (get token)
 */
import matrix_sample_common;
import std.stdio;

// main entry
public void main(string[] args)
{
    auto api = parseArgs(args);
    api.token = "";
    api.login();
    writeln("logged in, got token:");
    writeln(api.token);
    api.logout();
}
