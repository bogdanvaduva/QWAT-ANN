-- FUNCTION: fn_prediction_year_sql(numeric, numeric, numeric, numeric, numeric, numeric)

-- DROP FUNCTION IF EXISTS fn_prediction_year_sql(numeric, numeric, numeric, numeric, numeric, numeric);

CREATE OR REPLACE FUNCTION fn_prediction_year_sql(
	var_year numeric,
	var_month numeric,
	var_material_step numeric DEFAULT 100,
	var_function_step numeric DEFAULT 10,
	var_locationtype_step numeric DEFAULT 10,
	var_pressurezone_step numeric DEFAULT 10)
    RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE str_sql TEXT DEFAULT '';
DECLARE cur_materials CURSOR FOR 
		SELECT pipe.fk_material,COUNT(*)
		FROM qwat_od.pipe
		GROUP BY pipe.fk_material
		HAVING COUNT(*)>var_material_step
		ORDER BY pipe.fk_material;
DECLARE
    cur_functions  CURSOR FOR 
		SELECT pipe.fk_function,COUNT(*)
		FROM qwat_od.pipe
		GROUP BY pipe.fk_function
		HAVING COUNT(*)>var_function_step
		ORDER BY pipe.fk_function;
DECLARE
    cur_locationtypes  CURSOR FOR 
		SELECT pipe.fk_locationtype,COUNT(*)
		FROM qwat_od.pipe
		GROUP BY pipe.fk_locationtype
		HAVING COUNT(*)>var_locationtype_step
		ORDER BY pipe.fk_locationtype;
DECLARE
    cur_pressurezones  CURSOR FOR 
		SELECT pipe.fk_pressurezone,COUNT(*)
		FROM qwat_od.pipe
		GROUP BY pipe.fk_pressurezone
		HAVING COUNT(*)>var_pressurezone_step
		ORDER BY pipe.fk_pressurezone;
DECLARE rec_ RECORD;
BEGIN
str_sql := 'SELECT pipe.id/(( SELECT qwat_od_vw_pipe_max_id.max_id FROM vw_pipe_max_id))::numeric as id,';

-----------------------
-- add material COLUMNS
-----------------------
OPEN cur_materials;
LOOP
-- fetch row into the film
  	FETCH cur_materials INTO rec_;
-- exit when no more row to fetch
  	EXIT WHEN NOT FOUND;

-- build the output
	str_sql := str_sql || 'CASE WHEN pipe.fk_material=' || rec_.fk_material || ' THEN 1 ELSE 0 END as fk_materials_' || rec_.fk_material || ',';
END LOOP;
CLOSE cur_materials;
-----------------------
-- add function COLUMNS
-----------------------
OPEN cur_functions;
LOOP
-- fetch row into the film
  	FETCH cur_functions INTO rec_;
-- exit when no more row to fetch
  	EXIT WHEN NOT FOUND;

-- build the output
	str_sql := str_sql || 'CASE WHEN pipe.fk_function=' || rec_.fk_function || ' THEN 1 ELSE 0 END as fk_functions_' || rec_.fk_function || ',';
END LOOP;
CLOSE cur_functions;
-----------------------
-- add locationtype COLUMNS
-----------------------
OPEN cur_locationtypes;
LOOP
-- fetch row into the film
  	FETCH cur_locationtypes INTO rec_;
-- exit when no more row to fetch
  	EXIT WHEN NOT FOUND;

-- build the output
	str_sql := str_sql || 'CASE WHEN COALESCE(pipe.fk_locationtype,''{101}'')=''{' || array_to_string(COALESCE(rec_.fk_locationtype,'{101}'),',') || '}''::int[] THEN 1 ELSE 0 END as fk_locationtype_' || array_to_string(COALESCE(rec_.fk_locationtype,'{101}'),'_') || ',';
END LOOP;
CLOSE cur_locationtypes;
-----------------------
-- add pressurezone COLUMNS
-----------------------
OPEN cur_pressurezones;
LOOP
-- fetch row into the film
  	FETCH cur_pressurezones INTO rec_;
