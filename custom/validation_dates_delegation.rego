package permit.validation_dates

import future.keywords.in

# Fonction pour convertir une chaîne de date en format numérique (AAAAMMJJ)
# Format attendu: "AAAA-MM-JJ"
convertir_date_en_numerique(chaine_date) := date_numerique {
    parties := split(chaine_date, "-")
    count(parties) == 3
    date_numerique := (to_number(parties[0]) * 10000) + (to_number(parties[1]) * 100) + to_number(parties[2])
}

# Obtenir la date actuelle au format numérique (AAAAMMJJ)
date_actuelle := convertir_date_en_numerique(time.format(time.now_ns(), "2006-01-02"))

# Vérifier si la date actuelle est dans la période de validité de la délégation
delegation_est_valide {
    # Accéder aux données de l'instance de ressource
    instance_ressource := data.resource_instances[input.resource.key]
    
    # Vérifier s'il s'agit d'une délégation
    instance_ressource.type == "delegation"
    
    # Obtenir les dates de début et de fin depuis les attributs de la ressource
    DateDebut := convertir_date_en_numerique(instance_ressource.attributes.DateDebut)
    DateFin := convertir_date_en_numerique(instance_ressource.attributes.DateFin)
    
    # Vérifier si la date actuelle est dans la plage valide
    DateDebut <= date_actuelle
    date_actuelle <= DateFin
}

# Vérifier si la ressource est une délégation
est_delegation {
    input.resource.type == "delegation"
}

# Vérifier si la ressource a des attributs de date
a_attributs_date {
    input.resource.attributes.DateDebut
    input.resource.attributes.DateFin
}

default permettre := false

# Autoriser l'accès uniquement si la délégation est valide
permettre {
    delegation_est_valide
}