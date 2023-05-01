SELECT * FROM CovidDeaths
ORDER BY 3,4

SELECT * FROM CovidVaccinations
ORDER BY 3,4

-- Select Data that we are going to use.
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths.
-- Shows likelihood of dying if you contract covid in United States and United States Virgin Islands.
SELECT Location, Date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%' AND continent is not null
ORDER BY Location, Date

-- Total cases vs Population.
-- Percentage of population that got covid in United States and United States Virgin Islands.
SELECT Location, Date, total_cases, population, (total_cases/population)*100 as PercentOfPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%' AND continent is not null
ORDER BY Location, Date

-- Looking at countries with highest Infection Rates compared to Population.
-- Date is not included in this query so we are looking at highest point in history of these variables.
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 
AS PercentOfPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY Location, Population
ORDER BY PercentOfPopulationInfected DESC

-- Showing Countries with highest Death Count per Population.
-- Overall average percentage of deaths is presented to compare the countries to the global results.
SELECT 
	Location, 
	Population, 
	MAX(total_deaths) AS TotalDeaths, 
	MAX(total_deaths/population)*100 AS PercentageOfDeaths, 
	(SELECT AVG(total_deaths/population)*100 FROM CovidDeaths) AS AvgDeathsPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY Location, Population
ORDER BY PercentageOfDeaths DESC

-- Same previous calculations with continents this time.
-- When Continent is NULL we have global info about continents, income and other groups of which we
-- only want to take a look at continents.
SELECT
	Location,
	MAX(total_deaths) AS TotalDeathCount,
	MAX(Population) AS Population,
	MAX(total_deaths) / MAX(Population) * 100 AS PercentageOfDeaths,
	(SELECT AVG(total_deaths/population)*100 FROM CovidDeaths) AS AvgDeathsPercentage
FROM PortfolioProject..CovidDeaths
WHERE Continent is null AND Location NOT LIKE '%income%' AND Location NOT LIKE '%World%'AND Location NOT LIKE '%Union%'
GROUP BY Location
ORDER BY PercentageOfDeaths DESC

-- Global numbers per date.
-- We can observe how total deaths, total cases and the ratio between these two changes from day to day.
SELECT Date, max(total_cases) AS TotalCases, max(total_deaths) AS TotalDeaths, max(total_deaths)/max(total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY Date
ORDER BY Date


-- Total population vs Total Vaccinations
-- This is an interesting part of the code because it mixes different important functions to gather all the info.
-- To start, we need to join the tables so we connect population with vaccination data.
-- Next, we work with CTEs because we want to use a SUM operation in several columns and we don't
-- want to create that SUM every time.
WITH CTE_PopulationVSVaccination (Continent,Location,Date,Population, new_vaccinations,rolling_total_vaccination)
AS
(SELECT 
	CD.Continent,
	CD.Location,
	CD.Date,
	CD.Population,
	CV.new_vaccinations,
	SUM(CV.new_vaccinations) OVER (PARTITION BY CD.Location ORDER BY CD.Location,CD.Date) AS rolling_total_vaccinations
FROM CovidDeaths as CD
JOIN
CovidVaccinations as CV
	ON CD.Location=CV.Location
	AND CD.Date=CV.Date
WHERE CD.Continent is not null)
SELECT *, (rolling_total_vaccination/Population)*100 as percentage_of_vaccination
FROM CTE_PopulationVSVaccination
ORDER BY Location,Date

-- Same case than before but with Temp Tables this time.
-- We add a first line with DROP TABLE IF EXISTS in case we want to create a Procedure in another moment with this code.
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_total_vaccination numeric)

INSERT INTO #PercentPopulationVaccinated
SELECT 
	CD.Continent,
	CD.Location,
	CD.Date,
	CD.Population,
	CV.new_vaccinations,
	SUM(CV.new_vaccinations) OVER (PARTITION BY CD.Location ORDER BY CD.Location,CD.Date) AS rolling_total_vaccinations
FROM CovidDeaths as CD
JOIN
CovidVaccinations as CV
	ON CD.Location=CV.Location
	AND CD.Date=CV.Date
WHERE CD.Continent is not null
-- We can now query the data from our Temp Table
SELECT *, (rolling_total_vaccination/Population)*100 as percentage_of_vaccination
FROM #PercentPopulationVaccinated
ORDER BY Location,Date


-- Creating VIEW to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
	CD.Continent,
	CD.Location,
	CD.Date,
	CD.Population,
	CV.new_vaccinations,
	SUM(CV.new_vaccinations) OVER (PARTITION BY CD.Location ORDER BY CD.Location,CD.Date) AS rolling_total_vaccinations
FROM CovidDeaths as CD
JOIN
CovidVaccinations as CV
	ON CD.Location=CV.Location
	AND CD.Date=CV.Date
WHERE CD.Continent is not null