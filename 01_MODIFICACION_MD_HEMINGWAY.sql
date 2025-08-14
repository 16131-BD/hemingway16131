-- Recréa todo (drop + create) con FKs y comentarios
drop table if exists attendances;
drop table if exists descriptive_conclusions;
drop table if exists scores;
drop table if exists students;
drop table if exists courses;
drop table if exists periods;
drop table if exists types;
drop table if exists persons;

-- PERSONS (base para createdBy y relaciones)
create table persons(
	id serial primary key,
	code varchar(25) not null,
	fatherLastName varchar(500) not null,
	motherLastName varchar(500) not null,
	names varchar(500) not null,
	gender varchar(2) not null,
	createdAt timestamp with time zone default current_date,
	createdBy int, -- quien creó este registro (puede ser otro usuario/persona)
	updatedAt timestamp with time zone
)
WITH (
  OIDS=FALSE
);
COMMENT ON TABLE persons IS 'Tabla de registro de personas';
COMMENT ON COLUMN persons.id IS 'Llave primaria de la persona';
COMMENT ON COLUMN persons.code IS 'Código de la persona';
COMMENT ON COLUMN persons.fatherLastName IS 'Apellido paterno de la persona';
COMMENT ON COLUMN persons.motherLastName IS 'Apellido maternos de la persona';
COMMENT ON COLUMN persons.names IS 'Nombres de la persona';
COMMENT ON COLUMN persons.gender IS 'Genero de la persona';
COMMENT ON COLUMN persons.createdAt IS 'Fecha de Creación de la persona';
COMMENT ON COLUMN persons.createdBy IS 'Persona que creo el registro (FK -> persons.id)';
COMMENT ON COLUMN persons.updatedAt IS 'Fecha de Actualización de la persona';

-- Types (catálogo general; referenciado por status de estudiantes/asistencias, etc.)
create table types(
	id serial primary key,
	code varchar(100),
	type varchar(100),
	name varchar(500),
	description text,
	status bool default true,
	createdAt timestamp with time zone default current_date,
	createdBy int references persons(id),
	updatedAt timestamp with time zone
)
WITH (
  OIDS=FALSE
);
COMMENT ON TABLE types IS 'Tabla de tipos (catálogo general)';
COMMENT ON COLUMN types.id IS 'Llave primaria del tipo';
COMMENT ON COLUMN types.code IS 'Código del tipo (único semántico)';
COMMENT ON COLUMN types.type IS 'Tipo';
COMMENT ON COLUMN types.name IS 'Nombre del Tipo';
COMMENT ON COLUMN types.description IS 'Descripción del tipo';
COMMENT ON COLUMN types.status IS 'Estado del tipo';
COMMENT ON COLUMN types.createdAt IS 'Fecha de Creación del tipo';
COMMENT ON COLUMN types.createdBy IS 'Persona que creo el registro (FK -> persons.id)';
COMMENT ON COLUMN types.updatedAt IS 'Fecha de Actualización del tipo';

-- PERIODS (periodos académicos)
create table periods(
	id serial primary key,
	code varchar(25),
	name varchar(500),
	durationInMonths int,
	status bool default true,
	createdAt timestamp with time zone default current_date,
	createdBy int references persons(id),
	updatedAt timestamp with time zone
)
WITH (
  OIDS=FALSE
);
COMMENT ON TABLE periods IS 'Tabla de registro de periodos academicos';
COMMENT ON COLUMN periods.id IS 'Llave primaria de periodo';
COMMENT ON COLUMN periods.code IS 'Código del periodo';
COMMENT ON COLUMN periods.name IS 'Nombre del Periodo';
COMMENT ON COLUMN periods.durationInMonths IS 'Duración en meses';
COMMENT ON COLUMN periods.status IS 'Estado del periodo';
COMMENT ON COLUMN periods.createdAt IS 'Fecha de Creación del periodo';
COMMENT ON COLUMN periods.createdBy IS 'Persona que creo el registro (FK -> persons.id)';
COMMENT ON COLUMN periods.updatedAt IS 'Fecha de Actualización del periodo';

