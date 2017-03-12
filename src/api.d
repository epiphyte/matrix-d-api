/**
 * Copyright 2017
 * MIT License
 * Matrix API
 */
module matrix_api;
import core.time;
import matrix_client_errors;
import matrix_client_helpers;
import std.algorithm: canFind, remove;
import std.json;
import std.net.curl;
import std.regex: regex, replaceFirst;
import std.string: format;
import std.uri;
import std.uuid;

/**
 * Base listener
 */
public interface IBaseListener
{
    void onEvent(MatrixAPI api, string roomId, JSONValue context);
}

/**
 * Listen for room events
 */
public interface IRoomListener : IBaseListener
{
}

/**
 * Listen for invite events
 */
public interface IInviteListener : IBaseListener
{
}

/**
 * Listen for left/leave events
 */
public interface ILeftListener : IBaseListener
{
}

/**
 * Base room listener
 */
public abstract class BaseRoomListener
{
    /**
     * Unique identifier for the room listener
     */
    @property public string id()
    {
        if (this.uuid == null)
        {
            this.uuid = randomUUID().toString();
        }

        return this.uuid;
    }

    // backing identifier
    private string uuid = null;

    /**
     * Validate a callback is not null
     */
    protected void checkCall(bool callbackNull)
    {
        if (callbackNull)
        {
            throw new MatrixConfigException("event callback is null");
        }
    }
}

/**
 * Room event listener (base/common definition)
 */
public abstract class CommonRoomListener : BaseRoomListener, IRoomListener
{
    /**
     * Execute on room state events
     */
    public void onEvent(MatrixAPI api, string roomId, JSONValue context)
    {
        this.doEvent(api, roomId, context);
    }

    /**
     * Execute event callback
     */
    protected void doEvent(MatrixAPI api, string roomId, JSONValue context)
    {
    }
}

/**
 * Do action whenever a room updates
 */
public class AllRoomListener : CommonRoomListener
{
    // all room listener
    alias void function(MatrixAPI, JSONValue) AllRoomEvt;

    // backing callback
    @property public AllRoomEvt callback;

    // inherit doc
    protected override void doEvent(MatrixAPI api,
                                    string roomId,
                                    JSONValue context)
    {
        this.callback(api, context);
    }

    /**
     * Init the instance
     */
    this (AllRoomEvt call)
    {
        this.callback = call;
        this.checkCall(this.callback == null);
    }
}

/**
 * Do action when a room (specific room) updates
 */
public class RoomListener : CommonRoomListener
{
    // room event
    alias void function(MatrixAPI, string, JSONValue) RoomEvt;

    // room identifier
    @property public string roomId;

    // backing callback
    @property public RoomEvt callback;

    /**
     * Init the instance
     */
    this (string roomId, RoomEvt call)
    {
        validateRoomId(roomId);
        this.roomId = roomId;
        this.callback = call;
        this.checkCall(this.callback == null);
    }

    // inherit doc
    protected override void doEvent(MatrixAPI api,
                                    string roomId,
                                    JSONValue context)
    {
        if (roomId !is null && roomId.length > 0 && this.roomId == roomId)
        {
            this.callback(api, roomId, context);
        }
    }
}

/**
 * Listen for room invites
 */
public class InviteListener : BaseRoomListener, IInviteListener
{
    // invited alias
    alias void function(MatrixAPI, string, JSONValue) InvitedEvt;

    // backing callback
    @property public InvitedEvt callback;

    // inherit doc
    public override void onEvent(MatrixAPI api,
                                 string roomId,
                                 JSONValue context)
    {
        this.callback(api, roomId, context);
    }

    /**
     * Init the instance
     */
    this (InvitedEvt call)
    {
        this.callback = call;
        this.checkCall(this.callback == null);
    }
}

/**
 * Room left
 */
public class LeftListener : BaseRoomListener, ILeftListener
{
    // Left event alias
    alias void function(MatrixAPI, string, JSONValue) LeftEvt;

    // backing callback
    @property public LeftEvt callback;

    // inherit doc
    public override void onEvent(MatrixAPI api,
                                 string roomId,
                                 JSONValue context)
    {
        this.callback(api, roomId, context);
    }

