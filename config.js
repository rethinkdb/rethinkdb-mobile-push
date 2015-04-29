module.exports = {
  db: {
    host: "localhost",
    port: 28015,
    db: "pushdemo"
  },
  apns: {
    key: fs.readFileSync("key.pem"),
    cert: fs.readFileSync("cert.pem"),
    passphrase: "xxxxxxxxx",
    production: false
  },
  port: 8099
}
 
