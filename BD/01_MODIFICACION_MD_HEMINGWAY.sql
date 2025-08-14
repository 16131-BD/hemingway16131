-- DROP TABLES en orden de dependencias
drop table if exists attendances;
drop table if exists descriptive_conclusions;
drop table if exists scores;
drop table if exists students;
drop table if exists courses;
drop table if exists periods;
drop table if exists types;
drop table if exists persons;

-- PERSONS
create table persons(
	id serial primary key,
	code varchar(25) not null,
	father_last_name varchar(500) not null,
	mother_last_name varchar(500) not null,
	names varchar(500) not null,
	gender varchar(2) not null,
	created_at timestamp with time zone default current_date,
	created_by int references persons(id),
	updated_at timestamp with time zone
)
with (
	oids=false
);
comment on table persons is 'Tabla de registro de personas';
comment on column persons.id is 'Llave primaria de la persona';
comment on column persons.code is 'Código de la persona';
comment on column persons.father_last_name is 'Apellido paterno de la persona';
comment on column persons.mother_last_name is 'Apellido materno de la persona';
comment on column persons.names is 'Nombres de la persona';
comment on column persons.gender is 'Género de la persona';
comment on column persons.created_at is 'Fecha de Creación de la persona';
comment on column persons.created_by is 'Persona que creó el registro (FK -> persons.id)';
comment on column persons.updated_at is 'Fecha de Actualización de la persona';

-- TYPES
create table types(
	id serial primary key,
	code varchar(100),
	type varchar(100),
	name varchar(500),
	description text,
	status bool default true,
	created_at timestamp with time zone default current_date,
	created_by int references persons(id),
	updated_at timestamp with time zone
)
with (
	oids=false
);
comment on table types is 'Tabla de tipos (catálogo general)';
comment on column types.id is 'Llave primaria del tipo';
comment on column types.code is 'Código del tipo (único semántico)';
comment on column types.type is 'Tipo';
comment on column types.name is 'Nombre del Tipo';
comment on column types.description is 'Descripción del tipo';
comment on column types.status is 'Estado del tipo';
comment on column types.created_at is 'Fecha de Creación del tipo';
comment on column types.created_by is 'Persona que creó el registro (FK -> persons.id)';
comment on column types.updated_at is 'Fecha de Actualización del tipo';

-- PERIODS
create table periods(
	id serial primary key,
	code varchar(25),
	name varchar(500),
	duration_in_months int,
	status bool default true,
	created_at timestamp with time zone default current_date,
	created_by int references persons(id),
	updated_at timestamp with time zone
)
with (
	oids=false
);
comment on table periods is 'Tabla de registro de periodos académicos';
comment on column periods.id is 'Llave primaria de periodo';
comment on column periods.code is 'Código del periodo';
comment on column periods.name is 'Nombre del Periodo';
comment on column periods.duration_in_months is 'Duración en meses';
comment on column periods.status is 'Estado del periodo';
comment on column periods.created_at is 'Fecha de Creación del periodo';
comment on column periods.created_by is 'Persona que creó el registro (FK -> persons.id)';
comment on column periods.updated_at is 'Fecha de Actualización del periodo';

-- COURSES
create table courses(
	id serial primary key,
	code varchar(50) not null,
	name varchar(500) not null,
	description varchar(5000),
	status bool default true,
	created_at timestamp with time zone,
	created_by int references persons(id),
	updated_at timestamp with time zone
)
with (
	oids=false
);
comment on table courses is 'Tabla de registro de cursos';
comment on column courses.id is 'Llave primaria del curso';
comment on column courses.code is 'Código del curso';
comment on column courses.name is 'Nombre del curso';
comment on column courses.description is 'Descripción del curso';
comment on column courses.status is 'Estado del curso: 1 -> Activo; 0 - Inactivo';
comment on column courses.created_at is 'Fecha de Creación del curso';
comment on column courses.created_by is 'Persona que creó el registro (FK -> persons.id)';
comment on column courses.updated_at is 'Fecha de Actualización del curso';

