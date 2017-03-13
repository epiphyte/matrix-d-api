/**
 * Copyright 2017
 * MIT License
 * Generate a token
 */
import samples.common;
import std.stdio;

// main entry
public void main(string[] args)
{
    auto api = parseArgs(args);
    api.token = "";
    api.login();
    writeln("generated token:");
    writeln(api.token);
}
