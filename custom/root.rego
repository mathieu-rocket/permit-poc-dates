package permit.custom

import data.permit.debug
import data.permit.policies
import future.keywords.in

default allow := false

# You can find the official Rego tutorial at:
# https://www.openpolicyagent.org/docs/latest/policy-language/
# Example rule - you can replace this with something of your own
allow {
 	input.user.key == "martin-1"
    print("est martin-1")
}

allow {
    some delegation in data.delegations
    #delegation.DelegantId == "azimut-1"
    #delegation.DelegataireId == "matane-1"
}

# Also, you can add more allow blocks here to get an OR effect
# allow {
#     # i.e if you add my_custom_rule here - the policy will allow
#     # if my_custom_rule is true, EVEN IF policies.allow is false.
#     my_custom_rule
# }
