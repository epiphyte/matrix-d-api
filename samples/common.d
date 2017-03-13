/**
 * Copyright 2017
 * MIT License
 * Common sample operations
 */
module samples.common;
import matrix.api;
import std.getopt;

/**
 * parse input arguments
 */
MatrixAPI parseArgs(string[] args)
{
    string host;
    string user;
    string password;
    string token;
    auto opts = getopt(args,
                       "host",
                       &host,
                       "user",
                       &user,
                       "password",
                       &password,
                       "token",
                       &token);
    auto api = new MatrixAPI();
    api.url = host;
    api.userId = user;
    api.password = password;
    api.token = token;
    return api;
}
