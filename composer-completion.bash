#!/usr/bin/env bash
#
# MIT License
#
# Copyright (c) 2019 Steven Garcia
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#
# bash completion file for Composer dependency manager
#
# @see https://getcomposer.org/
# @see https://github.com/scop/bash-completion
# @see bash -c "help complete"
# @see bash -c "help compgen"
# @see bash -c "help compopt"

#
# Bash completion callback/handler for Composer
#
_composer()
{
    COMPREPLY=()
    local parameter
    local argument
    local wordlist=-W
    local exclude=-n
    local current=-c
    local prefix=-P
    local suffix=-S
    local previous=-p
    local directory=-d
    local delimiters=":="

    # get command-line parameters by reference
    _get_comp_words_by_ref $previous argument $current parameter $exclude $delimiters

    case "$argument" in
        -d)
            _disable_space
            COMPREPLY=($( compgen $directory $suffix / -- "$parameter" ))
            return
            ;;
    esac

    case "$parameter" in
        --format=*)
            _disable_space
            COMPREPLY=($( compgen $wordlist "$(_get_format_options)" -- "${parameter#*=}" ))
            return
            ;;
        --working-dir=*)
            _disable_space
            COMPREPLY=($( compgen $directory $suffix / -- "${parameter#*=}" ))
            return
            ;;
        --*)
            _disable_space
            COMPREPLY=($( compgen $wordlist "$(_get_long_global_options)" -- "$parameter" ))
            ;;
        -*)
            COMPREPLY=($( compgen $wordlist "$(_get_short_global_options)" -- "$parameter" ))
            ;;
        *)
            COMPREPLY=($( compgen $wordlist "$(_get_global_commands)" -- "$parameter" ))
            ;;
    esac

    return
}

_disable_space()
{
    compopt -o nospace
}

_get_format_options()
{
    local field_seperator=-F
    local dictionary_order=-d

    composer --raw --ansi --no-plugins --no-interaction help --format \
        | grep "format=FORMAT" \
            | awk $field_seperator '[(]*[)]*' '{ sub(/or\ /, "", $2); gsub(/,/, "", $2); gsub(/ +/, "\n", $2); print $2 }' \
                | sort $dictionary_order
}

_get_long_global_options()
{
    local dictionary_order=-d
    local unique=-u

    composer --raw --ansi --no-plugins --no-interaction help \
        | grep \\-\\- \
            | awk '{ for(token = 1; token <= NF; token++) { if ($token ~ /--[^\]]+/) { print $token } } }' \
                | sed 's/^\(.*=\).*$/\1/' \
                    | sort $unique $dictionary_order
}

_get_short_global_options()
{
    local field_seperator=-F
    local ignore_case=-f
    local regex=-E

    printf "$(composer --raw --ansi --no-plugins --no-interaction help \
        | grep $regex '^[^-]+-[a-zA-Z0-9]+' \
            | awk $field_seperator '[,|]' '{ print $1 }')\n  -vv\n  -vvv" \
                | sort $ignore_case
}

_get_global_commands()
{
    local exclude=-v
    local pattern=-e
    local regex=-E

    composer --no-plugins --no-interaction list \
        | grep $exclude $pattern \\-\\- $pattern Options: $pattern commands: \
            | awk '/\s*[a-z-]\s+.+/  { print $1 }' \
                | grep $exclude $regex $pattern '^command$' $pattern '^Composer$'
}

version()
{
    echo "$(basename $0) Version 0.1.0"
}

environment=$1
function=$2

if test "$environment" == 'test'; then
    $function
    exit $?
fi

function=-F

complete $function _composer composer
