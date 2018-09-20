#!/bin/bash

function usage() {
    echo -e "Syntax: $(basename $0) -t <tag>"
    echo -e "Set the project directory for a list of valid tags"
}

while getopts :t: opt; do
    case "$opt" in
        t)
            tag=${OPTARG}
            ;;
        :)
            usage; echo
            >&2 echo "Option -$OPTARG requires an argument"
            exit 1
            ;;
        ?)
            usage; echo
            >&2 echo "Invalid option -$OPTARG"
            exit 1
            ;;
        *)
            usage; echo
            >&2 echo "Undefined option -$OPTARG"
            exit 1
            ;;
    esac
done

shift $(($OPTIND - 1))

if [[ -n ${tag} ]]; then
    if [[ -d "${tag}" && "${tag}" =~ ^[0-9]|latest ]]; then
        docker build --compress -t "velocityorg/docker-gitlab-runner:${tag}" "${tag}/"
    else
        usage; echo
        >&2 echo "\"${tag}\" isn't a valid tag"
        exit 1
    fi
else
    usage; exit 1
fi

exit 0
