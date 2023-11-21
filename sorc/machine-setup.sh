# Create a test function for sh vs. bash detection.  The name is
# randomly generated to reduce the chances of name collision.
__ms_function_name="setup__test_function__$$"
eval "$__ms_function_name() { /bin/true ; }"

# Determine which shell we are using
__ms_ksh_test=$( eval '__text="text" ; if [[ $__text =~ ^(t).* ]] ; then printf "%s" ${.sh.match[1]} ; fi' 2> /dev/null | cat )
__ms_bash_test=$( eval 'if ( set | grep '$__ms_function_name' | grep -v name > /dev/null 2>&1 ) ; then echo t ; fi ' 2> /dev/null | cat )

# Note: on GAEA, this script only supports bash. That is due to
# a limitation of GAEA's own system init scripts.

if [[ ! -z "$__ms_ksh_test" ]] ; then
    __ms_shell=ksh
elif [[ ! -z "$__ms_bash_test" ]] ; then
    __ms_shell=bash
else
    # Not bash or ksh, so assume sh.
    __ms_shell=sh
fi

target=""
USERNAME=`echo $LOGNAME | awk '{ print tolower($0)'}`

# Disable -e (abort on non-zero exit status) -u (abort on empty or
# uninitialized variables) and -x (print every command executed)
# because they can break system scripts.
__ms_set_e=$( echo $- | grep e && echo YES || echo NO )
__ms_set_u=$( echo $- | grep u && echo YES || echo NO )
__ms_set_x=$( echo $- | grep x && echo YES || echo NO )
set +eux

if [[ -d /lfs4 ]] ; then
    # We are on NOAA Jet
    if ( ! eval module help > /dev/null 2>&1 ) ; then
        echo load the module command 1>&2
        source /apps/lmod/lmod/init/$__ms_shell
    fi
    target=jet
    module purge
elif [[ -d /lfs/h1 ]] ; then
    target=wcoss2
    module reset
elif [[ -d /scratch1 ]] ; then
    # We are on NOAA Hera
    if ( ! eval module help > /dev/null 2>&1 ) ; then
        echo load the module command 1>&2
        source /apps/lmod/lmod/init/$__ms_shell
    fi
    target=hera
    module purge
elif [[ -d /glade ]] ; then
    # We are on NCAR Cheyenne
    if ( ! eval module help > /dev/null 2>&1 ) ; then
        echo load the module command 1>&2
        . /glade/u/apps/ch/opt/lmod/8.1.7/lmod/8.1.7/init/sh
    fi
    target=cheyenne
    module purge
elif [[ -d /lustre && -d /ncrc ]] ; then
  if [[ $( hostname ) =~ gaea* ]] ; then
    module purge
    # Unset the read-only variables $PELOCAL_PRGENV and $RCLOCAL_PRGENV
    gdb -ex 'call (int) unbind_variable("PELOCAL_PRGENV")' \
        -ex 'call (int) unbind_variable("RCLOCAL_PRGENV")' \
        --pid=$$ --batch
    
    # Reload system default modules:
    source /etc/bash.bashrc.local

    # Load EPIC's module directories:
    source /lustre/f2/dev/role.epic/contrib/Lmod_init.sh
  fi    

  if ( head /proc/cpuinfo | grep EPYC > /dev/null ) ; then
      target=gaea_c5
  else
      target=gaea
  fi
elif [[ "$(hostname)" =~ "Orion" ]]; then
    target="orion"
    module purge
elif [[ -d /work/00315 && -d /scratch/00315 ]] ; then
    target=stampede
    module purge
elif [[ -d /data/prod ]] ; then
    # We are on SSEC S4
    if ( ! eval module help > /dev/null 2>&1 ) ; then
        echo load the module command 1>&2
        source /usr/share/lmod/lmod/init/$__ms_shell
    fi
    target=s4
    module purge
elif [[ "$(dnsdomainname)" =~ "pw" ]]; then
    if [[ "${PW_CSP}" == "aws" ]]; then # TODO: Add other CSPs here.
	target=noaacloud
        module purge
    else
        echo WARNING: UNSUPPORTED CSP PLATFORM 1>&2; exit 99
    fi
else

    echo WARNING: UNKNOWN PLATFORM 1>&2
fi

# Restore shell settings
if [[ "$__ms_set_e" == YES ]] ; then
    set -e
fi
if [[ "$__ms_set_u" == YES ]] ; then
    set -u
fi
if [[ "$__ms_set_x" == YES ]] ; then
    set -x
fi

# Remove script-local variables
unset __ms_set_e
unset __ms_set_u
unset __ms_set_x
unset __ms_shell
unset __ms_ksh_test
unset __ms_bash_test
unset $__ms_function_name
unset __ms_function_name
