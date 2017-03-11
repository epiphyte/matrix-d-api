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
import std.string: format;
import std.uri;

// Generali room listener
alias void function() Listener;

// Left/leave room listener
alias void function() LeftListener;

// Invite listener
alias void function() InviteListener;

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
        Listener[string] listeners;
        InviteListener[string] invites;
        LeftListener[string] leaves;
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

    public void joinRoom(string roomId)
    {
        // TODO: validate room id
        this.request(HTTP.Method.post, format("join/%s", encode(roomId)), null);
    }

    /**
     * Get rooms the user has joined
     */
    public string[] getRooms()
    {
        this.sync();
        return this.state.rooms.keys;
    }

    /**
     * Perform the sync call to matrix
     */
    private JSONValue sync()
    {
        this.checkAuthorized();
        return this.request(HTTP.Method.get, "sync", null);
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

            if (this.since !is null)
            {
                re.queryparams["since"] = this.since;
            }

            foreach (string qp; re.queryparams.keys)
            {
                auto start = '&';
                if (first)
                {
                    start = '?';
                }

                endpoint = endpoint ~ start ~ encode(qp);
                endpoint = endpoint ~ "=" ~ encode(re.queryparams[qp]);
            }

            auto client = HTTP(endpoint);
            client.operationTimeout = dur!"seconds"(this.timeout);
            client.addRequestHeader("ContentType", "application/json");
            if (re.data.length > 0 && method != HTTP.Method.get)
            {
                JSONValue j = JSONValue(re.data);
                client.postData = j.toJSON();
            }

            client.onReceive = (ubyte[] data)
            {
                val = val ~ cast(string)data;
                return data.length;
            };

            client.perform();
            auto json = parseJSON(val);
            if ("next_batch" in json)
            {
                this.since = json["next_batch"].str;
            }

            if (RoomKey in json)
            {
                auto rooms = json[RoomKey].object;
                foreach (string invite; rooms["invite"].object.keys)
                {
                    foreach (InviteListener invited; state.invites)
                    {
                    }
                }

                foreach (string leave; rooms["leave"].object.keys)
                {
                    foreach (LeftListener left; state.leaves)
                    {
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
                    foreach (JSONValue event; obj["state"]["events"].array)
                    {
                        // TODO: process state events
                        event["roomId"] = room;
                    }

                    foreach (JSONValue event; timeline["events"].array)
                    {
                        // TODO: process events
                        event["roomId"] = room;
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
