--SELECT * from CovidDeaths;
--SELECT * from CovidVaccinations; 


--SELECT DATA that we are going to use
SELECT location, date, total_cases, new_cases,total_deaths, population 
FROM CovidDeaths
ORDER BY location, date;

--Looking at Total Cases vs Total Deaths
	--Shows likelihood of dying if you contract covid in your country:

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage 
FROM CovidDeaths
WHERE location like '%india%'
ORDER BY location, date;


--Looking at the Total Cases vs Population:
	--Shows what percentage of population got covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS infected
FROM CovidDeaths
WHERE location like '%afghan%'
ORDER BY location

-- Looking at the Countries at the hihgest infection rate compared to population
SELECT 
	location, population,
	MAX(total_cases) as HighestInfectionCount, 
	MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC
/* 
--SELECT location, population , count(location) from CovidDeaths 
--GROUP BY location, population
--ORDER BY location
*/

-- Showing countries with highest death count per population
SELECT 
	continent, location, population,
	MAX(cast(total_deaths as int)) AS MaxTotalDeathCount from CovidDeaths
WHERE continent IS NOT NULL
GROUP By location, population, continent
ORDER By MaxTotalDeathCount DESC

-- Let's break this down only by continent
SELECT 
	location,
	MAX(cast(total_deaths as int)) AS MaxTotalDeathCount from CovidDeaths
WHERE continent IS NULL
GROUP By location
ORDER By MaxTotalDeathCount DESC

-- Global Numbers

SELECT 
	date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths,
	SUM(cast(new_deaths as int))/SUM(new_cases) *100 AS DeathPercentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

SELECT 
	SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths,
	SUM(cast(new_deaths as int))/SUM(new_cases) *100 AS DeathPercentage
FROM CovidDeaths
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2

-- Looking at Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT  
	CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population,
	CovidVaccinations.new_vaccinations,
	SUM(CONVERT(INT,CovidVaccinations.new_vaccinations)) 
	OVER(Partition by CovidDeaths.location ORDER BY CovidDeaths.date) AS RollingPeopleVaccinated
	--(RollingPeopleVaccinated/population)*100
FROM CovidDeaths
INNER JOIN CovidVaccinations
	ON CovidDeaths.location = CovidVaccinations.location
	AND CovidDeaths.date = CovidVaccinations.date
WHERE CovidDeaths.continent IS NOT NULL
ORDER BY 2,3

 -- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac(
	Continent, Location, Date, Population, New_vaccinations,RollingPeopleVaccinated) 
AS  
(SELECT  
	CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population,
	CovidVaccinations.new_vaccinations,
	SUM(CONVERT(INT,CovidVaccinations.new_vaccinations)) 
	OVER(Partition by CovidDeaths.location ORDER BY CovidDeaths.date) AS RollingPeopleVaccinated
FROM CovidDeaths
INNER JOIN CovidVaccinations
	ON CovidDeaths.location = CovidVaccinations.location
	AND CovidDeaths.date = CovidVaccinations.date
WHERE CovidDeaths.continent IS NOT NULL) 

Select *, (RollingPeopleVaccinated/Population)*100
from PopvsVac


--Temp Table 

Drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,	
	RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT  
	CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population,
	CovidVaccinations.new_vaccinations,
	SUM(CONVERT(INT,CovidVaccinations.new_vaccinations)) 
	OVER(Partition by CovidDeaths.location ORDER BY CovidDeaths.date) AS RollingPeopleVaccinated
FROM CovidDeaths
INNER JOIN CovidVaccinations
	ON CovidDeaths.location = CovidVaccinations.location
	AND CovidDeaths.date = CovidVaccinations.date

Select *, (RollingPeopleVaccinated/Population)*100
from #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
SELECT  
	CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population,
	CovidVaccinations.new_vaccinations,
	SUM(CONVERT(INT,CovidVaccinations.new_vaccinations)) 
	OVER(Partition by CovidDeaths.location ORDER BY CovidDeaths.date) AS RollingPeopleVaccinated
FROM CovidDeaths
INNER JOIN CovidVaccinations
	ON CovidDeaths.location = CovidVaccinations.location
	AND CovidDeaths.date = CovidVaccinations.date
Where CovidDeaths.continent is not null 

Select * From PercentPopulationVaccinated
	
