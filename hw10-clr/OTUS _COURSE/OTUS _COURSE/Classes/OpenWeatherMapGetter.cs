using System;
using System.IO;
using System.Net;

namespace OtusCourseCLR
{
    class OpenWeatherMapGetter
    {
        const string defaultApiKey = "";
        const string apiLocationUrl = "http://api.openweathermap.org/data/2.5/weather?q={1}&appid={0}&units=metric";

        private string apiKey;

        public OpenWeatherMapGetter(string _apiKey)
        {
            if (String.IsNullOrEmpty(apiKey))
            {
                apiKey = defaultApiKey;
            }
            else 
            {
                apiKey = _apiKey;
            }
        }

        public string GetWeatherByLocation(string location)
        {

            string requestUrl = String.Format(apiLocationUrl, WebUtility.UrlEncode(apiKey), WebUtility.UrlEncode(location));

            HttpWebRequest request = (HttpWebRequest) WebRequest.Create(requestUrl);

            request.Credentials = CredentialCache.DefaultCredentials;

            HttpWebResponse response = (HttpWebResponse)request.GetResponse();

            if (response.StatusCode != HttpStatusCode.OK)
            {
                throw new Exception("?????? ??? ????????? ??????. " + response.StatusDescription);
            }

            Stream dataStream = response.GetResponseStream();
           
            StreamReader reader = new StreamReader(dataStream);
            
            string responseFromServer = reader.ReadToEnd();
            
            Console.WriteLine(responseFromServer);
            // Cleanup the streams and the response.
            reader.Close();
            dataStream.Close();
            response.Close();

            return responseFromServer;
        }

    }
}