-- exit when no more row to fetch
  	EXIT WHEN NOT FOUND;

-- build the output
	str_sql := str_sql || 'CASE WHEN COALESCE(pipe.fk_pressurezone,101)=' || COALESCE(rec_.fk_pressurezone,101) || ' THEN 1 ELSE 0 END as fk_pressurezones_' || COALESCE(rec_.fk_pressurezone,101) || ',';
END LOOP;
CLOSE cur_pressurezones;

str_sql := str_sql || 'replace(replace( (CASE WHEN pipe_material.diameter_nominal IS NULL THEN CASE WHEN pipe_material.diameter_external IS NULL THEN 0 ELSE pipe_material.diameter_external::smallint END ELSE pipe_material.diameter_nominal END)::text, ''"''::text, ''''::text),''''''''::text,''''::text)::numeric / ((( SELECT qwat_od_vw_pipe_max_diameter.max_diameter 
	 FROM vw_pipe_max_diameter)) * 10)::numeric(20,6) AS diameter,
	 CASE
		WHEN pipe._length2d IS NULL THEN st_length(pipe.geometry)
		ELSE pipe._length2d::double precision
	 END / (( SELECT qwat_od_vw_pipe_max_length.max_length FROM vw_pipe_max_length))::double precision AS "length",';
--str_sql := str_sql || var_year || ' as year_reference,';
--str_sql := str_sql || var_month || ' as year_month,';
str_sql := str_sql || '(extract(year from age(to_timestamp(''' || var_year || '-' || var_month || '-01''::text, ''yyyy-MM-DD''::text),
	to_timestamp(
        CASE
            WHEN pipe.year IS NULL THEN
            CASE
                WHEN upper("substring"(
                CASE
                    WHEN pipe_material.short_ro IS NULL THEN ''PE''::character varying
                    ELSE pipe_material.short_ro
                END::text, 1, 2)) = ''PE''::text THEN ''2000''::text
                ELSE ''1970''::text
            END::smallint
            ELSE pipe.year
        END::text' || '||''-01-01'', ''yyyy-MM-DD''::text)))*12 + '
		|| 'extract(month from age(to_timestamp(''' || var_year || '-' || var_month || '-01''::text, ''yyyy-MM-DD''::text),
	to_timestamp(
        CASE
            WHEN pipe.year IS NULL THEN
            CASE
                WHEN upper("substring"(
                CASE
                    WHEN pipe_material.short_ro IS NULL THEN ''PE''::character varying
                    ELSE pipe_material.short_ro
                END::text, 1, 2)) = ''PE''::text THEN ''2000''::text
                ELSE ''1970''::text
            END::smallint
            ELSE pipe.year
        END::text' || '||''-01-01'', ''yyyy-MM-DD''::text)))) / 1000::double precision AS "month_passed",';
str_sql := str_sql || 'fn_pipe_leak(pipe.id, (to_timestamp(''' || var_year || '-' || var_month || '-01''::text, ''yyyy-MM-DD''::text) - ''1 day''::interval)::timestamp without time zone)::numeric / 10::numeric AS nofp,
    fn_pipe_leak_month(pipe.id, (to_timestamp(''' || var_year || '-' || var_month || '-01''::text, ''yyyy-MM-DD''::text) + ''1 month''::interval - ''1 day''::interval)::timestamp without time zone)::numeric / 10::numeric AS nof,
	';
str_sql := str_sql || 'to_timestamp(''' || var_year || '-' || var_month || '-01''::text, ''yyyy-MM-DD''::text) AS "month_reference"';		
str_sql := str_sql || ' FROM qwat_od.pipe LEFT JOIN qwat_vl.pipe_material ON pipe.fk_material=pipe_material.id ';
str_sql := 'SELECT * FROM (' || str_sql || ') tmp_ann WHERE "month_passed">=0';
--RAISE NOTICE '%',str_sql;
RETURN str_sql;
END;
$BODY$;
