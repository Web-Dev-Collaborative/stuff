using System.Linq;
using NewRelic.Microsoft.SqlServer.Plugin.Properties;
using NUnit.Framework;

namespace NewRelic.Microsoft.SqlServer.Plugin.Configuration
{
    [TestFixture]
    public class ConfigurationParserTests
    {
        [Test]
        public void Assert_external_file_can_be_loaded()
        {
            Settings settings = ConfigurationParser.ParseSettings();
            Assert.That(settings, Is.Not.Null, "The settings from the config file should not be null");

            Assert.That(settings.LicenseKey, Is.EqualTo("FooGuid"), "LicenseKey not mapped correctly");
            Assert.That(settings.PollIntervalSeconds, Is.EqualTo(45), "PollIntervalSeconds not mapped correctly");

            string[] expectedSqlInstances = new[]
                                            {
                                                new
                                                {
                                                    Name = "Local",
                                                    ConnectionString = "Server=.;Database=master;Trusted_Connection=True;",
                                                    IncludedDatabases = new[] {"Northwind", "tempdb", "master", "model", "msdb"},
                                                    ExcludedDatabases = new string[0],
                                                },
                                                new
                                                {
                                                    Name = "Important Server",
                                                    ConnectionString = "Server=192.168.10.123,1234;Database=master;User Id=foo;Password=bar;",
                                                    IncludedDatabases = new string[0],
                                                    ExcludedDatabases = new[] {"foo", "bar"}.Concat(Constants.SystemDatabases).ToArray(),
                                                },
                                            }.Select(i => SqlServerEndpoint.FormatProperties(i.Name, i.ConnectionString, i.IncludedDatabases, i.ExcludedDatabases)).ToArray();

            SqlServerEndpoint[] sqlServers = settings.Endpoints.OfType<SqlServerEndpoint>().ToArray();

            string[] actualInstances = sqlServers.Select(s => s.ToString()).ToArray();
            Assert.That(actualInstances, Is.EquivalentTo(expectedSqlInstances), "Endpoints Found different from expected");

            Database databaseWithDisplayName = sqlServers.Single(e => e.Name == "Local").IncludedDatabases.Single(d => d.Name == "Northwind");
            Assert.That(databaseWithDisplayName.DisplayName, Is.EqualTo("Southbreeze"), "Display name cannot be configured");

            string[] azureSqlDatabases = settings.Endpoints.OfType<AzureSqlEndpoint>().Select(a => a.ToString()).ToArray();
            var expectedAzureDatabases = new[] { "Name: CloudFtw, ConnectionString: Server=zzz,1433;Database=CloudFtw;User ID=NewRelic;Password=aaa;Trusted_Connection=false;Encrypt=true;Connection Timeout=30;" };
            Assert.That(azureSqlDatabases, Is.EqualTo(expectedAzureDatabases));
        }
    }
}
