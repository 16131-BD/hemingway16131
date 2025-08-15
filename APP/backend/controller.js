const prisma = require('./database');
const ApiResponse = require('./models');

// METODOS

StudentList = (filter) => new Promise( async (resolve, rejected) => {
  try {
    let result = await prisma.$queryRaw`SELECT * FROM public.fx_sel_students(${JSON.stringify(filter)}::jsonb)`;
    resolve(result);
  } catch (error) {
    rejected({ error: true, message: `Hubo un error: ${error}`});
  }
});

NewStudent = (data) => new Promise(async (resolve, rejected) => {
  try {
    let result = await prisma.$queryRaw`SELECT * FROM public.fx_ins_students(${JSON.stringify(data)}::jsonb)`;
    if (result.fx_ins_students) {
      resolve({message: "Proceso realizado correctamente"});
    } else {
      rejected({ error: true, message: `No se registro el usuario: ${result.fx_ins_students}`});  
    }
  } catch (error) {
    rejected({ error: true, message: `Hubo un error: ${error}`});
  }
})

// Controladores

getStudentsBy = async (req, res) => {
  try {
    let students = await StudentList(req.body.filter || {});
    if (students.error) {
      res.status(200),json(ApiResponse.errorResponse(students.message));
    }
    res.status(200).json(ApiResponse.successResponse(students));
  } catch (error) {
    res.status(200).json(ApiResponse.errorResponse(error.toString()));
  }
}

createStudents = async (req, res) => {
  try {
    if (!req.body.news) {
      res.status(200),json(ApiResponse.errorResponse("No se inserta ningun usuario"));
      return;
    }
    let students = await NewStudent(req.body.news);
    if (students.error) {
      res.status(200),json(ApiResponse.errorResponse(students.message));
    }
    res.status(200).json(ApiResponse.successResponse(students));
  } catch (error) {
    res.status(200).json(ApiResponse.errorResponse(error.toString()));
  }
}

module.exports = {
  getStudentsBy,
  createStudents
}