    /**
     * Init the instance
     */
    this (LeftEvt call)
    {
        this.callback = call;
        this.checkCall(this.callback == null);
    }
}

/**
 * Matrix API
 */
public class MatrixAPI
{
    // sync state, updated on calls to sync()
    private struct SyncState
    {
        // rooms the user is in
        string[string] rooms;
        IRoomListener[] listeners;
        IInviteListener[] invites;
        ILeftListener[] leaves;
    }

    // Room JSON key
    private enum RoomKey = "rooms";

    // authorization has happened
    private bool authorized = false;

    // user id to auth with
    @property public string userId;

    // user password for auth
    @property public string password;

    // user token
    @property public string token;

    // url to connect to for matrix
    @property public string url;

    // max timeout period
    @property public int timeout;

    // last event state
    private string since;

    // additional context store
    @property public string[string] context;

    // last known api state
    private SyncState state;

    // init the instance
    this ()
    {
        this.timeout = 30;
        this.since = null;
        this.state = SyncState();
    }

    /**
     * Data requests
     */
    private struct DataRequest
    {
        // post data
        string[string] data;

        // query parameters
        string[string] queryparams;
    }

    /**
     * login/init auth
     */
    public void login()
    {
        if (this.authorized)
        {
            return;
        }
        else
        {
            if (this.url is null || this.url.length == 0)
            {
                throw new MatrixConfigException("URL not configured");
            }

            validateUserId(this.userId);
            if (this.token is null || this.token.length == 0)
            {
                auto req = DataRequest();
                req.data = ["type": "m.login.password",
                            "user": this.userId,
                            "password": this.password];
                req.data["type"] = "m.login.password";
                req.data["user"] = this.userId;
                req.data["password"] = this.password;
                auto res = this.request(HTTP.Method.post, "login", &req);
                auto valid = false;
                if ("access_token" in res)
                {
                    this.token = res["access_token"].str;
                    valid = true;
                }

                if (!valid)
                {
                    throw new MatrixRequestException("unable to authorize");
                }
            }

            this.authorized = true;
        }
    }

///
version(MatrixUnitTest)
{
    unittest
    {
        auto api = new MatrixAPI();
        try
        {
            api.login();
            assert(false);
        }
        catch (MatrixConfigException e)
        {
            assert(e.msg == "URL not configured");
        }

        api.url = "test";
        api.userId = "@user:test";
        api.login();
        assert(api.token == "success");
        api = new MatrixAPI();
        api.url = "test2";
        api.userId = "@user:test";
        try
        {
            api.login();
            assert(false);
        }
        catch (MatrixRequestException e)
        {
            assert(e.msg == "unable to authorize");
        }
    }
}

    /**
     * Logout of matrix
     */
    public void logout()
    {
        if (!this.authorized)
        {
            return;
        }

        this.request(HTTP.Method.post, "logout", null);
    }

///
version(MatrixUnitTest)
{
    unittest
    {
        auto api = new MatrixAPI();
        api.url = "test";
        api.userId = "@user:test";
        api.login();
        api.logout();
    }
}

    /**
     * Clear invite listeners
     */
    public void clearInviteListeners()
    {
        this.state.invites = [];
    }

///
version(MatrixUnitTest)
{
    unittest
    {
        static void testing(MatrixAPI api, string room, JSONValue value)
        {
            import std.stdio;
            writeln("invite called");
        }

        int idx = 0;
        auto api = new MatrixAPI();
        api.url = "test";
        api.userId = "@user:test";
        api.login();
        api.inviteListener(new InviteListener(&testing));
        api.poll();
        api.poll();
        api = new MatrixAPI();
        api.url = "test";
        api.userId = "@user:test";
        api.inviteListener(new InviteListener(&testing));
        api.clearInviteListeners();
        api.login();
        api.poll();
        api.poll();
    }
}

