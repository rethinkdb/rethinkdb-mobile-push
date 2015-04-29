var express = require("express");
var bodyParser = require("body-parser");
var apn = require("apn");
var fs = require("fs");
var r = require("rethinkdb");

var config = require("./config");

var app = express();
app.use(bodyParser.json());

app.listen(config.port);
console.log("Server started on port " + config.port);
var apnConnection = new apn.Connection(config.apns);

function findNearby(location) {
  return r.table("users").getIntersecting(
    r.circle(location, 100, {unit: "mi"}), {index: "place"});
}

var conn;
r.connect(config.db).then(function(c) {
  conn = c;
  return r.dbCreate(config.db.db).run(conn);
})
.then(function() {
  return r.tableCreate("users").run(conn);
})
.error(function(err) {
  if (err.msg.indexOf("already exists") == -1)
    console.log(err);
})
.finally(function() {
  r.connect(config.db).then(function(conn) {
    return r.table("users").changes().run(conn);
  })
  .then(function(change) {
    change.each(function(err, item) {
      if (!item.new_val) return;
      findNearby(item.new_val.place).run(conn).then(function(users) {
        users.each(function(err, user) {
          if (user.id === item.new_val.id) return;

          var note = new apn.Notification();
          note.sound = "ping.aiff";
          note.alert = "A user checked in nearby";
          note.payload = item.new_val.place;

          apnConnection.pushNotification(note, new apn.Device(user.id));
        });
      });
    });
  });
});

app.get("/api/pins", function(req, res) {
  var place = req.query.place.split(",");

  r.connect(config.db).then(function(conn) {
    return findNearby([+place[1], +place[0]])("place").run(conn)
      .finally(function() { conn.close(); });
  })
  .then(function(cursor) { return cursor.toArray(); })
  .then(function(output) { res.json(output); });
});

app.post("/api/checkin", function(req,res) {
  var token = req.body.token.replace(/[<> ]/g, "");
  var place = r.point(req.body.place[1], req.body.place[0]);

  r.connect(config.db).then(function(conn) {
    return r.table("users").insert({id: token, place: place, time: r.now()},
      {conflict: "update"}).run(conn)
    .finally(function() { conn.close(); });
  })
  .then(function(output) {
    res.json({success: true});
  });
});
