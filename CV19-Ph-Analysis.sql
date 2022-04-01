-- PHILIPPINES vaccination & deaths data
-- VACCINATION DATA
SELECT * FROM [CV19-Ph-Analysis]..['CVvaccinations$']
WHERE continent is not null AND location like '%lippin%'
ORDER BY 3, 4

-- EXPLORE TOTAL CASES, NEW CASES, AND TOTAL DEATHS
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [CV19-Ph-Analysis]..['CVdeaths$']
WHERE location like '%lippin%'
ORDER BY 1, 2

-- DEATH PERCENTAGE
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS deathPercentage
FROM [CV19-Ph-Analysis]..['CVdeaths$']
WHERE location like '%lippin%'
ORDER BY 1,2

-- INFECTED PERCENTAGE
SELECT location, date, total_cases, population, (total_cases/population)*100 AS infectedPercentage
FROM [CV19-Ph-Analysis]..['CVdeaths$']
WHERE location like '%lippin%'
ORDER BY 1, 2

-- WORLD: MOST INFECTED COUNTRIES - by percentage population
SELECT location, MAX(total_cases) as highestInfection, population, MAX((total_cases/population))*100 AS infectedPercentage
FROM [CV19-Ph-Analysis]..['CVdeaths$']
WHERE continent is not null
GROUP BY location, population
ORDER BY infectedPercentage DESC

-- WORLD: countries with most deaths
SELECT location, population, MAX(cast(total_deaths as int)) as maximumDeath, MAX((total_deaths/population))*100 as deathPercentage
FROM [CV19-Ph-Analysis]..['CVdeaths$']
WHERE continent is not null
GROUP BY location, population
ORDER BY maximumDeath DESC

-- PER CONTINENT: most deaths
SELECT continent, MAX(cast(total_deaths as int)) as maximumDeath, MAX((total_deaths/population))*100 as deathPercentage
FROM [CV19-Ph-Analysis]..['CVdeaths$']
WHERE continent is not null
GROUP BY continent
ORDER BY maximumDeath DESC


-- GLOBAL NUMBERS
SELECT date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS deathPercentage
FROM [CV19-Ph-Analysis]..['CVdeaths$']
WHERE continent is not null
--GROUP BY date
ORDER BY 1, 2


-- WORLD COUNT: Death & Death Percentage
SELECT SUM(new_cases) as globalCaseCount, SUM(cast(new_deaths as int)) as globalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as deathPercentage
FROM [CV19-Ph-Analysis]..['CVdeaths$']
WHERE continent is not null
ORDER BY 3 DESC


-- looking at existing vaccinations & percentage of vaccinated population
-- CTE
WITH PopVsVac (continent,location, date, population, new_vaccinations, rollingVaccinatedCount)
AS (

SELECT vac.continent, vac.location, vac.date, vac.population, dea.new_vaccinations
, SUM(CONVERT(bigint,dea.new_vaccinations)) OVER (PARTITION BY vac.location ORDER BY vac.location, vac.date) AS rollingVaccinatedCount
--, (rollingVaccinatedCount/dea.population)*100

FROM [CV19-Ph-Analysis]..['CVvaccinations$'] dea
JOIN [CV19-Ph-Analysis]..['CVdeaths$'] vac
	ON vac.location = dea.location
	AND vac.date = dea.date
WHERE dea.continent is not null --AND vac.new_vaccinations is not null
--ORDER BY 1, 2, 3
)
SELECT *, (rollingVaccinatedCount/population)*100 AS percentageVaccinated
FROM PopVsVac


-- CREATING TEMP TABLE
-- condition to prevent multiple tables
DROP TABLE IF EXISTS #VaccinatedPopulationPercent
CREATE TABLE #VaccinatedPopulationPercent
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
rollingVaccinatedCount numeric
)

