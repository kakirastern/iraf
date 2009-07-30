include	<tbset.h>
include	<imhdr.h>
include	<imio.h>

# OMNIREAD -- High level routine to read columns from image or table

procedure omniread (file, dtype, data, nelem, ncol, maxcol)

char	file[ARB]	# i: file name, including sections or selectors
int	dtype		# i: data type of data to be read
pointer	data[ARB]	# o: pointers to columns of output data
long	nelem		# o: length of output columns
int	ncol		# o: number of output columns
int	maxcol		# i: maximum number of columns
#--
size_t	sz_val
pointer	sp, project

errchk	omniproject

begin
	# Allocate dummy projection array and set to zero,
	# indicating projection should not be done

	call smark (sp)
	sz_val = maxcol
	call salloc (project, sz_val, TY_INT)
	call aclri (Memi[project], sz_val)

	call omniproject (file, dtype, Memi[project], 
			  data, nelem, ncol, maxcol)

	call sfree (sp)
end

# OMNIPROJECT -- Read with optional projection of multi-dimensional columns

procedure omniproject (file, dtype, project, data, nelem, ncol, maxcol)

char	file[ARB]	# i: file name, including sections or selectors
int	dtype		# i: data type of data to be read
int	project		# i: axis to project multi-dimensional data on
pointer	data[ARB]	# o: pointers to columns of output data
long	nelem		# o: length of output columns
int	ncol		# o: number of output columns
int	maxcol		# i: maximum number of columns
#--
string	badtype  "Unrecognized file type"

int	is_image()
errchk	is_image, om_rdimage, om_rdtable, om_error

begin
	switch (is_image (file)) {
	case YES:
	    if (maxcol > 0) {
		ncol = 1
		call om_rdimage (file, dtype, project, data[1], nelem)
	    } else {
		ncol = 0
		nelem = 0
	    }

	case NO:
	    call om_rdtable (file, dtype, project, data, nelem, ncol, maxcol)

	default:
	    call om_error (file, badtype)
	}

end

# --------------------------------------------------------------
# The routines beyond this point are not in the public interface
# --------------------------------------------------------------

# OM_ERROR -- Error exit routine

procedure om_error (file, message)

char	file[ARB]	# i: file name
char	message[ARB]	# i: error message
#--
size_t	sz_val
pointer	sp, text

begin
	call smark (sp)
	sz_val = SZ_LINE
	call salloc (text, sz_val, TY_CHAR)

	call sprintf (Memc[text], SZ_LINE, "%s (%s)\n")
	call pargstr (message)
	call pargstr (file)

	call error (1, Memc[text])

	call sfree (sp)
end

# OM_PROJIM -- Project a multi-dimensional image onto one dimension

procedure om_projim (im, dtype, project, data, nelem)

pointer	im		# i: image descriptor
int	dtype		# i: data type of data to be read
int	project		# i: axis to project multi-dimensional data on
pointer	data		# o: pointers to columns of output data
long	nelem		# o: length of output columns
#--
size_t	sz_val
size_t	sz_nelem
long	axis
long	nline
pointer	sp, sum, vec, buf
long	l_val

string	badaxis  "Cannot project data on axis"
string	badtype  "Unrecognized input datatype"

double	asumd()
long	imgnld()
errchk	om_error

