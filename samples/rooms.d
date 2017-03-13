/**
 * Copyright 2017
 * MIT License
 * List rooms example
 */
import samples.common;
import std.stdio;

// main entry
public void main(string[] args)
{
    auto api = parseArgs(args);
    api.login();
    foreach (string roomId; api.getRooms())
    {
        writeln("in room " ~ roomId);
    }
}
