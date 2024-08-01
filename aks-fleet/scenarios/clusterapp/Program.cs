using System.Net;
using System.Net.Sockets;
using k8s;
using k8s.Models;


var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.MapGet("/hostinfo", async () =>
{
    var config = KubernetesClientConfiguration.InClusterConfig();
    var client = new Kubernetes(config);
    string nodeName = Environment.GetEnvironmentVariable("NODE_NAME");
    var node = await client.ReadNodeAsync(nodeName);
    var hostName = Dns.GetHostName(); // get container id
    var ip = Dns.GetHostEntry(hostName).AddressList.FirstOrDefault(x => x.AddressFamily == AddressFamily.InterNetwork)?.ToString();
    var labels = node.Metadata.Labels; // This is a Dictionary<string, string> of the node's labels
    labels.TryGetValue("topology.kubernetes.io/region", out var regionValue);

    var configMapName = "cluster-info"; // Replace with your ConfigMap name
    var configMapKey = "cluster-name"; // Replace with the key you want to read
    var clusterInfoNamespace = "kube-system"; // Namespace where your ConfigMap is located
    var configMap = await client.ReadNamespacedConfigMapAsync(configMapName, clusterInfoNamespace);
    configMap.Data.TryGetValue(configMapKey, out var clusterName);

    return new { Cluster = clusterName, Region = regionValue , Node = nodeName, Pod = hostName, IP = ip };
})
.WithName("GetHostInfo")
.WithOpenApi();

app.Run();