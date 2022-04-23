# QWAT-ANN

Crontab

DROP MATERIALIZED VIEW IF EXISTS vw_prediction; SELECT fn_prediction_create_view('vw_prediction'::text, %start_year%, extract(year from now())::integer);

In the example below the red dots at the end of the video represents predictions and the green area what happend for the predicted period. The highest value it is around the green area!

TensorFlow JS was used to build the online tool that you see running. For desktop integration you can use TensorFlow (Python)!

![Example of how it's used in an application](https://github.com/bogdanvaduva/QWAT-ANN/blob/main/prediction.gif)

