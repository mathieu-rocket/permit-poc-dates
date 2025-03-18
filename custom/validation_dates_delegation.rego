package permit.validation_dates

import future.keywords.in
import data.permit.rebac as rebac

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

# Vérifier si une délégation spécifique est valide en fonction de ses dates
delegation_est_valide(delegation_key) {
    # Accéder aux données de l'instance de ressource
    instance_ressource := data.resource_instances[delegation_key]
    
    # Vérifier s'il s'agit d'une délégation
    instance_ressource.type == "delegation"
    
    # Obtenir les dates de début et de fin depuis les attributs de la ressource
    date_debut := convertir_date_en_numerique(instance_ressource.attributes.DateDebut)
    date_fin := convertir_date_en_numerique(instance_ressource.attributes.DateFin)
    
    # Vérifier si la date actuelle est dans la plage valide
    date_debut <= date_actuelle
    date_actuelle <= date_fin
}

# Vérifier si la ressource demandée est une délégation
est_delegation {
    input.resource.type == "delegation"
}

# Vérifier si la ressource a des attributs de date
a_attributs_date {
    input.resource.attributes.DateDebut
    input.resource.attributes.DateFin
}

# Vérifier si l'accès est accordé via une chaîne de délégation
delegation_dans_chaine {
    # Obtenir les rôles actifs pour l'utilisateur courant sur la ressource
    some role_key in rebac.allowing_roles
    
    # Récupérer les informations de debug pour analyser la chaîne
    debug_info := rebac.rebac_roles_debugger[role_key]
    
    # Parcourir la chaîne de sources pour trouver les délégations
    delegation_dans_sources(debug_info)
}

# Fonction récursive pour vérifier si les délégations dans la chaîne sont valides
delegation_dans_sources(source_info) {
    # Si la ressource est une délégation, vérifier sa validité
    startswith(source_info.resource, "delegation:")
    
    # Extraire l'identifiant de la délégation
    delegation_key := trim_prefix(source_info.resource, "delegation:")
    
    # Vérifier que cette délégation est valide selon ses dates
    delegation_est_valide(delegation_key)
} else {
    # Vérifier récursivement dans les sources
    some source in source_info.sources
    delegation_dans_sources(source)
}

# Règle principale pour permettre l'accès
permettre {
    # Si la ressource demandée est directement une délégation
    est_delegation
    delegation_est_valide(input.resource.key)
} else {
    # Si l'accès est accordé via une chaîne contenant une délégation
    not est_delegation
    delegation_dans_chaine
}

default allow := false

# Autoriser l'accès uniquement si la délégation est valide
allow {
    permettre
}
