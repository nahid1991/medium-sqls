select operators.id,
       concat(users.first_name, ' ', users.last_name) as operator_name,
       users.email
from operators
       join users on users.id = operators.user_id
group by operators.id, concat(users.first_name, ' ', users.last_name), users.email
order by operators.id;