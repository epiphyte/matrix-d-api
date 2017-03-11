/**
 * Copyright 2017
 * MIT License
 * Read-only client
 */
import core.thread;
import matrix_api;
import matrix_sample_common;
import std.json;
import std.stdio;

// dump to console
private void dump(string call, string room, JSONValue context)
{
    writeln(call);
    writeln(room);
    writeln(context);
}

// user invited
public void onInvite(MatrixAPI api, string room, JSONValue context)
{
    dump("invite", room, context);
    api.joinRoom(room);
}

// all room callback
public void onAllRoom(MatrixAPI api, JSONValue context)
{
    dump("all", "ALL", context);
}

// specific room callback
public void onRoom(MatrixAPI api, string room, JSONValue context)
{
    dump("room", room, context);
}

// room left
public void onLeave(MatrixAPI api, string room, JSONValue context)
{
    dump("leave", room, context);
}

// main entry
public void main(string[] args)
{
    auto api = parseArgs(args);
    api.login();
    api.inviteListener(new InviteListener(&onInvite));
    api.leftListener(new LeftListener(&onLeave));
    api.roomListener(new AllRoomListener(&onAllRoom));
    foreach (string roomId; api.getRooms())
    {
        api.roomListener(new RoomListener(roomId, &onRoom));
    }

    int idx = 0;
    while (idx < 10)
    {
        writeln("sleeping...");
        api.poll();
        Thread.sleep( dur!("seconds")( 5 ) );
        idx++;
    }

    api.clearInviteListeners();
    api.clearLeftListeners();
    api.clearRoomListeners();
}
