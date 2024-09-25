#!/usr/bin/env zsh

# ---------------------------------------------------
# This is free program to change your keyboard
# language layout as efficient approach.
# ---------------------------------------------------

# Define terminal colors
NO_COLOR="\033[0m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
PURPLE="\033[35m"
LIGHT_BLUE="\033[36m"

# Check dependencies
DEPS=("localectl" "setxkbmap" "fzf")
echo -n "${LIGHT_BLUE}"
echo "Check dependencies..."
for dep in "${DEPS[@]}"; do 
    if command -v $dep > /dev/null; then 
        echo "${dep} is installed."
    else
        echo "${RED}"
        echo "${dep} is not installed."
        exit 1
    fi
done
echo "${NO_COLOR}"

# Declare no constant variables
primary_lang="us"
secondary_lang=
lang_toggler="grp:alt_shift_toggle"
persistent_conf="No"
prompt_message=

# Declare an associative array of layouts
typeset -A LANGUAGE_LAYOUTS
typeset -A LANGUAGE_TOGGLERS 
typeset -A PERSIST_ANSWERS

# Initialize associative arrays of layouts and toggler options
LANGUAGE_LAYOUTS=(
	['al']="Albanian"
	['et']="Amharic"
	['am']="Armenian"
	['ara']="Arabic"
	['eg']="Arabic (Egypt)"
	['iq']="Arabic (Iraq)"
	['ma']="Arabic (Morocco)"
	['sy']="Arabic (Syria)"
	['az']="Azerbaijani"
	['ml']="Bambara"
	['bd']="Bangla"
	['by']="Belarusian"
	['be']="Belgian"
	['dz']="Berber (Algeria, Latin)"
	['ba']="Bosnian"
	['brai']="Braille"
	['bg']="Bulgarian"
	['mm']="Burmese"
	['cn']="Chinese"
	['hr']="Croatian"
	['cz']="Czech"
	['dk']="Danish"
	['af']="Dari"
	['mv']="Dhivehi"
	['nl']="Dutch"
	['bt']="Dzongkha"
	['au']="English (Australia)"
	['cm']="English (Cameroon)"
	['gh']="English (Ghana)"
	['nz']="English (New Zealand)"
	['ng']="English (Nigeria)"
	['za']="English (South Africa)"
	['gb']="English (UK)"
	['us']="English (US)"
	['epo']="Esperanto"
	['ee']="Estonian"
	['fo']="Faroese"
	['ph']="Filipino"
	['fi']="Finnish"
	['fr']="French"
	['ca']="French (Canada)"
	['cd']="French (Democratic Republic of the Congo)"
	['tg']="French (Togo)"
	['ge']="Georgian"
	['de']="German"
	['at']="German (Austria)"
	['ch']="German (Switzerland)"
	['gr']="Greek"
	['il']="Hebrew"
	['hu']="Hungarian"
	['is']="Icelandic"
	['in']="Indian"
	['id']="Indonesian (Latin)"
	['ie']="Irish"
	['it']="Italian"
	['jp']="Japanese"
	['kz']="Kazakh"
	['kh']="Khmer (Cambodia)"
	['kr']="Korean"
	['kg']="Kyrgyz"
	['la']="Lao"
	['lv']="Latvian"
	['lt']="Lithuanian"
	['mk']="Macedonian"
	['my']="Malay (Jawi, Arabic Keyboard)"
	['mt']="Maltese"
	['md']="Moldavian"
	['mn']="Mongolian"
	['me']="Montenegrin"
	['np']="Nepali"
	['gn']="N'Ko (AZERTY)"
	['no']="Norwegian"
	['ir']="Persian"
	['pl']="Polish"
	['pt']="Portuguese"
	['br']="Portuguese (Brazil)"
	['ro']="Romanian"
	['ru']="Russian"
	['rs']="Serbian"
	['lk']="Sinhala (phonetic)"
	['sk']="Slovak"
	['si']="Slovenian"
	['es']="Spanish"
	['latam']="Spanish (Latin American)"
	['ke']="Swahili (Kenya)"
	['tz']="Swahili (Tanzania)"
	['se']="Swedish"
	['tw']="Taiwanese"
	['tj']="Tajik"
	['th']="Thai"
	['bw']="Tswana"
	['tm']="Turkmen"
	['tr']="Turkish"
	['ua']="Ukrainian"
	['pk']="Urdu (Pakistan)"
	['uz']="Uzbek"
	['vn']="Vietnamese"
	['sn']="Wolof"
)

