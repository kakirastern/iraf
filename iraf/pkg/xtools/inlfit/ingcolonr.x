include	<gset.h>
include	<error.h>
include	<pkg/inlfit.h>

# List of colon commands.
define	CMDS "|show|low_reject|high_reject|nreject|grow|errors|vshow|constant|\
fit|tolerance|maxiter|variables|data|page|results|"

define	SHOW		1	# Show fit information
define	LOW_REJECT	2	# Set or show lower rejection factor
define	HIGH_REJECT	3	# Set or show upper rejection factor
define	NREJECT		4	# Set or show rejection iterations
define	GROW		5	# Set or show rejection growing radius
define	ERRORS		6	# Show fit errors
define	VSHOW		7	# Show verbose information
define	CONSTANT	8	# Set constant parameter
define	FIT		9 	# Set fitting parameter
define	TOL		10	# Set or show fitting tolerance
define	MAXITER		11	# Set or show max number of iterations
define	VARIABLES	12	# List the variables
define	DATA		13	# List of data
define	PAGE		14	# Page through a file
define	RESULTS		15	# List the results of the fit


# ING_COLON -- Processes colon commands.  The common flags and newgraph
# signal changes in fitting parameters or the need to redraw the graph.

procedure ing_colonr (in, cmdstr, gp, gt, nl, x, y, wts, names, npts, nvars,
	len_name, newgraph)

pointer	in				# INLFIT pointer
char	cmdstr[ARB]			# Command string
pointer	gp				# GIO pointer
pointer	gt				# GTOOLS pointer
pointer	nl				# NLFIT pointer for error listing
real	x[ARB]				# Independent variabels (npts * nvars)
real	y[npts]				# dependent variables
real	wts[npts]			# Weights
char	names[ARB]			# Object names
int	npts				# Number of data points
int	nvars				# Number of variables
int	len_name			# Length of object name
int	newgraph			# New graph ?

size_t	sz_val
int	ncmd, ival
real	fval
pointer	sp, cmd

int	nscan(), strdic()
int	in_geti()
real	in_getr()