begin
	# The projection is the average of the data along the 
	# non-included axes

	if (project <= 0 || project > IM_NDIM(im)) {
	    call om_error (IM_NAME(im), badaxis)
	}

	# All calculations are done in double precision and then
	# converted to the output type

	nelem = IM_LEN(im,project)
	sz_nelem = nelem

	call smark (sp)
	call salloc (sum, sz_nelem, TY_DOUBLE)
	sz_val = IM_MAXDIM
	call salloc (vec, sz_val, TY_LONG)

	call aclrd (Memd[sum], sz_nelem)
	l_val = 1
	sz_val = IM_MAXDIM
	call amovkl (l_val, Meml[vec], sz_val)

	# Sum the data. In the general case, we read each line, 
	# get the index of the projected axis, compute the sum of 
	# that line and add the summed line to the indexed element 
	# of the sum. In the case where the projection is onto the 
	# first axis, we simply accumulate each line into the sum.

	if (project == 1) {
	    while (imgnld (im, buf, Meml[vec]) != EOF)
		call aaddd (Memd[buf], Memd[sum], Memd[sum], sz_nelem)

	} else {
	    axis = Meml[vec+project-1]

	    while (imgnld (im, buf, Meml[vec]) != EOF) {
		Memd[sum+axis-1] = Memd[sum+axis-1] + 
				   asumd (Memd[buf], IM_LEN(im,1))
		axis = Meml[vec+project-1]
	    }
	}

	# Divide sum by number of lines to get average

	nline = 1
	do axis = 1, IM_NDIM(im) {
	    if (axis != project)
		nline  = nline * IM_LEN(im,axis)
	}

	call adivkd (Memd[sum], double(nline), Memd[sum], sz_nelem)

	# Copy the result to an array of the proper data type

	call malloc (data, sz_nelem, dtype)

	switch (dtype) {
	case TY_SHORT:
	    call achtds (Memd[sum], Mems[data], sz_nelem)
	case TY_INT:
	    call achtdi (Memd[sum], Memi[data], sz_nelem)
	case TY_LONG:
	    call achtdl (Memd[sum], Meml[data], sz_nelem)
	case TY_REAL:
	    call achtdr (Memd[sum], Memr[data], sz_nelem)
	case TY_DOUBLE:
	    call amovd (Memd[sum], Memd[data], sz_nelem)
	default:
	    call om_error (IM_NAME(im), badtype)
	}

	call sfree (sp)

end

# OM_PROJTAB -- Project a multidimensional array on a line

procedure om_projtab (array, length, ndim, project, dtype, line)
					 
double	array[ARB]	# i: input array
long	length[ARB]	# i: array shape
int	ndim		# i: number of array dimensions
int	project		# i: axis to project onto
int	dtype		# i: datatype of output line
pointer	line		# o: output line
#--
size_t	sz_val
int	idim
long	axis, linelen, elem, l_val
pointer	sp, sum, nsum, vec

string	badtype  "om_projtab: illegal datatype"

begin
	# Allocate temporary arrays for computing sums

	linelen = length[project]

	call smark (sp)
	sz_val = linelen
	call salloc (sum, sz_val, TY_DOUBLE)
	call salloc (nsum, sz_val, TY_INT)
	sz_val = ndim
	call salloc (vec, sz_val, TY_LONG)

	# Initialize arrays

	sz_val = linelen
	call amovkd (double(0.0), Memd[sum], sz_val)
	call amovki (0, Memi[nsum], sz_val)
	l_val = 1
	sz_val = ndim
	call amovkl (l_val, Meml[vec], sz_val)

	elem = 1
	repeat {
	    # Determine which line element the array element is projected
	    # onto and add it to the sum

	    axis = Meml[vec+project-1]
	    Memd[sum+axis-1] = Memd[sum+axis-1] + array[elem]
	    Memi[nsum+axis-1] = Memi[nsum+axis-1] + 1

	    # Increment array and line element

	    elem = elem + 1
	    for (idim = 1; idim <= ndim; idim = idim +1) {
		Meml[vec+idim-1] = Meml[vec+idim-1] + 1
		if (Meml[vec+idim-1] > length[idim]) {
		    Meml[vec+idim-1] = 1
		} else {
		    break
		}
	    }

	} until (idim > ndim)

	# Compute average

	do axis = 1, linelen {
	    if (Memi[nsum+axis-1] > 0)
		Memd[sum+axis-1] = Memd[sum+axis-1] / Memi[nsum+axis-1]
	}

	# Copy to output array of correct datatype

	switch (dtype) {
	case TY_SHORT:
	    call achtds (Memd[sum], Mems[line], linelen)
	case TY_INT:
	    call achtdi (Memd[sum], Memi[line], linelen)
	case TY_LONG:
	    call achtdl (Memd[sum], Meml[line], linelen)
	case TY_REAL:
	    call achtdr (Memd[sum], Memr[line], linelen)
	case TY_DOUBLE:
	    call amovd (Memd[sum], Memd[line], linelen)
	default:
	    call error (1, badtype)
	}

	call sfree (sp)
