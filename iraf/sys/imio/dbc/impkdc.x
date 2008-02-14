# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<mach.h>

# IMPKDDC -- Put an image header parameter of type double.

procedure impkdc (im, key, dval, comment)

pointer	im			# image descriptor
char	key[ARB]		# parameter to be set
double	dval			# double precision value
char	comment[ARB]		# 

size_t	sz_val
pointer	sp, sval
int	i, strlen()

begin
	call smark (sp)
	sz_val = SZ_FNAME
	call salloc (sval, sz_val, TY_CHAR)

	# Reduce the precision of the encoded value if necessary to fit in
	# the FITS value field.  Start with NDIGITS_DP-1 as the precision
	# estimate NDIGITS_DP is only approximate, and if we make up half a
	# digit of precision the result can be 1.00000000000000001 instead
	# of 1.0.

	for (i=NDIGITS_DP-1;  i >= NDIGITS_RP;  i=i-1) {
	    call sprintf (Memc[sval], SZ_FNAME, "%0.*g")
		call pargi (i)
		call pargd (dval)
	    if (strlen (Memc[sval]) < 20)
		break
	}

	# Write the new value to the header.
	call impstrc (im, key, Memc[sval], comment)

	call sfree (sp)
end
