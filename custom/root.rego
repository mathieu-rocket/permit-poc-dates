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
# ou qui n'ont pas d'attributs de date et qui sont autorisées par les règles standards
allow {
    standard_access_allowed
    
    # Si ce n'est pas une délégation et qu'il n'y a pas de délégation dans la chaîne,
    # alors autoriser normalement
    not validation_dates.est_delegation
    not validation_dates.delegation_dans_chaine
}
