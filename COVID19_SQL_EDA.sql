SELECT * FROM [COVID Portfolio Project]..COVIDDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT * FROM [COVID Portfolio Project]..COVIDVaccincations
--ORDER BY 3,4


--Select data to be used
SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM [COVID Portfolio Project]..COVIDDeaths
ORDER BY 1,2

--Comparing Total Cases and Total Deaths
--Estimated likelihood of dying if a person contracts COVID
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM [COVID Portfolio Project]..COVIDDeaths
WHERE location = 'India'
ORDER BY 1,2

--Comparing Total Cases and Population
--Percentage of total population affected
SELECT location, date, total_cases, population, (total_cases/population) * 100 AS AffectedPercentage
FROM [COVID Portfolio Project]..COVIDDeaths
WHERE location = 'India'
ORDER BY 1,2

--Countries with highest infection rate with respect to population
SELECT location, MAX(total_cases) AS PeakCases, population, MAX((total_cases/population) * 100) AS MaxInfectedPopulation
FROM [COVID Portfolio Project]..COVIDDeaths
GROUP BY location, population
ORDER BY MaxInfectedPopulation DESC

--Countries with highest death rate with respect to population
SELECT location, MAX(CAST(total_deaths AS int)) AS PeakDeaths
FROM [COVID Portfolio Project]..COVIDDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY PeakDeaths DESC

--Grouping the same wrt continent
SELECT continent, MAX(CAST(total_deaths AS int)) AS PeakDeaths
FROM [COVID Portfolio Project]..COVIDDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY PeakDeaths DESC

SELECT location, MAX(CAST(total_deaths AS int)) AS PeakDeaths
FROM [COVID Portfolio Project]..COVIDDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY PeakDeaths DESC

--Continents with highest death count
SELECT continent, MAX(CAST(total_deaths as int)) AS PeakDeaths
FROM [COVID Portfolio Project]..COVIDDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY PeakDeaths DESC

SELECT date, SUM(new_cases) AS PeakCases, SUM(CAST(new_deaths AS int)) AS PeakDeaths, SUM(CAST(new_deaths AS int))/SUM(new_cases) * 100 AS DeathPercentage
FROM [COVID Portfolio Project]..COVIDDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) AS PeakCases, SUM(CAST(new_deaths AS int)) AS PeakDeaths, SUM(CAST(new_deaths AS int))/SUM(new_cases) * 100 AS DeathPercentage
FROM [COVID Portfolio Project]..COVIDDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--Total population vs Vaccinations
SELECT dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations
,SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) as new_vaccinations_rolling
--,(new_vaccinations_rolling/population) * 100
FROM [COVID Portfolio Project]..COVIDDeaths dea
JOIN [COVID Portfolio Project]..COVIDVaccincations vac
ON dea.location =vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2,3

--Using CTE 
WITH popVSvac (Continent, Location, Date, Population, NewVaccinations, RollingVaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations
,SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) as new_vaccinations_rolling
FROM [COVID Portfolio Project]..COVIDDeaths dea
JOIN [COVID Portfolio Project]..COVIDVaccincations vac
ON dea.location =vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 1,2,3
)
SELECT *, (RollingVaccinations/Population)*100 FROM popVSvac AS PercentPopulationVaccinated

--TEMP Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
NewVaccinations numeric,
NewVaccinationsRolling numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations
,SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) as new_vaccinations_rolling
FROM [COVID Portfolio Project]..COVIDDeaths dea
JOIN [COVID Portfolio Project]..COVIDVaccincations vac
ON dea.location =vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 1,2,3

SELECT *, (NewVaccinationsRolling/Population) * 100 
FROM #PercentPopulationVaccinated

--Create view for data visualization
DROP VIEW IF EXISTS PercentPopulationVaccinated

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations
,SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) as new_vaccinations_rolling
FROM [COVID Portfolio Project]..COVIDDeaths dea
JOIN [COVID Portfolio Project]..COVIDVaccincations vac
ON dea.location =vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 1,2,3