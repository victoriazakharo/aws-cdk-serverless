using Amazon.CDK;
using Amazon.CDK.AWS.APIGateway;
using Amazon.CDK.AWS.IAM;
using Amazon.CDK.AWS.DynamoDB;
using Amazon.CDK.AWS.Lambda;
using System.Collections.Generic;

namespace BlogService
{
    public class BlogServiceStack : Stack
    {
        public BlogServiceStack(Construct parent, string id, IStackProps props) : base(parent, id, props)
        {
            var role = Role.FromRoleArn(this, "LambdaRole", "arn:aws:iam::312226949769:role/IDTJawsLambdaFullAccessRole");
            var table = new Table(this, "BlogTable", new TableProps
            {
                PartitionKey = new Attribute { Name = "Id", Type = AttributeType.STRING },
                ReadCapacity = 3,
                WriteCapacity = 3
            });
            var env = new Dictionary<string, string> {
                    { "BlogTable", table.TableName },
                    { "DOTNET_SHARED_STORE", "/opt/dotnetcore/store/"}
                };
            var blogLayer = LayerVersion.FromLayerVersionArn(this, "BlogLayer", "arn:aws:lambda:us-east-1:312226949769:layer:BlogLayer:1");
            var getBlogs = new Function(this, "GetBlogs", new FunctionProps
            {
                Runtime = Runtime.DOTNET_CORE_2_1,
                Code = Code.FromAsset("src/GetBlogs/bin/Release/netcoreapp2.1/GetBlogs.zip"),
                Handler = "GetBlogs::GetBlogs.Function::GetBlogs",
                Description = "Function to get blogs",
                MemorySize = 256,
                Timeout = Duration.Seconds(30),
                Role = role,
                Environment = env,
                Layers = new [] { blogLayer }
            });
            var addBlog = new Function(this, "AddBlog", new FunctionProps
            {
                Runtime = Runtime.DOTNET_CORE_2_1,
                Code = Code.FromAsset("src/AddBlog/bin/Release/netcoreapp2.1/AddBlog.zip"),
                Handler = "AddBlog::AddBlog.Function::AddBlog",
                Description = "Function to add a blog",
                MemorySize = 256,
                Timeout = Duration.Seconds(30),
                Role = role,
                Environment = env,
                Layers = new[] { blogLayer }
            });
            var api = new RestApi(this, "BlogsRestApi", new RestApiProps
            {
                RestApiName = "Blog Service",
                CloudWatchRole = false
            });
            var getMethod = api.Root.AddMethod("GET", new LambdaIntegration(getBlogs, null), null);
            var postMethod = api.Root.AddMethod("POST", new LambdaIntegration(addBlog, null), null);
        }
    }
}
