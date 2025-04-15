package permit.generated.conditionset

import future.keywords.in

import data.permit.generated.abac.utils.attributes

default userset__5f_5fautogen_5fcompte_2dservice = false

userset__5f_5fautogen_5fcompte_2dservice {
	"compte-service" in attributes.user.roles
}
