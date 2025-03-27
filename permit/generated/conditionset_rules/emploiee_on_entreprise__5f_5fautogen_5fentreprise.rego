package permit.generated.conditionset.rules

import future.keywords.in

import data.permit.generated.abac.utils.attributes
import data.permit.generated.abac.utils.condition_set_permissions
import data.permit.generated.conditionset

default emploiee_5fon_5fentreprise_5f_5f5f_5f5fautogen_5f5fentreprise = false

emploiee_5fon_5fentreprise_5f_5f5f_5f5fautogen_5f5fentreprise {
	conditionset.userset_emploiee
	conditionset.resourceset__5f_5fautogen_5fentreprise
	input.action in condition_set_permissions.emploiee.__autogen_entreprise[input.resource.type]
}