end

# OM_RDARRAY -- Read array data from a table

procedure om_rdarray (tp, col, rcode, dtype, project, data, nelem, ncol)
			     
pointer	tp		# i: table descriptor
pointer	col[ARB]	# i: column selectors
pointer	rcode		# i: row selector
int	dtype		# i: data type of output columns
int	project		# i: axis to project multi-dimensional data on
pointer	data[ARB]	# o: pointers to output columns
long	nelem		# o: length of each output column
int	ncol		# i: number of columns
#--
size_t	sz_val
bool	done
long	irow, nrow, osize, size
int	icol, coltype, ndim
pointer	sp, length, file, olddata

string	ambiguous  "More than one row matches in file"
string	badtype    "Unrecognized input datatype"
string	badsize    "All arrays are not the same length"

bool	trseval()
long	tbpstl(), tcs_totsize()
errchk	trseval, om_error, tcs_rdarys, tcs_rdaryi, tcs_rdaryr, tcsrdaryd

begin
	# Allocate temporary arrays

	call smark (sp)
	sz_val = IM_MAXDIM
	call salloc (length, sz_val, TY_LONG)
	sz_val = SZ_PATHNAME
	call salloc (file, sz_val, TY_CHAR)

	# Get table name for error messages

	call tbtnam (tp, Memc[file], SZ_PATHNAME)

	# Find the row which matches the row selector
	# It is an error to have more than one row match

	done = false
	nrow = tbpstl (tp, TBL_NROWS)
	do irow = 1, nrow {
	    if (trseval (tp, irow, rcode)) {
		if (done)
		    call om_error (Memc[file], ambiguous)

		done = true
		do icol = 1, ncol {
		    # Determine which datatype is use to read the array

		    if (project > 0) {
			coltype = TY_DOUBLE
		    } else if (dtype == TY_LONG) {
			coltype = TY_INT
		    } else {
			coltype = dtype
		    }

		    # Read the array from the table

		    osize = tcs_totsize (col[icol])
		    sz_val = osize
		    call malloc (data[icol], sz_val, coltype)

		    switch (coltype) {
		    case TY_SHORT:
			call tcs_rdarys (tp, col[icol], irow, osize, 
					 size, Mems[data[icol]])
		    case TY_INT:
			call tcs_rdaryi (tp, col[icol], irow, osize, 
					 size, Memi[data[icol]])
		    case TY_REAL:
			call tcs_rdaryr (tp, col[icol], irow, osize, 
					 size, Memr[data[icol]])
		    case TY_DOUBLE:
			call tcs_rdaryd (tp, col[icol], irow, osize, 
					 size, Memd[data[icol]])
		    default:
			call om_error (Memc[file], badtype)
		    }


		    if (project > 0) {
			# Project a multi-dimensional array onto
			# a single dimension

			call tcs_shape (col[icol], Meml[length], 
					ndim, IM_MAXDIM)

			size = Meml[length+project-1]

			olddata = data[icol]
			sz_val = size
			call malloc (data[icol], sz_val, dtype)

			call om_projtab (Memd[olddata], Meml[length], ndim,
					 project, dtype, data[icol])

			call mfree (olddata, TY_DOUBLE)

		    } else if (dtype == TY_LONG) {
			# Copy integer data to a long array

			olddata = data[icol]
			sz_val = size
			call malloc (data[icol], sz_val, TY_LONG)
			call achtil (Memi[olddata], Meml[data[icol]], sz_val)
			call mfree (olddata, TY_INT)
		    }

		    # Check array lengths to make sure they are equal

		    if (icol == 1) {
			nelem = size
		    } else if (nelem != size) {
			call om_error (Memc[file], badsize)
		    }
		}
	    }
	}

	call sfree (sp)
