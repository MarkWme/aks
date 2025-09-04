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

 Adding a DNS policy now allows the private endpoint of KV to be resolved. But, error changes to the above, which is now indicating that we can't talk to Azure AD.

---

A customer I'm working with is trying to apply network policies to their AKS cluster, but they're running into issues with workload identity. I just want to confirm my thinking that this isn't really feasible, or whether I'm misssing a trick!

The main issue, I believe, is that their workload will need to connect to the well known OIDC endpoint https://login.microsoftonline.com/{tenant}/v2.0/.well-known/openid-configuration and for that to work they will need to list all of the IP addresses that Azure AD uses. They've added the IMDS endpoint and 168.63.129.16 to their policies, but I don't believe that works because IMDS isn't used for workload identity (if they're not using the sidecar) and 168.63.129.16 provides access to Azure platform services but has nothing to do with AAD.

I've got it working by figuring out the particular CIDR that's getting returned by DNS when the app tries to resolve login.microsoftonline.com, but that's not really going to be a scalable solution.

I think the only realistic approach to this is to use FQDN based filtering, which means they either need to go for something like BYO Cilium, or wait for the FQDN filtering that's coming in ACNS.

Have I got that right, or am I overlooking something obvious?