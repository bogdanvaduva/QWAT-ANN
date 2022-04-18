# QWAT-ANN

Crontab

DROP MATERIALIZED VIEW IF EXISTS vw_prediction; SELECT fn_prediction_create_view('vw_prediction'::text, 2016, extract(year from now())::integer);
