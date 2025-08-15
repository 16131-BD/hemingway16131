let express = require('express');
let cors = require('cors');
let helmet = require('helmet');

const app = express();
const host = process.env.HOST || "http://localhost";
const port = process.env.PORT || 3000;
const version = 'v1';

app.use(express.json());
app.use(express.urlencoded({extended: true}));
app.use(cors());
app.use(helmet());

app.use(`/api/${version}`, require('./routes'));

app.listen(3000, () => {
  console.log(`Servidor backend basico corriendo en ${host}:${port}`);
});
