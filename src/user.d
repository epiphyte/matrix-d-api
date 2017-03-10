/**
 * Copyright 2017
 * MIT License
 * User operations
 */
module matrix_client_user;
import matrix_api;
import matrix_client_helpers;

/**
 * User operations
 */
public class User
{
    // backing user id
    private string _userId;

    // backing api
    private IMatrixAPI _api;

    // Create a new user instance
    this (IMatrixAPI api, string userId)
    {
        validateUserId(userId);
        this._userId = userId;
        this._api = api;
    }

    // get the display name
    public string getDisplayName()
    {
        return this._api.getDisplayName(this._userId);
    }

    // get the friendly name
    public string getFriendlyName()
    {
        auto display = this.getDisplayName();
        if (display !is null && display.length > 0)
        {
            return display;
        }
        else
        {
            return this._userId;
        }
    }

    // set the display name
    public string setDisplayName(string name)
    {
        return this._api.setDisplayName(this._userId, name);
    }
}

///
version(MatrixUnitTest)
{
    unittest
    {
        auto user = new User(new MatrixTestAPI(), "@test:test");
        assert(user.getDisplayName() == "test");
        assert(user.setDisplayName(null) is null);
        assert(user.getFriendlyName() == "@test:test");
    }
}