begin
	# Allocate string space.
	call smark (sp)
	sz_val = SZ_LINE
	call salloc (cmd, sz_val, TY_CHAR)

	# Use formated scan to parse the command string.
	# The first word is the command and it may be minimum match
	# abbreviated with the list of commands.

	call sscan (cmdstr)
	call gargwrd (Memc[cmd], SZ_LINE)
	ncmd = strdic (Memc[cmd], Memc[cmd], SZ_LINE, CMDS)

	# Branch on command code.
	switch (ncmd) {
	case SHOW: # :show - Show the values of the fitting parameters.
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (nscan() == 1) {
		call gdeactivate (gp, AW_CLEAR)
		call ing_title (in, "STDOUT", gt)
		call ing_showr (in, "STDOUT")
		call greactivate (gp, AW_PAUSE)
	    } else {
		iferr {
		    call ing_title (in, Memc[cmd], gt)
		    call ing_showr (in, Memc[cmd])
		} then
		    call erract (EA_WARN)
	    }

	case LOW_REJECT: # :low_reject - List or set lower rejection factor.
	    call gargr (fval)
	    if (nscan() == 1) {
		call printf ("low_reject = %g\n")
		    call pargr (in_getr (in, INLLOW))
	    } else
		call in_putr (in, INLLOW, fval)

	case HIGH_REJECT: # :high_reject - List or set high rejection factor.
	    call gargr (fval)
	    if (nscan() == 1) {
		call printf ("high_reject = %g\n")
		    call pargr (in_getr (in, INLHIGH))
	    } else
		call in_putr (in, INLHIGH, fval)

	case NREJECT: # :nreject - List or set the rejection iterations.
	    call gargi (ival)
	    if (nscan() == 1) {
		call printf ("nreject = %d\n")
		    call pargi (in_geti (in, INLNREJECT))
	    } else
		call in_puti (in, INLNREJECT, ival)

	case GROW: # :grow - List or set the rejection growing.
	    call gargr (fval)
	    if (nscan() == 1) {
		call printf ("grow = %g\n")
		    call pargr (in_getr (in, INLGROW))
	    } else
		call in_putr (in, INLGROW, fval)

	case ERRORS: # :errors - print errors analysis of fit
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (nscan() == 1) {
		call gdeactivate (gp, AW_CLEAR)
		call ing_title (in, "STDOUT", gt)
		call ing_showr (in, "STDOUT")
		call ing_errorsr (in, "STDOUT", nl, x, y, wts, npts, nvars)
		call greactivate (gp, AW_PAUSE)
	    } else {
		iferr {
		    call ing_title (in, Memc[cmd], gt)
		    call ing_showr (in, Memc[cmd])
		    call ing_errorsr (in, Memc[cmd], nl, x, y, wts, npts,
		        nvars)
		} then
		    call erract (EA_WARN)
	    }

	case VSHOW: #  Verbose list of the fitting parameters and results. 
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (nscan() == 1) {
		call gdeactivate (gp, AW_CLEAR)
		call ing_vshowr (in, "STDOUT", nl, x, y, wts, names, npts,
		    nvars, len_name, gt)
		call greactivate (gp, AW_PAUSE)
	    } else {
		iferr {
		    call ing_vshowr (in, Memc[cmd], nl, x, y, wts, names,
		        npts, nvars, len_name, gt)
		} then 
		    call erract (EA_WARN)
	    }

	case CONSTANT:	# Set constant parameter.
	    call ing_changer (in, CONSTANT)

	case FIT:	# Set fitting parameter.
	    call ing_changer (in, FIT)

	case TOL:	# Set or show tolerance.
	    call gargr (fval)
	    if (nscan() == 1) {
		call printf ("tol = %g\n")
		    call pargr (in_getr (in, INLTOLERANCE))
	    } else
		call in_putr (in, INLTOLERANCE, fval)

	case MAXITER:	# Set or show max number of iterations.
	    call gargi (ival)
	    if (nscan() == 1) {
		call printf ("maxiter = %d\n")
		    call pargi (in_geti (in, INLMAXITER))
	    } else
		call in_puti (in, INLMAXITER, ival)

	case VARIABLES: # Show the list of variables.
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (nscan() == 1) {
		call gdeactivate (gp, AW_CLEAR)
		call ing_title (in, "STDOUT", gt)
		call ing_variablesr (in, "STDOUT", nvars)
		call greactivate (gp, AW_PAUSE)
	    } else {
		iferr {
		    call ing_title (in, Memc[cmd], gt)
		    call ing_variablesr (in, Memc[cmd], nvars)
		} then 
		    call erract (EA_WARN)
	    }

	case DATA: # List the raw data.
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (nscan() == 1) {
		call gdeactivate (gp, AW_CLEAR)
		call ing_title (in, "STDOUT", gt)
		call ing_datar (in, "STDOUT", x, names, npts, nvars, len_name)
		call greactivate (gp, AW_PAUSE)
	    } else {
		iferr {
		    call ing_title (in, Memc[cmd], gt)
		    call ing_datar (in, Memc[cmd], x, names, npts, nvars,
		        len_name)
		} then 
		    call erract (EA_WARN)
	    }

	case PAGE: # Page through a file.
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (nscan() == 1)
		call printf ("File to be paged is undefined\n")
	    else
		call gpagefile (gp, Memc[cmd], "")

	case RESULTS: # List the results of the fit.
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (nscan() == 1) {
		call gdeactivate (gp, AW_CLEAR)
		call ing_title (in, "STDOUT", gt)
		call ing_resultsr (in, "STDOUT", nl, x, y, wts, names, npts,
		    nvars, len_name)
		call greactivate (gp, AW_PAUSE)
	    } else {
		iferr {
		    call ing_title (in, Memc[cmd], gt)
		    call ing_resultsr (in, Memc[cmd], nl, x, y, wts, names,
		        npts, nvars, len_name)
		} then 
		    call erract (EA_WARN)
	    }

	default:	# User definable action.
	    call ing_ucolonr (in, gp, gt, nl, x, y, wts, npts, nvars, newgraph)
	}

	# Free memory
	call sfree (sp)
