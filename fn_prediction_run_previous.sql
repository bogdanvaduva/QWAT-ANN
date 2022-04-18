-- FUNCTION: fn_prediction_run_previous(refcursor, numeric, numeric)

-- DROP FUNCTION IF EXISTS fn_prediction_run_previous(refcursor, numeric, numeric);

CREATE OR REPLACE FUNCTION fn_prediction_run_previous(
	query_name refcursor,
	var_year_start numeric,
	var_year_end numeric)
    RETURNS refcursor
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE strsql text;
BEGIN
-- Create the query for the new temp table
strsql := (SELECT fn_prediction_year_start_end_sql(var_year_start, var_year_end));
RAISE NOTICE 'sql %', strsql;
OPEN query_name for execute strsql;
RETURN query_name;
END
$BODY$;
