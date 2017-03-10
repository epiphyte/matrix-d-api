/**
 * Copyright 2017
 * MIT License
 * Matrix API
 */
module matrix_api;

/**
 * Interface to implement to create an api
 */
public interface IMatrixAPI
{
    /**
     * Get the display name of a user
     */
    string getDisplayName(string userId);

    /**
     * Set the display name of a user
     */
    string setDisplayName(string userId, string name);
}

///
version(MatrixUnitTest)
{
    // test api
    public class MatrixTestAPI : IMatrixAPI
    {
        // display name
        private string _display = "test";

        // inherits doc
        public string getDisplayName(string userId)
        {
            return this._display;
        }

        // inherits doc
        public string setDisplayName(string userId, string name)
        {
            this._display = name;
            return this._display;
        }
    }
}
