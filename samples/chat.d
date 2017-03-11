/**
 * Copyright 2017
 * MIT License
 * Read-only client
 */
import core.thread;
import matrix_api;
import matrix_sample_common;
import std.json;

// user invited
public void onInvite(MatrixAPI api, string room, JSONValue context)
{
    api.joinRoom(room);
}

// specific room callback
public void onRoom(MatrixAPI api, string room, JSONValue context)
{
    import std.stdio;
    writeln(context);
    if (context["sender"].str != api.userId)
    {
        api.sendText(room, "hello");
        api.sendHTML(room, "<html><b>I'm here</b></html>");
    }
}

// main entry
public void main(string[] args)
{
    auto api = parseArgs(args);
    api.login();
    api.inviteListener(new InviteListener(&onInvite));
    foreach (string roomId; api.getRooms())
    {
        api.roomListener(new RoomListener(roomId, &onRoom));
    }

    int idx = 0;
    while (idx < 100)
    {
        api.poll();
        Thread.sleep( dur!("msecs")( 100 ) );
        idx++;
    }

    api.clearInviteListeners();
    api.clearRoomListeners();
}
