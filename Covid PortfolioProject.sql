/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Converting Data Types, Creating Views.

*/

Select *
From dbo.CovidDeathss 
order by 3,4;

Select *
From dbo.CovidVaccinationss 
order by 3,4;

-- Creating Staging Table

SELECT * INTO dbo.CovidDeathss_staging
FROM dbo.CovidDeathss
WHERE 1 = 0;

INSERT INTO dbo.CovidDeathss_staging
SELECT * FROM dbo.CovidDeathss;

SELECT * 
FROM dbo.CovidDeathss_staging;

SELECT * INTO dbo.CovidVaccinationss_staging
FROM dbo.CovidVaccinationss
WHERE 1 = 0;

INSERT INTO dbo.CovidVaccinationss_staging
SELECT * FROM dbo.CovidVaccinationss;

SELECT * 
FROM dbo.CovidVaccinationss_staging;

Select *
From dbo.CovidDeathss_staging
Where Continent = Location
order by 3,4;


-- Selecting Useful Data


Select Location, date, total_cases, new_cases, total_deaths, population
From dbo.CovidDeathss_staging
Where Continent <> Location
order by 1,2;


 --Total Cases vs Total Deaths
 --Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases, total_deaths, (CAST(total_deaths AS float) / CAST(total_cases AS float))*100 as DeathPercentage
From dbo.CovidDeathss_staging
--Where location like 'Nigeria'
Where Continent <> Location
order by 1,2;


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid 

Select Location, date, Population, total_cases,  (Cast(total_cases AS float) / CAST(population AS float))*100 as PercentPopulationInfected
From dbo.CovidDeathss_staging
--Where location like 'Nigeria'
Where Continent <> Location
order by 1,2

UPDATE dbo.CovidDeathss_staging
SET total_cases = NULL
WHERE total_cases = '';

UPDATE dbo.CovidDeathss_staging
SET population = NULL
WHERE population = '';


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(Cast(total_cases AS float)) as HighestInfectionCount,  Max((CAST(total_cases AS float)/CAST(population AS float)))*100 as PercentPopulationInfected
From dbo.CovidDeathss_staging
--Where location like '%Nigeria%'
Where Continent <> Location
Group by Location, Population
order by PercentPopulationInfected desc;


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From dbo.CovidDeathss_staging
--Where location like 'Nigeria'
Where Continent <> Location
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent
From dbo.CovidDeathss_staging
Where continent = ''; 

UPDATE dbo.CovidDeathss_staging
SET continent = NULL
WHERE continent = '';

Select continent
From dbo.CovidDeathss_staging
Where continent is Null;

UPDATE dbo.CovidDeathss_staging
SET continent = location
WHERE continent IS NULL;

Select Continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From dbo.CovidDeathss_staging
--Where location like 'Nigeria'
Group by continent
order by TotalDeathCount desc

Select Continent, date, total_cases, new_cases, total_deaths, population
From dbo.CovidDeathss_staging
order by 1,2;


--Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your Continent

Select Continent, Population, date, total_cases, total_deaths, (CAST(total_deaths AS float) / CAST(total_cases AS float))*100 as DeathPercentage
From dbo.CovidDeathss_staging
--Where Continent like 'Africa'
order by 1,2;


-- Continent with Highest Infection Rate compared to Population

Select Continent, MAX(Cast(total_cases AS float)) as HighestInfectionCount,  Max((CAST(total_cases AS float)/CAST(population AS float)))*100 as PercentPopulationInfected
From dbo.CovidDeathss_staging
--Where Continent like 'Africa'
Group by Continent
order by PercentPopulationInfected desc;


-- Continent with Highest Death Count per Population

Select Continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From dbo.CovidDeathss_staging
--Where location like 'Nigeria'
Group by Continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

UPDATE dbo.CovidDeathss_staging
SET new_deaths = NULL
WHERE new_deaths = '' ;

UPDATE dbo.CovidDeathss_staging
SET New_Cases = NULL
WHERE New_Cases = '' ;

--Select date, SUM(Cast(new_cases as bigint)) as total_cases, SUM(cast(new_deaths as bigint)) as total_deaths, SUM(cast(new_deaths as bigint)) / SUM(cast(New_Cases as bigint))*100 as DeathPercentage
--From dbo.CovidDeathss_staging
--Group By date
--order by 1,2

-- Formatting the Date Column for both CovidDeathss and CovidVaccinationss

SELECT 
    [date], 
    CONVERT(DATE, [date], 101) AS formatted_date
FROM dbo.CovidDeathss_staging;

SELECT [date]
FROM dbo.CovidDeathss_staging
WHERE TRY_CONVERT(DATE, [date], 101) IS NULL;

UPDATE dbo.CovidDeathss_staging
SET [date] = CONVERT(DATE, [date], 101);

SELECT 
    [date], 
    CONVERT(DATE, [date], 101) AS formatted_date
FROM dbo.CovidVaccinationss_staging;

UPDATE dbo.CovidVaccinationss_staging
SET [date] = CONVERT(DATE, [date], 101);

SELECT 
    date, SUM(CAST(new_cases AS BIGINT)) AS total_cases, SUM(CAST(new_deaths AS BIGINT)) AS total_deaths, 
    CASE 
        WHEN SUM(CAST(new_cases AS BIGINT)) = 0 THEN NULL  -- Avoid division by zero
        ELSE (SUM(CAST(new_deaths AS BIGINT)) * 100.0) / SUM(CAST(new_cases AS BIGINT))
    END AS DeathPercentage
FROM dbo.CovidDeathss_staging
GROUP BY date
ORDER BY 1, 2;





-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select *
From dbo.CovidVaccinationss_staging;

UPDATE dbo.CovidVaccinationss_staging
SET new_vaccinations = NULL
WHERE new_vaccinations = '' ;


Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From dbo.CovidDeathss_staging dea
Join dbo.CovidVaccinationss_staging vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.Continent <> dea.Location
order by 2,3;


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From dbo.CovidDeathss_staging dea
Join dbo.CovidVaccinationss_staging vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.Continent <> dea.Location 
--order by 2,3
)
Select *, (CAST(RollingPeopleVaccinated AS float)/ Cast(Population AS float))*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.CovidDeathss_staging dea
Join dbo.CovidVaccinationss_staging vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.Continent <> dea.Location 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.CovidDeathss_staging dea
Join dbo.CovidVaccinationss_staging vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 