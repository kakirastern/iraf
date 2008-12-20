# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include <fset.h>
include <mii.h>
include <mach.h>

# RFT_INIT_READ_PIXELS and READ_PIXELS -- Read pixel data with record buffering
# and data type conversion.  The input data must meet the MII standard
# except for possibly in the case of integers having the least significant
# byte first.
#
# Read data in records of len_record and convert to the specified IRAF
# data type.  Successive calls of rft_read_pixels returns the next npix pixels.
# Read_pixels returns EOF or the number of pixels converted.
# Init_read_pixels must be called before read_pixels.
#
# Error conditions are:
# 1. A short input record
# 2. Error in converting the pixels by miiup.
#
# This routine is based on the MII unpack routine which is machine dependent.
# The bitpix must correspond to an MII type.  If the lsbf (least significant
# byte first) flag is YES then the pixels do not satisfy the MII standard.
# In this case the bytes are first swapped into most significant byte first
# before the MII unpack routine is called.

long procedure rft_init_read_pixels (npix_record, bitpix, lsbf, spp_type)

size_t	npix_record	# number of pixels per input record
int	bitpix		# bits per pixel (must correspond to an MII type)
int	lsbf		# byte swap?
int	spp_type	# SPP data type to be returned

# entry rft_read_pixels (fd, buffer, npix)

long	rft_read_pixels
int	fd		# input file descriptor
char	buffer[1]	# output buffer
size_t	npix		# number of pixels to read

size_t	c_1
int	swap, ty_mii, ty_spp
size_t	npix_rec, nch_rec, sz_rec, nchars, len_mii
long	recptr
size_t	bufsize, n
long	i, ip, op
pointer	mii, spp

long	rft_getbuf()
int	sizeof()
size_t	miipksize()
errchk	miipksize, mfree, malloc, rft_getbuf, miiupk
data	mii/NULL/, spp/NULL/

begin
	ty_mii = bitpix
	ty_spp = spp_type
	swap = lsbf
	npix_rec = npix_record
	nch_rec = npix_rec * sizeof (ty_spp)

	len_mii = miipksize (npix_rec, ty_mii)
	sz_rec = len_mii

	if (mii != NULL)
	    call mfree (mii, TY_CHAR)
	call malloc (mii, len_mii, TY_CHAR)

	if (spp != NULL)
	    call mfree (spp, TY_CHAR)
	call malloc (spp, nch_rec, TY_CHAR)

	ip = nch_rec
	return (OK)

entry	rft_read_pixels (fd, buffer, npix, recptr, bufsize)

	nchars = npix * sizeof (ty_spp)
	op = 0

	repeat {

	    # If data is exhausted read the next record
	    if (ip == nch_rec) {

		i = rft_getbuf (fd, Memc[mii], sz_rec, bufsize, recptr)
		if (i == EOF)
		    return (EOF)

		if (swap == YES) {
		    c_1 = 1
		    switch (ty_mii) {
		    case MII_SHORT:
			call bswap2 (Memc[mii], c_1, Memc[mii], c_1,
				sz_rec * SZB_CHAR)
		    case MII_LONG:
			call bswap4 (Memc[mii], c_1, Memc[mii], c_1,
				sz_rec * SZB_CHAR)
		    case MII_LONGLONG:
			call bswap8 (Memc[mii], c_1, Memc[mii], c_1,
				sz_rec * SZB_CHAR)
		    }
		}

		call miiupk (Memc[mii], Memc[spp], npix_rec, ty_mii, ty_spp)

		ip = 0
		#recptr = recptr + 1
	    }

	    n = min (nch_rec - ip, nchars - op)
	    call amovc (Memc[spp+ip], buffer[1+op], n)
	    ip = ip + n
	    op = op + n

	} until (op == nchars)

	return (npix)
end
