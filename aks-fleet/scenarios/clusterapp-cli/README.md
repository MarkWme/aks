# ClusterApp CLI

Simple app to call the ClusterApp and display the result returned.

It will display the returned information from the API in a table format.

The app closes the connection between each call to the API to increase the likelihood that a different backend will be selected each time.

Usage:

The app expects and IP address for the API endpoint and a number of iterations to run.

For example

`dotnet run -- 1.2.3.4 20`

Will run the app, use `1.2.3.4` as the API endpoint and will attempt to call it 20 times.