end

# OM_RDIMAGE -- Read a line from an image

procedure om_rdimage (file, dtype, project, data, nelem)

char	file[ARB]	# i: file name, including sections or selectors
int	dtype		# i: data type of data to be read
int	project		# i: axis to project multi-dimensional data on
pointer	data		# o: pointers to columns of output data
long	nelem		# o: length of output columns
#--
size_t	sz_nelem
pointer	im, buf

string	notline  "Cannot read multi-dimensional data"
string	badtype  "Unrecognized input datatype"
string	badaxis  "Cannot project data on axis"

pointer	immap(), imgl1s(), imgl1i(), imgl1l(), imgl1r(), imgl1d()

errchk	immap, om_error, om_projim

include	<nullptr.inc>

begin
	data = NULL
	nelem = 0

	im = immap (file, READ_ONLY, NULLPTR)

	if (project == 0 || IM_NDIM(im) == 1) {
	    # No projection, so check to see if the image is really 
	    # one dimensional and read the line with the routine of
	    # the appropriate datatype

	    if (IM_NDIM(im) > 1)
		call om_error (file, notline)

	    if (project > 1)
		call om_error (file, badaxis)

	    nelem = IM_LEN(im,1)
	    sz_nelem = nelem
	    call malloc (data, sz_nelem, dtype)

	    switch (dtype) {
	    case TY_SHORT:
		buf = imgl1s (im)
		call amovs (Mems[buf], Mems[data], sz_nelem)
	    case TY_INT:
		buf = imgl1i (im)
		call amovi (Memi[buf], Memi[data], sz_nelem)
	    case TY_LONG:
		buf = imgl1l (im)
		call amovl (Meml[buf], Meml[data], sz_nelem)
	    case TY_REAL:
		buf = imgl1r (im)
		call amovr (Memr[buf], Memr[data], sz_nelem)
	    case TY_DOUBLE:
		buf = imgl1d (im)
		call amovd (Memd[buf], Memd[data], sz_nelem)
	    default:
		call om_error (file, badtype)
	    }

	} else {
	    call om_projim (im, dtype, project, data, nelem)
	}

	call imunmap (im)
end

# OM_RDSCALAR -- Read scalar data from a table

procedure om_rdscalar (tp, col, rcode, dtype, data, nelem, ncol)

pointer	tp		# i: table descriptor
pointer	col[ARB]	# i: column selectors
pointer	rcode		# i: row selector
int	dtype		# i: data type of output columns
pointer	data[ARB]	# o: pointers to output columns
long	nelem		# o: length of each output column
int	ncol		# i: number of columns
#--
size_t	sz_val
long	irow, nrow
int	icol, ival
pointer	sp, cp

bool	trseval()
long	tbpstl()
pointer	tcs_column()
errchk	trseval, tbegts, tbegti, tbegtr, tbegtd

