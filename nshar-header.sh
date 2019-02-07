cat << __HEADER__
#!/bin/sh -e
# This script was generated using $COMMAND $VERSION
# The license covering this archive and its contents, if any, is wholly independent of the $COMMAND license (GPL)

(
    USER_PWD="\$PWD"; export USER_PWD

    print_cmd_arg=""
    if type printf > /dev/null; then
        print_cmd="printf"
    elif test -x /usr/ucb/echo; then
        print_cmd="/usr/ucb/echo"
    else
        print_cmd="echo"
    fi

    if test -d /usr/xpg4/bin; then
        PATH=/usr/xpg4/bin:\$PATH
        export PATH
    fi

    if test -d /usr/sfw/bin; then
        PATH=\$PATH:/usr/sfw/bin
        export PATH
    fi

    unset CDPATH

    __diskspace()
    {
        (
        df -kP "\$1" | tail -1 | awk '{ if (\$4 ~ /%/) {print \$3} else {print \$4} }'
        )
    }

    __usage() {
        cat << __HELP__ >&2
nshar version $VERSION archive
 1) Getting help or info about \$0 :
  \$0 --help   Print this message
  \$0 --list   Print the list of files in the archive

 2) Running \$0 :
  \$0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --quiet               Do not print anything except error messages
  --keep                Do not erase target directory after running
                        the embedded script
__HELP__
    }

    list= keep= quiet=

    while true ; do
        case "\$1" in
        --quiet|-q)
            quiet=y
            ;;
        --help|-h)
            __usage
            exit 1
            ;;
        --list|-l)
            list=y
            ;;
        --keep|-k)
            keep=y
            ;;
        "")
            break
            ;;
        *)
            echo Unrecognized flag : "\$1"
            __usage
            exit 1
            ;;
        esac
        shift
    done

    if test "\$list" = y; then
        TAR_PARAMS="-t"
    elif test "\$quiet" = y; then
        TAR_PARAMS="-x"
    else
        TAR_PARAMS="-xv"
    fi


    { $DECODE_CMD || echo "... Decode failed." >&2; } | \
        { $GUNZIP_CMD || echo "... Decompress failed." >&2; } | \
        { tar \$TAR_PARAMS || echo "... Untar failed." >&2; }
) << $__EOF_MARK__
__HEADER__
