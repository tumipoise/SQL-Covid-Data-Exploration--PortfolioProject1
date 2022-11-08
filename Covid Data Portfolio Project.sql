-- COVID DEATH DATA

-- display all the rows and columns in the Covid death's table

SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2

-- select the variables that we are going to use from the covid death table

SELECT continent, location, date, population, total_cases, 
new_cases, total_deaths
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1, 2

-- check the percentage of people who died that had covid per location

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as percentage_of_Covid_death
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2

-- check the percentage of people who died that had covid in Africa
 --this shows the likelihood of dying if you contract covid in your country.

SELECT continent, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as percentage_of_Covid_death
FROM PortfolioProject..CovidDeaths
WHERE continent LIKE '%Africa%'
AND continent is not null
ORDER BY percentage_of_Covid_death DESC

-- what is the total no of deaths in Africa and Europe?

SELECT continent, MAX(cast(total_deaths as int)) as total_death
FROM PortfolioProject..CovidDeaths
WHERE continent LIKE 'Africa%'
OR continent LIKE 'Europe%'
GROUP BY continent

-- what percentage of population has got covid in Nigeria?

SELECT location, date, total_cases, population, (total_cases/population)*100 as percent_of_population_infected
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%Nigeria%'
ORDER BY percent_of_population_infected DESC;

-- looking at countries with highest infection rate compared to population 

SELECT location, population, MAX(total_cases) as highest_infection_count, MAX(total_cases/population)*100 as percent_population_infected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY percent_population_infected DESC

-- looking at countries with the highest death count

SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY total_death_count DESC

-- looking at the highest number of ICU patients and the total cases

SELECT location, MAX(cast(total_cases as int)) as max_total_cases, MAX(cast(icu_patients as int)) as max_ICU_patients
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY max_ICU_patients DESC

-- looking at continents with the highest death count 

SELECT continent, MAX(cast(total_deaths as int)) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY total_death_count DESC

--- GLOBAL NUMBERS

-- What is the sum of the new cases and new deaths in each day?

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_death, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1, 2

-- What is the sum of the new cases and new deaths in general?

SELECT SUM(new_cases) as total_new_cases, SUM(cast(new_deaths as int)) as total_new_death, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as new_death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1, 2

-- COVID VACCINATIONS DATA

-- display all the rows and columns in the Covid vaccination table

SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 1, 2

-- Join both Covid tables with date and location being the common variables

-- display all the rows and columns in the combined table

SELECT *
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.date = vac.date
	AND dea.location = vac.location

-- what is the number of people that have been vaccinated in the world

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.date = vac.date
	AND dea.location = vac.location
WHERE dea.continent is not null
ORDER BY 1, 2, 3

-- what is the total number of vaccinated people in the world against the population

SELECT SUM(cast(dea.population as bigint)) as total_population, SUM(cast(vac.new_vaccinations as bigint)) as total_vaccination, SUM(cast(vac.people_vaccinated as bigint)) as total_vaccinated_people
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.date = vac.date
	AND dea.location = vac.location
WHERE dea.continent is not null

-- what is the total no of people vaccinated in Africa and Europe

SELECT dea.continent, SUM(cast(vac.people_vaccinated as bigint)) as total_vaccinated_people
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.date = vac.date
	AND dea.location = vac.location
WHERE dea.continent LIKE 'Africa%'
OR dea.continent LIKE 'Europe%'
GROUP BY dea.continent

-- Using partition by, and windows function, do a rolling count of the new vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (partition by dea.location Order by dea.location, dea.date) as rolling_count_new_vaccination
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.date = vac.date
	AND dea.location = vac.location
WHERE dea.continent is not null
ORDER BY 1, 2

-- how many people in each country are vaccinatinated using the hightest rolling no?

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (partition by dea.location Order by dea.location, dea.date) as rolling_count_new_vaccination
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.date = vac.date
	AND dea.location = vac.location
WHERE dea.continent is not null
ORDER BY 1, 2

-- look at the total population vs the vaccinations using the max rolling count of each location
	-- since we can't use a newly created column (rolling_count_new_vaccination) to divide the population, it will give an error we then use;
		-- a CTE(Common Table Expression)  or  TEMP table(Temporary Table) 

-- CTE

WITH PopvsVac (Continent, Location, Date, Population, New_vacinations, Rolling_count_new_vaccination)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (partition by dea.location Order by dea.location, dea.date) as rolling_count_new_vaccination
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.date = vac.date
	AND dea.location = vac.location
WHERE dea.continent is not null
)
SELECT *, (Rolling_count_new_vaccination/Population)*100 as Percent_rolling_vaccninated_population
FROM PopvsVac

-- TEMP TABLE

DROP TABLE IF exists #PercentPopulationVaccinated --add this incase you want to make alterations to the temp table and run multiple times
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_count_new_vaccination numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (partition by dea.location Order by dea.location, dea.date) as rolling_count_new_vaccination
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.date = vac.date
	AND dea.location = vac.location
WHERE dea.continent is not null

SELECT *, (Rolling_count_new_vaccination/Population)*100 as Percent_rolling_vaccninated_population
FROM #PercentPopulationVaccinated


-- CREATE VIEWS

-- What is the sum of the new cases and new deaths in general?

SELECT SUM(new_cases) as total_new_cases, SUM(cast(new_deaths as int)) as total_new_death, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as new_death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1, 2

-- What is the total new deaths in each continent?

SELECT continent, SUM(cast(new_deaths as int)) as total_death
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY total_death DESC

-- creating views to store data for later visulaizations

CREATE VIEW PopulationVaccinatedPercent 
AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (partition by dea.location Order by dea.location, dea.date) as rolling_count_new_vaccination
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.date = vac.date
	AND dea.location = vac.location
WHERE dea.continent is not null

CREATE VIEW ContinentTotalDeath AS
SELECT continent, SUM(cast(new_deaths as int)) as total_death
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent

CREATE VIEW VaccinatedPopulation AS
SELECT dea.continent, SUM(cast(vac.people_vaccinated as bigint)) as total_vaccinated_people
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.date = vac.date
	AND dea.location = vac.location
WHERE dea.continent LIKE 'Africa%'
OR dea.continent LIKE 'Europe%'
GROUP BY dea.continent

-- select all from the views created
SELECT * FROM PopulationVaccinatedPercent
SELECT * FROM ContinentTotalDeath
SELECT * FROM VaccinatedPopulation

