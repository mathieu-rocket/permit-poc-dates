package permit.custom

import future.keywords.in
import future.keywords.if
import data.permit.root as policies

# By default, deny requests
default allow := false

# Helper function to check if the current date is within the delegation period
is_delegation_active(delegation) {
    current_date := time.now_ns() / 1000000000  # Convert to seconds
    
    # Parse delegation start and end dates to unix timestamps
    date_debut := time.parse_rfc3339_ns(delegation.attributes.DateDebut) / 1000000000
    date_fin := time.parse_rfc3339_ns(delegation.attributes.DateFin) / 1000000000
    
    # Add debug trace for date verification
    print({"function": "is_delegation_active", "delegation": delegation.key, "current_date": current_date, "date_debut": date_debut, "date_fin": date_fin})
    
    # Check if current date is within the delegation period
    current_date >= date_debut
    current_date <= date_fin
}

# Check if a user has a derived role through the delegation chain
has_delegated_role(user, role, resource) {
    # Get the user's associated enterprises
    enterprise := data.resource_instances[sprintf("entreprise:%s", [user.attributes.entreprise])]
    
    # Check if the enterprise is a delegataire of any delegation
    some delegation_key, _ in data.relationships
    delegation := data.resource_instances[delegation_key]
    
    # Verify that the delegation is active
    is_delegation_active(delegation)
    
    # Check if enterprise is delegataire of this delegation
    enterprise_key := sprintf("entreprise:%s", [user.attributes.entreprise])
    relation_exists(enterprise_key, "delegataire", delegation_key)
    
    # For super-agent role, the enterprise must be delegataire of an active delegation
    role == "super-agent"
}

# Check if enterprise is delegant and user has agent-saisie-delegataire role
has_delegant_role(user, role, resource) {
    # Get the user's associated enterprise
    enterprise_key := sprintf("entreprise:%s", [user.attributes.entreprise])
    
    # Check if the enterprise is a delegant of any delegation
    some delegation_key, _ in data.relationships
    delegation := data.resource_instances[delegation_key]
    
    # Verify that the delegation is active
    is_delegation_active(delegation)
    
    # Check if enterprise is delegant of this delegation
    relation_exists(delegation_key, "delegant", enterprise_key)
    
    # For delegation-agent-delegataire role derived from agent-saisie-delegataire
    role == "delegation-agent-delegataire"
    
    # Verify user has the base role agent-saisie-delegataire
    user_has_role(user, "agent-saisie-delegataire", resource)
}

# Helper to check if relationship exists
relation_exists(source, relation_type, target) {
    relation := sprintf("%s#%s", [source, relation_type])
    target in data.relationships[relation]
}

# Helper to check if user has a specific role directly
user_has_role(user, role, resource) {
    user_roles := data.users[user.key].roleAssignments[resource.tenant]
    role in user_roles
}

# Allow access based on delegation rules
allow {
    # Allow if user has delegated super-agent role through a valid delegation
    has_delegated_role(input.user, "super-agent", input.resource)
    
    # Check if the action is allowed for the super-agent role
    input.action in data.role_permissions[input.resource.type]["super-agent"].grants[input.resource.type]
    
    # Add debug traces
    print("Custom policy - Allowing through super-agent delegated role")
    print({"user": input.user.key, "action": input.action, "resource": input.resource.type, "role": "super-agent", "reason": "time-based-delegation"})
    print(policies.__allow_sources)
}

# Allow access for users with delegation-agent-delegataire derived role
allow {
    # Allow if enterprise is delegant and user has derived role
    has_delegant_role(input.user, "delegation-agent-delegataire", input.resource)
    
    # Check if the action is allowed for the delegation-agent-delegataire role
    input.action in data.role_permissions[input.resource.type]["delegation-agent-delegataire"].grants[input.resource.type]
    
    # Add debug traces
    print("Custom policy - Allowing through delegation-agent-delegataire derived role")
    print({"user": input.user.key, "action": input.action, "resource": input.resource.type, "role": "delegation-agent-delegataire", "reason": "time-based-delegation"})
    print(policies.__allow_sources)
}

# Regular RBAC allow still works
allow {
    # Get the user's roles for the resource's tenant
    roles := data.users[input.user.key].roleAssignments[input.resource.tenant]
    
    # Check if the user has a role that allows the action on the resource type
    some role in roles
    input.action in data.role_permissions[input.resource.type][role].grants[input.resource.type]
    
    # Add debug traces
    print("Custom policy - Allowing through regular RBAC role")
    print({"user": input.user.key, "action": input.action, "resource": input.resource.type, "role": role, "reason": "standard-rbac"})
    print(policies.__allow_sources)
}
