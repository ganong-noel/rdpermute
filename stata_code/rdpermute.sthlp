{smcl}
{* *! version 1.1.1 08nov2016}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "rdpermute##syntax"}{...}
{viewerjumpto "Description" "rdpermute##description"}{...}
{viewerjumpto "Options" "rdpermute##options"}{...}
{viewerjumpto "Examples" "rdpermute##examples"}{...}
{viewerjumpto "Stored Results" "rdpermute##stored_results"}{...}
{viewerjumpto "Remarks" "rdpermute##remarks"}{...}
{viewerjumpto "Dependencies" "rdpermute##dependencies"}{...}
{viewerjumpto "References" "rdpermute##references"}{...}
{viewerjumpto "Additional References" "rdpermute##also_see"}{...}
{viewerjumpto "Authors" "rdpermute##authors"}{...}
{viewerjumpto "Acknowledgments" "rdpermute##acknowledgments"}{...}

{title:Title}

{hline}
{phang}{bf:rdpermute} {hline 2} Permutation Test for RD and RK designs {p_end}
{hline}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:rdpermute depvar runvar}
[{it:if}],
placebo_disconts({it:numlist})
true_discont({it:string})
[position_true_discont({it:#}) deriv_discont({it:#}) bw({it:#})) linear quad cubic skip_install filename({it:#}) save_path({it:#}) dgp({it:#}) bw_manual({it:#}) fg_bandwidth_scaling({it:# #}) fg_bias_porder({it:#}) fg_f_0({it:#}) fg_density_porder({it:#}) fg_num_bins({it:#}) cct_bw_par({it:#}) cct_reg_par({it:#}) silent ]


{marker description}{...}
{title:Description}

{pstd}{cmd:rdpermute} implements permutation tests for regression discontinuity (RD) or regression kink (RK) designs developed in {browse "https://www.tandfonline.com/doi/full/10.1080/01621459.2017.1328356":Ganong and Jäger (2018)}. The code calculates RD or RK estimates at a list of pre-specified placebo discontinuities or kinks and computes both asymptotic and randomization-based p-values. It tests for the sharp null hypothesis of no effect of the policy on the outcome and can accommodate several bandwidth choice, estimation, and inference procedures including {cmd:rdrobust} developed by Calonico, Cattaneo and Titiunik (2014a,b).


{marker options}{...}
{title:Options}
{dlgtab:Required}

{phang}
{opt placebo_disconts} defines the locations of placebo kinks. See Section 3.3 of Ganong and Jäger (2018) for a discussion on how to select {opt placebo_disconts}.

{phang}
{opt true_discont} defines the integer at which the true kink or discontinuity is located. This value has to appear in the set  {cmd:placebo_disconts}. If {cmd:placebo_disconts} is not generated manually, but automatically (for example by loops), it may happen that the binary representations of {cmd:true_discont} differs from its corresponding value in {cmd:placebo_disconts}. In this case it is possible to use the parameter {cmd:position_true_discont} instead. Unless rdpermute prints an error message, this modification is not necessary.


{dlgtab:Optional}

{phang}
{opt position_true_discont(integer -1)} Position of the expected discontinuity {cmd:true_discont} in the vector {cmd:placebo_disconts}. This parameter replaces {cmd:true_discont} in the case of binary representation errors.

{phang}
{opt deriv_discont(integer 1)} specifies whether a regression discontinuity (0) or a regression kink (1) design is implemented. Default is the implementation of a regression kink design.

{phang}
{opt bw(string)} defines the bandwidth choice method.  {opt "fg_aic"} is used as default if no alternative is specified. The possible bandwidth choices are:
{break}{tab}{tab}{opt "- cct"}: uses the procedures and functions in the {cmd:rdbwselect} package developed in Calonico, Cattaneo and Titiunik (2014a,b) as a subroutine. The parameters of {cmd:rdbwselect} can be altered with the parameter {cmd:cct_bw_par}.
{break}{tab}{tab}{opt "- fg"}: Bandwidth choice as proposed by Fan and Gijbels (1996). Additional parameters ({cmd:fg_bias_p_order}, {cmd:fg_density_p_order}, {cmd:fg_num_bins}, {cmd:fg_f0}, and {cmd:fg_bandwidth_scaling}) can be used to alter the calculations.
{break}{tab}{tab}{opt "- fg_aic"}: Fan and Gijbels (1996) bandwidth choice with automatic selection of {cmd:fg_bias_p_order}. Additional parameters ({cmd:fg_density_p_order}, {cmd:fg_num_bins}, {cmd:fg_f0}, and {cmd:fg_bandwidth_scaling}) can be used to alter the the calculations.
{break}{tab}{tab}{opt "- manual"}: Manual choice of a constant bandwidth. The bandwidth can be set with the parameter {cmd:manual_bw}.

{phang}
{opt linear/quad/cubic} specifies that a linear, quadratic, or cubic model be used. {cmd:rdpermute} will calculate the p-values for each specified model. If neither linear, quad nor cubic are specified, {cmd:rdpermute} will calculate the p-values for all of them automatically.

{phang}
{opt skip_install} skips the installation of required packages. {cmd:rdpermute} will try to install all dependent packages automatically using stable, predefined versions. This may not always be possible or desired. {cmd:skip_install} suppresses the installation. Attention: Some subroutines and parts of our code may not work if the dependent packages are not installed.

{phang}
{opt filename(string)} Name for final .dta output. Only if {cmd:filename} is provided, will the data be saved.

{phang}
{opt save_path(string)} Path for final .dta output. If no {cmd:save_path} is provided, the results will automatically be placed in the working directory.

{phang}
{opt dgp(string)} adds a column with an index variable to .dta output

{phang}
{opt bw_manual(real 1)}  is a numerical value for the method choice {cmd:bw(manual)}. The value will be used as bandwidth for the computation of the p-values for all placebo_disconts.

{phang}
{opt fg_bandwidth_scaling(numlist)} specifies the model-dependent constants for the rule-of-thumb bandwidth calculation formula by Fan and Gijbels (1996). It may be necessary to use other values than our presets for linear, quadratic, and cubic regressions. {cmd:fg_bandwidth_scaling[1]} describes the prefactor, {cmd:fg_bandwidth_scaling[2]} the used exponents. The parameter {cmd:fg_bandwidth_scaling} has to contain values for both entries. All other entries in {cmd:fg_bandwidth_scaling} are omitted. A detailed description of the formula can be found in Fan and Gijbels (1996).

{phang}
{opt fg_bias_porder(integer 4)} specifies the maximal order of the polynomial used to estimate m^2 m^3 and m^4 for bandwidth choice {cmd:bw(fg)}. This parameter is only necessary if the chosen method is {cmd:fg} and not  {cmd:bw(fg_aic)}. Warning: A high {cmd:fg_bias_p_order} may result in the instability of the used regressions, without indication by STATA. The choice bw="fg_aic" will automatically prevent such errors and is therefore set as default.

{phang}
{opt fg_f_0(real 0)} specifies the placement of bins for the choice bw(fg). If not set with {cmd:fg_num_bins}, 50 equally spaced bins on the range of the running variable will be used. We recommend to leave this parameter empty for an automatic estimation of {cmd:fg_f_0}. If you wish to use a manual value, you can define a numerical value in {cmd:fg_f_0}.


{phang}
{opt fg_density_porder(integer 3)} specifies the polynomial order for density estimation meaning that it chooses the maximal exponent of x^p for the estimation of {cmd:bw(fg)} by regression. Warning: A high {cmd:fg_density_p_order} may lead to the same problems as in {cmd:fg_bias_p_order}. We recommend to use the preset value.

{phang}
{opt fg_num_bins(integer 50)} specifies the number of equally spaced bins for the choice {cmd:bw(fg)} and {cmd:fg_f_0(0)} that is used to estimate {cmd:fg_f_0}.

{phang}
{opt cct_bw_par(string)} specifies additional or alternative parameters for the subroutine {cmd:rdbwselect} for the choice {cmd:bw(cct)}. All parameters of {cmd:rdbwselect} can be altered except for: y, x, p, q, deriv. To alter an option, define the intended values within html-Tags within the string. Example: {cmd:cct_bw_par}("<kernel>epa</kernel><bwselect>cerrd</bwselect>").

{phang}
{opt cct_reg_par(string)} specifies additional or alternative parameters for the subroutine {cmd:rdrobust} for the choice {cmd:bw(cct)}. All parameters of rdrobust can be altered except for: y, x, p, q, deriv, h. Altering is done as in {cmd:cct_bw_par}.

{phang}
{opt silent} generates less output while running.



{hline}

{marker examples}{...}
{title:Examples}

{phang}
{cmd: rdpermute} {cmd:y} {cmd:x}, {cmd:placebo_disconts(-0.9(0.1)0.9)} {cmd:true_discont(0)} {cmd:linear} {cmd:quad} {cmd:silent} {cmd:bw(fg)} {cmd:save_path(~/Data/working/)} {cmd:filename(placebo_pvalues)} {cmd:dgp(1)} {cmd:fg_density_porder(1)}{p_end}

{phang}
{cmd: rdpermute} {cmd:y} {cmd:x}, {cmd:placebo_disconts(-100(10)200)} {cmd:true_discont(20)} {cmd:linear} {cmd:silent} {cmd:bw(manual)} {cmd:save_path(~/Data/working/)} {cmd:filename(placebo_pvalues)} {cmd:bw_manual(10)}{p_end}

{phang}
{cmd: rdpermute} {cmd:y} {cmd:x}, {cmd:placebo_disconts(1960(0.25)2017)} {cmd:true_discont(2000)} {cmd:linear} {cmd:quad} {cmd:bw(cct)}  {cmd:cct_bw_par(<bwselect>cerrd</bwselect>)}{p_end}


{marker stored_results}{...}
{title:Stored Results}

{phang}
{cmd:rdpermute} stores the following in {cmd:e()}: {p_end}

{p 8 8 2}{cmd:e}(kink_beta_linear){p_end}
{p 8 8 2}{cmd:e}(kink_se_linear){p_end}
{p 8 8 2}{cmd:e}(bw_linear){p_end}
{p 8 8 2}{cmd:e}(pval_linear){p_end}
{p 8 8 2}{cmd:e}(kink_beta_quadratic){p_end}
{p 8 8 2}{cmd:e}(kink_se_quadratic){p_end}
{p 8 8 2}{cmd:e}(bw_quadratic){p_end}
{p 8 8 2}{cmd:e}(pval_quadratic){p_end}
{p 8 8 2}{cmd:e}(kink_beta_cubic){p_end}
{p 8 8 2}{cmd:e}(kink_se_cubic){p_end}
{p 8 8 2}{cmd:e}(bw_cubic){p_end}
{p 8 8 2}{cmd:e}(pval_cubic){p_end}

{p 4 4 2}
With N as number of placebo kinks, matrices kink* and bw* are Nx1 with row i reflecting the parameter at the ith placebo kink.

{p 4 4 2}
Matrices pval* are 2 x 1. Row 1 is asymptotic p-value. Row 2 is randomization p-value.

{p 4 4 2}
Optional .dta output: collapses all of the above into a single file.


{marker references}{...}
{title:References}{...}

{pstd}

{phang} Calonico, S., Cattaneo, M. D., and Titiunik, R. "Robust data-driven inference in the regression-discontinuity design." {it:Stata Journal} 14.4: 909-946 (2014a). {p_end}

{phang} Calonico, S., Cattaneo, M. D., and Titiunik, R. "Robust Nonparametric Confidence Intervals for Regression-Discontinuity Designs." {it:Econometrica}, 82(6):2295-2326 (2014b). {p_end}

{phang} Fan, J. and Gijbels, I. {it:Local Polynomial Modelling and Its Applications,} volume 66. Chapman and Hall (1996). {p_end}

{phang} Ganong, P. and Jäger, S. "A Permutation Test for the Regression Kink Design." {it:Journal of the American Statistical Association} (2018). {p_end}

{phang} Nichols, A. "rd 2.0: Revised Stata module for regression discontinuity estimation." (2011). {p_end}


{marker also_see}{...}
{title:Online References and Dependent Code:}

{phang} {browse "https://sites.google.com/site/rdpackages/rdrobust/stata/rdbwselect.pdf":rdbwselect} - Bandwidth Selection Procedures for Local Polynomial Regression Discontinuity Estimators {p_end}

{phang} {browse "https://sites.google.com/site/rdpackages/rdrobust":rdrobust} - Local Polynomial Regression Discontinuity Estimation with Robust Bias-Corrected Confidence Intervals and Inference Procedures {p_end}

{phang} {browse "https://sites.google.com/site/rdpackages/rdrobust/stata/rdplot.pdf":rdplot} - Data-Driven Regression Discontinuity Plots {p_end}

{phang} {browse "http://fmwww.bc.edu/repec/bocode/r/rd.html":rd} - Regression discontinuity (RD) estimator  {p_end}

{phang} All dependent packages will automatically download at the first run of rdpermute. See {cmd: skip_install} for suppressing the installation.{p_end}

{marker authors}{...}
{title:Authors}{...}


{pstd} Peter Ganong, University of Chicago, {browse "mailto:ganong@uchicago.edu":ganong@uchicago.edu}. {p_end}

{phang}Simon Jäger, MIT,  {browse "sjaeger@mit.edu":sjaeger@mit.edu}. {p_end}

{marker acknowledgments}{...}
{title:Acknowledgments}{...}

{pstd}Dennis Kubitza and Michael Schöner provided excellent research assistance to develop the Stata package. {p_end}
