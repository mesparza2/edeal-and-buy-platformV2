using System.Reflection;
using NetArchTest.Rules;

namespace EDealBuy.Api.Tests;

public class ArchitectureTests
{
    private static readonly Assembly Api = Assembly.Load("EDealBuy.Api");
    private static readonly Assembly Domain = Assembly.Load("EDealBuy.Domain");
    private static readonly Assembly Infrastructure = Assembly.Load("EDealBuy.Infrastructure");

    private static readonly string[] DataAccess =
    [
        "Microsoft.EntityFrameworkCore",
        "Microsoft.Data.SqlClient",
        "System.Data.SqlClient",
        "System.Data",
        "Dapper",
    ];

    [Fact]
    public void Controllers_do_not_depend_on_data_access()
    {
        var result = Types.InAssembly(Api)
            .That().ResideInNamespace("EDealBuy.Api.Controllers")
            .ShouldNot().HaveDependencyOnAny(DataAccess)
            .GetResult();

        Assert.True(result.IsSuccessful, Failing(result));
    }

    [Fact]
    public void Controllers_do_not_depend_on_infrastructure()
    {
        var result = Types.InAssembly(Api)
            .That().ResideInNamespace("EDealBuy.Api.Controllers")
            .ShouldNot().HaveDependencyOn("EDealBuy.Infrastructure")
            .GetResult();

        Assert.True(result.IsSuccessful, Failing(result));
    }

    [Fact]
    public void Domain_has_no_framework_or_outer_layer_dependencies()
    {
        var result = Types.InAssembly(Domain)
            .ShouldNot().HaveDependencyOnAny(
                [.. DataAccess, "EDealBuy.Api", "EDealBuy.Infrastructure", "Microsoft.AspNetCore"])
            .GetResult();

        Assert.True(result.IsSuccessful, Failing(result));
    }

    [Fact]
    public void Infrastructure_does_not_depend_on_api()
    {
        var result = Types.InAssembly(Infrastructure)
            .ShouldNot().HaveDependencyOn("EDealBuy.Api")
            .GetResult();

        Assert.True(result.IsSuccessful, Failing(result));
    }

    private static string Failing(TestResult result) =>
        "Violaciones: " + string.Join(", ", result.FailingTypeNames ?? []);
}
