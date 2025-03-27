package permit.generated.conditionset

import future.keywords.in

import data.permit.generated.abac.utils.attributes

default userset_emploiee = false

userset_emploiee {
	"sad" in attributes.user.roles
}