begin
	# Allocate arrays to read data and 
	# get column pointers from selectors

	nrow = tbpstl (tp, TBL_NROWS)

	call smark (sp)
	sz_val = ncol
	call salloc (cp, sz_val, TY_POINTER)

	do icol = 1, ncol {
	    Memp[cp+icol-1] = tcs_column (col[icol])
	    call malloc (data[icol], nrow, dtype)
	}

	# Look at each row and read values from rows where
	# row selector expression is true. Use appropriate 
	# routine for the data type.

	nelem = 0
	do irow = 1, nrow {
	    if (trseval (tp, irow, rcode)) {
		switch (dtype) {
		case TY_SHORT:
		    do icol = 1, ncol
			call tbegts (tp, Memp[cp+icol-1], irow, 
				     Mems[data[icol]+nelem])
		case TY_INT:
		    do icol = 1, ncol
			call tbegti (tp, Memp[cp+icol-1], irow, 
				     Memi[data[icol]+nelem])
		case TY_LONG:
		    do icol = 1, ncol {
			call tbegti (tp, Memp[cp+icol-1], irow, ival)
			Meml[data[icol]+nelem] = ival
		    }
		case TY_REAL:
		    do icol = 1, ncol
			call tbegtr (tp, Memp[cp+icol-1], irow, 
				     Memr[data[icol]+nelem])
		case TY_DOUBLE:
		    do icol = 1, ncol
			call tbegtd (tp, Memp[cp+icol-1], irow, 
				     Memd[data[icol]+nelem])
		}

		nelem = nelem + 1
	    }
	}

	# Reallocate memory to fit number of elements read
	# Free memory if no elements were read

	do icol = 1, ncol {
	    if (nelem > 0) {
		call realloc (data[icol], nelem, dtype)
	    } else {
		call mfree (data[icol], dtype)
	    }
	}

	call sfree (sp)
end

# OM_RDTABLE -- Read data from table columns or arrays

procedure om_rdtable (file, dtype, project, data, nelem, ncol, maxcol)

char	file[ARB]	# i: file name, including sections or selectors
int	dtype		# i: data type of data to be read
int	project		# i: axis to project multi-dimensional data on
pointer	data[ARB]	# o: pointers to columns of output data
long	nelem		# o: length of output columns
int	ncol		# o: number of output columns
int	maxcol		# i: maximum number of columns
#--
size_t	sz_val
int	nscalar, icol, ndim
long	length
pointer	tp, sp, col, root, rowselect, colselect, rcode

string	nodata   "Could not read data from file"
string	norows   "No rows read from file"
string	mixtype  "Cannot read both scalar and array columns"
string	badaxis  "Cannot project data on axis"

pointer	tbtopn(), trsopen()

errchk	rdselect, tbtopn, tcs_open, trsopen, om_error

include	<nullptr.inc>

begin
	# Break the table name into its various parts

	call smark (sp)
	sz_val = maxcol
	call salloc (col, sz_val, TY_POINTER)
	sz_val = SZ_PATHNAME
	call salloc (root, sz_val, TY_CHAR)
	call salloc (rowselect, sz_val, TY_CHAR)
	call salloc (colselect, sz_val, TY_CHAR)

	call rdselect (file, Memc[root], Memc[rowselect], 
		       Memc[colselect], SZ_PATHNAME)

	# Open then table

	tp = tbtopn (Memc[root], READ_ONLY, NULLPTR)

	# Check to see if we are dealing with scalar or array columns
	# It is an error to mix scalar and array columns in one call.

	call tcs_open (tp, Memc[colselect], Memp[col], ncol, maxcol)

	if (ncol == 0)
	    call om_error (file, nodata)

	nscalar = 0
	do icol = 1, ncol {
	    call tcs_shape (Memp[col+icol-1], length, ndim, 1)
	    if (ndim == 0)
		nscalar = nscalar + 1
	}

	# Process the row selector

	rcode = trsopen (tp, Memc[rowselect])

	# Call the appropriate 
	if (nscalar == ncol) {
	    do icol = 1, ncol {
		if (project > 1)
		    call om_error (file, badaxis)
	    }

	    call om_rdscalar (tp, Memp[col], rcode, dtype, 
			      data, nelem, ncol)
	    if (nelem == 0)
		call om_error (file, norows)

	} else if (nscalar == 0) {
	    call om_rdarray (tp, Memp[col], rcode, dtype, 
			     project, data, nelem, ncol)

	} else {
	    call om_error (file, mixtype)
	}

	call trsclose (rcode)
	call tcs_close (Memp[col], ncol)
	call tbtclo (tp)
end
