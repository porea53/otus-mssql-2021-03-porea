/* пример теста для проверки получения текущих погодных данных
используется https://openweathermap.org/api

скрипт получился неэстетичный из-за необходимости проверки ошибок.
см. пример для NewYork (пропущен пробел)
*/

;WITH Cities AS (
	SELECT 'Moscow' AS City
	UNION
	SELECT 'Beijing' AS City
	UNION
	SELECT 'London' AS City
	UNION
	SELECT 'NewYork' AS City
	UNION
	SELECT 'Sydney' AS City
	UNION
	SELECT 'Bogota' AS City
),
CitiesJSON AS (
	SELECT C.City, dbo.udfGetLocationTemperature(C.City,'') AS CityJSONData
	FROM Cities AS C	
),
CitiesChecked AS (
	SELECT C.City,
	CASE 
		WHEN LEFT(C.CityJSONData,5) = 'Error' THEN 1
		ELSE 0
	END AS isError,
	C.CityJSONData   
	FROM CitiesJSON AS C
)
SELECT	CError.City,
		CError.isError,
		null as SourceCityName,
		null as Country,
		null as WeatherDescription,
		null as Temperature,
		null as Pressure,
		null as Humidity
FROM CitiesChecked AS CError
WHERE isError = 1
UNION
SELECT	C.City,
		C.isError,
		J.[name] AS SourceCityName,
		J_SYS.Country,
		J_WEATHER.WeatherDescription,
		J_MAIN.Temperature,
		J_MAIN.Pressure,
		J_MAIN.Humidity
FROM CitiesChecked AS C
CROSS APPLY (
	SELECT * 
	FROM OPENJSON(dbo.udfGetLocationTemperature(C.City,''))
	WITH (
		weather nvarchar(max)				AS JSON,
		main	nvarchar(max)				AS JSON,
		[sys]		nvarchar(max)			AS JSON,
		name	nvarchar(150)		
	) 
) AS J
CROSS APPLY(
	SELECT main + ' ' + [description] as WeatherDescription
	FROM OPENJSON(J.weather)
	WITH (
		main nvarchar(50),
		[description] nvarchar(100)
	)
) AS J_WEATHER
CROSS APPLY(
	SELECT temp as Temperature, pressure as Pressure, humidity as Humidity
	FROM OPENJSON(J.main)
	WITH (
		temp decimal(10,2),
		pressure int,
		humidity int
	)
) AS J_MAIN
CROSS APPLY(
	SELECT country as Country 
	FROM OPENJSON(J.[sys])
	WITH (
		country nvarchar(100)
	)
) AS J_SYS
WHERE C.isError = 0;

