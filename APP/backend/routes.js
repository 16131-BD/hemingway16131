const express = require('express');
const api = express.Router();

const MainController = require('./controller');

api.post('/:entity/by', MainController.getEntitiesBy);
api.post('/:entity/create', MainController.createEntities);
api.put('/:entity/update', MainController.updateEntities);
api.post('/:entity/delete', MainController.createEntities);

module.exports = api;