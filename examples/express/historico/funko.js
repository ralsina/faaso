const { Client } = require("pg");
const express = require("express");
const fs = require("node:fs");
const app = express();
const port = 3000;

const client = new Client({
  user: "postgres", // fs.readFileSync("/secrets/user"),
  password: "postgres", // fs.readFileSync("/secrets/pass"),
  host: "localhost",
  database: "nombres",
});

app.get("/", (req, res) => {
  client.connect().then(() => {
    client.query("SELECT * FROM nombres limit 5").then((err, result) => {
      if (err) {
        console.error(err);
      } else {
        res.send(result.rows);
      }
      client.end();
    });
  });
});

app.get("/ping", (req, res) => {
  res.send("OK");
});

app.listen(port, () => {
  console.log(`Example funko listening on port ${port}`);
});
