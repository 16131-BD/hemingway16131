drop table if exists periods;
create table periods(
	id serial primary key,
	code varchar(25),
	name varchar(500),
	durationInMonths int,
	status bool default true,
	createdAt timestamp with time zone default current_date,
	createdBy int,
	updatedAt timestamp with time zone
)
WITH (
  OIDS=FALSE
);
COMMENT ON TABLE periods IS 'Tabla de registro de periodos academicos';
COMMENT ON COLUMN periods.id IS 'Llave primaria de periodo';
COMMENT ON COLUMN periods.name IS 'Nombre del Periodo';
COMMENT ON COLUMN periods.durationInMonths IS 'Duración en meses';
COMMENT ON COLUMN periods.status IS 'Estado del periodo';
COMMENT ON COLUMN periods.createdAt IS 'Fecha de Creación de la persona';
COMMENT ON COLUMN periods.createdBy IS 'Persona que creo el registro';
COMMENT ON COLUMN periods.updatedAt IS 'Fecha de Actualización de la persona';

-- TABLA DE CONFIGURACIÓN DE PERIODOS ACADEMICOS

drop table if exists types;
create table types(
	id serial primary key,
	code varchar(100),
	type varchar(100),
	name varchar(500),
	description text,
	status bool default true,
	createdAt timestamp with time zone default current_date,
	createdBy int,
	updatedAt timestamp with time zone
)
WITH (
  OIDS=FALSE
);
COMMENT ON TABLE types IS 'Tabla de tipos';
COMMENT ON COLUMN types.id IS 'Llave primaria del tipo';
COMMENT ON COLUMN types.code IS 'Código del tipo';
COMMENT ON COLUMN types.type IS 'Tipo';
COMMENT ON COLUMN types.name IS 'Nombre del Tipo';
COMMENT ON COLUMN types.description IS 'Descripción del tipo';
COMMENT ON COLUMN types.status IS 'Estado del periodo';
COMMENT ON COLUMN types.createdAt IS 'Fecha de Creación de la persona';
COMMENT ON COLUMN types.createdBy IS 'Persona que creo el registro';
COMMENT ON COLUMN types.updatedAt IS 'Fecha de Actualización de la persona';

drop table if exists persons;
create table persons(
	id serial primary key,
	code varchar(25) not null,
	fatherLastName varchar(500) not null,
	motherLastName varchar(500) not null,
	names varchar(500) not null,
	gender varchar(2) not null,
	createdAt timestamp with time zone default current_date,
	createdBy int,
	updatedAt timestamp with time zone
)
WITH (
  OIDS=FALSE
);
COMMENT ON TABLE persons IS 'Tabla de registro de personas';
COMMENT ON COLUMN persons.id IS 'Llave primaria de la persona';
COMMENT ON COLUMN persons.fatherLastName IS 'Apellido paterno de la persona';
COMMENT ON COLUMN persons.motherLastName IS 'Apellido maternos de la persona';
COMMENT ON COLUMN persons.gender IS 'Genero de la persona';
COMMENT ON COLUMN persons.createdAt IS 'Fecha de Creación de la persona';
COMMENT ON COLUMN persons.createdBy IS 'Persona que creo el registro';
COMMENT ON COLUMN persons.updatedAt IS 'Fecha de Actualización de la persona';

-- falta table detalle de correo y direcciones (p1 - c1, p1 -c2, p1 - c3, p1 - d1, p1 - d2...)

drop table if exists students;
create table students(
	id serial primary key,
	personId int not null,
	status varchar(2) not null,
	createdAt timestamp with time zone,
	createdBy int,
	updatedAt timestamp with time zone
)
WITH (
  OIDS=FALSE
);
COMMENT ON TABLE students IS 'Tabla de registro de estudiantes';
COMMENT ON COLUMN students.id IS 'Llave primaria del estudiante';
COMMENT ON COLUMN students.personId IS 'Llave primaria de la persona';
COMMENT ON COLUMN students.status IS 'Estado del estudiante: Tabla Types';
COMMENT ON COLUMN students.createdAt IS 'Fecha de Creación de la persona';
COMMENT ON COLUMN students.createdBy IS 'Persona que creo el registro';
COMMENT ON COLUMN students.updatedAt IS 'Fecha de Actualización de la persona';


drop table if exists courses;
create table courses(
	id serial primary key,
	code varchar(50) not null,
	name varchar(500) not null,
	description varchar(5000),
	status bool default true,
	createdAt timestamp with time zone,
	createdBy int,
	updatedAt timestamp with time zone
)
WITH (
  OIDS=FALSE
);
COMMENT ON TABLE courses IS 'Tabla de registro de cursos';
COMMENT ON COLUMN courses.id IS 'Llave primaria del curso';
COMMENT ON COLUMN courses.code IS 'Código del curso';
COMMENT ON COLUMN courses.name IS 'Nombre del curso';
COMMENT ON COLUMN courses.description IS 'Descripción del curso';
COMMENT ON COLUMN courses.status IS 'Estado del curso: 1 -> Activo; 0 - Inactivo';
COMMENT ON COLUMN courses.createdAt IS 'Fecha de Creación del curso';
COMMENT ON COLUMN courses.createdBy IS 'Persona que creo el registro';
COMMENT ON COLUMN courses.updatedAt IS 'Fecha de Actualización del curso';

