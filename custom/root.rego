package permit.custom

import data.permit.validation_dates
import data.permit.rbac
import data.permit.rebac
import data.permit.abac

default allow := false

# Vérifier si les règles standards RBAC, ReBAC ou ABAC autorisent l'accès
standard_access_allowed {
    rbac.allow
} else {
    rebac.allow
} else {
    abac.allow
}

# Règle principale d'autorisation
allow {
    # Si les règles standards permettent l'accès, vérifier aussi les contraintes de date
    standard_access_allowed
    
    # Si la règle concerne une délégation ou implique des délégations dans la chaîne
    # alors vérifier que les dates sont valides
    validation_dates.permettre
}

# Autoriser l'accès normal pour les ressources qui ne sont pas des délégations
# ou qui n'impliquent pas de délégations dans la chaîne d'accès
allow {
    standard_access_allowed
    
    # Si ce n'est pas une délégation 
    not validation_dates.est_delegation
    
    # Et s'il n'y a pas de délégations dans la chaîne ou si toutes sont valides
    validation_dates.delegations_valides
}

# Informations de débogage supplémentaires
debug_info := {
    "date_actuelle": validation_dates.date_actuelle,
    "delegations_trouvees": validation_dates.debug_delegations,
    "delegations_invalides": validation_dates.delegations_invalides,
    "est_delegation_directe": validation_dates.est_delegation,
    "delegations_chain_count": count(validation_dates.delegations_in_chain)
}
