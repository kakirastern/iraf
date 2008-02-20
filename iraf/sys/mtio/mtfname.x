# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include "mtio.h"

# MTFNAME -- Edit the input mtname (magtape file specification) to reference
# the numbered file.  The edited mtname is returned in the output string.

procedure mtfname (mtname, fileno, outstr, maxch)

char	mtname[ARB]			#I magtape device specification
long	fileno				#I desired file number
char	outstr[ARB]			#O output mtname string
int	maxch				#I maxch chars out

size_t	sz_val
long	ofileno, orecno
pointer	sp, device, devcap

begin
	call smark (sp)
	sz_val = SZ_DEVICE
	call salloc (device, sz_val, TY_CHAR)
	sz_val = SZ_DEVCAP
	call salloc (devcap, sz_val, TY_CHAR)

	call mtparse (mtname, Memc[device], SZ_DEVICE, ofileno, orecno,
	    Memc[devcap], SZ_DEVCAP)
	call mtencode (outstr, maxch,
	    Memc[device], fileno, orecno, Memc[devcap])

	call sfree (sp)
end