-- COURSES
create table courses(
	id serial primary key,
	code varchar(50) not null,
	name varchar(500) not null,
	description varchar(5000),
	status bool default true,
	createdAt timestamp with time zone,
	createdBy int references persons(id),
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
COMMENT ON COLUMN courses.createdBy IS 'Persona que creo el registro (FK -> persons.id)';
COMMENT ON COLUMN courses.updatedAt IS 'Fecha de Actualización del curso';

-- STUDENTS
-- Nota: students.personId referencia persons(id).
--       students.status referencia types(id) (estado del estudiante).
create table students(
	id serial primary key,
	personId int not null references persons(id),
	status int not null references types(id),
	createdAt timestamp with time zone,
	createdBy int references persons(id),
	updatedAt timestamp with time zone
)
WITH (
  OIDS=FALSE
);
COMMENT ON TABLE students IS 'Tabla de registro de estudiantes';
COMMENT ON COLUMN students.id IS 'Llave primaria del estudiante';
COMMENT ON COLUMN students.personId IS 'FK -> persons.id (Persona asociada al estudiante)';
COMMENT ON COLUMN students.status IS 'FK -> types.id (Estado del estudiante: catálogo types)';
COMMENT ON COLUMN students.createdAt IS 'Fecha de Creación del registro estudiante';
COMMENT ON COLUMN students.createdBy IS 'Persona que creo el registro (FK -> persons.id)';
COMMENT ON COLUMN students.updatedAt IS 'Fecha de Actualización del estudiante';

-- ATTENDANCES
-- attendances.studentId -> students.id
-- attendances.status -> types.id (P.ej. registros: PUNTUAL, TARDANZA, FALTA)
create table attendances(
	id serial primary key,
	studentId int references students(id),
	createdAt timestamp with time zone,
	obs varchar(5000),
	status int,            -- FK a types.id para tipificar la asistencia (PUNTUAL/TARDE/FALTA)
	createdBy int references persons(id),
	updatedAt timestamp with time zone
)
WITH (
  OIDS=FALSE
);
COMMENT ON TABLE attendances IS 'Tabla de registro de asistencias';
COMMENT ON COLUMN attendances.id IS 'Llave primaria de la asistencia';
COMMENT ON COLUMN attendances.studentId IS 'FK -> students.id (Código del Estudiante)';
COMMENT ON COLUMN attendances.createdAt IS 'Fecha de creación del registro de asistencia';
COMMENT ON COLUMN attendances.obs IS 'Observación de asistencia';
COMMENT ON COLUMN attendances.status IS 'FK -> types.id (Estado de la Asistencia: PUNTUAL; FALTA; TARDE)';
COMMENT ON COLUMN attendances.createdBy IS 'Persona que creo el registro (FK -> persons.id)';
COMMENT ON COLUMN attendances.updatedAt IS 'Fecha de Actualización del registro';

-- DESCRIPTIVE_CONCLUSIONS (conclusiones descriptivas por estudiante y periodo)
create table descriptive_conclusions(
	id serial primary key,
	studentId int not null references students(id),
	periodId int not null references periods(id),
	score numeric(5,2),
	achievement text,
	difficulty text,
	recommedation text,
	obs varchar(5000),
	status bool default true,
	createdAt timestamp with time zone default current_date,
	createdBy int references persons(id),
	updatedAt timestamp with time zone
)
WITH (
  OIDS=FALSE
);
COMMENT ON TABLE descriptive_conclusions IS 'Tabla de conclusiones descriptivas por estudiante y periodo';
COMMENT ON COLUMN descriptive_conclusions.id IS 'Llave primaria de la conclusión descriptiva';
COMMENT ON COLUMN descriptive_conclusions.studentId IS 'FK -> students.id (Codigo del Estudiante)';
COMMENT ON COLUMN descriptive_conclusions.periodId IS 'FK -> periods.id (Codigo de Periodo de Evaluación)';
COMMENT ON COLUMN descriptive_conclusions.score IS 'Nota de Conclusión Descriptiva (0-20)';
COMMENT ON COLUMN descriptive_conclusions.achievement IS 'Descripción de Logro';
COMMENT ON COLUMN descriptive_conclusions.difficulty IS 'Descripción de Dificultad';
COMMENT ON COLUMN descriptive_conclusions.recommedation IS 'Descripción de Recomendación';
COMMENT ON COLUMN descriptive_conclusions.obs IS 'Observaciones';
COMMENT ON COLUMN descriptive_conclusions.status IS 'Estado del registro (activo/inactivo)';
COMMENT ON COLUMN descriptive_conclusions.createdAt IS 'Fecha de creación';
COMMENT ON COLUMN descriptive_conclusions.createdBy IS 'Persona que creo el registro (FK -> persons.id)';
COMMENT ON COLUMN descriptive_conclusions.updatedAt IS 'Fecha de Actualización del registro';

-- SCORES (registro de notas por estudiante y periodo)
create table scores(
	id serial primary key,
	studentId int not null references students(id),
	periodId int not null references periods(id),
	score numeric(5,2),
	achievement text,
	difficulty text,
	recommedation text,
	obs varchar(5000),
	status bool default true,
	createdAt timestamp with time zone default current_date,
	createdBy int references persons(id),
	updatedAt timestamp with time zone
)
WITH (
  OIDS=FALSE
);
COMMENT ON TABLE scores IS 'Tabla de registro de calificaciones por estudiante y periodo';
COMMENT ON COLUMN scores.id IS 'Llave primaria del registro de calificación';
COMMENT ON COLUMN scores.studentId IS 'FK -> students.id (Codigo del Estudiante)';
COMMENT ON COLUMN scores.periodId IS 'FK -> periods.id (Codigo de Periodo de Evaluación)';
COMMENT ON COLUMN scores.score IS 'Nota (0-20)';
COMMENT ON COLUMN scores.achievement IS 'Descripción de Logro';
COMMENT ON COLUMN scores.difficulty IS 'Descripción de Dificultad';
COMMENT ON COLUMN scores.recommedation IS 'Descripción de Recomendación';
COMMENT ON COLUMN scores.obs IS 'Observaciones';
COMMENT ON COLUMN scores.status IS 'Estado del registro (activo/inactivo)';
COMMENT ON COLUMN scores.createdAt IS 'Fecha de creación';
COMMENT ON COLUMN scores.createdBy IS 'Persona que creo el registro (FK -> persons.id)';
COMMENT ON COLUMN scores.updatedAt IS 'Fecha de Actualización del registro';
