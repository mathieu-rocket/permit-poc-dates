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

# Extraire les délégations des chaînes d'accès
delegations_in_chain[delegation_key] {
    # Obtenir les rôles actifs pour l'utilisateur
    some role_key in rebac.allowing_roles
    
    # Récupérer les infos de debug
    debug_info := rebac.rebac_roles_debugger[role_key]
    
    # Directement chercher des resources de type délégation dans tout l'arbre
    resource := extract_delegation_resources(debug_info)[_]
    delegation_key := trim_prefix(resource, "delegation:")
}

# Extrait toutes les ressources de délégation d'un nœud et de ses enfants sans récursivité directe
extract_delegation_resources(node) := result {
    # Récupère les ressources du nœud actuel
    current := [node.resource | startswith(node.resource, "delegation:")]
    
    # Si le nœud n'a pas de sources, on retourne juste les ressources actuelles
    not node.sources
    result := current
} else := result {
    # Si le nœud a des sources, on collecte les délégations des sources
    children_sources := node.sources
    
    # On extrait les ressources de chaque source individuellement
    child_results := [child_delegations |
        child := children_sources[i]
        
        # On vérifie si la ressource de l'enfant est une délégation
        child_current := [child.resource | startswith(child.resource, "delegation:")]
        
        # On vérifie si l'enfant a des sous-sources
        child_has_sources := child.sources != null
        
        # On extrait les délégations des sous-sources
        child_subsources := [sub_resource |
            child_has_sources
            sub := child.sources[j]
            startswith(sub.resource, "delegation:")
            sub_resource := sub.resource
        ]
        
        # On combine les résultats
        child_delegations := array.concat(child_current, child_subsources)
    ]
    
    # On aplatit tous les résultats
    flat_children := array.concat(current, child_results[_])
    result := flat_children
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
