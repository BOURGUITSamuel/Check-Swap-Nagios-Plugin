#!/bin/bash

# Fonction pour convertir les seuils en MB
convert_to_mb() {
    local threshold="$1"
    local unit="${threshold: -2}" # Extrait les deux derniers caractères (par ex. GB ou MB)
    local value="${threshold:0: -2}" # Extrait la valeur sans l'unité

    if [[ $unit == "GB" ]]; then
        echo $(echo "$value * 1024" | bc) # Convertit GB en MB
    else
        echo $value # Seuil déjà en MB
    fi
}

# Fonction pour convertir les valeurs en GB
convert_to_gb() {
    local value="$1"
    local gb_value=$(awk "BEGIN { printf \"%.2f\", $value / 1024 }") # Convertit MB en GB avec deux décimales
    echo $gb_value
}

# Fonction pour afficher les instructions d'utilisation
usage_instructions() {
    echo "Ce script permet de vérifier l'utilisation de l'espace swap sur un système Linux."
    echo "Il prend deux arguments :"
    echo "   1. Seuil de WARNING (en GB ou MB)"
    echo "   2. Seuil de CRITICAL (en GB ou MB)"
    echo ""
    echo "Utilisation :"
    echo "   $0 <seuil_warning GB/MB> <seuil_critical GB/MB>"
    echo ""
    echo "Exemples :"
    echo "   $0 200MB 2GB : Vérifie si l'utilisation de l'espace swap est au-dessus de 200MB en WARNING et 2GB en CRITICAL."
    echo ""
}

# Fonction pour vérifier l'utilisation correcte du script
check_usage() {
    # Vérifie si le nombre d'arguments est différent de 2
    if [ "$#" -ne 2 ]; then
        usage_instructions
        exit 1
    fi
}

# Fonction pour vérifier l'utilisation de l'espace swap
check_used_swap() {
    local used_swap_pourcentage=$(free -t | awk 'FNR == 3 {print $3/$2*100}' | awk '{printf("%.2f", $1)}')
    local used_swap=$(free -m | awk 'NR==3' | awk '{ print $3 }')
    local free_swap=$(free -m | awk 'NR==3' |  awk '{ print $4 }')
    local total_swap=$(free -m | awk 'NR==3' |  awk '{ print $2 }')

    local warning_mb=$(convert_to_mb "$warning_threshold")
    local critical_mb=$(convert_to_mb "$critical_threshold")
    
    used_swap_gb=$(convert_to_gb "$used_swap")
    free_swap_gb=$(convert_to_gb "$free_swap")
    total_swap_gb=$(convert_to_gb "$total_swap")

    if (( $(echo "$used_swap >= $warning_mb" | bc -l) && $(echo "$used_swap < $critical_mb" | bc -l) )); then
        echo "WARNING - Utilisation du Swap : ${used_swap_pourcentage}% : Taille : ${total_swap_gb}GB - Utilisé : ${used_swap_gb}GB - Libre : ${free_swap_gb}GB"
        exit 1  # Code de sortie Nagios : Warning
    elif (( $(echo "$used_swap >= $critical_mb" | bc -l) )); then
        echo "CRITICAL - Utilisation du Swap : ${used_swap_pourcentage}% : Taille : ${total_swap_gb}GB - Utilisé : ${used_swap_gb}GB - Libre : ${free_swap_gb}GB"
        exit 2  # Code de sortie Nagios : Critical
    else
        echo "OK - Utilisation du Swap : ${used_swap_pourcentage}% : Taille : ${total_swap_gb}GB - Utilisé : ${used_swap_gb}GB - Libre : ${free_swap_gb}GB"
        exit 0  # Code de sortie Nagios : OK
    fi
}

# Vérifie l'utilisation du script
check_usage "$@"

# Récupération des seuils fournit par l'utilisateur 
warning_threshold="$1"
critical_threshold="$2"

check_used_swap "$warning_threshold" "$critical_threshold"

exit 0
