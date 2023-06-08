--Dataset used can be found at https://ourworldindata.org/covid-deaths

-- Finding percentage of deaths in patients who contracted COVID

SELECT location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDataProject..CovidDeaths
ORDER BY location, date

-- Comparing total cases and population to find the percentage of the population that contracted COVID

SELECT location, date, total_cases, population, (total_cases/population)*100 as PopulationPercentage
FROM CovidDataProject..CovidDeaths
ORDER BY location, date

-- Finding highest infection rate of each country compared to population, removing aggregated continent numbers

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PopulationPercentage
FROM CovidDataProject..CovidDeaths
WHERE continent IS NOT null
GROUP BY location, population
ORDER BY PopulationPercentage desc

-- Finding highest death rate among countries recorded, removing aggregated continent numbers

SELECT location, MAX(cast(total_deaths as int)) as HighestDeathCount, MAX((total_deaths/population))*100 as DeathPercentage
FROM CovidDataProject..CovidDeaths
WHERE continent IS NOT null
GROUP BY location
ORDER BY HighestDeathCount desc

-- Finding highest infection rate grouped by continent

SELECT location, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as InfectionPercentage
FROM CovidDataProject..CovidDeaths
WHERE continent IS null
GROUP BY location
ORDER BY HighestInfectionCount desc

-- Finding highest death rate grouped by continent 

SELECT location, MAX(cast(total_deaths as int)) as HighestDeathCount, MAX((total_deaths/population))*100 as DeathPercentage
FROM CovidDataProject..CovidDeaths
WHERE (continent IS null) AND (location != 'World')
GROUP BY location
ORDER BY HighestDeathCount desc

--Finding global daily number of new cases vs new deaths and total cases vs total deaths

SELECT date, SUM(new_cases) as NewCases, SUM(cast(new_deaths as int)) as NewDeaths, SUM(total_cases) as TotalCases, SUM(cast(total_deaths as int)) as TotalDeaths
FROM CovidDataProject..CovidDeaths
WHERE (continent IS null) AND (location != 'World')
GROUP BY date
ORDER BY date


--VACCINATION DATA EXPLORATION

--Joining tables and finding new vaccinations
SELECT death.location, death.date, vaccination.new_vaccinations
FROM CovidDataProject..CovidDeaths death
JOIN CovidDataProject..CovidVaccinations vaccination
ON death.location = vaccination.location AND death.date = vaccination.date
WHERE death.continent IS NOT null
ORDER BY location, date

--Comparing total population against a rolling total of vaccinations by date
SELECT death.location, death.date, death.population, vaccination.new_vaccinations, 
SUM(cast(vaccination.new_vaccinations as int)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as VaccinationCount
FROM CovidDataProject..CovidDeaths death
JOIN CovidDataProject..CovidVaccinations vaccination
ON death.location = vaccination.location AND death.date = vaccination.date
WHERE death.continent IS NOT null
ORDER BY location, date

-- Finding percentage of population vaccinated using VaccinationCount in a CTE

WITH VaccPop (location, date, population, new_vaccinations, VaccinationCount) AS
(
SELECT death.location, death.date, death.population, vaccination.new_vaccinations, 
SUM(cast(vaccination.new_vaccinations as int)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as VaccinationCount
FROM CovidDataProject..CovidDeaths death
JOIN CovidDataProject..CovidVaccinations vaccination
ON death.location = vaccination.location AND death.date = vaccination.date
WHERE death.continent IS NOT null
) 
SELECT *, (VaccinationCount/population) * 100 as PercentageVaccinated
FROM VaccPop

-- Creating view for vaccination count increase
CREATE VIEW PopulationVaccinationCount AS
SELECT death.location, death.date, death.population, vaccination.new_vaccinations, 
SUM(cast(vaccination.new_vaccinations as int)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as VaccinationCount
FROM CovidDataProject..CovidDeaths death
JOIN CovidDataProject..CovidVaccinations vaccination
ON death.location = vaccination.location AND death.date = vaccination.date
WHERE death.continent IS NOT null
