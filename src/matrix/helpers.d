/**
 * Copyright 2017
 * MIT License
 * Helper functions for client/api operations
 */
module matrix.helpers;
import matrix.errors;
import std.string: indexOf;

/**
 * Validate an identifier <char><name>:<domain>
 */
public static void validateId(string id, char start, string type)
{
    if (id is null || id.length == 0)
    {
        throw new MatrixConfigException(type ~ " id is empty");
    }
    else
    {
        if (id[0] != start)
        {
            throw new MatrixConfigException(
                    type ~ " id must start with '" ~ start ~ "'"
                                           );
        }
        else
        {
            if (id.indexOf(":") < 0)
            {
                throw new MatrixConfigException(
                        type ~ " id must be <name>:<domain>"
                                               );
            }
        }
    }
}

/**
 * Validate a user id
 */
public static void validateUserId(string userId)
{
    validateId(userId, '@', "user");
}

///
version(MatrixUnitTest)
{
    unittest
    {
        try
        {
            validateUserId("");
            assert(false);
        }
        catch (MatrixConfigException e)
        {
            assert(e.msg == "user id is empty");
        }

        try
        {
            validateUserId("test");
            assert(false);
        }
        catch (MatrixConfigException e)
        {
            assert(e.msg == "user id must start with '@'");
        }

        try
        {
            validateUserId("@test");
            assert(false);
        }
        catch (MatrixConfigException e)
        {
            assert(e.msg == "user id must be <name>:<domain>");
        }
    }
}

/**
 * Validate a room id
 */
public static void validateRoomId(string roomId)
{
    validateId(roomId, '!', "room");
}

///
version(MatrixUnitTest)
{
    unittest
    {
        try
        {
            validateRoomId("");
            assert(false);
        }
        catch (MatrixConfigException e)
        {
            assert(e.msg == "room id is empty");
        }

        try
        {
            validateRoomId("test");
            assert(false);
        }
        catch (MatrixConfigException e)
        {
            assert(e.msg == "room id must start with '!'");
        }

        try
        {
            validateRoomId("!test");
            assert(false);
        }
        catch (MatrixConfigException e)
        {
            assert(e.msg == "room id must be <name>:<domain>");
        }
    }
}
