package permit.generated.conditionset.rules

import future.keywords.in

import data.permit.generated.abac.utils.attributes
import data.permit.generated.abac.utils.condition_set_permissions
import data.permit.generated.conditionset

default emploiee_5fon_5fapp_5f_5f5f_5f5fautogen_5f5fapp = false

emploiee_5fon_5fapp_5f_5f5f_5f5fautogen_5f5fapp {
	conditionset.userset_emploiee
	conditionset.resourceset__5f_5fautogen_5fapp
	input.action in condition_set_permissions.emploiee.__autogen_app[input.resource.type]
}
