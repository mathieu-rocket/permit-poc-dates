package permit.generated.conditionset.rules

import future.keywords.in

import data.permit.generated.abac.utils.attributes
import data.permit.generated.abac.utils.condition_set_permissions
import data.permit.generated.conditionset

default emploiee_5fon_5fdelegation_5f_5f5f_5f5fautogen_5f5fdelegation = false

emploiee_5fon_5fdelegation_5f_5f5f_5f5fautogen_5f5fdelegation {
	conditionset.userset_emploiee
	conditionset.resourceset__5f_5fautogen_5fdelegation
	input.action in condition_set_permissions.emploiee.__autogen_delegation[input.resource.type]
}
