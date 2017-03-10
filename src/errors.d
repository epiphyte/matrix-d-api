/**
 * Copyright 2017
 * MIT License
 * Matrix Client Exceptions
 */
module matrix_client_errors;

/**
 * Base matrix exception type
 */
private abstract class MatrixException : Exception
{
    // backing content
    protected string _content;

    // gets the exception content
    @property public string content()
    {
        return this._content;
    }

    // defines a new exception from interacting with Matrix
    this (string message, string content)
    {
        super(message);
        this._content = content;
    }
}

/**
 * Matrix setup/configuration errors
 */
public class MatrixConfigException : Exception
{
    // init the instance
    this (string message)
    {
        super(message);
    }
}

///
version(MatrixUnitTest)
{
    unittest
    {
        auto req = new MatrixConfigException("test");
        assert("test" == req.msg);
    }
}

/**
 * Responses when getting data from matrix
 */
public class MatrixResponseException : MatrixException
{
    // defines a new response exception
    this (string message, string content = "")
    {
        super(message, content);
    }
}

///
version(MatrixUnitTest)
{
    unittest
    {
        auto req = new MatrixResponseException("test");
        assert("" == req.content);
        assert("test" == req.msg);
        req = new MatrixResponseException("test2", "content");
        assert("content" == req.content);
        assert("test2" == req.msg);
    }
}

/**
 * Matrix requests out (exceptions)
 */
public class MatrixRequestException : MatrixException
{
    // backing request code error
    private int _code;

    // gets the error code
    @property public int code()
    {
        return this._code;
    }

    // creates a new response exception
    this (string message, string content = "", int code = 0)
    {
        super(message, content);
        this._code = code;
    }
}

///
version(MatrixUnitTest)
{
    unittest
    {
        auto req = new MatrixRequestException("test");
        assert(0 == req.code);
        assert("" == req.content);
        assert("test" == req.msg);
        req = new MatrixRequestException("test2", "content");
        assert(0 == req.code);
        assert("content" == req.content);
        assert("test2" == req.msg);
        req = new MatrixRequestException("test3", "content2", 1);
        assert(1 == req.code);
        assert("content2" == req.content);
        assert("test3" == req.msg);
    }
}
