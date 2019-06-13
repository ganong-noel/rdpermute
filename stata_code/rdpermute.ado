/*
————
Code for Paper "A Permutation Test for the Regression Kink Design"
Peter Ganong and Simon Jaeger
ganong@gmail.com, sjaeger@mit.edu
Please contact us with feature suggestions and questions!

 rdpermute (Version 1.0.2)
-------------------------------
 The function provides an implementation for the Regression Kink Permuation
 Test described in "A Permutation Test for the Regression Kink Design"
 Documentation: https://github.com/rdpermute/STATA

-------------------------------
 Authors:
 - Peter Ganong (ganong@uchicago.edu)
 - Simon Jaeger (sjaeger@mit.edu)

 Dependencies:
 - rd
 - rdrobust

-------------------------------
 References for Code:

 - Peter Ganong, Simon Jaeger (2017). A Permutation Test for
   the Regression Kink Design, Journal of the American Statistical Association
   http://dx.doi.org/10.1080/01621459.2017.1328356

 - Sebastian Calonico, Matias D. Cattaneo, Max H. Farrell
   and Rocio Titiunik (2017). rdrobust: Software for regression-discontinuity Designs
   STATA package version 0.97.
   http://www-personal.umich.edu/~cattaneo/papers/Calonico-Cattaneo-Farrell-Titiunik_2017_Stata.pdf
   https://sites.google.com/site/rdpackages/rdrobust/stata

 - Nichols, Austin. 2011.  rd 2.0: Revised Stata module for regression
   discontinuity estimation.
   http://ideas.repec.org/c/boc/bocode/s456888.html

Output
----------------
Default matrix output:
	e(kink_beta_linear)
	e(kink_se_linear)
	e(bw_linear)
	e(pval_linear)
	e(kink_beta_quad)
	e(kink_se_quad)
	e(bw_quad)
	e(pval_quad)

	With N as number of placebo kinks, matrices kink* and bw* are Nx1.

	Matrices pval* are 2 x 1. Row 1 is asymptotic pvalue. Row 2 is randomization pvalue.

    Optional .dta output: collapses all of the above into a single file.


Annotations
---------------
- To avoid the unindented manipulation of Variables in the Dataset,
 we use the prefix rdpermute_ for all Variables defined in following code.
*/

cap program drop rdpermute
program define rdpermute, eclass
  version 13.0
	syntax varlist [, ///
		placebo_disconts(numlist) ///
		true_discont(string) ///
		position_true_discont(integer -1) ///
		deriv_discont(integer 1) ///
		bw(string) ///
		linear ///
		quad ///
		cubic ///
		skip_install ///
		filename(string) ///
		save_path(string) ///
		dgp(string) ///
		bw_manual(real 1) ///
		fg_bandwidth_scaling(numlist) ///
		fg_bias_porder(integer 4) ///
		fg_f_0(real 0) ///
		fg_density_porder(integer 3) ///
		fg_num_bins(integer 50) ///
		cct_bw_par(string) ///
		cct_reg_par(string) ///
		silent ///
		]
	preserve
	*Format for console

	if ("`silent'" == "") {
		local noi = "noisily"
		`noi' di ""
		`noi' di "__________________________________________________"

		di "Operating in verbose mode. Add option <silent> to suppress intermediate output."
	}

	*************
	*** SET DEFAULT VALUES FOR STRINGS
	*********
	if("`bw'" == ""){
		local bw = "fg_aic"
	}
	if("`bw'" == "cct"){
	  local reg = "cct"
	}
	else {
	  local reg = "regress"
	}
	*****************
	***CHECK WE HAVE NEEDED ADOs, SET PARAMETERS AND MATRICES***
	*****************
	if("`placebo_disconts'" == ""){
		di as error "Error: The required parameter placebo_disconts is missing. Please specify a numlist of placebo points."
		exit
	}
	if(missing(real("`true_discont'"))){
		di as error "Error: The required parameter true_discont is missing. Please specify the location of the true discont as a single numeric point."
		exit
	}

	*review installed packages
	if("`skip_install'" != ""){
			local required_ados "rdrobust.ado rd.ado" //add the required ados here//
			foreach x of local required_ados {
				capture findfile `x'
				if _rc==601 {
				di "Trying to install `x'"
				net install rdrobust, from("https://sites.google.com/site/rdpackages/rdrobust/stata") replace
				net get rdrobust, replace
			}
		}
	}

	*review required inputs
	local true_discont_in_list = 0
	local counter = 1
	foreach kink of numlist `placebo_disconts'{
		if (`kink' == `true_discont'){
			local true_discont_in_list = 1
			scalar true_discont_index = `counter'
		}
		local ++counter
	}
	if (`true_discont_in_list' == 0 & `position_true_discont' >= 0){
		local true_discont_in_list = 1
		scalar true_discont_index = `position_true_discont'
	}
	if (`true_discont_in_list' == 0){
		di as error "Error: true_discont is `true_discont' which is not in the list of placebo discontinuities `placebo_disconts'. If this is Error occurs due to the binary representation you can use additionally the optional parameter position_true_discont."
		exit
	}

	*review optional inputs
	if (`deriv_discont' != 0 & `deriv_discont' != 1){
		di as error "Error: Must specify option deriv=0 for Regression Discontinuity or deriv=1 for Regression Kink."
		exit
	}
	else if (`deriv_discont' == 0){
		qui `noi' di "Evaluating placebo regression discontinuities"
	}
	else if (`deriv_discont' == 1){
		qui `noi' di "Evaluating placebo regression kinks"
	}
	if (!inlist("`bw'" ,"cct" ,"fg" ,"manual" ,"fg_aic")){
		di as error "Error: Bandwidth choice must be <cct>, <fg>, or <manual>."
		exit
	}
