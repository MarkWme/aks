Thoughts on network policy

Don't think IMDS access is needed for the scenario. 

At the moment, the error in the app is:

E0725 21:29:10.818483       1 main.go:60] "failed to get secret from keyvault" err="Get \"https://azwi-kv-quickstart.vault.azure.net/secrets/my-secret/?api-version=7.4\": dial tcp: lookup azwi-kv-quickstart.vault.azure.net: i/o timeout" keyvault="https://azwi-kv-quickstart.vault.azure.net/" secretName="my-secret"

Sounds like the app can't get to key vault. Works fine without network policy.

So, is the fix to this to setup a private endpoint for the key vault?

```
E0726 07:55:05.768046       1 main.go:60] "failed to get secret from keyvault" err=<
	unable to resolve an endpoint: server response error:
	 Get "https://login.microsoftonline.com/cead5b25-9ce3-4db1-83d6-b397dbc7f167/v2.0/.well-known/openid-configuration": dial tcp 40.126.32.134:443: i/o timeout
 > keyvault="https://azwi-kv-quickstart.vault.azure.net/" secretName="my-secret"
 ```
