-- Begin exploration 

SHOW COLUMNS FROM covid_deaths;
SHOW COLUMNS FROM covid_vacc;

SELECT * 
FROM covid_deaths;

SELECT * 
FROM covid_vacc;

-- Checking which continents we have in the dataset
SELECT DISTINCT continent
FROM covid_deaths;

-- Checking for population change over the dataset period
SELECT location, MAX(population) - MIN(population) AS difference
FROM covid_deaths
GROUP BY location;

-- Smoking comparison between men and women
SELECT continent, AVG(female_smokers), AVG(male_smokers) 
FROM covid_deaths
GROUP BY continent
ORDER BY AVG(male_smokers) DESC;

-- Total cases up to the end of the data set
SELECT location, MAX(total_cases) 
FROM covid_deaths
GROUP BY location;

-- Total case vs total deaths
-- Percentage chance once infected to die
SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases) * 100, 2) AS Daily_Death_Percentage
FROM covid_deaths;

-- Total cases vs population
SELECT location, date, total_cases, population, ROUND((total_cases/population) * 100, 2) AS Rolling_Infected_Percentage
FROM covid_deaths;

-- Highest rate of infection per country
SELECT location, MAX(total_cases/population) * 100 AS Max_Infected_Rate
FROM covid_deaths
GROUP BY location
ORDER BY Max_Infected_Rate DESC;

-- Highest percent of deaths to population by country, with total deaths shown
SELECT location, population, MAX(CAST(total_deaths AS UNSIGNED)) AS total_deaths, MAX(total_deaths/population)*100 AS Deaths_Percent
FROM covid_deaths
GROUP BY location, population
ORDER BY Deaths_Percent DESC;

-- By continent
SELECT TRIM(continent), MAX(CAST(total_deaths AS UNSIGNED)) AS total_deaths
FROM covid_deaths
GROUP BY continent
ORDER BY total_deaths DESC;

-- Global numbers as well as rolling death percentage and total deaths
SELECT 
	date,
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS UNSIGNED)) AS total_deaths,
    SUM(CAST(new_deaths AS UNSIGNED)) / SUM(new_cases) * 100  AS DeathPercentage
FROM covid_deaths
GROUP BY date;

-- Joining tables to analyse deaths and vaccine effects
-- New vaccs where there are no nulls
SELECT 
	dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_total_vaccinated,
    (rolling_total_vaccinated/population)
FROM covid_deaths dea
JOIN covid_vacc vac
	ON dea.location = vac.location
    AND dea.date = vac.date
    WHERE vac.new_vaccinations > 0; 
    
-- Using diabetes_prevalence to see how it impacted chances of catching and dying from covid

SELECT vac.location, vac.diabetes_prevalence, MAX(dea.total_deaths / dea.population) * 100 AS death_percentage
FROM covid_vacc vac
JOIN covid_deaths dea 
ON vac.date = dea.date AND vac.location = dea.location
GROUP BY vac.location, vac.diabetes_prevalence
ORDER BY death_percentage DESC
LIMIT 5;

-- Top 5 in order in terms of death_percentage from Covid : Bosnia, Colombia, Bolivia, Belize, and Costa Rica

SELECT vac.location, vac.diabetes_prevalence, MAX(dea.total_deaths / dea.population) * 100 AS death_percentage
FROM covid_vacc vac
JOIN covid_deaths dea 
ON vac.date = dea.date AND vac.location = dea.location
GROUP BY vac.location, vac.diabetes_prevalence
ORDER BY diabetes_prevalence DESC;

-- 4 of the top 5 from death_percentage appear in the top 10 highest diabetes_prevalence countries

-- Make this information into a view to use in Tableau later

CREATE VIEW DiabetesVsDeathPercentage 
AS 
SELECT vac.location, vac.diabetes_prevalence, MAX(dea.total_deaths / dea.population) * 100 AS death_percentage
FROM covid_vacc vac
JOIN covid_deaths dea 
ON vac.date = dea.date AND vac.location = dea.location
GROUP BY vac.location, vac.diabetes_prevalence
ORDER BY diabetes_prevalence DESC; 

-- USE CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_Total_Vaccinated)
AS
(
SELECT 
	dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_total_vaccinated    
FROM covid_deaths dea
JOIN covid_vacc vac
	ON dea.location = vac.location
    AND dea.date = vac.date
    WHERE vac.new_vaccinations > 0
    )
    SELECT *, (Rolling_Total_Vaccinated/Population)* 100 AS Rolling_Percentage
    FROM PopvsVac;
    
-- TEMP TABLE 
DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
Continent char(255),
Location char(255),
Date char(255), 
Population numeric, 
New_vaccinations numeric,
Rolling_Total_Vaccinated numeric
);

INSERT INTO PercentPopulationVaccinated
SELECT 
	dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_total_vaccinated    
FROM covid_deaths dea
JOIN covid_vacc vac
	ON dea.location = vac.location
    AND dea.date = vac.date
    WHERE vac.new_vaccinations > 0;
    
SELECT *
FROM PercentPopulationVaccinated;

-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinatedView
AS
SELECT 
	dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_total_vaccinated    
FROM covid_deaths dea
JOIN covid_vacc vac
	ON dea.location = vac.location
    AND dea.date = vac.date
    WHERE vac.new_vaccinations > 0;