qui {
	if "`bw'" == "fg_aic" & `deriv_discont' == 1{
		`noi' di "Using AIC to choose polynomial order for bias estimate in FG bw choice"
	}
	else if "`bw'" == "fg" & `deriv_discont' == 1{
		`noi' di "Using polynomial order of `fg_bias_porder' for bias estimate in FG bw choice"
	}
	else if ("`bw'" == "fg" ||"`bw'" == "fg_aic") & `deriv_discont' == 0{
		`noi' di "Using Imbens and Kalyanaraman bandwidth selection."
	}
	if ("`linear'" == "" & "`quad'" == "" & "`cubic'" == "") {
		local linear = "linear"
		local quad = "quad"
		local cubic = "cubic"
	}
	if  ("`bw'" == "fg" || "`bw'" == "fg_aic") & `deriv_discont' == 0 & ("`quad'" != "" || "`cubic'" != "") {
		di as error "Our code currently does not allow FG bw selection for local quadradtic or cubic models within a regression discontinuity design."
		exit
	}
}

	tokenize "`varlist'"
	local y `1'
	local x `2'
	local var_linear = "rdpermute_kink_x_1 rdpermute_x_0 rdpermute_x_1"
	local var_quad = "rdpermute_kink_x_1 rdpermute_x_0 rdpermute_x_1 rdpermute_kink_x_2 rdpermute_x_2"
	local var_cubic = "rdpermute_kink_x_1 rdpermute_x_0 rdpermute_x_1 rdpermute_kink_x_2 rdpermute_x_2 rdpermute_kink_x_3 rdpermute_x_3"

	*Generate storage for output
	local kinks_n : list sizeof local(placebo_disconts)
	foreach p in `linear' `quad' `cubic' {
		mat bw_`p' = J(`kinks_n',1,.)
		mat kink_beta_`p' = J(`kinks_n',1,.)
		mat kink_se_`p' = J(`kinks_n',1,.)
		mat pval_`p' = J(2,1,.)
	}

qui {

	******************
	*EVALUATE PLACEBO KINKS
	******************
	set more off
	local percentage_last = 0
	local kink_counter = 1
	*Progress bar initialization
	`noi' di as text ""
	`noi' di as text "Progress:"
	`noi' di as text "|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....| "
	`noi' di as text "|" _continue


	foreach kink of numlist `placebo_disconts' {

		*Progress bar update
		local total_num: word count `placebo_disconts'
		local percentage = round(`kink_counter' / `total_num' * 100)
		if (`percentage' > `percentage_last' ){
			local times = `percentage' - `percentage_last'
			`noi' di as text _dup(`times') "*" _continue
			local percentage_last = `percentage'
		}

		*Calculation of values for each kink
		destring `x', replace
		destring `y', replace
		cap drop rdpermute_*
		gen rdpermute_y = `y'
		gen rdpermute_x_0 = 1
		gen rdpermute_x_1 = `x'-`kink'
		gen rdpermute_kink_x_1 = rdpermute_x_1 * (rdpermute_x_1 >= 0)
		gen rdpermute_kink_x_2 = rdpermute_x_1^2 * (rdpermute_x_1 >= 0)
		gen rdpermute_discont_x_1 = (rdpermute_x_1 >= 0)
		gen rdpermute_kink_x_3 = rdpermute_x_1^3 * (rdpermute_x_1 >= 0)
		gen rdpermute_x_2 = rdpermute_x_1^2
		gen rdpermute_x_3 = rdpermute_x_1^3


		******************
		*BANDWIDTH SELECTION FOR EACH KINK
		******************
		if ("`bw'" == "fg" | "`bw'" == "fg_aic" ) {
			*Fan and Gijbels -- used by Card, Lee, Pei and Weber
			if `deriv_discont' == 1 {
				if ("`bw'" == "fg_aic") {
					*Prepare Variables
					cap drop rdpermute_x_2
					cap drop rdpermute_x_3
					qui reg rdpermute_y rdpermute_kink_x_1 rdpermute_x_1 , noconst
					estat ic
					matrix define AIC = r(S)
					local aic_p_order = 1
					local aic_min = AIC[1,5]

					*Add successively one variable more to the model
					forvalues p = 2/20 {
						gen rdpermute_x_`p' = rdpermute_x_1^`p'
						matrix accum X_T_X = rdpermute_kink_x_1 rdpermute_x_* , noconst
						matrix symeig Vectors lambda = X_T_X
						*Calculate eigenvector for inversion control
						mata: st_matrix("minabslambda",min(abs(st_matrix("lambda"))))
						if minabslambda[1,1]<0.01 {
							*If inversion might get unstable turn models off,
							* that need at least the current p
							if (`p' == 4){
								local cubic_off="off"
							}
							if (`p' == 3){
								local quad_off="off"
							}
							continue, break
						}
						else{
							*Save only model with minimal AIC
							estat ic
							matrix define AIC = r(S)
							local AIC_can = AIC[1,5]
							if (`AIC_can' < `aic_min' ) {
								local aic_min = AIC[1,5]
								local aic_p_order = `p'
							}
						}
					}
					local fg_opt_p_order = max(`deriv_discont'+1, `aic_p_order')

					forvalues p = 2(1)20 {
						cap drop rdpermute_x_`p'
					}
					if ("`quad_off'"=="off" & "`quad'"=="quad"){
						`noi' di as error "Warning: Encountered numerical instabilities at a placebo discont. A possible reason is sparse data within the neighbourhood of a placebo discont. rdpermute will not compute the values for a quadratic model assumption, as the p-values might get random due to automatic omitting of variables by stata."
						local quad =""
					}
					if ("`cubic_off'"=="off" & "`cubic'"=="cubic"){
						`noi' di as error "Warning: Encountered numerical instabilities at a placebo discont. A possible reason is sparse data within the neighbourhood of a placebo discont. rdpermute will not compute the values for a cubic model assumption, as the p-values might get random due to automatic omitting of variables by stata."
						local cubic =""
					}
				}

				* Use manual fg_opt_p_order for fg
				else {
					local fg_opt_p_order = `fg_bias_porder'
				}

				* Generate all neccessary variables
				forvalues p = 2 / `fg_opt_p_order' {
					cap gen rdpermute_x_`p' = rdpermute_x_1^`p'
				}

				qui reg rdpermute_y rdpermute_x_* rdpermute_kink_x_1, noconst
				local sigma_hat_0 = e(rss) / e(df_r)
				local m_hat_2_0 = 2*(_b[rdpermute_x_2])

				if ( "`quad'" == "quad"){
					cap gen rdpermute_x_3 = rdpermute_x_1^3
					qui reg rdpermute_y rdpermute_x_* rdpermute_kink_x_1, noconst
					local m_hat_3_0 = 6*(_b[rdpermute_x_3])
				}
				if ( "`cubic'" == "cubic"){
					cap gen rdpermute_x_4 = rdpermute_x_1^4
					qui reg rdpermute_y rdpermute_x_* rdpermute_kink_x_1, noconst
					local m_hat_4_0 = 24*(_b[rdpermute_x_4])
				}
				cap drop rdpermute_bin_var rdpermute_rdpermute_f_* rdpermute_n_obs

				*Calculation of fg_f_0 if not specified*
				if (`fg_f_0' == 0) {
					sum rdpermute_x_1
					local min_x = r(min)
					local max_x = r(max)
					local step_size = (r(max)-r(min))/`fg_num_bins'
					gen rdpermute_bin_var = .
					forvalues mu = 1/`fg_num_bins' {
						replace rdpermute_bin_var = `mu' if rdpermute_x_1>=(`min_x'+(`mu'-1)*`step_size')&rdpermute_x_1<(`min_x'+(`mu')*`step_size')
					}

					bys rdpermute_bin_var: egen rdpermute_n_obs = count(rdpermute_x_1)
					gen rdpermute_f_discrete = rdpermute_n_obs/_N
					forvalues p = 0/`fg_density_porder' {
						gen rdpermute_f_x_`p' = rdpermute_x_1^`p'
					}
					qui reg rdpermute_f_discrete rdpermute_f_x_*, noconst
					local f_hat_0 = `fg_num_bins' * _b[rdpermute_f_x_0] / (`max_x'-`min_x')
				}
				else {
					local f_hat_0 = `fg_f_0'
				}


				local h_linear = 2.35 * ([`sigma_hat_0'/((`m_hat_2_0')^2*`f_hat_0')]^(1/5))*_N^(-1/5)

				if ( "`quad'" !=""){
					local h_quad = 3.93 * ([`sigma_hat_0'/((`m_hat_3_0')^2*`f_hat_0')]^(1/7))*_N^(-1/7)
				}
				if ( "`cubic'" != ""){
					local h_cubic = 3.93 * ([`sigma_hat_0'/((`m_hat_4_0')^2*`f_hat_0')]^(1/9))*_N^(-1/9)
				}

				if ("`fg_bandwidth_scaling'"!=""){
					local number1 : word 1 of `fg_bandwidth_scaling'
					local number2 : word 2 of `fg_bandwidth_scaling'

					local h_linear = `number1' * ([`sigma_hat_0' / ((`m_hat_2_0')^2 * `f_hat_0')]^`number2') * _N^`number2'
					if ( "`quad'" !=""){
						local h_quad = `number1' * ([`sigma_hat_0' / ((`m_hat_3_0')^2 * `f_hat_0')]^`number2') * _N^`number2'
					}
					if ( "`cubic'" !=""){
						local h_cubic = `number1' * ([`sigma_hat_0' / ((`m_hat_4_0')^2 * `f_hat_0')]^`number2') * _N^`number2'
					}
				}
			}
			*Imbens and Kalyanaraman -- based on Fan and Gijbels
			if `deriv_discont' == 0 {
				if ("`linear'"~="") {
					qui rd rdpermute_y rdpermute_x_1, kernel(triangle)
					local h_linear = e(w)
				}
			}
		}

		if ("`bw'" == "manual") {
			local h_linear = `bw_manual'
			local h_quad = `bw_manual'
			local h_cubic = `bw_manual'
		}

		******************
		*RUN REGRESSIONS
		******************

		if (`deriv_discont' == 0) {
			local rdvar = "rdpermute_discont_x_1"
			local estimand = "rdpermute_discont_x_1"
		}
		else if (`deriv_discont' == 1) {
			local estimand = "rdpermute_kink_x_1"
		}

		if ("`reg'" == "regress" ) {
			foreach p in `linear' `quad' `cubic' {
					qui reg rdpermute_y `var_`p'' `rdvar' if abs(rdpermute_x_1)< `h_`p'', robust noconstant
					mat bw_`p'[`kink_counter',1] = `h_`p''
					mat kink_beta_`p'[`kink_counter',1] = _b[`estimand']
					mat kink_se_`p'[`kink_counter',1] = _se[`estimand']
			}
		}
		else if ("`reg'" == "cct") {
			foreach p in `linear' `quad' `cubic'{
				if ("`p'" == "linear") {
					local p_n = 1
					local q_n = 2
				}
				else if ("`p'" == "quad") {
					local p_n = 2
					local q_n = 3
				}
				else if ("`p'" == "cubic") {
					local p_n = 3
					local q_n = 4
				}
				local reg_kernel = "triangular"
				local reg_bwselect = "mserd"
				local reg_vce = "nn 3"
				*set alternative parameters for rdrobust
				if ("`cct_reg_par'" !=  ""){
					foreach par1name in "reg_c" "reg_fuzzy" "reg_covs" "reg_kernel" "reg_weights" "reg_bwselect" "reg_vce" "reg_b" {
						local from = strpos("`cct_reg_par'", "<"+"`par1name'"+">") + strlen("`par1name'") +2
						local to = strpos("`cct_reg_par'", "</"+"`par1name'"+">") - `from'
						if(`to' != 0){
							local `par1name' = substr("`cct_reg_par'", `from' , `to')
						}
					}
				}
				rdrobust rdpermute_y rdpermute_x_1,  p(`p_n') q(`q_n') deriv(`deriv_discont') kernel("`reg_kernel'")  bwselect("`reg_bwselect'") b("`reg_b'") vce("`reg_vce'") fuzzy("`reg_fuzzy'") covs("`reg_covs'") weights("`reg_weights'")
				mat bw_`p'[`kink_counter',1] = e(h_l)
				mat kink_beta_`p'[`kink_counter',1] =  e(tau_bc)
				mat kink_se_`p'[`kink_counter',1] = e(se_tau_rb)
			}
		}

		local ++kink_counter
	}

	******************
	*COMPUTE PVALUES
	******************
	foreach p in `linear' `quad' `cubic' {
		`noi' di as result ""
		`noi' di as result "pvalues for local `p' model"
			*asymptotic SEs
			local t = kink_beta_`p'[true_discont_index,1]/kink_se_`p'[true_discont_index,1]
			mat pval_`p'[1,1] = 2*(1-normal(abs(`t')))
			`noi' di as result "Bandwidth at true discontinuity using `bw': " bw_`p'[true_discont_index,1]
			`noi' di as result "Coef at true discontinuity is " kink_beta_`p'[true_discont_index,1]

      local tmp_pval = round(pval_`p'[1,1], 0.0001)
      if ( `tmp_pval' == 0) {
        local tmp_pval = "<.0001"
      }
			`noi' di as result "p-value asymptotic: "  "`tmp_pval'"

			*randomization-based SEs
			clear
			qui svmat kink_beta_`p'
			egen rank_tmp_pos = rank(kink_beta_`p'1)
			scalar pval = 2*min(rank_tmp_pos[true_discont_index]/`kinks_n',1-((rank_tmp_pos[true_discont_index])-1)/`kinks_n')
			mat pval_`p'[2,1] = pval
			mat list pval_`p'
			
	local tmp_pvalr = round(pval_`p'[2,1], 0.0001)
        if ( `tmp_pvalr' == 0) {
        local tmp_pvalr = "<.0001"
		}
			`noi' di as result "p-value random: "`tmp_pvalr'"
		}
	}

	******************
	*SUMMARY OUTPUT
	******************
	foreach mat_stub in kink_beta kink_se bw pval {
		foreach p in `linear' `quad' `cubic' {
			*save .dta output
			if "`filename'"!=""{
				clear
				qui svmat `mat_stub'_`p'
				cap gen dgp = "`dgp'"
				cap gen kink_location = _n
				qui save  "`save_path'`mat_stub'_`p'`dgp'", replace
			}
			*save matrix output
			ereturn matrix `mat_stub'_`p' `mat_stub'_`p'
			}
		}


	clear
	if "`filename'"!=""{
		foreach mat_stub in kink_beta kink_se bw pval {
			foreach p in `linear' `quad' `cubic' {
				append using "`save_path'`mat_stub'_`p'`dgp'"
			}
		}
		collapse kink_beta* kink_se* bw* pval*, by(kink_location)
		sort kink_location
		gen actualKink = _n == true_discont_index
		qui `noi' save `save_path'`filename', replace
	}

	cap drop rdpermute_*
	qui `noi' di as text "__________________________________________________"
	restore
end
