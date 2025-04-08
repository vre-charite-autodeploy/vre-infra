CREATE DATABASE ${db_name};
CREATE USER ${db_user} WITH PASSWORD '${db_password}';
GRANT ALL PRIVILEGES ON DATABASE ${db_name} TO ${db_user};

\c ${db_name}
GRANT ALL ON SCHEMA public TO ${db_user};
GRANT ALL ON ALL TABLES IN SCHEMA public TO ${db_user};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${db_user};
ALTER SCHEMA public OWNER TO ${db_user};

%{ for schema in schemas ~}
CREATE SCHEMA ${schema} AUTHORIZATION ${db_user};
GRANT ALL ON SCHEMA ${schema} TO ${db_user};
ALTER DEFAULT PRIVILEGES IN SCHEMA ${schema} GRANT ALL ON TABLES TO ${db_user};
%{ endfor ~}