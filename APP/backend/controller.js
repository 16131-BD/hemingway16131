const prisma = require('./database');
const ApiResponse = require('./models');

let functions = {
  'POST': {
    // SELECTS
    'students/by': 'fx_sel_students',
    'attendances/by': 'fx_sel_attendances', 
    'descriptive_conclusions/by': 'fx_sel_descriptive_conclusions', 
    'scores/by': 'fx_sel_scores', 
    'courses/by': 'fx_sel_courses', 
    'periods/by': 'fx_sel_periods', 
    'types/by': 'fx_sel_types', 
    'persons/by': 'fx_sel_persons',
    // POSTS
    'students/create': 'fx_ins_students',
    'attendances/create': 'fx_ins_attendances', 
    'descriptive_conclusions/create': 'fx_ins_descriptive_conclusions', 
    'scores/create': 'fx_ins_scores', 
    'courses/create': 'fx_ins_courses', 
    'periods/create': 'fx_ins_periods', 
    'types/create': 'fx_ins_types', 
    'persons/create': 'fx_ins_persons', 
  },
  'PUT': {
    // ACTUALIZACIONES
    'students/update': 'fx_upd_students',
    'attendances/update': 'fx_upd_attendances', 
    'descriptive_conclusions/update': 'fx_upd_descriptive_conclusions', 
    'scores/update': 'fx_upd_scores', 
    'courses/update': 'fx_upd_courses', 
    'periods/update': 'fx_upd_periods', 
    'types/update': 'fx_upd_types', 
    'persons/update': 'fx_upd_persons', 
  }
}


// ===== METODOS GENERICOS =====
ListEntity = (fnName, filter) => new Promise(async (resolve, rejected) => {
  try {
    let result = await prisma.$queryRawUnsafe(`SELECT * FROM public.${fnName}('${JSON.stringify(filter)}'::jsonb)`);
    resolve(result);
  } catch (error) {
    rejected({ error: true, message: `Hubo un error: ${error}` });
  }
});

NewEntity = (fnName, data) => new Promise(async (resolve, rejected) => {
  try {
    let result = await prisma.$queryRawUnsafe(`SELECT * FROM public.${fnName}('${JSON.stringify(data)}'::jsonb)`);
    if (result[0] && Object.values(result[0])[0]) {
      resolve(result);
    } else {
      rejected({ error: true, message: `No se pudo registrar: ${JSON.stringify(result)}` });
    }
  } catch (error) {
    rejected({ error: true, message: `Hubo un error: ${error}` });
  }
});

AlterEntity = (fnName, data) => new Promise(async (resolve, rejected) => {
  try {
    let result = await prisma.$queryRawUnsafe(`SELECT * FROM public.${fnName}('${JSON.stringify(data)}'::jsonb)`);
    if (result[0] && Object.values(result[0])[0]) {
      resolve({ message: "Proceso realizado correctamente" });
    } else {
      rejected({ error: true, message: `No se pudo actualizar: ${JSON.stringify(result)}` });
    }
  } catch (error) {
    rejected({ error: true, message: `Hubo un error: ${error}` });
  }
});

// Controladores

getEntitiesBy = async (req, res) => {
  try {
    let partUrl = req.url.substring(1);
    let fnName = functions[req.method][partUrl];
    let entities = await ListEntity(fnName, req.body.filter || {});
    // let entities = await StudentList(req.body.filter || {});
    if (entities.error) {
      res.status(200),json(ApiResponse.errorResponse(entities.message));
    }
    res.status(200).json(ApiResponse.successResponse(entities));
  } catch (error) {
    res.status(200).json(ApiResponse.errorResponse(error.toString()));
  }
}

createEntities = async (req, res) => {
  try {
    if (!req.body.news) {
      res.status(200),json(ApiResponse.errorResponse("No se inserta ningun usuario"));
      return;
    }
    let partUrl = req.url.substring(1);
    let fnName = functions[req.method][partUrl];
    let entities = await NewEntity(fnName, req.body.news);
    if (entities.error) {
      res.status(200),json(ApiResponse.errorResponse(entities.message));
    }
    res.status(200).json(ApiResponse.successResponse(entities));
  } catch (error) {
    res.status(200).json(ApiResponse.errorResponse(error.toString()));
  }
}

updateEntities = async (req, res) => {
  try {
    if (!req.body.updateds) {
      res.status(200),json(ApiResponse.errorResponse("No se inserta ningun usuario"));
      return;
    }
    console.log(req.method);
    console.log(req.url);
    let partUrl = req.url.substring(1);
    let fnName = functions[req.method][partUrl];
    let entities = await AlterEntity(fnName, req.body.updateds);
    if (entities.error) {
      res.status(200),json(ApiResponse.errorResponse(entities.message));
    }
    res.status(200).json(ApiResponse.successResponse(entities));
  } catch (error) {
    res.status(200).json(ApiResponse.errorResponse(error.toString()));
  }
}

module.exports = {
  getEntitiesBy,
  createEntities,
  updateEntities
}