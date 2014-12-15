rem curl -XPUT "http://localhost:9200/sports/" -d @athlete-mappings.json;
curl -XPOST "http://localhost:9200/sports/_bulk" --data-binary @athlete-data.json
