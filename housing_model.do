* =====================================================================
* House Price Prediction & Agent Recommendation - Junction housing data
* Business Statistics major project, Adelaide University, Semester 2 2026
* Stata do-file: data summary, model building, headline model, prediction
* and diagnostics
* =====================================================================

clear all
set more off

* Dataset provided by Adelaide University for coursework (not included in this repository)
import excel "Major Project - Data Set.xlsx", sheet("Sheet1") firstrow clear

* ---------------------------------------------------------------------
* Task 1 - Data summary
* ---------------------------------------------------------------------
summarize PRICE SIZE AGE STORIES SHOPS CRIME TOWN SOLD, detail
tabulate SHOPS                       // 0/1 variable contains 2s and 3s
tabulate SOLD

histogram PRICE, frequency title("Sale price")
scatter PRICE OBS, mlabel(OBS)
scatter PRICE SIZE

sktest PRICE                         // normality of sale price
qnorm PRICE

foreach g in SUBURB OCEAN AGENT POOL TENNIS {
    ttest PRICE, by(`g') unequal
    median PRICE, by(`g')
}

graph hbox PRICE, over(SUBURB)
graph hbox PRICE, over(OCEAN)

* ---------------------------------------------------------------------
* Task 2 - Data preparation
* ---------------------------------------------------------------------
* OBS 362: $30,000 for a 157 m2, 4-year-old house (likely entry error)
* OBS 400: $3.1m, 356 m2, only 4-storey house (unlike Jenny's house)
drop if OBS == 362 | OBS == 400

* SUBURB, CRIME and TOWN are perfectly collinear: use SUBURB only
correlate PRICE SIZE AGE SUBURB CRIME TOWN OCEAN POOL TENNIS AGENT

* ---------------------------------------------------------------------
* Model building
* ---------------------------------------------------------------------
* Model 1: all variables
regress PRICE AGE SHOPS CRIME TOWN STORIES OCEAN POOL AGENT SIZE SUBURB TENNIS SOLD

* Model 2: drop insignificant variables, SUBURB in place of TOWN
regress PRICE OCEAN POOL AGENT SIZE SUBURB TENNIS

* Model 3: interaction terms, tested one at a time
gen SIZESUBURB   = SIZE*SUBURB
gen TENNISSUBURB = TENNIS*SUBURB
gen AGENTSUBURB  = AGENT*SUBURB
gen TENNISOCEAN  = TENNIS*OCEAN

regress PRICE OCEAN POOL AGENT SIZE SUBURB TENNIS SIZESUBURB
regress PRICE OCEAN POOL AGENT SIZE SUBURB TENNIS TENNISSUBURB
regress PRICE OCEAN POOL AGENT SIZE SUBURB TENNIS AGENTSUBURB
regress PRICE OCEAN POOL AGENT SIZE SUBURB TENNIS TENNISOCEAN

* Model 4: both kept interactions (AGENT becomes insignificant)
regress PRICE OCEAN POOL AGENT SIZE SUBURB TENNIS AGENTSUBURB TENNISOCEAN

* Model 5: re-test dropped variables one at a time
foreach v in AGE SHOPS STORIES SOLD {
    regress PRICE POOL SIZE SUBURB TENNIS OCEAN AGENTSUBURB TENNISOCEAN `v'
}

* ---------------------------------------------------------------------
* Headline Regression Model (R2 = 0.8988, n = 533)
* ---------------------------------------------------------------------
regress PRICE AGE POOL SIZE SUBURB TENNIS OCEAN AGENTSUBURB TENNISOCEAN

predict RESID, residuals
scatter RESID OBS, mlabel(OBS) yline(0)

* Jenny's house: 9 years, no pool, 153 m2, Claygate, tennis court, ocean view
* W&M (AGENTSUBURB = 0)
display "W&M point prediction: " _b[_cons] + _b[AGE]*9 + _b[SIZE]*153 + ///
    _b[SUBURB] + _b[TENNIS] + _b[OCEAN] + _b[TENNISOCEAN]
* A&B (AGENTSUBURB = 1)
display "A&B point prediction: " _b[_cons] + _b[AGE]*9 + _b[SIZE]*153 + ///
    _b[SUBURB] + _b[TENNIS] + _b[OCEAN] + _b[TENNISOCEAN] + _b[AGENTSUBURB]
* Approximate 95% interval: point prediction +/- 2 x Root MSE
display "2 x Root MSE: " 2*e(rmse)

* Marginal effect of size and its 95% CI
lincom SIZE

* ---------------------------------------------------------------------
* Task 3 - Diagnostics
* ---------------------------------------------------------------------
sktest RESID                         // residual normality
estat vif                            // multicollinearity
estat hettest, rhs                   // heteroskedasticity (Breusch-Pagan)
scatter RESID SIZE, yline(0)
estat ovtest                         // functional form (Ramsey RESET)
