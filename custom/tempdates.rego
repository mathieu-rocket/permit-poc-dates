package package permit.tempdates

import future.keywords.in
import data.permit.policies
import data.permit.rbac

default allow := false

allow {
 	input.user.key == "mmm"
}
