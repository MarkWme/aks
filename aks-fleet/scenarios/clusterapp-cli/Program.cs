using Newtonsoft.Json;
using System;
using System.Net.Http;
using System.Threading.Tasks;

class Program
{
    class ClusterInfo
    {
        public string? Cluster { get; set; }
        public string? Region { get; set; }
        public string? Node { get; set; }
        public string? Pod { get; set; }
        public string? Ip { get; set; }
    }

    static async Task Main(string[] args)
    {
        if (args.Length == 0)
        {
            Console.WriteLine("Usage: Program <IP Address> [Number of Iterations]");
            return;
        }

        string hostIp = args[0];
        int n = args.Length > 1 ? int.Parse(args[1]) : 10; // Default to 10 iterations if not specified

        using HttpClient client = new HttpClient
        {
            Timeout = TimeSpan.FromSeconds(5) // Set timeout to 5 seconds
        };
        Console.WriteLine($"{"Cluster",-35} {"Region",-15} {"Node",-30} {"Pod",-45} {"IP",-15}");
        Console.WriteLine(new string('-', 140));
        for (int i = 0; i < n; i++)
        {
            try
            {
                using var requestMessage = new HttpRequestMessage(HttpMethod.Get, $"http://{hostIp}/hostinfo");
                requestMessage.Headers.ConnectionClose = true; // Close the connection to ensure a different pod is used for each request
                HttpResponseMessage response = await client.SendAsync(requestMessage);
                string result = await response.Content.ReadAsStringAsync();
                var clusterInfo = JsonConvert.DeserializeObject<ClusterInfo>(result);
                Console.WriteLine($"{clusterInfo?.Cluster,-35} {clusterInfo?.Region,-15} {clusterInfo?.Node,-30} {clusterInfo?.Pod,-45} {clusterInfo?.Ip,-15}");
            }
            catch (TaskCanceledException)
            {
                Console.WriteLine("Operation timed out.");
            }
            catch (HttpRequestException e)
            {
                Console.WriteLine($"HTTP Request failed: {e.Message}");
            }
            catch (Exception e)
            {
                Console.WriteLine($"An error occurred: {e.Message}");
            }
            await Task.Delay(1000);
        }
    }
}