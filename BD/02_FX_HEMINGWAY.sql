DROP FUNCTION IF EXISTS public.fx_ins_persons(JSONB);
CREATE FUNCTION public.fx_ins_persons(JSONB)
    RETURNS BOOLEAN
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- 1. Crear tabla temporal para recibir los datos del JSONB
    DROP TABLE IF EXISTS tmp_persons;
    CREATE TEMPORARY TABLE tmp_persons AS
    SELECT 
        x.code,
        x.father_last_name,
        x.mother_last_name,
        x.names,
        x.gender,
        x.created_at,
        x.created_by,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x( 
        code              VARCHAR(25),
        father_last_name  VARCHAR(500),
        mother_last_name  VARCHAR(500),
        names             VARCHAR(500),
        gender            VARCHAR(2),
        created_at        TIMESTAMP WITH TIME ZONE,
        created_by        INT,
        updated_at        TIMESTAMP WITH TIME ZONE
    );

    -- 2. Insertar en tabla persons
    INSERT INTO persons(
        code,
        father_last_name,
        mother_last_name,
        names,
        gender,
        created_at,
        created_by,
        updated_at
    )
    SELECT  
        UPPER(TRIM(code)),
        UPPER(TRIM(father_last_name)),
        UPPER(TRIM(mother_last_name)),
        INITCAP(TRIM(names)),
        UPPER(TRIM(gender)),
        COALESCE(created_at, CURRENT_TIMESTAMP),
        created_by,
        updated_at
    FROM tmp_persons;

    RETURN TRUE;

END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

COMMENT ON FUNCTION public.fx_ins_persons(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Insertar nuevo registro en persons
* ESCRITO POR : 16131-BD - Developers
* FECHA CREACIÓN : 2025.08.14
* SISTEMA / MODULO : PRINCIPAL / Personas
* MODIFICACIONES :
* FECHA   RESPONSABLE  DESCRIPCIÓN DEL CAMBIO
*
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_ins_persons(
*     ''[{"code":"P001","father_last_name":"Perez","mother_last_name":"Lopez","names":"Juan Carlos",
*        "gender":"M","created_by":1}]''
* );
***************************************************************************************************/';


DROP FUNCTION IF EXISTS public.fx_upd_persons(JSONB);
CREATE FUNCTION public.fx_upd_persons(JSONB)
    RETURNS BOOLEAN
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- 1) Cargar datos a una tabla temporal desde el JSONB
    DROP TABLE IF EXISTS tmp_persons_upd;
    CREATE TEMPORARY TABLE tmp_persons_upd AS
    SELECT 
        x.id,
        x.code,
        x.father_last_name,
        x.mother_last_name,
        x.names,
        x.gender,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x(
        id                INT,
        code              VARCHAR(25),
        father_last_name  VARCHAR(500),
        mother_last_name  VARCHAR(500),
        names             VARCHAR(500),
        gender            VARCHAR(2),
        updated_at        TIMESTAMP WITH TIME ZONE
    );

    -- 2) Actualizar persons (solo columnas provistas; COALESCE conserva valor actual si viene NULL)
    UPDATE persons p
    SET
        code            = COALESCE(UPPER(TRIM(t.code)), p.code),
        father_last_name = COALESCE(UPPER(TRIM(t.father_last_name)), p.father_last_name),
        mother_last_name = COALESCE(UPPER(TRIM(t.mother_last_name)), p.mother_last_name),
        names           = COALESCE(INITCAP(TRIM(t.names)), p.names),
        gender          = COALESCE(UPPER(TRIM(t.gender)), p.gender),
        updated_at      = COALESCE(t.updated_at, CURRENT_TIMESTAMP)
    FROM tmp_persons_upd t
    WHERE p.id = t.id;

    RETURN TRUE;
END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

