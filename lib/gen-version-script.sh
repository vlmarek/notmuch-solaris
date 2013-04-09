#!/bin/sh

# we go through a bit of work to get the unmangled names of the
# typeinfo symbols because of
# http://sourceware.org/bugzilla/show_bug.cgi?id=10326

if [ $# -lt 2 ]; then
    echo Usage: $0 header obj1 obj2 obj3
    exit 1;
fi

HEADER=$1
shift

if [ `uname -s` = SunOS ] ; then
    #
    # Using Solaris "nm", a defined symbol looks like this:
    #
    # [Index]    Value    Size Type  Bind  Other Shndx   Name
    # [15]    |    128|     16|FUNC |GLOB |0    |1      |notmuch_tags_get
    #
    # and an undefined symbol looks like this:
    #
    # [Index]    Value    Size Type  Bind  Other Shndx   Name
    # [35]    |      0|      0|NOTY |GLOB |0    |UNDEF  |notmuch_tags_get
    #
    find_xapian_error() {
	nawk -F'\|' '$7 !~ "UNDEF" && $8 ~ "Xapian.*Error" { print $8 }'
    }
    find_compat_syms() {
	nawk -F'\|' '$7 !~ "UNDEF" && $8 ~ "get(line|delim)" { print $8 ";" }'
    }
    demangle() {
	gc++filt "$@"
    }
else
    find_xapian_error() {
	awk '$1 ~ "^[0-9a-fA-F][0-9a-fA-F]*$" && $3 ~ "Xapian.*Error" {print $3}'
    }
    find_compat_syms() {
	awk '$1 ~ "^[0-9a-fA-F][0-9a-fA-F]*$" && $2 == "T" && $3 ~ "^get(line|delim)$" {print $3 ";"}'
    }
    demangle() {
	c++filt "$@"
    }
fi

printf '{\nglobal:\n'

# Find the typeinfo for "Xapian::*Error"s.
nm $* | find_xapian_error | sort | uniq | while read sym; do
    demangled=`demangle $sym`
    case $demangled in
	typeinfo*) 
	    printf "\t$sym;\n"
	    ;;
	*)
	    ;;
    esac
done

# Find the "compat" syms that we need to export.
nm $* | find_compat_syms

# Finally, get the real notmuch symbols.
sed -n 's/^[ 	]*\(notmuch_[a-z_]*\)[ 	]*(.*/ \1;/p' $HEADER

printf "local: *;\n};\n"
