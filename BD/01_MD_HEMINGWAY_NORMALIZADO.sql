-- DROP TABLES en orden de dependencias

drop table if exists descriptive_conclusions;
drop table if exists attendances;
drop table if exists courses_in_grade;
drop table if exists score_details;
drop table if exists competences;
drop table if exists scores;
drop table if exists students_in_grade;
drop table if exists grade_in_academic_periods;
drop table if exists academic_period_details;
drop table if exists academic_periods;
drop table if exists periods;
drop table if exists students;

drop table if exists grades;

drop table if exists courses;

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
comment on column persons.id is 'Llave primaria';
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
comment on column types.id is 'Llave primaria';
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
	quantity int,
	status bool default true,
	created_at timestamp with time zone default current_date,
	created_by int references persons(id),
	updated_at timestamp with time zone
)
with (
	oids=false
);
comment on table periods is 'Tabla de registro de periodos académicos';
comment on column periods.id is 'Llave primaria';
comment on column periods.code is 'Código del periodo';
comment on column periods.name is 'Nombre del Periodo';
comment on column periods.quantity is 'Cantidad';
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
comment on column courses.id is 'Llave primaria';
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
comment on column students.id is 'Llave primaria';
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
	status int not null references types(id),
	created_by int references persons(id),
	updated_at timestamp with time zone
)
with (
	oids=false
);
comment on table attendances is 'Tabla de registro de asistencias';
comment on column attendances.id is 'Llave primaria';
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
comment on column descriptive_conclusions.id is 'Llave primaria';
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


-- periodos academicos
create table academic_periods(
	id serial primary key,
	year int,
	period_id int not null references periods(id),
	init_date date,
	finish_date date,
	status bool default true,
	is_current bool default false,
	created_at timestamp with time zone default current_date,
	created_by int references persons(id),
	updated_at timestamp with time zone
)
with (
	oids=false
);
comment on table academic_periods is 'Tabla de registro de Periodos Academicos';
comment on column academic_periods.id is 'Llave primaria';
comment on column academic_periods.year is 'Año';
comment on column academic_periods.period_id is 'FK -> periods.id (Código de Periodo de Evaluación)';
comment on column academic_periods.init_date is 'Fecha de Inicio';
comment on column academic_periods.finish_date is 'Fecha de Fin';
comment on column academic_periods.status is 'Estado del registro (activo/inactivo)';
comment on column academic_periods.is_current is 'Periodo Academico actual';
comment on column academic_periods.created_at is 'Fecha de creación';
comment on column academic_periods.created_by is 'Persona que creó el registro (FK -> persons.id)';
comment on column academic_periods.updated_at is 'Fecha de Actualización del registro';


create table academic_period_details(
	id serial primary key,
	academic_period_id int not null references academic_periods(id),
	name varchar(500),
	order_num int default 1,
	status bool default true,
	created_at timestamp with time zone default current_date,
	created_by int references persons(id),
	updated_at timestamp with time zone
)
with (
	oids=false
);
comment on table academic_period_details is 'Tabla Detalle de registro de Detalle de Periodos Academicos';
comment on column academic_period_details.id is 'Llave primaria';
comment on column academic_period_details.academic_period_id is 'FK -> academic_periods(id)';
comment on column academic_period_details.name is 'Nombre del detalle de detalle de periodo';
comment on column academic_period_details.order_num is 'Orden';
comment on column academic_period_details.status is 'Estado del registro (activo/inactivo)';
comment on column academic_period_details.created_at is 'Fecha de creación';
comment on column academic_period_details.created_by is 'Persona que creó el registro (FK -> persons.id)';
comment on column academic_period_details.updated_at is 'Fecha de Actualización del registro';

-- grades
create table grades(
	id serial primary key,
	abbr varchar(50),
	name varchar(5000),
	status bool default true,
	created_at timestamp with time zone default current_date,
	created_by int references persons(id),
	updated_at timestamp with time zone
)
with (
	oids=false
);
comment on table grades is 'Tabla de registro de Periodos Academicos';
comment on column grades.id is 'Llave primaria';
comment on column grades.abbr is 'Abreviatura';
comment on column grades.name is 'Nombre del grado';
comment on column grades.status is 'Estado del registro (activo/inactivo)';
comment on column grades.created_at is 'Fecha de creación';
comment on column grades.created_by is 'Persona que creó el registro (FK -> persons.id)';
comment on column grades.updated_at is 'Fecha de Actualización del registro';


-- grade_in_academic_periods
create table grade_in_academic_periods(
	id serial primary key,
	academic_period_id int not null references academic_periods(id),
	grade_id int not null references grades(id),
	vacancies int,
	status bool default true,
	created_at timestamp with time zone default current_date,
	created_by int references persons(id),
	updated_at timestamp with time zone
)
with (
	oids=false
);
comment on table grade_in_academic_periods is 'Tabla de registro de Grados en Periodos Academicos';
comment on column grade_in_academic_periods.id is 'Llave primaria';
comment on column grade_in_academic_periods.academic_period_id is 'FK -> academic_periods';
comment on column grade_in_academic_periods.grade_id is 'FK -> grades';
comment on column grade_in_academic_periods.vacancies is 'Vacantes por grado';
comment on column grade_in_academic_periods.status is 'Estado del registro (activo/inactivo)';
comment on column grade_in_academic_periods.created_at is 'Fecha de creación';
comment on column grade_in_academic_periods.created_by is 'Persona que creó el registro (FK -> persons.id)';
comment on column grade_in_academic_periods.updated_at is 'Fecha de Actualización del registro';