-- USING THE TEMP TABLE
INSERT INTO #VaccinatedPopulationPercent
SELECT vac.continent, vac.location, vac.date, vac.population, dea.new_vaccinations
, SUM(CONVERT(bigint,dea.new_vaccinations)) OVER (PARTITION BY vac.location ORDER BY vac.location, vac.date) AS rollingVaccinatedCount
--, (rollingVaccinatedCount/dea.population)*100

FROM [CV19-Ph-Analysis]..['CVdeaths$'] vac
JOIN [CV19-Ph-Analysis]..['CVvaccinations$'] dea
	ON vac.location = dea.location
	AND vac.date = dea.date
WHERE dea.continent is not null --AND vac.new_vaccinations is not null
--ORDER BY 1, 2, 3
SELECT *, (rollingVaccinatedCount/population)*100
FROM #VaccinatedPopulationPercent


-- CREATE VIEW: For visualization later
CREATE VIEW VaccinatedPopulationPercent AS 
SELECT vac.continent, vac.location, vac.date, vac.population, dea.new_vaccinations
, SUM(CONVERT(bigint,dea.new_vaccinations)) OVER (PARTITION BY vac.location ORDER BY vac.location, vac.date) AS rollingVaccinatedCount
--, (rollingVaccinatedCount/dea.population)*100

FROM [CV19-Ph-Analysis]..['CVdeaths$'] vac
JOIN [CV19-Ph-Analysis]..['CVvaccinations$'] dea
	ON vac.location = dea.location
	AND vac.date = dea.date
WHERE dea.continent is not null --AND vac.new_vaccinations is not null
--ORDER BY 1, 2, 3

SELECT *
FROM VaccinatedPopulationPercent


-- FOR TABLEAU

-- WORLD: death percentage
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths
, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as deathPercentage
FROM [CV19-Ph-Analysis]..['CVdeaths$']
WHERE continent is not null AND location not in ('World', 'European Union', 'International', 'Low income', 'Lower middle income', 'High income', 'Upper middle income')
ORDER BY 1, 2

-- CONTINENTS: total death
SELECT location, SUM(cast(new_deaths as int)) as totalDeaths
FROM [CV19-Ph-Analysis]..['CVdeaths$']
-- continent is null condition to access continents (ironically)zz
WHERE continent is null AND location not in ('World', 'European Union', 'International', 'Low income', 'Lower middle income', 'High income', 'Upper middle income')
GROUP BY location
ORDER BY totalDeaths

-- COUNTRIES: most infected by population
SELECT location, population, MAX(total_cases) as highestInfection, MAX((total_cases/population))*100 as infectedPopulationPercent
FROM [CV19-Ph-Analysis]..['CVdeaths$']
WHERE continent is not null AND location not in ('World', 'European Union', 'International', 'Low income', 'Lower middle income', 'High income', 'Upper middle income')
GROUP BY location, population
ORDER BY infectedPopulationPercent DESC

-- COUNTRIES: most infected by population with date
SELECT location, population, date, MAX(total_cases) as highestInfection, MAX((total_cases/population))*100 as infectedPopulationPercent
FROM [CV19-Ph-Analysis]..['CVdeaths$']
WHERE continent is not null AND location not in ('World', 'European Union', 'International', 'Low income', 'Lower middle income', 'High income', 'Upper middle income')
GROUP BY location, population, date
ORDER BY infectedPopulationPercent DESC

-- ASEAN: highest infected percentage population
SELECT location, population, date, MAX(total_cases) as highestInfection, MAX((total_cases/population))*100 as infectedPopulationPercent
FROM [CV19-Ph-Analysis]..['CVdeaths$']
WHERE location like '%lippin%' OR location like '%rune%'
OR location like '%mbodi%' OR location like '%ndones%' OR location like '%aos%'
OR location like '%alaysi%' OR location like '%yanma%' OR location like '%ingapo%'
OR location like '%hailan%' OR location like '%ietna%'
GROUP BY location, population, date
ORDER BY infectedPopulationPercent DESC