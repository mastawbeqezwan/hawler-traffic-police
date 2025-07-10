#!/bin/bash

# Hawler Traffic Police Fines Checker
# written by @mastawbeqezwan on github

# This script is licensed under the GNU General Public License v3.0
# See: https://www.gnu.org/licenses/gpl-3.0.html
#
# You are free to use, modify, and distribute this script under the terms of the GPLv3.

#  Colors
RED='\033[31;1m'
BLUE='\033[34;1m'
GREEN='\033[32;1m'
YELLOW='\033[33;1m'
MAGENTA='\033[35;1m'
CYAN='\033[36;1m'
RESET='\033[m'

# User-Agent
VERSION="1.01"

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
        -e 's/ \+/ /g'
}

show_help() {
    cat <<EOF
Usage: $0 <Vehicle Type> [<Plate Character>] <Plate Number> <Registration Number>

Options:
  -h, --help        Show this help message and exit
  -v                Show script version

Vehicle Type:
  p | private
  r | rental
  l | load
  a | agricultural
  c | commercial
  m | motorcycle

Examples:
  $0 private F 123 0123456
  $0 c B 123 0123456
  $0 motorcycle 123 0123456     (without Plate Character)
EOF
}

map_vehicle_type() {
    local input="$1"

    case "$input" in
        private|p)
            vehicle_type="1"
            vehicle_type_text="Private"
            ;;
        rental|r)
            vehicle_type="2"
            vehicle_type_text="Rental"
            ;;
        load|l)
            vehicle_type="3"
            vehicle_type_text="Load"
            ;;
        agricultural|a)
            vehicle_type="4"
            vehicle_type_text="Agricultural"
            ;;
        commercial|c)
            vehicle_type="5"
            vehicle_type_text="Commercial"
            ;;
        motorcycle|m)
            vehicle_type="6"
            vehicle_type_text="Motorcycle"
            ;;
        *)
            echo "Error: Invalid vehicle type '$input'"
            exit 1
            ;;
    esac
}

function fetch_data {
    local plate_char="$1"
    local plate_char_text=$([ $plate_char = "0" ] && echo "" || echo "$plate_char ")
    local plate_number="$2"
    local registration_number="$3"
   
    COOKIE_JAR=$(mktemp)

    curl -s \
        --http1.1 \
        -c "$COOKIE_JAR" \
        -A "$USER_AGENT" \
        -m 30 "https://htp.moi.gov.krd/fines_form.php" >/dev/null

    RESULT=$(curl -s \
        --http1.1 \
        -b "$COOKIE_JAR" \
        -A "$USER_AGENT" \
        -H "X-Requested-With: XMLHttpRequest" \
        -H "Referer: https://htp.moi.gov.krd/fines_form.php" \
        -H "Origin: https://htp.moi.gov.krd" \
        -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
        --data "Sinif=${vehicle_type}&plate=${plate_number}&PlateChar=${plate_char}&SanNumber=${registration_number}" \
        -m 30 "https://htp.moi.gov.krd/fines_form_data_1.php") >/dev/null

    #echo "$RESULT"
    
    # Check if the curl command made a successful request
    if [[ "$?" -eq 0 && ! "$RESULT" =~ 404|robot|nginx ]]; then
        echo -e "${YELLOW}Hawler Traffic Police${RESET}\n"
        echo -e "Vehicle Type:          ${CYAN}$vehicle_type_text${RESET}"
        echo -e "Plate Number:          ${GREEN}${plate_char_text}$plate_number${RESET}"
        echo -e "Registration Number:   ${MAGENTA}$registration_number${RESET}"
        
        if [[ "$RESULT" == *"هیچ سزایه‌كى له‌سه‌ر نیه‌"* ]]; then
            echo -e "\n${GREEN}No fines were found.${RESET}"
        elif [[ "$RESULT" == *"ژماره‌ى ساڵیانە هەلەیە"* ]]; then
            echo -e "\n${YELLOW}Error: Wrong registration number.${RESET}"
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
        fi
    else
        echo "Error: Failed to fetch data from HTP"
    fi
    rm -f "$COOKIE_JAR"
}

main() {
    if [ "$#" -eq 0 ]; then
        show_help
        exit 1
    fi

    case "$1" in
        -h|--help)
            show_help
            ;;
        -v)
            echo "Version: $VERSION"
            ;;
        *)
            # Check argument count
            if [ "$#" -eq 3 ]; then
                plate_char="0"
                plate_number="$2"
                registration_number="$3"

            elif [ "$#" -eq 4 ]; then
                plate_char="$2"
                plate_number="$3"
                registration_number="$4"
                
                # Capitalize plate character 
                plate_char="${plate_char^}"
                
                # Check if the entered plate character is an alphabet
                ! [[ "$plate_char" =~ ^[A-Z]$ ]] && echo "Error: Plate character must be an alphabet." && exit 1
            else
                echo "Error: You must provide 3 or 4 arguments."
                show_help
                exit 1
            fi
            
            # Validate numeric values
            if ! [[ "$plate_number" =~ ^[0-9]+$ && "$registration_number" =~ ^[0-9]+$ ]]; then
                echo "Error: Plate and registration numbers must be numeric."
                exit 1
            fi

            # Map vehicle type
            map_vehicle_type "$1"
            
            # Call fetch_data
            fetch_data "$plate_char" "$plate_number" "$registration_number"
            ;;
    esac
}

# Entrypoint
main "$@"
