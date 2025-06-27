#!/bin/bash

# written by @mastawbeqezwan on github

# basic colors
RED='\033[31;1m'
BLUE='\033[34;1m'
GREEN='\033[32;1m'
YELLOW='\033[33;1m'
MAGENTA='\033[35;1m'
CYAN='\033[36;1m'
RESET='\033[m'

VERSION="1.00"

PLATE_NO=""
PLATE_CHAR=""
REG_NO=""
VEHICLE_CATEGORY=""

# Define user-agent
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64; rv:136.0) Gecko/20100101 Firefox/136.0"

# replace kurdish sorani characters to latin ones
sorani_to_latin() {
    sed -e 's/ا/a/g' -e 's/ب/b/g' -e 's/پ/p/g' -e 's/ت/t/g' -e 's/ي/y/g' \
        -e 's/ك/k/g' -e 's/ج/j/g' -e 's/چ/ch/g' -e 's/ح/h/g' -e 's/خ/kh/g' \
        -e 's/د/d/g' -e 's/ڕ/r/g' -e 's/ر/r/g' -e 's/ز/z/g' -e 's/ژ/zh/g' \
        -e 's/س/s/g' -e 's/ش/sh/g' -e 's/ع/3/g' -e 's/غ/gh/g' -e 's/ف/f/g' \
        -e 's/ڤ/v/g' -e 's/ق/q/g' -e 's/ک/k/g' -e 's/گ/g/g' -e 's/ل/l/g' \
        -e 's/ڵ/ll/g' -e 's/م/m/g' -e 's/ن/n/g' -e 's/ه‌/e/g' -e 's/ه/h/g' \
        -e 's/و/w/g' -e 's/ۆ/o/g' -e 's/ۇ/u/g' -e 's/ی/y/g' -e 's/ێ/ê/g' \
        -e 's/ە/e/g' -e 's/ئ//g' -e 's/ة/e/g' -e 's/ن/n/g' -e 's/ى/y/g' \
        -e 's/\t/ /g'
}

show_help() {
    echo "Usage: ./htp.sh [options]"
    echo "./htp.sh <Vehicle Category> <Plate Character> <Plater Number> <Registration Number>"
    echo
    echo "Options:"
    echo "  -h, --help        Show this help message and exit"
    echo "  -t, --type        Show available vehicle types"
    echo "  -v                Show script version"
    echo
    echo "Example:"
    echo "  ./htp.sh private F 123 0123456"
    echo "  ./htp.sh commericial - 123 0123456"
    echo "  ./htp.sh m A 123 0123456"
}

function fetch_data {
    COOKIE_JAR=$(mktemp)
    curl -s -c "$COOKIE_JAR" -A "$USER_AGENT" "https://htp.moi.gov.krd/fines_form.php" >/dev/null

    RESULT=$(curl -s -b "$COOKIE_JAR" -A "$USER_AGENT" \
        -H "X-Requested-With: XMLHttpRequest" \
        -H "Referer: https://htp.moi.gov.krd/fines_form.php" \
        -H "Origin: https://htp.moi.gov.krd" \
        -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
        --data "Sinif=${VEHICLE_CATEGORY}&plate=${PLATE_NO}&PlateChar=${PLATE_CHAR}&SanNumber=${REG_NO}" \
        "https://htp.moi.gov.krd/fines_form_data_1.php")

    echo -e "Vehicle Category:      ${CYAN}$VEHICLE_CATEGORY${RESET}"
    echo -e "Plate Number:          ${GREEN}$PLATE_CHAR $PLATE_NO${RESET}"
    echo -e "Registration Number:   ${MAGENTA}$REG_NO${RESET}"

    if awk -v result="$RESULT" 'BEGIN { 
        if (result ~ /<div class=".*?<\/span> هیچ سزایه‌كى له‌سه‌ر نیه‌<\/h5><\/div>/) 
            exit 0; 
        else 
            exit 1 
        }'; then
        echo -e "\n${GREEN}No fines were found.${RESET}"
    else
        # total amount of fines
        total_fine_amount=$(echo "$RESULT" | awk 'match($0, /<h5>ژماره‌ى سه‌رپێچى <.*>(.*)<\/span><\/h5>/, arr) {print arr[1]}')
        total_fine=$(echo "$RESULT" | awk 'match($0, /<h5>بڕى گشتى سه‌رپێچیه‌كانى <.*>(.*)<\/span><\/h5>/, arr) {print arr[1]}')

        fines=$(echo "$RESULT" | awk -v blue="$BLUE" \
            -v green="$GREEN" \
            -v yellow="$YELLOW" \
            -v red="$RED" \
            -v cyan="$CYAN" \
            -v reset="$RESET" 'BEGIN {
        RS="</tr>";
        ORS="\n"; 
        print "Date|Time|City|Violation|Fine|Location" }
        {
            if (match($0, /<tr style="font-size: 0\.8rem">\s*<td>(.*?)<\/td>\s*<td>(.*?)<\/td>\s*<td>(.*?)<\/td>\s*<td>(.*?)<\/td>\s*<td>(.*?)<\/td>\s*<td>(.*?)<\/td>\s*<td>(.*?)<\/td>\s*/, arr)) 
            {
                printf "%s%s%s|%s|%s%s%s|%s%s%s|%s%s%s|%s%s%s\n", \
                blue, arr[1], reset, \
                arr[7], \
                green, arr[3], reset, \
                yellow, arr[4], reset, \
                red, arr[5], reset, \
                cyan, arr[6], reset
            }
        }' | sorani_to_latin |
            column -t -s '|' -o " ")
        echo -e "Number of Fines:       ${YELLOW}$total_fine_amount${RESET}"
        echo -e "Total Fine Amount:     ${RED}$total_fine${RESET}"

        echo -e "\n$fines"

        #echo -e "\n${YELLOW}I am not the one to tell you to pay the fines as soon as possible :)"
    fi

    rm -f "$COOKIE_JAR"
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
    -h | --help)
        show_help
        exit 0
        ;;
    private | p | rental | r | load | l | agricultural | a | commercial | c | motorcycle | m)
        if [ "$#" -eq 4 ] && [[ "$2" == [a-zA-Z-] ]] && [ "$3" -eq "$3" ] && [ "$4" -eq "$4" ]; then
            VEHICLE_CATEGORY=$(echo "$1" |
                sed -E -e 's/private|p/1/g' \
                    -e 's/rental|r/2/g' \
                    -e 's/load|l/3/g' \
                    -e 's/agricultural|a/4/g' \
                    -e 's/commercial|c/5/g' \
                    -e 's/motorcycle|m/6/g')
            PLATE_CHAR=$([ "$2" = "-" ] && echo "0" || echo "$2")
            PLATE_NO="$3"
            REG_NO="$4"
            fetch_data
        else
            echo "Use --help to see correct syntax"
            exit 1
        fi
        exit
        ;;
    -t | --type)
        echo -e "private | p\nrental | r\nload | l\nagricultural | a\ncommercial | c\nmotorcyle | m"
        exit
        ;;
    -v)
        echo "Version $VERSION"
        exit
        ;;
    *)
        echo "Use --help to see correct syntax"
        exit 1
        ;;
    esac
done

if [ "$#" -eq 0 ]; then
    show_help
    exit 1
fi
