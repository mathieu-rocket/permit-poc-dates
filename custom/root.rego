package permit.custom

import data.permit.debug
import data.permit.policies

default allow := false

# You can find the official Rego tutorial at:
# https://www.openpolicyagent.org/docs/latest/policy-language/
# Example rule - you can replace this with something of your own
allow {
 	input.user.key == "martin-1d"
  print("martin-1 is in the house")
  print(policies.__allow_sources)
}
# Also, you can add more allow blocks here to get an OR effect
# allow {
#     # i.e if you add my_custom_rule here - the policy will allow
#     # if my_custom_rule is true, EVEN IF policies.allow is false.
#     my_custom_rule
# }
