# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<knet.h>
include	<config.h>
include	"mtio.h"

# ZAWRMT -- MTIO asynchronous write primitive.  Initiate a write of nbytes
# bytes to the tape.

procedure zawrmt (mtchan, buf, nbytes, offset)

int	mtchan			#I i/o channel
char	buf[ARB]		#I data to be written
size_t	nbytes			#I number of bytes of data
long	offset			#I file offset

int	chan
include	"mtio.com"

begin
	chan = MT_OSCHAN(mtchan)
	call zzwrmt (chan, buf, nbytes, offset)
end
