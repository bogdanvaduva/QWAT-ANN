-- FUNCTION: fn_prediction_create_view(text, numeric, numeric)

-- DROP FUNCTION IF EXISTS fn_prediction_create_view(text, numeric, numeric);

CREATE OR REPLACE FUNCTION fn_prediction_create_view(
	view_name text,
	var_year_start numeric,
	var_year_end numeric)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
   -- appending _tmp for temp table
   _tmp text := quote_ident(view_name::text);
DECLARE strsql text;
BEGIN
-- Create the query for the new temp table
strsql := (SELECT fn_prediction_year_start_end_sql(var_year_start, var_year_end));
EXECUTE 'SET search_path TO erp,public; DROP MATERIALIZED VIEW IF EXISTS ' || _tmp || '; CREATE MATERIALIZED VIEW ' || _tmp || ' AS ' || strsql || ';';
END
$BODY$;
