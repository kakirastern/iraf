# AP_READSKY -- Procedure to read sky values, sigma and skew from a file
# The x and y positions, sky mode, sigma, and skew values, number of sky
# pixels and number of rejected sky pixels are assumed to be columns
# 1 to 7 respectively.

int procedure ap_readsky (fd, x, y, sky_mode, sky_sigma, sky_skew, nsky,
    nsky_reject)

int	fd		# sky file descriptor
real	x, y		# center of sky annulus
real	sky_mode	# sky valye
real	sky_sigma	# sky sigma
real	sky_skew	# skew of sky pixels
size_t	nsky		# number of sky pixels
size_t	nsky_reject	# number of rejected pixesl

int	stat
long	l_val0, l_val1
int	fscan(), nscan()

begin
	# Initialize.
	sky_mode = INDEFR
	sky_sigma = INDEFR
	sky_skew = INDEFR
	nsky = 0
	nsky_reject = 0

	# Read in and decode a sky file text line.
	stat = fscan (fd)
	if (stat == EOF)
	    return (EOF)
	call gargr (x)
	call gargr (y)
	call gargr (sky_mode)
	call gargr (sky_sigma)
	call gargr (sky_skew)
	call gargl (l_val0)
	call gargl (l_val1)
	nsky = l_val0
	nsky_reject = l_val1
	return (nscan ())
end
