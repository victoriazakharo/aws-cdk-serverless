using Amazon.CDK;

namespace BlogService
{
    class Program
    {
        static void Main(string[] args)
        {
            var app = new App(null);
            new BlogServiceStack(app, "BlogServiceStack", new StackProps());
            app.Synth();
        }
    }
}
