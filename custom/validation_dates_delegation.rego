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

# Extraire toutes les ressources de délégation dans la chaîne d'accès
delegations_in_chain[delegation_key] {
    # Obtenir les rôles actifs pour l'utilisateur courant sur la ressource
    some role_key in rebac.allowing_roles
    
    # Récupérer les informations de debug pour analyser la chaîne
    debug_info := rebac.rebac_roles_debugger[role_key]
    
    # Chercher les ressources de délégation dans les sources
    delegation_resource := find_delegations(debug_info)[_]
    
    # Extraire la clé de délégation
    delegation_key := trim_prefix(delegation_resource, "delegation:")
}

# Trouver toutes les ressources de délégation dans l'arbre de sources
find_delegations(node) := result {
    # Initialiser avec la ressource actuelle si c'est une délégation
    current := [node.resource | startswith(node.resource, "delegation:")]
    
    # Collecter les délégations des sources enfants
    children := [delegation |
        node.sources != null
        child := node.sources[_]
        delegation := find_delegations(child)[_]
    ]
    
    # Combiner les résultats actuels et des enfants
    result := array.concat(current, children)
}

# Vérifier si toutes les délégations dans la chaîne sont valides
delegations_valides {
    count(delegations_in_chain) == 0
} else {
    # Pour chaque délégation trouvée, vérifier sa validité
    delegations_invalides := [key | 
        key := delegations_in_chain[_]
        not delegation_est_valide(key)
    ]
    
    count(delegations_invalides) == 0
}

# Information de débogage sur les délégations trouvées
debug_delegations[delegation_key] := info {
    delegation_key := delegations_in_chain[_]
    instance := data.resource_instances[delegation_key]
    info := {
        "key": delegation_key,
        "type": instance.type,
        "date_debut": instance.attributes.DateDebut,
        "date_fin": instance.attributes.DateFin,
        "valide": delegation_est_valide(delegation_key),
        "date_actuelle_num": date_actuelle,
        "date_debut_num": convertir_date_en_numerique(instance.attributes.DateDebut),
        "date_fin_num": convertir_date_en_numerique(instance.attributes.DateFin)
    }
}

# Liste des délégations invalides pour le débogage
delegations_invalides[delegation_key] {
    delegation_key := delegations_in_chain[_]
    not delegation_est_valide(delegation_key)
}

# Règle principale pour permettre l'accès
permettre {
    # Si la ressource demandée est directement une délégation
    est_delegation
    delegation_est_valide(input.resource.key)
} else {
    # Si l'accès est accordé via une chaîne de délégations
    not est_delegation
    delegations_valides
}

default allow := false

# Autoriser l'accès uniquement si la délégation est valide
allow {
    permettre
}
