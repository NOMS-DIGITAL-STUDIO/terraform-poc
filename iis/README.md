# Historical Prisoner Application (IIS/HPA)

A NodeJS with express application deployed onto app service in Azure with an Azure SQL backend.

There is no app support currently for this application except a reasonable endavours basis by Paul Solecki.


For managing the github provider you need to export two environment variables.
If you dont have a Personal access token(PAT) already you will need to set it up and enable SSO with the MOJ org.
```
export GITHUB_TOKEN="..."
xEport GITHUB_ORGANIZATION="ministryofjustice"
```

Known Risks:

* initial setup of DB is unknown
* Deployment process may be broken and is not the same across environments.
* dependabot security alerts with the source code.
* RedirectHttpToHttps extension is no longer available so cannot be rebuilt.

Deployment process can be easily fixed with oauth to github and managed in terraform with resource below.
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_source_control_token

References:
https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/140643751/Historical+Prisoner+Application

https://github.com/ministryofjustice/iis

https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_source_control_token
