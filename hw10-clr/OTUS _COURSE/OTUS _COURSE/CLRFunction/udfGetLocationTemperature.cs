using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using OtusCourseCLR;
public partial class UserDefinedFunctions
{
    [Microsoft.SqlServer.Server.SqlFunction]
    public static SqlString udfGetLocationTemperature(SqlString locationName, SqlString apiKey)
    {
        try 
        { 
            var weatherGetter = new OpenWeatherMapGetter(apiKey.ToString());

            return (SqlString) weatherGetter.GetWeatherByLocation(locationName.ToString());
        }
        catch(Exception ex)
        {
            return (SqlString) "Error: " + ex.Message;
        }
    }
}
