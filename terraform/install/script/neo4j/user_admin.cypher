MERGE (
    u:User {global_entity_id: 'e25a09aa-919f-11eb-ac2b-ee9477001436-1617140144', 
    announcement_indoctestproject: 7, 
    path: 'users', 
    time_lastmodified: '2023-02-13T15:27:53.831053083', 
    role: $ROLE, 
    last_login: '2023-03-15T15:12:13.280840', 
    name: $ROLE, 
    last_name: $ROLE, 
    first_name: $ROLE, 
    email: $EMAIL, 
    username: $ROLE, 
    status: 'active'}) RETURN u;