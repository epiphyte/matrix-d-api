/**
 * Copyright 2017
 * MIT License
 * Helper functions for client/api operations
 */
module matrix_client_helpers;
import matrix_client_errors;
import std.string: indexOf;

/**
 * Validate a user identifier
 */
public static void validateUserId(string userId)
{
    if (userId.length == 0)
    {
        throw new MatrixConfigException("user id is empty");
    }
    else
    {
        if (userId[0] != '@')
        {
            throw new MatrixConfigException("user id must start with '@'");
        }
        else
        {
            if (userId.indexOf(":") < 0)
            {
                throw new MatrixConfigException(
                        "user id must be <name>:<domain>"
                                               );
            }
        }
    }
}

///
version(MatrixUnitTest)
{
    unittest
    {
        try
        {
            validateUserId("");
        }
        catch (MatrixConfigException e)
        {
            assert(e.msg == "user id is empty");
        }

        try
        {
            validateUserId("test");
        }
        catch (MatrixConfigException e)
        {
            assert(e.msg == "user id must start with '@'");
        }

        try
        {
        }
        catch (MatrixConfigException e)
        {
            assert(e.msg == "user id must be <name>:<domain>");
        }
    }
}