    /**
     * Clear leave room listeners
     */
    public void clearLeftListeners()
    {
        this.state.leaves = [];
    }

///
version(MatrixUnitTest)
{
    unittest
    {
        static void testing(MatrixAPI api, string room, JSONValue value)
        {
            import std.stdio;
            writeln("left called");
        }

        int idx = 0;
        auto api = new MatrixAPI();
        api.url = "test";
        api.userId = "@user:test";
        api.login();
        api.leftListener(new LeftListener(&testing));
        api.poll();
        api.poll();
        api = new MatrixAPI();
        api.url = "test";
        api.userId = "@user:test";
        api.leftListener(new LeftListener(&testing));
        api.clearLeftListeners();
        api.login();
        api.poll();
        api.poll();
    }
}

    /**
     * Clear all and room-based listeners
     */
    public void clearRoomListeners()
    {
        this.state.listeners = [];
    }

///
version(MatrixUnitTest)
{
    unittest
    {
        static void all(MatrixAPI api, JSONValue value)
        {
            import std.stdio;
            writeln("all called");
        }

        static void room(MatrixAPI api, string room, JSONValue value)
        {
            import std.stdio;
            writeln("room called");
        }

        int idx = 0;
        auto api = new MatrixAPI();
        api.url = "test";
        api.userId = "@user:test";
        api.login();
        api.roomListener(new AllRoomListener(&all));
        api.roomListener(new RoomListener("!asfLdzLnOdGRkdPZWu:localhost",
                                          &room));
        api.roomListener(new RoomListener("!asfLdzLnOdGRkdPZWu:localhost",
                                          &room));
        api.roomListener(new RoomListener("!blah:localhost", &room));
        api.poll();
        api.poll();
        api = new MatrixAPI();
        api.url = "test";
        api.userId = "@user:test";
        api.roomListener(new AllRoomListener(&all));
        api.clearRoomListeners();
        api.login();
        api.poll();
        api.poll();
    }
}

    /**
     * Add an invite listener
     */
    public void inviteListener(IInviteListener invite)
    {
        this.state.invites ~= invite;
    }

    /**
     * Add a room listener
     */
    public void roomListener(IRoomListener room)
    {
        this.state.listeners ~= room;
    }

    /**
     * Add a room-exit listener
     */
    public void leftListener(ILeftListener left)
    {
        this.state.leaves ~= left;
    }

    /**
     * Join a room
     */
    public void joinRoom(string roomId)
    {
        validateRoomId(roomId);
        this.checkAuthorized();
        this.request(HTTP.Method.post, format("join/%s", roomId), null);
    }

///
version(MatrixUnitTest)
{
    unittest
    {
        auto api = new MatrixAPI();
        api.url = "test";
        api.userId = "@user:test";
        api.login();
        api.joinRoom("!room:test");
    }
}

    /**
     * Get rooms the user has joined
     */
    public string[] getRooms()
    {
        this.sync();
        return this.state.rooms.keys;
    }

///
version(MatrixUnitTest)
{
    unittest
    {
        auto api = new MatrixAPI();
        api.url = "test";
        api.userId = "@user:test";
        api.login();
        assert(api.getRooms().length == 1);
    }
}

    /**
     * Send plain text
     */
    public void sendText(string roomId, string text)
    {
        auto req = DataRequest();
        req.data["msgtype"] = "m.text";
        req.data["body"] = text;
        this.sendMessage(roomId, req);
    }

///
version(MatrixUnitTest)
{
    unittest
    {
        auto api = new MatrixAPI();
        api.url = "test";
        api.userId = "@user:test";
        api.login();
        api.sendText("!room:test", "blah");
    }
}

    /**
     * Send a message
     */
    private void sendMessage(string roomId, DataRequest req)
    {
        validateRoomId(roomId);
        this.checkAuthorized();
        auto endpoint = format("rooms/%s/send/%s",
                               roomId,
                               "m.room.message");
        this.request(HTTP.Method.put, endpoint, &req);
    }

    /**
     * Send HTML
     */
    public void sendHTML(string roomId, string html)
    {
        auto req = DataRequest();
        req.data["msgtype"] = "m.text";
        req.data["body"] = replaceFirst(html, regex("<[^<]+?>"), "");
        req.data["format"] = "org.matrix.custom.html";
        req.data["formatted_body"] = html;
        this.sendMessage(roomId, req);
    }

///
version(MatrixUnitTest)
{
    unittest
    {
        auto api = new MatrixAPI();
        api.url = "test";
        api.userId = "@user:test";
        api.login();
        api.sendHTML("!room:test", "<html>blah</html>");
    }
}