drop table if exists attendances;
create table attendances(
	id serial primary key,
	studentId int,
	createdAt timestamp with time zone,
	obs varchar(5000),
	status varchar(2),
	createdBy int,
	updatedAt timestamp with time zone
)
WITH (
  OIDS=FALSE
);
COMMENT ON TABLE attendances IS 'Tabla de registro de cursos';
COMMENT ON COLUMN attendances.id IS 'Llave primaria del curso';
COMMENT ON COLUMN attendances.studentId IS 'Código del Estudiante';
COMMENT ON COLUMN attendances.createdAt IS 'Fecha de Creación del curso';
COMMENT ON COLUMN attendances.obs IS 'Observación de asistencia';
COMMENT ON COLUMN attendances.status IS 'Estado de la Asistencia: PUNTUAL; FALTA, TARDE';
COMMENT ON COLUMN attendances.createdBy IS 'Persona que creo el registro';
COMMENT ON COLUMN attendances.updatedAt IS 'Fecha de Actualización del curso';

drop table if exists descriptive_conclusions;
create table descriptive_conclusions(
	id serial primary key,
	studentId int not null,
	periodId int not null,
	score numeric(2,2),
	achievement text,
	difficulty text,
	recommedation text,
	obs varchar(5000),
	status bool default true,
	createdAt timestamp with time zone default current_date,
	createdBy int,
	updatedAt timestamp with time zone
)
WITH (
  OIDS=FALSE
);
COMMENT ON TABLE descriptive_conclusions IS 'Tabla de registro de cursos';
COMMENT ON COLUMN descriptive_conclusions.id IS 'Llave primaria del curso';
COMMENT ON COLUMN descriptive_conclusions.studentId IS 'Codigo del Estudiante';
COMMENT ON COLUMN descriptive_conclusions.periodId IS 'Codigo de Periodo de Evaluación';
COMMENT ON COLUMN descriptive_conclusions.score IS 'Nota de Conclusión Descriptiva';
COMMENT ON COLUMN descriptive_conclusions.achievement IS 'Descripción de Logro';
COMMENT ON COLUMN descriptive_conclusions.difficulty IS 'Descripción de Dificultad';
COMMENT ON COLUMN descriptive_conclusions.recommedation IS 'Descripción de Recomendación';
COMMENT ON COLUMN descriptive_conclusions.obs IS 'Observaciones';
COMMENT ON COLUMN descriptive_conclusions.status IS 'Estado de la Asistencia: PUNTUAL; FALTA, TARDE';
COMMENT ON COLUMN descriptive_conclusions.createdAt IS 'Fecha de creación';
COMMENT ON COLUMN descriptive_conclusions.createdBy IS 'Persona que creo el registro';
COMMENT ON COLUMN descriptive_conclusions.updatedAt IS 'Fecha de Actualización del curso';

drop table if exists scores;
create table scores(
	id serial primary key,
	studentId int not null,
	periodId int not null,
	score numeric(2,2),
	achievement text,
	difficulty text,
	recommedation text,
	obs varchar(5000),
	status bool default true,
	createdAt timestamp with time zone default current_date,
	createdBy int,
	updatedAt timestamp with time zone
)
WITH (
  OIDS=FALSE
);
COMMENT ON TABLE scores IS 'Tabla de registro de cursos';
COMMENT ON COLUMN scores.id IS 'Llave primaria del curso';
COMMENT ON COLUMN scores.studentId IS 'Codigo del Estudiante';
COMMENT ON COLUMN scores.periodId IS 'Codigo de Periodo de Evaluación';
COMMENT ON COLUMN scores.score IS 'Nota de Conclusión Descriptiva';
COMMENT ON COLUMN scores.achievement IS 'Descripción de Logro';
COMMENT ON COLUMN scores.difficulty IS 'Descripción de Dificultad';
COMMENT ON COLUMN scores.recommedation IS 'Descripción de Recomendación';
COMMENT ON COLUMN scores.obs IS 'Observaciones';
COMMENT ON COLUMN scores.status IS 'Estado de la Asistencia: PUNTUAL; FALTA, TARDE';
COMMENT ON COLUMN scores.createdAt IS 'Fecha de creación';
COMMENT ON COLUMN scores.createdBy IS 'Persona que creo el registro';
COMMENT ON COLUMN scores.updatedAt IS 'Fecha de Actualización del curso';