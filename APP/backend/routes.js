const express = require('express');
const api = express.Router();

const MainController = require('./controller');

api.post('/:entity/by', MainController.getEntitiesBy);
api.post('/:entity/create', MainController.createEntities);
api.put('/:entity/update', MainController.updateEntities);

module.exports = api;