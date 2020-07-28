# Cardilogs

- Start the server: `./app.rb`
- Send some records of an ECG: `curl -F "data=@spec/data/records.csv" -F "starts_at=2020-07-28" http://127.0.0.1:4567/delineation`
