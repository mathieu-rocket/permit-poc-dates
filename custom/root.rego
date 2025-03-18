package permit.custom

package permit.delegation

import future.keywords.in
import future.keywords.if

# Cette fonction vérifie si la date actuelle est comprise entre DateDebut et DateFin
# Retourne true si la délégation est active, false sinon
is_delegation_active(delegation) := active {
    # Récupération de la date actuelle au format ISO8601
    current_date := time.now_ns() / 1000000000
    
    # Conversion des dates de chaîne en timestamp pour la comparaison
    date_debut := time.parse_rfc3339_ns(delegation.DateDebut) / 1000000000
    
    # Si DateFin n'est pas définie, la délégation n'expire jamais
    has_end_date := object.get(delegation, "DateFin", null) != null
    
    active := date_debut <= current_date if has_end_date == false
    
    # Si DateFin est définie, vérifier que la date actuelle est avant la date de fin
    date_fin := time.parse_rfc3339_ns(delegation.DateFin) / 1000000000 if has_end_date
    active := date_debut <= current_date && current_date <= date_fin if has_end_date
}

# Récupère toutes les délégations actives pour une entreprise donnée
active_delegations(entreprise_id) := delegations {
    delegations := [delegation |
        delegation := data.delegations[_]
        delegation.delegant.id == entreprise_id
        is_delegation_active(delegation)
    ]
}

# Récupère toutes les entreprises délégataires actives pour une entreprise donnée
active_delegataires(entreprise_id) := delegataires {
    delegataires := {delegation.delegataire.id: delegation.delegataire |
        delegation := data.delegations[_]
        delegation.delegant.id == entreprise_id
        is_delegation_active(delegation)
    }
}

# Récupère tous les rôles actifs d'un utilisateur via les délégations
# en tenant compte des dates de validité
user_delegated_roles(user_id) := roles {
    # Récupérer l'entreprise de l'utilisateur
    user := data.users[user_id]
    entreprise_id := user.entreprise.id
    
    # Obtenir les délégations dont l'entreprise est délégataire
    roles := {role |
        delegation := data.delegations[_]
        delegation.delegataire.id == entreprise_id
        is_delegation_active(delegation)
        role := delegation.roles[_]
    }
}

# Détermine si un utilisateur a un rôle spécifique via une délégation active
has_delegated_role(user_id, role) := result {
    delegated_roles := user_delegated_roles(user_id)
    result := role in delegated_roles
}

# Vérifie si un utilisateur peut accéder à une ressource via une délégation
# en fonction des rôles et des dates de validité
default allow := false

allow {
    # Extraire l'ID utilisateur et l'action demandée
    user_id := input.user.id
    action := input.action
    resource_type := input.resource.type
    resource_owner_id := input.resource.owner_id
    
    # Récupérer l'entreprise de l'utilisateur
    user := data.users[user_id]
    user_entreprise_id := user.entreprise.id
    
    # Vérifier s'il existe une délégation active entre le propriétaire de la ressource
    # et l'entreprise de l'utilisateur
    some delegation in data.delegations
    delegation.delegant.id == resource_owner_id
    delegation.delegataire.id == user_entreprise_id
    is_delegation_active(delegation)
    
    # Vérifier si un des rôles délégués permet l'action demandée
    some role in delegation.roles
    action in data.role_permissions[role].grants[resource_type]
}

# Les délégations ne sont pas récursives - une entreprise peut déléguer à une autre
# mais cette dernière ne peut pas déléguer à son tour
# Cette fonction récupère uniquement les délégations directes
get_direct_delegations(entreprise_id) := delegations {
    delegations := [delegation |
        delegation := data.delegations[_]
        delegation.delegant.id == entreprise_id
        is_delegation_active(delegation)
    ]
}
