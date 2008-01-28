# XHELP.H -- Include file for the XHELP GUI task.

# Help database header structure.  Stored at the beginning of a help
# database file.  This information is taken from the help$helpdb.x source.

define  LEN_HDBHEADER   14
define  HDB_MAGICVAL    110104B

define  HDB_MAGIC       Memi[P2I($1)]        # helpdb file type code
define  HDB_RAW         Memi[P2I($1+1)]      # access compiled or raw database
define  HDB_RHD         Memp[$1+2]      # if raw, HP of root help directory
define  HDB_INDEX       Memi[P2I($1+3)]      # index of root help directory
define  HDB_CRDATE      Meml[P2L($1+4)]      # creation date
define  HDB_NENTRIES    Memi[P2I($1+5)]      # number of help directories in db
define  HDB_MAXENTRIES  Memi[P2I($1+6)]      # maximum no. of help directories in db
define  HDB_NMODULES    Memi[P2I($1+7)]      # count of the total number of modules
define  HDB_INDEXOFFSET Meml[P2L($1+8)]      # file offset of index, chars
define  HDB_INDEXPTR    Memp[$1+9]      # pointer to loaded index, ty_struct
define  HDB_INDEXLEN    Memi[P2I($1+10)]     # length of index structure, su
define  HDB_DATAOFFSET  Meml[P2L($1+11)]     # file offset of data area, chars
define  HDB_DATAPTR     Memp[$1+12]     # pointer to loaded data area, ty_struct
define  HDB_DATALEN     Memi[P2I($1+13)]     # length of data area, struct units

# Index structure.  Identifies the contents of the database and tells where
# they are stored.  There is one index entry for each help directory, i.e.,
# for each package.

define  LEN_HDBINDEX    34
define  SZ_DBIKEY       63
define  LEN_DBIDATA     2

define  DBI_KEY         Memc[P2C($1)]   # entry name
define  DBI_OFFSET      Memi[P2I($1+32)]     # offset of entry into data area, su
define  DBI_MTIME       Meml[P2L($1+33)]     # modification date of entry

define  MAX_ENTRIES     100             # initial max db entries
define  INC_ENTRIES     50              # increment if overflow
define  MAX_DEPTH       20              # max nesting of packages
define  MAX_MENUSIZE    500             # max modules in a table
define  MAX_NAMELEN     20              # max chars in a module name in table


# XHELP Macro definitions.
define	SZ_HELPLIST	20480
define	SZ_XHELPSTRUCT	45

define	XH_GP		Memp[$1]	# graphics descriptor
define	XH_LPTR		Memp[$1+1]	# ptr for pkg list
define	XH_TEMPLATE	Memp[$1+2]	# initial help topic
define	XH_OPTION	Memp[$1+3]	# help option
define	XH_PRINTER	Memp[$1+4]	# printer name
define	XH_CURTASK	Memp[$1+5]	# current task name
define	XH_CURPACK	Memp[$1+6]	# current package name
define	XH_QUICKREF	Memp[$1+7]	# quick-reference filen
define	XH_HOMEPAGE	Memp[$1+8]	# startup page
define	XH_CURDIR	Memp[$1+9]	# current directory
define	XH_PATTERN	Memp[$1+10]	# current filename template
define	XH_HELPDB	Memp[$1+11]	# help database string
define	XH_SHOWTYPE	Memi[P2I($1+12)]	# indicate packages in list
define	XH_STP		Memp[$1+13]	# package list symtab ptr

# Helpful macros
define	LIST		Memc[XH_LPTR($1)]
define	TEMPLATE	Memc[XH_TEMPLATE($1)]
define	OPTION		Memc[XH_OPTION($1)]
define	PRINTER		Memc[XH_PRINTER($1)]
define	CURTASK		Memc[XH_CURTASK($1)]
define	CURPACK		Memc[XH_CURPACK($1)]
define	QUICKREF	Memc[XH_QUICKREF($1)]
define	HOMEPAGE	Memc[XH_HOMEPAGE($1)]
define	CURDIR		Memc[XH_CURDIR($1)]
define	PATTERN		Memc[XH_PATTERN($1)]
define	HELPDB		Memc[XH_HELPDB($1)]

define	WIDE_PAGE	100		# needed by the print routines
define	SZ_DDSTR	256


# Filenames.
define  HELP      "base$scr/help.html"	# default help file
define  PKGFILE   "uparm$help.pkgs"     # default package list symtab
define  QREFFILE  "uparm$quick.ref"     # default references file


# Symbol table definitions.
define  LEN_INDEX       10              # length of symtab index
define  LEN_STAB        32              # initial length of symtab
define  SZ_SBUF         32              # initial size of symtab string buffer

