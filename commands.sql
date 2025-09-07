
-- 1. Create a vertual environment (linux)
python -m venv dbt_venv
source ./dbt_venv/bin/activate

-- 2. install dbt core 
pip install dbt-snowflake==1.9.0

-- 3. set up a dbt project
mkdir ~/.dbt
dbt init project_name<movielens_dbt>

-- 4. check the connection
cd ./movielens_dbt
dbt debug



