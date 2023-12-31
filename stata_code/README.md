rdpermute
===========
**rdpermute** implements a permutation test for the Regression Kink (RK) and Regression Discontinuity (RD) Design for the one dimensional case of one **Outcome Variable (y)** and one **Assignment Variable (x)**.  By analyzing a set of user defined **placebo estimates (placebo_disconts)** in and outside the region of a suspected policy kink defined by its **position on the x-Axis (true_discont)** , it tests for the sharp null hypothesis of no effect of the policy on the outcome. The printed results describe the *calculated bandwidth* at the suspected policy kink, the *coefficient* of the treatment effect, the classical *p-Value for asymptotic inference analysis* and the *p-Value for* our recently proposed *randomization test*. A list of all calculated information for each placebo estimate is stored in the return value.


This test is based on _'A Permutation Test for the Regression Kink Design"_ by _Peter Ganong and Simon Jaeger_ (2018). 

- A detailed description of **rdpermute** and its arguments can be found in [rdpermute.pdf](https://github.com/ganong-noel/rdpermute/blob/master/stata_code/rdpermute.pdf).
- We provided also a short [usage example](https://github.com/ganong-noel/rdpermute) applying **rdpermute** with different parameters on real-life Datasets, showing advantages and disadvantages of different running modes. 
- In the case that you encounter a bug or want to provide suggestions for improving our code, feel free to commit under the Issues tab or contact us directly. 
 
**Simon Jaeger, (sjaeger[at]mit.edu)** and **Peter Ganong, (ganong[at]uchicago.edu)**


Installation
----------
**rdpermute** is available on SSC. 

```STATA
ssc install rdpermute
```

Alternatively, the installation is possible with the net command

```STATA
net from https://raw.githubusercontent.com/ganong-noel/rdpermute/master/stata_code
net describe rdpermute
net install rdpermute, replace
```