-- STUDENTS
create table students(
	id serial primary key,
	person_id int not null references persons(id),
	status int not null references types(id),
	created_at timestamp with time zone,
	created_by int references persons(id),
	updated_at timestamp with time zone
)
with (
	oids=false
);
comment on table students is 'Tabla de registro de estudiantes';
comment on column students.id is 'Llave primaria del estudiante';
comment on column students.person_id is 'FK -> persons.id (Persona asociada al estudiante)';
comment on column students.status is 'FK -> types.id (Estado del estudiante: catálogo types)';
comment on column students.created_at is 'Fecha de Creación del registro estudiante';
comment on column students.created_by is 'Persona que creó el registro (FK -> persons.id)';
comment on column students.updated_at is 'Fecha de Actualización del estudiante';

-- ATTENDANCES
create table attendances(
	id serial primary key,
	student_id int references students(id),
	created_at timestamp with time zone,
	obs varchar(5000),
	status int,
	created_by int references persons(id),
	updated_at timestamp with time zone
)
with (
	oids=false
);
comment on table attendances is 'Tabla de registro de asistencias';
comment on column attendances.id is 'Llave primaria de la asistencia';
comment on column attendances.student_id is 'FK -> students.id (Código del Estudiante)';
comment on column attendances.created_at is 'Fecha de creación del registro de asistencia';
comment on column attendances.obs is 'Observación de asistencia';
comment on column attendances.status is 'FK -> types.id (Estado de la Asistencia: PUNTUAL; FALTA; TARDE)';
comment on column attendances.created_by is 'Persona que creó el registro (FK -> persons.id)';
comment on column attendances.updated_at is 'Fecha de Actualización del registro';

-- DESCRIPTIVE_CONCLUSIONS
create table descriptive_conclusions(
	id serial primary key,
	student_id int not null references students(id),
	period_id int not null references periods(id),
	score numeric(5,2),
	achievement text,
	difficulty text,
	recommedation text,
	obs varchar(5000),
	status bool default true,
	created_at timestamp with time zone default current_date,
	created_by int references persons(id),
	updated_at timestamp with time zone
)
with (
	oids=false
);
comment on table descriptive_conclusions is 'Tabla de conclusiones descriptivas por estudiante y periodo';
comment on column descriptive_conclusions.id is 'Llave primaria de la conclusión descriptiva';
comment on column descriptive_conclusions.student_id is 'FK -> students.id (Código del Estudiante)';
comment on column descriptive_conclusions.period_id is 'FK -> periods.id (Código de Periodo de Evaluación)';
comment on column descriptive_conclusions.score is 'Nota de Conclusión Descriptiva (0-20)';
comment on column descriptive_conclusions.achievement is 'Descripción de Logro';
comment on column descriptive_conclusions.difficulty is 'Descripción de Dificultad';
comment on column descriptive_conclusions.recommedation is 'Descripción de Recomendación';
comment on column descriptive_conclusions.obs is 'Observaciones';
comment on column descriptive_conclusions.status is 'Estado del registro (activo/inactivo)';
comment on column descriptive_conclusions.created_at is 'Fecha de creación';
comment on column descriptive_conclusions.created_by is 'Persona que creó el registro (FK -> persons.id)';
comment on column descriptive_conclusions.updated_at is 'Fecha de Actualización del registro';

-- SCORES
create table scores(
	id serial primary key,
	student_id int not null references students(id),
	period_id int not null references periods(id),
	score numeric(5,2),
	achievement text,
	difficulty text,
	recommedation text,
	obs varchar(5000),
	status bool default true,
	created_at timestamp with time zone default current_date,
	created_by int references persons(id),
	updated_at timestamp with time zone
)
with (
	oids=false
);
comment on table scores is 'Tabla de registro de calificaciones por estudiante y periodo';
comment on column scores.id is 'Llave primaria del registro de calificación';
comment on column scores.student_id is 'FK -> students.id (Código del Estudiante)';
comment on column scores.period_id is 'FK -> periods.id (Código de Periodo de Evaluación)';
comment on column scores.score is 'Nota (0-20)';
comment on column scores.achievement is 'Descripción de Logro';
comment on column scores.difficulty is 'Descripción de Dificultad';
comment on column scores.recommedation is 'Descripción de Recomendación';
comment on column scores.obs is 'Observaciones';
comment on column scores.status is 'Estado del registro (activo/inactivo)';
comment on column scores.created_at is 'Fecha de creación';
comment on column scores.created_by is 'Persona que creó el registro (FK -> persons.id)';
comment on column scores.updated_at is 'Fecha de Actualización del registro';
