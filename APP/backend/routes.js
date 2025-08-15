const express = require('express');
const api = express.Router();

const MainController = require('./controller');

api.post('/students-by', MainController.getStudentsBy);
api.post('/students-create', MainController.createStudents);

module.exports = api;