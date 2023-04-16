-- use portfolio ;
-- show tables ;
-- select count(*) from portfolio.covid_vaccinations;
-- select * from portfolio.covid_deaths;
-- delete from portfolio.covid_vaccinations
-- SET SESSION sql_mode = ''

-- Total Cases vs Total Deaths
SELECT location, date ,total_cases, population, (total_cases/population)*100 AS death_percentage
from portfolio.covid_deaths
WHERE location = 'india'
order by  STR_TO_DATE(date, '%M %d, %Y') DESC
limit 1000;

-- which country has the highest infection rate 
SELECT location ,population,MAX(total_cases) AS highest_infect, population, MAX( (total_cases/population))*100 AS infected_percentage
from portfolio.covid_deaths
group by location,population
order by infected_percentage desc;

-- how many people dead, highest death count per population 
SELECT location, date ,total_deaths, population, (total_deaths/population)*100 AS death_percentage
from portfolio.covid_deaths
order by death_percentage DESC;

SELECT location, date ,total_deaths, population, (total_deaths/population)*100 AS death_percentage
from portfolio.covid_deaths
order by death_percentage ASC;


select continent,MAX(total_deaths) AS total_deathcount
from portfolio.covid_deaths
WHERE continent is not null
group by continent 
order by total_deathcount DESC;

-- GLOBAL NUMBERS
SELECT SUM(new_cases) AS total_cases , SUM(new_deaths) AS total_deaths, SUM(new_deaths)/ SUM(new_cases)* 100 AS death_percentage 
FROM portfolio.covid_deaths
WHERE continent is not null
order by 1,2 ;

-- error related(self reference)
SELECT * FROM portfolio.covid_deaths death
JOIN portfolio.covid_vaccinations vacci
ON death.location = vacci.location AND death.date = vacci.date
WHERE death.date='03-01-2020';
SELECT count(*) date 
FROM portfolio.covid_deaths;

-- total vaccinations vs population , how many people got vaccinated 
SELECT death.continent , death.location , death.date, death.population , vacci.new_vaccinations 
FROM portfolio.covid_deaths death
JOIN portfolio.covid_vaccinations vacci
ON death.location = vacci.location AND death.date = vacci.date
WHERE death.continent is not null 
ORDER BY 3,4;

-- Percentage of Population that has recieved at least one Covid Vaccine(india)
SELECT death.continent  ,death.location, death.date, death.population , vacci.new_vaccinations,
SUM(vacci.new_vaccinations) OVER (PARTITION BY death.continent ORDER BY death.continent ,death.date) AS people_vaccinated
,(people_vaccinated/population)*100 AS people_vaccinated_percentage
FROM portfolio.covid_deaths death
JOIN portfolio.covid_vaccinations vacci
ON death.location = vacci.location AND death.date = vacci.date
WHERE death.location ='india'
ORDER BY people_vaccinated_percentage, STR_TO_DATE(death.date, '%M %d, %Y') ASC;

-- Percentage of Population that has recieved at least one Covid Vaccine
SELECT death.continent  ,death.location, death.date, death.population , vacci.new_vaccinations,
SUM(vacci.new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location ,death.date) AS people_vaccinated
-- (people_vaccinated/population)*100 AS people_vaccinated_percentage
FROM portfolio.covid_deaths death
JOIN portfolio.covid_vaccinations vacci
ON death.location = vacci.location AND death.date = vacci.date
-- WHERE death.location ='india'
WHERE death.continent is not null
ORDER BY 2,3;
-- people_vaccinated_percentage, STR_TO_DATE(death.date, '%M %d, %Y') ASC


-- Using CTE to perform Calculation on Partition By in previous query
WITH popVSvac( continent,location,date,population, new_vaccinations, people_vaccinated) 
AS(
SELECT death.continent  ,death.location, death.date, death.population , vacci.new_vaccinations,
SUM(vacci.new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location ,death.date) AS people_vaccinated
-- (people_vaccinated/population)*100 AS people_vaccinated_percentage
FROM portfolio.covid_deaths death
JOIN portfolio.covid_vaccinations vacci
ON death.location = vacci.location AND death.date = vacci.date
-- WHERE death.location ='india'
WHERE death.continent is not null
)
SELECT * , (people_vaccinated/population)*100 
-- MAX((people_vaccinated/population)*100) AS MAX_percentage
from popvsvac;

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE if exists portfolio.percent_vaccinated_population;
USE portfolio;
Create TABLE percent_vaccinated_population
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric ,
new_vaccinations numeric ,
 people_vaccinated numeric 
 );
 INSERT INTO percent_vaccinated_population 
 SELECT death.continent  ,death.location, STR_TO_DATE(death.date, '%d-%m-%Y'), death.population , vacci.new_vaccinations,
SUM(vacci.new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS people_vaccinated
-- (people_vaccinated/population)*100 AS people_vaccinated_percentage
FROM portfolio.covid_deaths death
JOIN portfolio.covid_vaccinations vacci
ON death.location = vacci.location AND death.date = vacci.date;
-- WHERE death.location ='india'
-- WHERE death.continent is not null
SELECT * , (people_vaccinated/population)*100 AS vaccinated_population_percent
FROM  percent_vaccinated_population;
-- ORDER BY STR_TO_DATE(death.date, '%M %d, %Y');



-- creating data for later visulaization 
CREATE VIEW percent_population_vaccine AS
 SELECT death.continent  ,death.location, death.date, death.population , vacci.new_vaccinations,
SUM(vacci.new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location ,death.date) AS people_vaccinated
-- (people_vaccinated/population)*100 AS people_vaccinated_percentage
FROM portfolio.covid_deaths death
JOIN portfolio.covid_vaccinations vacci
ON death.location = vacci.location AND death.date = vacci.date
WHERE death.continent is not null;

SELECT *
FROM percent_population_vaccine
 