COMMENT ON FUNCTION public.fx_upd_persons(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Actualizar registro(s) en persons (actualización parcial por campos)
* ESCRITO POR : Jorge Mayo
* EMAIL/MOVIL/PHONE : [tu email/teléfono]
* FECHA CREACIÓN : 2025.08.14
* SISTEMA / MODULO : [Sistema] / Personas
* MODIFICACIONES :
* FECHA   RESPONSABLE  DESCRIPCIÓN DEL CAMBIO
*
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_upd_persons(
*   ''[
*      {"id":1, "names":"Juan Carlos", "updated_at":"2025-08-14T10:00:00Z"},
*      {"id":2, "code":"P002N","father_last_name":"Ramirez","mother_last_name":"Soto","gender":"F"}
*   ]''
* );
***************************************************************************************************/';

-- TABLA TIPOS

DROP FUNCTION IF EXISTS public.fx_ins_types(JSONB);
CREATE FUNCTION public.fx_ins_types(JSONB)
    RETURNS BOOLEAN
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- Crear tabla temporal desde el JSONB
    DROP TABLE IF EXISTS tmp_types;
    CREATE TEMPORARY TABLE tmp_types AS
    SELECT 
        x.code,
        x.type,
        x.name,
        x.description,
        x.status,
        x.created_at,
        x.created_by,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x( 
        code         VARCHAR(100),
        type         VARCHAR(100),
        name         VARCHAR(500),
        description  TEXT,
        status       BOOLEAN,
        created_at   TIMESTAMP WITH TIME ZONE,
        created_by   INT,
        updated_at   TIMESTAMP WITH TIME ZONE
    );

    -- Insertar en tabla types
    INSERT INTO types(
        code,
        type,
        name,
        description,
        status,
        created_at,
        created_by,
        updated_at
    )
    SELECT  
        UPPER(TRIM(code)),
        UPPER(TRIM(type)),
        INITCAP(TRIM(name)),
        description,
        COALESCE(status, TRUE),
        COALESCE(created_at, CURRENT_TIMESTAMP),
        created_by,
        updated_at
    FROM tmp_types;

    RETURN TRUE;
END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

ALTER FUNCTION public.fx_ins_types(JSONB) OWNER TO rgensoftia;
GRANT EXECUTE ON FUNCTION public.fx_ins_types(JSONB) TO rgensoftia;
REVOKE ALL ON FUNCTION public.fx_ins_types(JSONB) FROM public;

COMMENT ON FUNCTION public.fx_ins_types(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Insertar nuevo registro en types
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.14
* SISTEMA / MODULO : [Sistema] / Catálogos
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_ins_types(
*     ''[{"code":"ALUM_ACT","type":"ESTUDIANTE","name":"Activo","description":"Estudiante activo","status":true,"created_by":1}]''
* );
***************************************************************************************************/';


DROP FUNCTION IF EXISTS public.fx_upd_types(JSONB);
CREATE FUNCTION public.fx_upd_types(JSONB)
    RETURNS BOOLEAN
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- Cargar datos en tabla temporal
    DROP TABLE IF EXISTS tmp_types_upd;
    CREATE TEMPORARY TABLE tmp_types_upd AS
    SELECT 
        x.id,
        x.code,
        x.type,
        x.name,
        x.description,
        x.status,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x(
        id           INT,
        code         VARCHAR(100),
        type         VARCHAR(100),
        name         VARCHAR(500),
        description  TEXT,
        status       BOOLEAN,
        updated_at   TIMESTAMP WITH TIME ZONE
    );

    -- Actualizar tabla types
    UPDATE types t
    SET
        code         = COALESCE(UPPER(TRIM(u.code)), t.code),
        type         = COALESCE(UPPER(TRIM(u.type)), t.type),
        name         = COALESCE(INITCAP(TRIM(u.name)), t.name),
        description  = COALESCE(u.description, t.description),
        status       = COALESCE(u.status, t.status),
        updated_at  = COALESCE(u.updated_at, CURRENT_TIMESTAMP)
    FROM tmp_types_upd u
    WHERE t.id = u.id;

    RETURN TRUE;
END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

ALTER FUNCTION public.fx_upd_types(JSONB) OWNER TO rgensoftia;
GRANT EXECUTE ON FUNCTION public.fx_upd_types(JSONB) TO rgensoftia;
REVOKE ALL ON FUNCTION public.fx_upd_types(JSONB) FROM public;

COMMENT ON FUNCTION public.fx_upd_types(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Actualizar registro(s) en types (actualización parcial)
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.14
* SISTEMA / MODULO : [Sistema] / Catálogos
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_upd_types(
*   ''[
*      {"id":1,"name":"Inactivo","status":false},
*      {"id":2,"description":"Modificado por proceso"}
*   ]''
* );
***************************************************************************************************/';

-- TABLA PERIODOS

DROP FUNCTION IF EXISTS public.fx_ins_periods(JSONB);
CREATE FUNCTION public.fx_ins_periods(JSONB)
    RETURNS BOOLEAN
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- Crear tabla temporal desde el JSONB
    DROP TABLE IF EXISTS tmp_periods;
    CREATE TEMPORARY TABLE tmp_periods AS
    SELECT 
        x.period_code,
        x.period_name,
        x.start_date,
        x.end_date,
        x.status,
        x.created_at,
        x.created_by,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x( 
        period_code   VARCHAR(50),
        period_name   VARCHAR(100),
        start_date    DATE,
        end_date      DATE,
        status        BOOLEAN,
        created_at    TIMESTAMP WITH TIME ZONE,
        created_by    INT,
        updated_at    TIMESTAMP WITH TIME ZONE
    );

    -- Insertar en tabla periods
    INSERT INTO periods(
        period_code,
        period_name,
        start_date,
        end_date,
        status,
        created_at,
        created_by,
        updated_at
    )
    SELECT  
        UPPER(TRIM(period_code)),
        INITCAP(TRIM(period_name)),
        start_date,
        end_date,
        COALESCE(status, TRUE),
        COALESCE(created_at, CURRENT_TIMESTAMP),
        created_by,
        updated_at
    FROM tmp_periods;

    RETURN TRUE;
END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

ALTER FUNCTION public.fx_ins_periods(JSONB) OWNER TO rgensoftia;
GRANT EXECUTE ON FUNCTION public.fx_ins_periods(JSONB) TO rgensoftia;
REVOKE ALL ON FUNCTION public.fx_ins_periods(JSONB) FROM public;

COMMENT ON FUNCTION public.fx_ins_periods(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Insertar nuevo registro en periods
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.14
* SISTEMA / MODULO : [Sistema] / Catálogos
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_ins_periods(
*     ''[{"period_code":"2025A","period_name":"Periodo Académico 2025A","start_date":"2025-01-15","end_date":"2025-06-30","created_by":1}]''
* );
***************************************************************************************************/';


DROP FUNCTION IF EXISTS public.fx_upd_periods(JSONB);
CREATE FUNCTION public.fx_upd_periods(JSONB)
    RETURNS BOOLEAN
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- Cargar datos en tabla temporal
    DROP TABLE IF EXISTS tmp_periods_upd;
    CREATE TEMPORARY TABLE tmp_periods_upd AS
    SELECT 
        x.id,
        x.period_code,
        x.period_name,
        x.start_date,
        x.end_date,
        x.status,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x(
        id            INT,
        period_code   VARCHAR(50),
        period_name   VARCHAR(100),
        start_date    DATE,
        end_date      DATE,
        status        BOOLEAN,
        updated_at    TIMESTAMP WITH TIME ZONE
    );

    -- Actualizar tabla periods
    UPDATE periods t
    SET
        period_code  = COALESCE(UPPER(TRIM(u.period_code)), t.period_code),
        period_name  = COALESCE(INITCAP(TRIM(u.period_name)), t.period_name),
        start_date   = COALESCE(u.start_date, t.start_date),
        end_date     = COALESCE(u.end_date, t.end_date),
        status       = COALESCE(u.status, t.status),
        updated_at  = COALESCE(u.updated_at, CURRENT_TIMESTAMP)
    FROM tmp_periods_upd u
    WHERE t.id = u.id;

    RETURN TRUE;
END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

ALTER FUNCTION public.fx_upd_periods(JSONB) OWNER TO rgensoftia;
GRANT EXECUTE ON FUNCTION public.fx_upd_periods(JSONB) TO rgensoftia;
REVOKE ALL ON FUNCTION public.fx_upd_periods(JSONB) FROM public;

COMMENT ON FUNCTION public.fx_upd_periods(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Actualizar registro(s) en periods (actualización parcial)
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.14
* SISTEMA / MODULO : [Sistema] / Catálogos
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_upd_periods(
*   ''[
*      {"id":1,"period_name":"Periodo 2025A Modificado","status":false},
*      {"id":2,"end_date":"2025-07-15"}
*   ]''
* );
***************************************************************************************************/';

-- TABLA CURSOS

-- ============================================
-- INSERTAR REGISTRO EN COURSES
-- ============================================
DROP FUNCTION IF EXISTS public.fx_ins_courses(JSONB);
CREATE FUNCTION public.fx_ins_courses(JSONB)
    RETURNS BOOLEAN
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- Crear tabla temporal desde el JSONB
    DROP TABLE IF EXISTS tmp_courses;
    CREATE TEMPORARY TABLE tmp_courses AS
    SELECT 
        x.code,
        x.name,
        x.description,
        x.status,
        x.created_at,
        x.created_by,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x( 
        code         VARCHAR(50),
        name         VARCHAR(500),
        description  VARCHAR(5000),
        status       BOOLEAN,
        created_at   TIMESTAMP WITH TIME ZONE,
        created_by   INT,
        updated_at   TIMESTAMP WITH TIME ZONE
    );

    -- Insertar en tabla courses
    INSERT INTO courses(
        code,
        name,
        description,
        status,
        created_at,
        created_by,
        updated_at
    )
    SELECT  
        UPPER(TRIM(code)),
        INITCAP(TRIM(name)),
        description,
        COALESCE(status, TRUE),
        COALESCE(created_at, CURRENT_TIMESTAMP),
        created_by,
        updated_at
    FROM tmp_courses;

    RETURN TRUE;
END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

ALTER FUNCTION public.fx_ins_courses(JSONB) OWNER TO rgensoftia;
GRANT EXECUTE ON FUNCTION public.fx_ins_courses(JSONB) TO rgensoftia;
REVOKE ALL ON FUNCTION public.fx_ins_courses(JSONB) FROM public;

COMMENT ON FUNCTION public.fx_ins_courses(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Insertar nuevo registro en courses
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.14
* SISTEMA / MODULO : [Sistema] / Académico
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_ins_courses(
*     ''[{"code":"MAT101","name":"Matemáticas Básicas","description":"Curso introductorio de matemáticas","status":true,"created_by":1}]''
* );
***************************************************************************************************/';

-- ============================================
-- ACTUALIZAR REGISTRO EN COURSES
-- ============================================
DROP FUNCTION IF EXISTS public.fx_upd_courses(JSONB);
CREATE FUNCTION public.fx_upd_courses(JSONB)
    RETURNS BOOLEAN
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- Crear tabla temporal desde el JSONB
    DROP TABLE IF EXISTS tmp_courses_upd;
    CREATE TEMPORARY TABLE tmp_courses_upd AS
    SELECT 
        x.id,
        x.code,
        x.name,
        x.description,
        x.status,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x(
        id           INT,
        code         VARCHAR(50),
        name         VARCHAR(500),
        description  VARCHAR(5000),
        status       BOOLEAN,
        updated_at   TIMESTAMP WITH TIME ZONE
    );

    -- Actualizar en tabla courses
    UPDATE courses c
    SET
        code        = COALESCE(UPPER(TRIM(u.code)), c.code),
        name        = COALESCE(INITCAP(TRIM(u.name)), c.name),
        description = COALESCE(u.description, c.description),
        status      = COALESCE(u.status, c.status),
        updated_at  = COALESCE(u.updated_at, CURRENT_TIMESTAMP)
    FROM tmp_courses_upd u
    WHERE c.id = u.id;

    RETURN TRUE;
END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

ALTER FUNCTION public.fx_upd_courses(JSONB) OWNER TO rgensoftia;
GRANT EXECUTE ON FUNCTION public.fx_upd_courses(JSONB) TO rgensoftia;
REVOKE ALL ON FUNCTION public.fx_upd_courses(JSONB) FROM public;

COMMENT ON FUNCTION public.fx_upd_courses(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Actualizar registro(s) en courses (actualización parcial)
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.14
* SISTEMA / MODULO : [Sistema] / Académico
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_upd_courses(
*   ''[
*      {"id":1,"name":"Matemáticas Avanzadas","status":true},
*      {"id":2,"description":"Curso modificado"}
*   ]''
* );
***************************************************************************************************/';

-- TABLA ESTUDIANTES

DROP FUNCTION IF EXISTS public.fx_ins_students(JSONB);
CREATE FUNCTION public.fx_ins_students(JSONB)
    RETURNS BOOLEAN
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- Crear tabla temporal desde JSONB
    DROP TABLE IF EXISTS tmp_students;
    CREATE TEMPORARY TABLE tmp_students AS
    SELECT 
        x.person_id,
        x.status,
        x.created_at,
        x.created_by,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x( 
        person_id   INT,
        status      INT,
        created_at  TIMESTAMP WITH TIME ZONE,
        created_by  INT,
        updated_at  TIMESTAMP WITH TIME ZONE
    );

    -- Insertar en students
    INSERT INTO students(
        person_id,
        status,
        created_at,
        created_by,
        updated_at
    )
    SELECT  
        person_id,
        status,
        COALESCE(created_at, CURRENT_TIMESTAMP),
        created_by,
        updated_at
    FROM tmp_students;

    RETURN TRUE;
END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

ALTER FUNCTION public.fx_ins_students(JSONB) OWNER TO rgensoftia;
GRANT EXECUTE ON FUNCTION public.fx_ins_students(JSONB) TO rgensoftia;
REVOKE ALL ON FUNCTION public.fx_ins_students(JSONB) FROM public;

COMMENT ON FUNCTION public.fx_ins_students(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Insertar nuevo registro en students
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.14
* SISTEMA / MODULO : [Sistema] / Estudiantes
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_ins_students(
*     ''[
*         {"person_id":1,"status":2,"created_by":1}
*     ]''
* );
***************************************************************************************************/';


DROP FUNCTION IF EXISTS public.fx_upd_students(JSONB);
CREATE FUNCTION public.fx_upd_students(JSONB)
    RETURNS BOOLEAN
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- Crear tabla temporal desde JSONB
    DROP TABLE IF EXISTS tmp_students_upd;
    CREATE TEMPORARY TABLE tmp_students_upd AS
    SELECT 
        x.id,
        x.person_id,
        x.status,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x(
        id          INT,
        person_id   INT,
        status      INT,
        updated_at  TIMESTAMP WITH TIME ZONE
    );

    -- Actualizar students
    UPDATE students s
    SET
        person_id  = COALESCE(u.person_id, s.person_id),
        status     = COALESCE(u.status, s.status),
        updated_at = COALESCE(u.updated_at, CURRENT_TIMESTAMP)
    FROM tmp_students_upd u
    WHERE s.id = u.id;

    RETURN TRUE;
END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

ALTER FUNCTION public.fx_upd_students(JSONB) OWNER TO rgensoftia;
GRANT EXECUTE ON FUNCTION public.fx_upd_students(JSONB) TO rgensoftia;
REVOKE ALL ON FUNCTION public.fx_upd_students(JSONB) FROM public;

COMMENT ON FUNCTION public.fx_upd_students(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Actualizar registro(s) en students (actualización parcial)
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.14
* SISTEMA / MODULO : [Sistema] / Estudiantes
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_upd_students(
*   ''[
*      {"id":1,"status":3},
*      {"id":2,"person_id":5}
*   ]''
* );
***************************************************************************************************/';

-- ATTENDANCES

DROP FUNCTION IF EXISTS public.fx_ins_attendances(JSONB);
CREATE FUNCTION public.fx_ins_attendances(JSONB)
    RETURNS BOOLEAN
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- Crear tabla temporal desde el JSONB
    DROP TABLE IF EXISTS tmp_attendances;
    CREATE TEMPORARY TABLE tmp_attendances AS
    SELECT 
        x.student_id,
        x.created_at,
        x.obs,
        x.status,
        x.created_by,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x( 
        student_id   INT,
        created_at   TIMESTAMP WITH TIME ZONE,
        obs          VARCHAR(5000),
        status       INT,
        created_by   INT,
        updated_at   TIMESTAMP WITH TIME ZONE
    );

    -- Insertar en tabla attendances
    INSERT INTO attendances(
        student_id,
        created_at,
        obs,
        status,
        created_by,
        updated_at
    )
    SELECT  
        student_id,
        COALESCE(created_at, CURRENT_TIMESTAMP),
        obs,
        status,
        created_by,
        updated_at
    FROM tmp_attendances;

    RETURN TRUE;
END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

ALTER FUNCTION public.fx_ins_attendances(JSONB) OWNER TO rgensoftia;
GRANT EXECUTE ON FUNCTION public.fx_ins_attendances(JSONB) TO rgensoftia;
REVOKE ALL ON FUNCTION public.fx_ins_attendances(JSONB) FROM public;

COMMENT ON FUNCTION public.fx_ins_attendances(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Insertar nuevo registro en attendances
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.14
* SISTEMA / MODULO : [Sistema] / Asistencias
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_ins_attendances(
*     ''[{"student_id":1,"obs":"Asistencia puntual","status":101,"created_by":1}]''
* );
***************************************************************************************************/';

DROP FUNCTION IF EXISTS public.fx_upd_attendances(JSONB);
CREATE FUNCTION public.fx_upd_attendances(JSONB)
    RETURNS BOOLEAN
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- Cargar datos en tabla temporal
    DROP TABLE IF EXISTS tmp_attendances_upd;
    CREATE TEMPORARY TABLE tmp_attendances_upd AS
    SELECT 
        x.id,
        x.student_id,
        x.created_at,
        x.obs,
        x.status,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x(
        id           INT,
        student_id   INT,
        created_at   TIMESTAMP WITH TIME ZONE,
        obs          VARCHAR(5000),
        status       INT,
        updated_at   TIMESTAMP WITH TIME ZONE
    );

    -- Actualizar tabla attendances
    UPDATE attendances t
    SET
        student_id  = COALESCE(u.student_id, t.student_id),
        created_at  = COALESCE(u.created_at, t.created_at),
        obs         = COALESCE(u.obs, t.obs),
        status      = COALESCE(u.status, t.status),
        updated_at  = COALESCE(u.updated_at, CURRENT_TIMESTAMP)
    FROM tmp_attendances_upd u
    WHERE t.id = u.id;

    RETURN TRUE;
END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

ALTER FUNCTION public.fx_upd_attendances(JSONB) OWNER TO rgensoftia;
GRANT EXECUTE ON FUNCTION public.fx_upd_attendances(JSONB) TO rgensoftia;
REVOKE ALL ON FUNCTION public.fx_upd_attendances(JSONB) FROM public;

COMMENT ON FUNCTION public.fx_upd_attendances(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Actualizar registro(s) en attendances (actualización parcial)
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.14
* SISTEMA / MODULO : [Sistema] / Asistencias
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_upd_attendances(
*   ''[
*      {"id":1,"obs":"Llegó tarde","status":102},
*      {"id":2,"status":103}
*   ]''
* );
***************************************************************************************************/';

-- TABLA DESCRIPTIVE CONCLUSIONS
DROP FUNCTION IF EXISTS public.fx_ins_descriptive_conclusions(JSONB);
CREATE FUNCTION public.fx_ins_descriptive_conclusions(JSONB)
    RETURNS BOOLEAN
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- Crear tabla temporal desde el JSONB
    DROP TABLE IF EXISTS tmp_descriptive_conclusions;
    CREATE TEMPORARY TABLE tmp_descriptive_conclusions AS
    SELECT 
        x.student_id,
        x.period_id,
        x.score,
        x.achievement,
        x.difficulty,
        x.recommedation,
        x.obs,
        x.status,
        x.created_at,
        x.created_by,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x( 
        student_id     INT,
        period_id      INT,
        score          NUMERIC(5,2),
        achievement    TEXT,
        difficulty     TEXT,
        recommedation  TEXT,
        obs            VARCHAR(5000),
        status         BOOLEAN,
        created_at     TIMESTAMP WITH TIME ZONE,
        created_by     INT,
        updated_at     TIMESTAMP WITH TIME ZONE
    );

    -- Insertar en tabla descriptive_conclusions
    INSERT INTO descriptive_conclusions(
        student_id,
        period_id,
        score,
        achievement,
        difficulty,
        recommedation,
        obs,
        status,
        created_at,
        created_by,
        updated_at
    )
    SELECT  
        student_id,
        period_id,
        score,
        achievement,
        difficulty,
        recommedation,
        obs,
        COALESCE(status, TRUE),
        COALESCE(created_at, CURRENT_TIMESTAMP),
        created_by,
        updated_at
    FROM tmp_descriptive_conclusions;

    RETURN TRUE;
END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

ALTER FUNCTION public.fx_ins_descriptive_conclusions(JSONB) OWNER TO rgensoftia;
GRANT EXECUTE ON FUNCTION public.fx_ins_descriptive_conclusions(JSONB) TO rgensoftia;
REVOKE ALL ON FUNCTION public.fx_ins_descriptive_conclusions(JSONB) FROM public;

COMMENT ON FUNCTION public.fx_ins_descriptive_conclusions(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Insertar nuevo registro en descriptive_conclusions
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.14
* SISTEMA / MODULO : [Sistema] / Evaluaciones
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_ins_descriptive_conclusions(
*     ''[{
*         "student_id":1,
*         "period_id":2,
*         "score":18.50,
*         "achievement":"Buen desempeño en ciencias",
*         "difficulty":"Leve dificultad en redacción",
*         "recommedation":"Refuerzo en ortografía",
*         "obs":"Participa activamente",
*         "status":true,
*         "created_by":1
*     }]''
* );
***************************************************************************************************/';


DROP FUNCTION IF EXISTS public.fx_upd_descriptive_conclusions(JSONB);
CREATE FUNCTION public.fx_upd_descriptive_conclusions(JSONB)
    RETURNS BOOLEAN
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- Cargar datos en tabla temporal
    DROP TABLE IF EXISTS tmp_descriptive_conclusions_upd;
    CREATE TEMPORARY TABLE tmp_descriptive_conclusions_upd AS
    SELECT 
        x.id,
        x.student_id,
        x.period_id,
        x.score,
        x.achievement,
        x.difficulty,
        x.recommedation,
        x.obs,
        x.status,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x(
        id             INT,
        student_id     INT,
        period_id      INT,
        score          NUMERIC(5,2),
        achievement    TEXT,
        difficulty     TEXT,
        recommedation  TEXT,
        obs            VARCHAR(5000),
        status         BOOLEAN,
        updated_at     TIMESTAMP WITH TIME ZONE
    );

    -- Actualizar tabla descriptive_conclusions
    UPDATE descriptive_conclusions t
    SET
        student_id     = COALESCE(u.student_id, t.student_id),
        period_id      = COALESCE(u.period_id, t.period_id),
        score          = COALESCE(u.score, t.score),
        achievement    = COALESCE(u.achievement, t.achievement),
        difficulty     = COALESCE(u.difficulty, t.difficulty),
        recommedation  = COALESCE(u.recommedation, t.recommedation),
        obs            = COALESCE(u.obs, t.obs),
        status         = COALESCE(u.status, t.status),
        updated_at     = COALESCE(u.updated_at, CURRENT_TIMESTAMP)
    FROM tmp_descriptive_conclusions_upd u
    WHERE t.id = u.id;

    RETURN TRUE;
END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

ALTER FUNCTION public.fx_upd_descriptive_conclusions(JSONB) OWNER TO rgensoftia;
GRANT EXECUTE ON FUNCTION public.fx_upd_descriptive_conclusions(JSONB) TO rgensoftia;
REVOKE ALL ON FUNCTION public.fx_upd_descriptive_conclusions(JSONB) FROM public;

COMMENT ON FUNCTION public.fx_upd_descriptive_conclusions(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Actualizar registro(s) en descriptive_conclusions (actualización parcial)
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.14
* SISTEMA / MODULO : [Sistema] / Evaluaciones
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_upd_descriptive_conclusions(
*   ''[
*      {"id":1,"score":17.80,"obs":"Mejora notable","status":true},
*      {"id":2,"achievement":"Dominio total del tema","status":true}
*   ]''
* );
***************************************************************************************************/';

-- TABLA SCORES

-- =========================================
-- INSERTAR SCORES
-- =========================================
DROP FUNCTION IF EXISTS public.fx_ins_scores(JSONB);
CREATE FUNCTION public.fx_ins_scores(JSONB)
    RETURNS BOOLEAN
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- Crear tabla temporal desde el JSONB
    DROP TABLE IF EXISTS tmp_scores;
    CREATE TEMPORARY TABLE tmp_scores AS
    SELECT 
        x.student_id,
        x.period_id,
        x.score,
        x.achievement,
        x.difficulty,
        x.recommedation,
        x.obs,
        x.status,
        x.created_at,
        x.created_by,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x(
        student_id     INT,
        period_id      INT,
        score          NUMERIC(5,2),
        achievement    TEXT,
        difficulty     TEXT,
        recommedation  TEXT,
        obs            VARCHAR(5000),
        status         BOOLEAN,
        created_at     TIMESTAMP WITH TIME ZONE,
        created_by     INT,
        updated_at     TIMESTAMP WITH TIME ZONE
    );

    -- Insertar en tabla scores
    INSERT INTO scores(
        student_id,
        period_id,
        score,
        achievement,
        difficulty,
        recommedation,
        obs,
        status,
        created_at,
        created_by,
        updated_at
    )
    SELECT  
        student_id,
        period_id,
        score,
        achievement,
        difficulty,
        recommedation,
        obs,
        COALESCE(status, TRUE),
        COALESCE(created_at, CURRENT_TIMESTAMP),
        created_by,
        updated_at
    FROM tmp_scores;

    RETURN TRUE;
END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

ALTER FUNCTION public.fx_ins_scores(JSONB) OWNER TO rgensoftia;
GRANT EXECUTE ON FUNCTION public.fx_ins_scores(JSONB) TO rgensoftia;
REVOKE ALL ON FUNCTION public.fx_ins_scores(JSONB) FROM public;

COMMENT ON FUNCTION public.fx_ins_scores(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Insertar nuevo registro en scores
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.14
* SISTEMA / MODULO : [Sistema] / Calificaciones
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_ins_scores(
*     ''[
*         {"student_id":1,"period_id":1,"score":18.5,"achievement":"Buen desempeño","difficulty":"Ninguna","recommedation":"Seguir así","obs":"Observación","status":true,"created_by":1}
*     ]''
* );
***************************************************************************************************/';

-- =========================================
-- ACTUALIZAR SCORES
-- =========================================
DROP FUNCTION IF EXISTS public.fx_upd_scores(JSONB);
CREATE FUNCTION public.fx_upd_scores(JSONB)
    RETURNS BOOLEAN
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- Cargar datos en tabla temporal
    DROP TABLE IF EXISTS tmp_scores_upd;
    CREATE TEMPORARY TABLE tmp_scores_upd AS
    SELECT 
        x.id,
        x.student_id,
        x.period_id,
        x.score,
        x.achievement,
        x.difficulty,
        x.recommedation,
        x.obs,
        x.status,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x(
        id             INT,
        student_id     INT,
        period_id      INT,
        score          NUMERIC(5,2),
        achievement    TEXT,
        difficulty     TEXT,
        recommedation  TEXT,
        obs            VARCHAR(5000),
        status         BOOLEAN,
        updated_at     TIMESTAMP WITH TIME ZONE
    );

    -- Actualizar tabla scores
    UPDATE scores s
    SET
        student_id    = COALESCE(u.student_id, s.student_id),
        period_id     = COALESCE(u.period_id, s.period_id),
        score         = COALESCE(u.score, s.score),
        achievement   = COALESCE(u.achievement, s.achievement),
        difficulty    = COALESCE(u.difficulty, s.difficulty),
        recommedation = COALESCE(u.recommedation, s.recommedation),
        obs           = COALESCE(u.obs, s.obs),
        status        = COALESCE(u.status, s.status),
        updated_at    = COALESCE(u.updated_at, CURRENT_TIMESTAMP)
    FROM tmp_scores_upd u
    WHERE s.id = u.id;

    RETURN TRUE;
END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

ALTER FUNCTION public.fx_upd_scores(JSONB) OWNER TO rgensoftia;
GRANT EXECUTE ON FUNCTION public.fx_upd_scores(JSONB) TO rgensoftia;
REVOKE ALL ON FUNCTION public.fx_upd_scores(JSONB) FROM public;

COMMENT ON FUNCTION public.fx_upd_scores(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Actualizar registro(s) en scores (actualización parcial)
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.14
* SISTEMA / MODULO : [Sistema] / Calificaciones
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_upd_scores(
*   ''[
*      {"id":1,"score":19.0,"achievement":"Excelente","status":true},
*      {"id":2,"obs":"Revisión por coordinación"}
*   ]''
* );
***************************************************************************************************/';
