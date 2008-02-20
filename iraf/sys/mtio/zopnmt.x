# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<knet.h>
include	<config.h>
include	"mtio.h"

# ZOPNMT -- Open magtape device at the specifed file.  We are called indirectly
# by MTOPEN (via fopnbf), which sets up a new mtio device decriptor pointed
# to by NEW_MTCHAN, and passes it via the mtio common.

procedure zopnmt (iodev, acmode, mtchan)

char	iodev[ARB]		#I PACKED i/o device name string
int	acmode			#I file access mode
int	mtchan			#O return value (mt descriptor index)

size_t	sz_val
int	mt, n_acmode, n_newfile, n_chan
pointer	sp, pk_devcap
include	"mtio.com"
define	err_ 91

begin
	call smark (sp)
	sz_val = SZ_DEVCAP
	call salloc (pk_devcap, sz_val, TY_CHAR)

	# Pick up index of mt descriptor slot set up by MTOPEN.  Make sure
	# that we were called by MTOPEN and not somebody else.

	mt = new_mtchan
	if (mt < 1 || mt > MT_MAXTAPES)
	    goto err_

	# Open the device.
	sz_val = SZ_DEVCAP
	call strpak (Memc[MT_DEVCAP(mt)], Memc[pk_devcap], sz_val)
	n_acmode = MT_ACMODE(mt)
	n_newfile = MT_FILE(mt)
	call zzopmt (iodev, n_acmode, Memc[pk_devcap], MT_DEVPOS(mt),
	    n_newfile, n_chan)
	MT_FILE(mt) = n_newfile
	MT_OSCHAN(mt) = n_chan
	if (MT_OSCHAN(mt) == ERR)
	    goto err_

	# If "new_mtchan" is nonzero when ZCLSMT is called, it implies that
	# CLOSE was called during error recovery due to an interrupt of ZZOPMT
	# and the position of the tape is undefined.  Clear the flag since the
	# open is now complete and we were not interrupted.

	new_mtchan = NULL
	MT_FILNO(mt) = MT_FILE(mt)
	call mt_savepos (mt)

	mtchan = mt
	call sfree (sp)
	return

err_
	# Z-routines can only return ERR in the event of an error.
 	MT_OSCHAN(mt) = NULL
	call sfree (sp)
	mtchan = ERR
end
