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
    auto pub = api.getPublicRooms();
    foreach (roomId; pub.byKey())
    {
        writeln("public room found " ~ roomId);
        foreach (room; pub[roomId])
        {
            writeln("which has alias " ~ room);
        }
    }
}