LANGUAGE_TOGGLERS=(
    ['grp:alt_caps_toggle']="Alt+Caps Lock"
    ['grp:caps_toggle']="Caps Lock"
    ['grp:toggle']="Right Alt"
    ['grp:lalt_toggle']="Left Alt"
    ['grp:shift_caps_toggle']="Shift+Caps Lock"
    ['grp:shifts_toggle']="Both Shifts together"
    ['grp:alts_toggle']="Both Alts together"
    ['grp:ctrls_toggle']="Both Ctrls together"
    ['grp:ctrl_shift_toggle']="Ctrl+Shift"
    ['grp:lctrl_lshift_toggle']="Left Ctrl+Left Shift"
    ['grp:rctrl_rshift_toggle']="Right Ctrl+Right Shift"
    ['grp:ctrl_alt_toggle']="Alt+Ctrl"
    ['grp:lctrl_lalt_toggle']="Left Alt+Left Ctrl"
    ['grp:rctrl_ralt_toggle']="Right Alt+Right Ctrl"
    ['grp:alt_shift_toggle']="Alt+Shift (default)"
    ['grp:lalt_lshift_toggle']="Left Alt+Left Shift"
    ['grp:ralt_rshift_toggle']="Right Alt+Right Shift"
    ['grp:win_space_toggle']="Win+Space"
    ['grp:ctrl_space_toggle']="Ctrl+Space"
    ['grp:lwin_toggle']="Left Win"
    ['grp:rwin_toggle']="Right Win"
    ['grp:lshift_toggle']="Left Shift"
    ['grp:rshift_toggle']="Right Shift"
    ['grp:lctrl_toggle']="Left Ctrl"
    ['grp:rctrl_toggle']="Right Ctrl"
    ['grp:sclk_toggle']="Scroll Lock"
    ['grp:alt_space_toggle']="Alt+Space"
)

# NOTE: For see complete list of options and layouts see this file: 
# 		/usr/share/X11/xkb/rules/base.lst

PERSIST_ANSWERS=( 
    ['No']="When you logout this changes disappear.(Recommended)" 
    ['Yes']="Write in /etc/X11/xorg.conf.d/00-keyboard.conf (Need sudo permissions)" 
)
 

function prompt() {
    # Check if there are any arguments
    if [[ $# -eq 0 ]]; then
        echo "${RED}No arguments provided.${NO_COLOR}"
        return 1
    fi

    local args=("${@}")
    local input=$(printf '%s,\t\t%s\n' "${args[@]}" | fzf --height 50% --reverse --prompt="${prompt_message}")

    local selected=$(echo $input | cut -d',' -f1)

    echo "$selected"
}

function set_variable() {
    # Check if there are any arguments
    if [[ $# -eq 0 ]]; then
        echo "${RED}No arguments provided.${NO_COLOR}"
        return 1
    fi

    if [ -n "$1"  ]; then
        echo -e "${LIGHT_BLUE}You selected: $1${NO_COLOR}"
        eval "$2='$1'"
    else
        echo "${RED}No anything selected for $2 ${NO_COLOR}"
        exit 1 
    fi
}

function set_lang_layout() {
    if [[ -n $secondary_lang && -n $lang_toggler && -n $persistent_conf ]]; then 

        if [[ $persistent_conf == "Yes" ]]; then 
            # User configs should be persistent and system-wide
            # Create backup
            if [[ -f "/etc/X11/xorg.conf.d/00-keyboard.conf" ]]; then 
                cp /etc/X11/xorg.conf.d/00-keyboard.conf ~/.cache
            fi

            localectl --no-convert set-x11-keymap "${primary_lang},${secondary_lang}" "pc105" "" "${lang_toggler}"

            if [[ $? -eq 0 ]]; then
                success_message "localectl"
            else
                failed_message "localectl"
                # if [[ -f "~/.cache/00-keyboard.conf" ]]; then
                    # echo "${RED}We have problem to change your keyboard layout.Let me to recover it... ${NO_COLOR}"
                    # sudo mv -v "~/.cache/00-keyboard.conf" "/etc/X11/xorg.conf.d/"
                # fi
            fi

        else 
            # User configs should be temporary
            setxkbmap -layout "${primary_lang},${secondary_lang}" -option "${lang_toggler}"

            if [[ $? -eq 0 ]];then 
                success_message "setxkbmap"
            else
                failed_message "setxkbmap"
            fi

        fi

    else
        echo "${RED}Your inputs is not correct.${NO_COLOR}"
        exit 1
    fi
}

function main() {
    # Set secondary language
    prompt_message="Select your secondary language (Primary language is always English): "
    local lang=$(prompt ${(@kv)LANGUAGE_LAYOUTS})
    set_variable "$lang" "secondary_lang"
    
    # Set language keyboard toggler
    prompt_message="Select your toggler key: "
    local toggler=$(prompt ${(@kv)LANGUAGE_TOGGLERS})
    set_variable "${toggler}" "lang_toggler"

    # Find is user want to configure language layouts persistent or not want temporary.
    prompt_message="Do you want to make this change as consistent and as system-wide? "
    local persist=$(prompt ${(@kv)PERSIST_ANSWERS})
    set_variable  "$persist" "persistent_conf"

    set_lang_layout
}


function success_message() {
    echo ""
    echo "${GREEN}Your new configs successfully added.${NO_COLOR}"
    echo ""
    echo "${BLUE}This is your new configuration: ${NO_COLOR}"
    echo "${YELLOW}Your secondary language is: ${secondary_lang}${NO_COLOR}"
    echo "${YELLOW}Your language toggler is: ${lang_toggler}${NO_COLOR}"
    echo "${YELLOW}Persistent configuration: ${persistent_conf}${NO_COLOR}"

    echo "${PURPLE}"
    if [[ $1 == "localectl" ]]; then 
        localectl status
    elif [[ $1 == "setxkbmap" ]]; then 
        setxkbmap -query
    fi
    echo "${NO_COLOR}"
}

function failed_message() {
    echo ""
    echo "${RED}Your new configs failure to added.${NO_COLOR}"
    echo "${PURPLE}"
    if [[ $1 == "localectl" ]]; then 
        localectl status
    elif [[ $1 == "setxkbmap" ]]; then 
        setxkbmap -query
    fi
    echo "${NO_COLOR}"
}

main 

