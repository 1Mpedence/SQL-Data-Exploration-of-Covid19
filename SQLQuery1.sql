select * from CovidProject..CovidDeaths
order by location, date;

select * from CovidProject..CovidVaccinations
order by location, date;

select location, date,	total_cases, new_cases, total_deaths, population
from CovidProject..CovidDeaths
order by location, date;

-- Total cases Vs Total deaths each day
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentageByCases
from CovidProject..CovidDeaths
where continent is not null
order by location, date;

-- Total cases Vs Population each day
select location, date, total_cases, population, (total_cases/population)*100 as CasesPercentageByPopulation
from CovidProject..CovidDeaths
where continent is not null
order by location, date;

--Countries with Total Deaths sorted high to low
select location, max(cast(total_deaths as int)) as "Total Deaths"
from CovidProject..CovidDeaths
where continent is not null
group by location
order by "Total Deaths" desc;

--Highest Infection rate countries had sorted high to low
select location, population, max(total_cases) as Infected, max(total_cases)/population as "Infection Rate"
from CovidProject..CovidDeaths
where continent is not null
group by location, population
order by "Infection Rate" desc;

--Countries with their Death Rates sorted high to low
select location, population, max(cast(total_deaths as int)) as "Total Deaths", max(cast(total_deaths as int))/population as "Death Rate"
from CovidProject..CovidDeaths
where continent is not null
group by location, population
order by "Death Rate" desc;



--Continents with Total Deaths sorted high to low -- 212576
select location, max(cast(total_deaths as int)) as "Total Deaths"
from CovidProject..CovidDeaths
where continent is null and location not in ('world', 'international')
group by location
order by "Total Deaths" desc;

--Highest Infection rate Continents had sorted high to low
select location, max(total_cases) as Infected, max(total_cases)/population as "Infection Rate"
from CovidProject..CovidDeaths
where continent is null and location not in ('world', 'European Union', 'international')
group by location, population
order by "Infection Rate" desc;

--Continents with their Death Rates sorted high to low
select location, population, max(cast(total_deaths as int)) as "Total Deaths", max(cast(total_deaths as int))/population as "Death Rate"
from CovidProject..CovidDeaths
where continent is null and location not in ('world', 'European Union', 'international')
group by location, population
order by "Death Rate" desc;

--Total Cases int the world by Date
select date, sum(total_cases) as "Total Cases"
from CovidProject..CovidDeaths
where continent is not null
group by date
order by date


--Total Cases and Deaths in the world by Date
select date, sum(convert(int, new_cases)) as "Total Cases", sum(convert(int, new_deaths)) as "Total Deaths"
from CovidProject..CovidDeaths
where continent is not null
group by date
order by date

--Total Cases and Deaths int the World Current
select sum(new_cases) as "Total Current Cases", sum(convert(int, new_deaths)) as "Total Deaths"
from CovidProject..CovidDeaths
where continent is not null;

--Total Pouplation Vs Vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from CovidProject..CovidDeaths dea
join CovidProject..CovidVaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
order by dea.continent, dea.location, dea.date;

--Rolling People Vaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3;


--Percent Population Vaccinated Using Temp Table

DROP Table if exists PercentPopulationVaccinated
Create Table PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population float,
New_vaccinations float,
RollingPeopleVaccinated float
)

Insert into PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, CONVERT(float, dea.population), CONVERT(float, vac.new_vaccinations)
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100 as "Percentage People Vaccinated"
From PercentPopulationVaccinated;


--Creating Views

--

--Rolling People Vaccinated

create view ViewPercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, CONVERT(float, dea.population) as Population, CONVERT(float, vac.new_vaccinations) as "New Vaccinations"
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null;

------------------------------------------------------------------------------
------------------------------------------------------------------------------

--Tableau Views Here!!

--1. Entire World
Select SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int)) as Total_Deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidProject..CovidDeaths
where continent is not null 
order by 1,2;

--2. Total Deaths Coutnry Wise
Select location as Country, SUM(cast(new_deaths as float)) as "Total Death Count"
From CovidProject..CovidDeaths
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by "Total Death Count" desc;

--3. Population Infected Country Wise
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidProject..CovidDeaths
Where continent is not null 
Group by Location, Population
order by PercentPopulationInfected desc;

--4. Population vaccinated Country Wise
select vac.location, dea.population, Max(convert(float, vac.people_vaccinated)) as PopulationVaccinated, (Max(convert(float, vac.people_vaccinated))/dea.population)*100  as TotalVaccinated
from CovidProject..CovidVaccinations vac
join CovidProject..CovidDeaths dea
on dea.location = vac.location and dea.date = vac.date
where vac.continent is not null
Group by vac.location, dea.population
order by TotalVaccinated desc
