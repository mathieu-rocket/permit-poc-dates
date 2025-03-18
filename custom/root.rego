package permit.custom
import data.permit.validation_dates
default allow := false


# Inclure la règle de validation des dates pour les délégations
allow {
    # Si c'est une délégation, vérifier la validité des dates
    validation_dates.est_delegation
    validation_dates.permettre
}

# Règle permettant l'accès normal pour les ressources qui ne sont pas des délégations
# ou qui n'ont pas d'attributs de date
allow {
    not validation_dates.est_delegation
    not validation_dates.a_attributs_date
}

# You can find the official Rego tutorial at:
# https://www.openpolicyagent.org/docs/latest/policy-language/
# Example rule - you can replace this with something of your own
# allow {
# 	input.user.key == "test@permit.io"
# }
# Also, you can add more allow blocks here to get an OR effect
# allow {
#     # i.e if you add my_custom_rule here - the policy will allow
#     # if my_custom_rule is true, EVEN IF policies.allow is false.
#     my_custom_rule
# }
