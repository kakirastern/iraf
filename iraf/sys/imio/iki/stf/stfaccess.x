# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	"stf.h"

# STF_ACCESS -- Test the accessibility or existence of an existing image, or
# the legality of the name of a new image.

procedure stf_access (kernel, root, extn, acmode, status)

int	kernel			#I IKI kernel
char	root[ARB]		#I root filename
char	extn[ARB]		#I extension (SET on output if none specified)
int	acmode			#I access mode (0 to test only existence)
int	status			#O return value

size_t	sz_val
int	i
pointer	sp, fname, kextn
int	access(), iki_validextn(), iki_getextn(), btoi()

begin
	call smark (sp)
	sz_val = SZ_PATHNAME
	call salloc (fname, sz_val, TY_CHAR)
	sz_val = MAX_LENEXTN
	call salloc (kextn, sz_val, TY_CHAR)

	# If new image, test only the legality of the given extension.
	# This is used to select a kernel given the imagefile extension.

	if (acmode == NEW_IMAGE || acmode == NEW_COPY) {
	    status = btoi (iki_validextn (kernel, extn) > 0)
	    call sfree (sp)
	    return
	}

	status = NO

	# If no extension was given, look for a file with the default
	# extension, and return the actual extension if an image with the
	# default extension is found.

	if (extn[1] == EOS) {
	    do i = 1, ARB {
		if (iki_getextn (kernel, i, Memc[kextn], MAX_LENEXTN) <= 0)
		    break
		call iki_mkfname (root, Memc[kextn], Memc[fname], SZ_PATHNAME)
		if (access (Memc[fname], acmode, 0) == YES) {
		    call strcpy (Memc[kextn], extn, MAX_LENEXTN)
		    status = YES
		    break
		}
	    }		
	} else if (iki_validextn (kernel, extn) == kernel) {
	    call iki_mkfname (root, extn, Memc[fname], SZ_PATHNAME)
	    if (access (Memc[fname], acmode, 0) == YES)
		status = YES
	}

	call sfree (sp)
end
