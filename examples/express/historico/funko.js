const asyncHandler = require("express-async-handler");
const express = require("express");
const { Client } = require("pg");
const fs = require("node:fs");
const app = express();
const port = 3000;

USER = fs.readFileSync("/secrets/user", "utf8").trim(),
PASS = fs.readFileSync("/secrets/pass", "utf8").trim(),

app.get(
  "/",
  asyncHandler(async (req, res) => {
    names = req.query.names;
    if (!names) {
      res.send("No names provided");
      return;
    }
    names = names.split(",").map((n) => n.trim());

    const client = new Client({
      user: USER,
      password: PASS,
      host: "database",
      database: "nombres",
    });

    var response = [];
    response.push(["Año", ...names]);
    for (year = 1922; year < 2016; year++) {
      row = [year, ...names.map((n) => 0)];
      response.push(row);
    }

    await client.connect();
    for (const [i, name] of names.entries()) {
      console.log(i, name)
      const result = await client.query(
        "SELECT anio,contador FROM nombres where nombre = $1",
        [name]
      );
      console.log("filling response");
      for (row of result.rows) {
        response[row.anio - 1921][i + 1] = row.contador;
      }
    }
    console.log("responding");
    res.json(response);
  })
);

app.get("/ping", (req, res) => {
  res.send("OK");
});

app.use(express.static("public"));

app.listen(port, () => {
  console.log(`Example funko listening on port ${port}`);
});
