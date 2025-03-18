package permit.custom

import future.keywords.in
import data.permit.policies
import data.permit.rebac
import data.permit.root

default allow := false

# Allow regular policy decisions that don't involve our custom delegation logic
allow {
    root.allow
    not has_delegation_relationship
    print("Regular policy allow - no delegation involved")
}

# Override allow decision for delegation relationships with time boundaries
allow {
    # Only intercept rebac decisions
    "rebac" in policies.__allow_sources
    
    # Get resources that involve delegations
    some filtered_resource in delegation_resources
    
    # Check if the current time is within the delegation's time boundaries
    enforce_time_boundaries(filtered_resource)
    
    print("Allowing delegated resource: ", filtered_resource)
    print("Time boundaries enforced: ", enforce_time_boundaries(filtered_resource))
}

# Check if any delegation relationship is involved in this decision
has_delegation_relationship {
    count(delegation_resources) > 0
}

# Filter resources that involve delegation relationships
delegation_resources[derived_resource] {
    print("Checking for delegation resources...")
    
    # Examine each allowing role from rebac
    some allowing_role in rebac.rebac_roles_debugger
    print("Allowing role: ", allowing_role.role)
    
    # Check role derivation sources
    some source in allowing_role.sources
    derived_resource = extract_delegation_resource(allowing_role, source)
    print("Found delegation resource: ", derived_resource)
}

# Extract the resource that has delegation relationship
extract_delegation_resource(allowing_role, source) := returned_resource {
    # For direct role assignments
    source.type == "role_assignment"
    print("Role assignment - role: ", allowing_role.role)
    
    # Check if it's one of our delegation-related roles
    is_delegation_role(allowing_role.role)
    
    returned_resource := allowing_role.resource
    print("Role assignment - returned resource: ", returned_resource)
} else := returned_resource {
    # For role derivations through relationships
    source.type == "role_derivation"
    print("Role derivation - role: ", source.role)
    
    # Check if it's one of our delegation-related roles
    is_delegation_role(source.role)
    
    returned_resource := source.resource
    print("Role derivation - returned resource: ", returned_resource)
}

# Check if the role is related to our delegation system
is_delegation_role(role) {
    endswith(role, "#delegation-agent-delegatee")
    print("Found delegation-agent-delegatee role")
} else {
    endswith(role, "#super-agent")
    print("Found super-agent role")
}

# Check if the delegation's time boundaries are enforced
enforce_time_boundaries(resource) {
    print("Enforcing time boundaries for resource: ", resource)
    
    # Extract delegation resource from the resource
    delegation_key := get_related_delegation(resource)
    print("Related delegation: ", delegation_key)
    
    # Get the delegation resource
    delegation := data.resource_instances[delegation_key]
    print("Delegation data: ", delegation)
    
    # Get current time and delegation time boundaries
    current_time := time.now_ns()
    start_date := time.parse_rfc3339_ns(delegation.attributes.DateDebut)
    end_date := time.parse_rfc3339_ns(delegation.attributes.DateFin)
    
    print("Current time: ", current_time)
    print("Start date: ", start_date)
    print("End date: ", end_date)
    
    # Check if current time is within boundaries
    current_time >= start_date
    current_time <= end_date
}

# Get the delegation related to a company resource
get_related_delegation(resource) := delegation_key {
    # Handle the case where the resource is a company as delegatee
    startswith(resource, "entreprise:")
    
    # Find delegation where this company is delegatee
    some relation, targets in data.relationships
    startswith(relation, "delegation:")
    endswith(relation, "#delegant")
    
    resource in targets
    delegation_key := trim_suffix(relation, "#delegant")
    
    print("Found delegation (company is delegatee): ", delegation_key)
} else := delegation_key {
    # Handle the case where the resource is a delegation
    startswith(resource, "delegation:")
    
    # The resource itself is the delegation
    delegation_key := resource
    print("Resource is delegation: ", delegation_key)
} else := delegation_key {
    # Handle company as delegant case
    startswith(resource, "entreprise:")
    
    # Find delegation where this company is delegant
    some relation, targets in data.relationships
    startswith(relation, "entreprise:")
    endswith(relation, "#delegataire")
    
    resource in targets
    delegation_key := trim_suffix(relation, "#delegataire")
    
    print("Found delegation (company is delegant): ", delegation_key)
}