    /**
     * Poll, no-op
     */
    public void poll()
    {
        this.sync();
    }

///
version(MatrixUnitTest)
{
    unittest
    {
        auto api = new MatrixAPI();
        api.url = "test";
        api.userId = "@user:test";
        api.login();
        api.poll();
        api.poll();
    }
}

    /**
     * Perform the sync call to matrix
     */
    private JSONValue sync()
    {
        this.checkAuthorized();
        auto req = DataRequest();
        if (this.since !is null)
        {
            req.queryparams["since"] = this.since;
        }

        return this.request(HTTP.Method.get, "sync", &req);
    }

    /**
     * Check that the API has auth'd
     */
    private void checkAuthorized()
    {
        if (!this.authorized)
        {
            throw new MatrixConfigException("not logged in/authorized");
        }
    }

    /**
     * Make a request
     */
    private JSONValue request(HTTP.Method method, string call, DataRequest* req)
    {
        string val = "";
        try
        {
            auto re = DataRequest();
            if (req !is null)
            {
                re = *req;
            }

            auto endpoint = this.url ~ "/_matrix/client/r0/" ~ call;
            bool first = true;
            if (this.token !is null && this.token.length > 0)
            {
                re.queryparams["access_token"] = this.token;
            }

            foreach (string qp; re.queryparams.keys)
            {
                auto start = '&';
                if (first)
                {
                    start = '?';
                    first = false;
                }

                endpoint = endpoint ~ start ~ encode(qp);
                endpoint = endpoint ~ "=" ~ encode(re.queryparams[qp]);
            }

            bool curl = true;
            version(MatrixUnitTest)
            {
                curl = false;
                import std.file: readText;
                import std.stdio;
                writeln(endpoint);
                auto text = readText("test/harness.json");
                auto test = parseJSON(text);
                if (endpoint in test)
                {
                    val = readText("test/" ~ test[endpoint].str ~ ".json");
                }
                else
                {
                    val = "{}";
                }
            }

            HTTP client = null;
            if (curl)
            {
                client = HTTP(endpoint);
                client.operationTimeout = dur!"seconds"(this.timeout);
                client.addRequestHeader("ContentType", "application/json");
            }

            if (method != HTTP.Method.get)
            {
                string data = "{}";
                if (re.data.length > 0)
                {
                    JSONValue j = JSONValue(re.data);
                    data = j.toJSON();
                }

                version(MatrixUnitTest)
                {
                    import std.stdio;
                    writeln(data);
                }

                if (curl)
                {
                    client.postData = data;
                }
            }

            if (curl)
            {
                client.onReceive = (ubyte[] data)
                {
                    val = val ~ cast(string)data;
                    return data.length;
                };

                client.perform();
            }

            auto json = parseJSON(val);
            if ("next_batch" in json)
            {
                this.since = json["next_batch"].str;
            }

            if (RoomKey in json)
            {
                auto rooms = json[RoomKey].object;
                auto invites = rooms["invite"];
                foreach (string invite; invites.object.keys)
                {
                    foreach (IInviteListener invited; state.invites)
                    {
                        invited.onEvent(this,
                                        invite,
                                        invites[invite]["invite_state"]);
                    }
                }

                auto leaves = rooms["leave"];
                foreach (string leave; leaves.object.keys)
                {
                    foreach (ILeftListener left; state.leaves)
                    {
                        left.onEvent(this, leave, leaves[leave]);
                    }

                    if (leave in state.rooms)
                    {
                        state.rooms.remove(leave);
                    }
                }

                auto joined = rooms["join"];
                foreach (string room; joined.object.keys)
                {
                    auto obj = joined[room];
                    auto timeline = obj["timeline"];
                    state.rooms[room] = timeline["prev_batch"].str;
                    foreach (JSONValue event; timeline["events"].array)
                    {
                        foreach (IRoomListener listen; state.listeners)
                        {
                            listen.onEvent(this, room, event);
                        }
                    }
                }
            }

            return json;
        }
        catch (Exception e)
        {
            throw new MatrixResponseException(e.msg, val);
        }
    }
}
