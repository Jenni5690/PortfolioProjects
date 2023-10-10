/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/



Select * 
From PortfolioProject..[Covid Deaths]
Where continent is not NULL
order by 3,4

--Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..[Covid Deaths]
Where continent is not null 
order by 1,2


--Total Cases vs Total Deaths
--Shows likelihood of dying if you contract Covid in your country

Select location, date, total_deaths,total_cases, (CAST(total_deaths as float)/CAST(total_cases as float))*100 as DeathParcentage
From PortfolioProject..[Covid Deaths]
where location like '%states%'
order by 1,2


-- Total Cases vs Population 
--Shows what percentage of population infected with Covid

Select location, date, population,total_cases, 
(total_cases/population)*100 as PercentofPopulation
From PortfolioProject..[Covid Deaths]
--where location like '%states%'
order by 1,2

-- Countries with Highest Infection Rate Compared to Population

Select location,population, MAX(total_cases)as HighestInfectionCount, population, 
MAX((total_cases/population))*100 as PercentofPopulationInfected
From PortfolioProject..[Covid Deaths]
--where location like '%states%'
Group by location,population
order by PercentofPopulationInfected desc

-- Countries with Highest Death Count Per Population

Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..[Covid Deaths]
Where continent is not null
Group by location
order by TotalDeathCount desc

--BREAKING THINGS DOWN BY CONTINENT

--Showing the Continents with the Highest Death Counts

Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..[Covid Deaths]
Where continent is null and location <> 'high income' and location <>'Lower middle income' and location <> 'Low income'
Group by location
order by TotalDeathCount desc

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..[Covid Deaths]
Where continent is not null 
Group by continent
order by TotalDeathCount desc


-- Global Numbers

Select date, SUM(new_cases)as TotalCases,SUM(new_deaths) as TotalDeaths,
SUM(new_deaths)/ SUM(nullif(new_cases,0)) *100 as DeathPercentage
From PortfolioProject..[Covid Deaths]
Where continent is not null
Group by date
order by 1,2


--Looking at Total Population vs Vaccination 
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent,dea.location,dea.date, dea.population,vac.new_vaccinations
,SUM(convert(float, new_vaccinations)) OVER( Partition By dea.location order by dea.location, 
dea.date) as RollingPeopleVaccinated
From PortfolioProject..[Covid Deaths] dea
Join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
Where dea.continent is not null
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopVsVac (Continent, Location, Data, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent,dea.location,dea.date, dea.population,vac.new_vaccinations
,SUM(convert(float, new_vaccinations)) OVER( Partition By dea.location order by dea.location, 
dea.date) as RollingPeopleVaccinated
From PortfolioProject..[Covid Deaths] dea
Join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
Where dea.continent is not null
--order by 2,3
)
Select *,(RollingPeopleVaccinated/Population) * 100
From PopVsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

Drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
( 
Continent nvarchar(255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPopVaccinated numeric
)

Insert into #PercentPopulationVaccinated
select dea.continent,dea.location,dea.date, dea.population,vac.new_vaccinations
,SUM(convert(float, new_vaccinations)) OVER( Partition By dea.location order by dea.location, 
dea.date) as RollingPeopleVaccinated
From PortfolioProject..[Covid Deaths] dea
Join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
Where dea.continent is not null
order by 2,3

Select *,(RollingPopVaccinated/nullif(Population,0))
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..[Covid Deaths] dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

Select *
From PercentPopulationVaccinated