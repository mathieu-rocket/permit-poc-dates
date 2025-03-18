package permit.validation_dates

import future.keywords.in

# Fonction pour convertir une chaîne de date en format numérique (AAAAMMJJ)
# Format attendu: "AAAA-MM-JJ"
convertir_date_en_numerique(chaine_date) := date_numerique {
    parties := split(chaine_date, "-")
    count(parties) == 3
    date_numerique := (to_number(parties[0]) * 10000) + (to_number(parties[1]) * 100) + to_number(parties[2])
}

# Récupérer la date du jour à partir de l'input ou utiliser une méthode alternative
date_actuelle := convertir_date_en_numerique(current_date) {
    # Si la date est fournie dans l'input
    current_date := input.context.current_date
} else := today {
    # Fallback: utiliser une date codée en dur pour le test
    # En production, vous devriez injecter la date actuelle via le contexte
    today := 20250318  # Format: AAAAMMJJ pour le 18 mars 2025
}

# Vérifier si la date actuelle est dans la période de validité de la délégation
delegation_est_valide {
    # Accéder aux données de l'instance de ressource
    instance_ressource := data.resource_instances[input.resource.key]
    
    # Vérifier s'il s'agit d'une délégation
    instance_ressource.type == "delegation"
    
    # Obtenir les dates de début et de fin depuis les attributs de la ressource
    date_debut := convertir_date_en_numerique(instance_ressource.attributes.date_debut)
    date_fin := convertir_date_en_numerique(instance_ressource.attributes.date_fin)
    
    # Vérifier si la date actuelle est dans la plage valide
    date_debut <= date_actuelle
    date_actuelle <= date_fin
}

# Vérifier si la ressource est une délégation
est_delegation {
    input.resource.type == "delegation"
}

# Vérifier si la ressource a des attributs de date
a_attributs_date {
    input.resource.attributes.date_debut
    input.resource.attributes.date_fin
}

default allow := false

# Autoriser l'accès uniquement si la délégation est valide
allow {
    delegation_est_valide
}
