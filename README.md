This example uses lambda to serve-up widgets.

## Build

To build this app, you need to be in this example's root folder. Then run the following:

```bash
npm install -g aws-cdk
dotnet build src
```

This will install the necessary CDK, then this example's dependencies, and then build your csharp files and your CloudFormation template.

## Deploy

Run `cdk deploy`. This will deploy / redeploy your Stack to your AWS Account.

After the deployment you will see the API's URL, which represents the url you can then use.

## Test the service
```bash
#List all widgets
curl https://<api gateway domain/prod/

#Add a few widgets
curl -X POST https://<api gateway domain>/prod/123
curl -X POST https://<api gateway domain>/prod/456
curl -X POST https://<api gateway domain>/prod/abc

#List all widgets (should return array)
curl https://<api gateway domain/prod/

## Synthesize Cloudformation Template

To see the Cloudformation template generated by the CDK, run `cdk synth`, then check the output file in the "cdk.out" directory.