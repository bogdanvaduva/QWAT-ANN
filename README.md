# QWAT-ANN

Crontab

DROP MATERIALIZED VIEW IF EXISTS vw_prediction; SELECT fn_prediction_create_view('vw_prediction'::text, %start_year%, extract(year from now())::integer);
