-- FUNCTION: fn_prediction_year_start_end_sql(numeric, numeric)

-- DROP FUNCTION IF EXISTS fn_prediction_year_start_end_sql(numeric, numeric);

CREATE OR REPLACE FUNCTION fn_prediction_year_start_end_sql(
	var_year_start numeric,
	var_year_end numeric)
    RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE str_sql TEXT DEFAULT '';
DECLARE counter_year NUMERIC := var_year_start ; 
DECLARE counter_month NUMERIC := 1 ; 
BEGIN
WHILE counter_year <= var_year_end LOOP
	counter_month := 1;
	WHILE counter_month <= 12 LOOP
		IF str_sql != '' AND to_timestamp(counter_year||'-'||counter_month||'-01','yyyy-MM-DD'::text)<NOW() THEN
			str_sql := str_sql || ' UNION ';
		END IF;
		if to_timestamp(counter_year||'-'||counter_month||'-01','yyyy-MM-DD'::text)<NOW() then
			str_sql := str_sql || (select fn_prediction_year_sql(counter_year,counter_month));
		end if;
		counter_month := counter_month + 1;
	END LOOP;
	counter_year := counter_year + 1 ; 
END LOOP ; 
RETURN str_sql;
END;
$BODY$;