end


# ING_CHANGE -- Change fitting parameter into constant parameter, and
# viceversa. Parameters can be specified either by a name, supplied in
# the parameter labels, or just by a sequence number.

procedure ing_changer (in, type)

pointer	in			# INLFIT descriptor
int	type			# parameter type (fit, constant)

size_t	sz_val
bool	isfit
int	ip, pos, number, npars
real	rval
pointer	param, value, pname
pointer	pvalues, plist, plabels
pointer	sp

bool	streq()
int	ctoi(), ctor()
int	strdic()
int	in_geti()
pointer	in_getp()

begin
	# Allocate string space.
	call smark (sp)
	sz_val = SZ_LINE
	call salloc (param, sz_val, TY_CHAR)
	call salloc (value, sz_val, TY_CHAR)
	call salloc (pname, sz_val, TY_CHAR)
	call salloc (plabels, sz_val, TY_CHAR)

	# Get parameter name.
	Memc[param] = EOS
	call gargwrd (Memc[param], SZ_LINE)
	if (streq (Memc[param], "")) {
	    call eprintf ("Parameter not specified\n")
	    call sfree (sp)
	    return
	}

	# Try to find the parameter name in the parameter labels.
	call in_gstr (in, INLPLABELS, Memc[plabels], SZ_LINE)
	number = strdic (Memc[param], Memc[pname], SZ_LINE, Memc[plabels])

	# Try to find the parameter by number if it was not found
	# by name in the dictionary.
	if (number == 0) {
	    ip = 1
	    if (ctoi (Memc[param], ip, number) == 0) {
		call eprintf ("Parameter not found (%s)\n")
		    call pargstr (Memc[param])
	        call sfree (sp)
		return
	    }
	}

	# Test parameter number.
	npars = in_geti (in, INLNPARAMS)
	if (number < 1 || number > npars) {
	    call eprintf ("Parameter out of range (%d)\n")
		call pargi (number)
	    call sfree (sp)
	    return
	}

	# Get pointers to parameter values and list.
	pvalues = in_getp (in, INLPARAM)
	plist   = in_getp (in, INLPLIST)

	# Get new value if specified. Otherwise assume
	# old parameter value.
	Memc[value] = EOS
	call gargwrd (Memc[value], SZ_LINE)
	if (streq (Memc[value], ""))
	    rval = Memr[pvalues + number - 1]
	else {
	    ip = 1
	    if (ctor (Memc[value], ip, rval) == 0) {
	        call eprintf ("Bad parameter value (%s)\n")
		    call pargstr (Memc[value])
	        call sfree (sp)
	        return
	    }
	}

	# Update parameter value.
	Memr[pvalues + number - 1] = rval

	# Find the parameter position in the parameter list.
	do pos = 1, npars {
	    if (Memi[plist + pos - 1] >= number ||
		Memi[plist + pos - 1] == 0)
	        break
	}

	# Insert or remove parameter from the parameter list
	# according with its type, i.e., with the type of change.
	# The list is not changed if it's not necesary to do so.

	if (type == FIT) {
	    if (Memi[plist + pos - 1] != number) {
		do ip = npars, pos + 1, -1
		    Memi[plist + ip - 1] = Memi[plist + ip - 2]
		Memi[plist + pos - 1] = number
		call in_puti (in, INLNFPARAMS, in_geti (in, INLNFPARAMS) + 1)
	    }
	    isfit = true
	} else {
	    if (Memi[plist + pos - 1] == number) {
		do ip = pos, npars - 1
		    Memi[plist + ip - 1] = Memi[plist + ip]
		Memi[plist + npars - 1] = 0
		call in_puti (in, INLNFPARAMS, in_geti (in, INLNFPARAMS) - 1)
	    }
	    isfit = false
	}

	# Print setting.
	call printf ("(%s) changed to %s parameter, with value=%g\n")
	    call pargstr (Memc[pname])
	if (isfit)
	    call pargstr ("fitting")
	else
	    call pargstr ("constant")
	    call pargr (rval)

	# Free memory.
	call sfree (sp)
end
