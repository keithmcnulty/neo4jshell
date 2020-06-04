## Test environments
* local R installation, R 4.0.0
* ubuntu 16.04 (on travis-ci), R 4.0.0
* win-builder (devel)

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Changes from previous submission

Addressed feedback from last submission on 2020-05-30:

1. Corrected unquoted software name in DESCRIPTION --> 'R'
2. Created executable examples for all functions.  (Some examples are wrapped in a check for the existence of the software.)
3. Ensured all logicals are written as TRUE, FALSE
4. Added SystemRequirements to the DESCRIPTION.
