# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<plset.h>
include	<plio.h>

# PL_R2P -- Convert a range list to a pixel array.  The number of pixels
# output (always npix) is returned as the function value.

int procedure pl_r2pi (rl_src, xs, px_dst, npix)

int	rl_src[3,ARB]		#I input range list
int	xs			#I starting pixel index in range list
int	px_dst[ARB]		#O output pixel array
int	npix			#I number of pixels to convert

int	hi, pv
int	xe, x1, x2, iz, op, np, nz, nr, i, j
define	done_ 91

begin
	# No input pixels?
	nr = RL_LEN(rl_src)
	if (npix <= 0 || nr <= 0)
	    return (0)

	xe = xs + npix - 1
	iz = xs
	op = 1
	hi = 1

	# Process the array of range lists.
	do i = RL_FIRST, nr {
	    x1 = rl_src[1,i]
	    np = rl_src[2,i]
	    pv = rl_src[3,i]
	    x2 = x1 + np - 1

	    # Get an inbounds range.
	    if (x1 > xe)
		break
	    else if (xs > x2)
		next
	    else if (x1 < xs)
		x1 = xs
	    else if (x2 > xe)
		x2 = xe
		
	    nz = x1 - iz
	    np = x2 - x1 + 1
	    if (np <= 0)
		next

	    # Output range of zeros to catch up to current range?
	    if (nz > 0) {
		do j = 1, nz
		    px_dst[op+j-1] = 0
		op = op + nz
	    }

	    # Output the pixels.
	    do j = 1, np
		px_dst[op+j-1] = pv
	    op = op + np
done_
	    x1 = x2 + 1
	    iz = x1
	}

	# Zero any remaining output range.
	do i = op, npix
	    px_dst[i] = 0

	return (npix)
end