-- courses_in_grade
create table courses_in_grade(
	id serial primary key,
	grade_in_academic_period_id int not null references grade_in_academic_periods(id),
	course_id int not null references courses(id),
	status bool default true,
	created_at timestamp with time zone default current_date,
	created_by int references persons(id),
	updated_at timestamp with time zone
)
with (
	oids=false
);
comment on table courses_in_grade is 'Tabla de registro de Cursos en Grados';
comment on column courses_in_grade.id is 'Llave primaria';
comment on column courses_in_grade.grade_in_academic_period_id is 'Codigo de Grado en Periodo Academico';
comment on column courses_in_grade.course_id is 'Codigo del Curso';
comment on column courses_in_grade.status is 'Estado del registro (activo/inactivo)';
comment on column courses_in_grade.created_at is 'Fecha de creación';
comment on column courses_in_grade.created_by is 'Persona que creó el registro (FK -> persons.id)';
comment on column courses_in_grade.updated_at is 'Fecha de Actualización del registro';

-- students_in_grade
create table students_in_grade(
	id serial primary key,
	grade_in_academic_period_id int not null references grade_in_academic_periods(id),
	student_id int not null references students(id),
	obs varchar(5000),
	status bool default true,
	created_at timestamp with time zone default current_date,
	created_by int references persons(id),
	updated_at timestamp with time zone
)
with (
	oids=false
);
comment on table students_in_grade is 'Tabla de registro de Estudiantes en Grados';
comment on column students_in_grade.id is 'Llave primaria';
comment on column students_in_grade.grade_in_academic_period_id is 'FK -> grade_in_academic_periods';
comment on column students_in_grade.student_id is 'FK -> students';
comment on column students_in_grade.obs is 'Observaciones';
comment on column students_in_grade.status is 'Estado del registro (activo/inactivo)';
comment on column students_in_grade.created_at is 'Fecha de creación';
comment on column students_in_grade.created_by is 'Persona que creó el registro (FK -> persons.id)';
comment on column students_in_grade.updated_at is 'Fecha de Actualización del registro';


-- SCORES
create table scores(
	id serial primary key,
	courses_in_grade_id int not null references courses_in_grade(id),
	academic_period_details_id int not null references academic_period_details(id),
	students_in_grade_id int not null references students_in_grade(id),
	score numeric(5,2),
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
comment on column scores.id is 'Llave primaria';
comment on column scores.courses_in_grade_id is 'FK -> courses_in_grade.id (Código del Curso en Grado de Periodo Academico)';
comment on column scores.academic_period_details_id is 'FK -> academic_period_details.id (Código del Curso en Grado de Periodo Academico)';
comment on column scores.students_in_grade_id is 'FK -> students_in_grade.id (Código del Estudiante)';
comment on column scores.score is 'Nota (0-20)';
comment on column scores.obs is 'Observaciones';
comment on column scores.status is 'Estado del registro (activo/inactivo)';
comment on column scores.created_at is 'Fecha de creación';
comment on column scores.created_by is 'Persona que creó el registro (FK -> persons.id)';
comment on column scores.updated_at is 'Fecha de Actualización del registro';

-- COMPETENCES
create table competences(
	id serial primary key,
	academic_period_details_id int not null references academic_period_details(id),
	courses_in_grade_id int not null references courses_in_grade(id),
	name varchar(500),
	description varchar(5000),
	status bool default true,
	created_at timestamp with time zone default current_date,
	created_by int references persons(id),
	updated_at timestamp with time zone
)
with (
	oids=false
);
comment on table competences is 'Tabla de registro de competencias de evaluación';
comment on column competences.id is 'Llave primaria';
comment on column competences.courses_in_grade_id is 'FK -> courses_in_grade.id';
comment on column competences.name is 'Nombre de Competencia';
comment on column competences.description is 'Descripción de Competencia';
comment on column competences.status is 'Estado del registro (activo/inactivo)';
comment on column competences.created_at is 'Fecha de creación';
comment on column competences.created_by is 'Persona que creó el registro (FK -> persons.id)';
comment on column competences.updated_at is 'Fecha de Actualización del registro';

-- score details
create table score_details(
	id serial primary key,
	score_id int not null references scores(id),
	competence_id int not null references competences(id),
	score numeric(5,2),
	obs varchar(5000),
	status bool default true,
	created_at timestamp with time zone default current_date,
	created_by int references persons(id),
	updated_at timestamp with time zone
)
with (
	oids=false
);
comment on table score_details is 'Tabla de registro de calificaciones por estudiante y periodo';
comment on column score_details.id is 'Llave primaria';
comment on column score_details.score_id is 'FK -> score.id (Código de Nota)';
comment on column score_details.score is 'Nota (0-20)';
comment on column score_details.obs is 'Observaciones';
comment on column score_details.status is 'Estado del registro (activo/inactivo)';
comment on column score_details.created_at is 'Fecha de creación';
comment on column score_details.created_by is 'Persona que creó el registro (FK -> persons.id)';
comment on column score_details.updated_at is 'Fecha de Actualización del registro';
