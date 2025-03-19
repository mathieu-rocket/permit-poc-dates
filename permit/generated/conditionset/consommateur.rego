package permit.generated.conditionset

import future.keywords.in

import data.permit.generated.abac.utils.attributes

default userset_consommateur = false

userset_consommateur {
	"agent-saisie-delegataire" in attributes.user.roles
}
