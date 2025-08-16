-- SELECCIONAR PERSONS
DROP FUNCTION IF EXISTS public.fx_sel_persons(JSONB);
CREATE FUNCTION public.fx_sel_persons(JSONB)
    RETURNS TABLE (
        id                INT,
        code              VARCHAR,
        father_last_name  VARCHAR,
        mother_last_name  VARCHAR,
        names             VARCHAR,
        gender            VARCHAR,
        created_at        TIMESTAMP WITH TIME ZONE,
        created_by        INT,
        updated_at        TIMESTAMP WITH TIME ZONE
    )
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    RETURN QUERY
    WITH filtros AS (
        SELECT 
            x.id,
            x.code,
            x.father_last_name,
            x.mother_last_name,
            x.names,
            x.gender,
            x.created_by,
            x.created_at
        FROM JSONB_TO_RECORDSET(COALESCE(p_json_data, '[]'::JSONB)) AS x(
            id                INT,
            code              VARCHAR(25),
            father_last_name  VARCHAR(500),
            mother_last_name  VARCHAR(500),
            names             VARCHAR(500),
            gender            VARCHAR(2),
            created_by        INT,
            created_at        TIMESTAMP WITH TIME ZONE
        )
    )
    SELECT 
        p.id,
        p.code,
        p.father_last_name,
        p.mother_last_name,
        p.names,
        p.gender,
        p.created_at,
        p.created_by,
        p.updated_at
    FROM persons p
    LEFT JOIN filtros f ON TRUE
    WHERE
        (f.id IS NULL OR p.id = f.id)
        AND (f.code IS NULL OR p.code ILIKE '%' || f.code || '%')
        AND (f.father_last_name IS NULL OR p.father_last_name ILIKE '%' || f.father_last_name || '%')
        AND (f.mother_last_name IS NULL OR p.mother_last_name ILIKE '%' || f.mother_last_name || '%')
        AND (f.names IS NULL OR p.names ILIKE '%' || f.names || '%')
        AND (f.gender IS NULL OR p.gender = f.gender)
        AND (f.created_by IS NULL OR p.created_by = f.created_by)
        AND (f.created_at IS NULL OR DATE(p.created_at) = DATE(f.created_at));

END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

COMMENT ON FUNCTION public.fx_sel_persons(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Consultar registros en persons con filtros opcionales enviados en formato JSONB
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.14
* SISTEMA / MODULO : [Sistema] / Personas
* SINTAXIS DE EJEMPLO:
* -- Todos los registros
* SELECT * FROM public.fx_sel_persons(NULL);
*
* -- Filtrar por código y género
* SELECT * FROM public.fx_sel_persons(
*     ''[{"code":"P001","gender":"M"}]''
* );
***************************************************************************************************/';


DROP FUNCTION IF EXISTS public.fx_ins_persons(JSONB);
CREATE FUNCTION public.fx_ins_persons(JSONB)
    RETURNS table (
    	id int,
    	code VARCHAR(25)
    )
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
	RETURN QUERY
    INSERT INTO persons as A(
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
        UPPER(TRIM(B.code)),
        UPPER(TRIM(B.father_last_name)),
        UPPER(TRIM(B.mother_last_name)),
        INITCAP(TRIM(B.names)),
        UPPER(TRIM(B.gender)),
        COALESCE(B.created_at, CURRENT_TIMESTAMP),
        B.created_by,
        B.updated_at
    FROM tmp_persons AS B
	RETURNING A.id,
		A.code;


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

-- ELIMINAR FUNCIÓN SI EXISTE
-- ELIMINAR FUNCIÓN SI EXISTE
DROP FUNCTION IF EXISTS public.fx_sel_types(JSONB);

CREATE FUNCTION public.fx_sel_types(JSONB)
    RETURNS TABLE (
        id            INT,
        code          VARCHAR(100),
        type          VARCHAR(100),
        name          VARCHAR(500),
        description   TEXT,
        status        BOOLEAN,
        created_at    TIMESTAMP WITH TIME ZONE,
        created_by    INT,
        updated_at    TIMESTAMP WITH TIME ZONE
    )
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
    v_id        INT;
    v_code      VARCHAR(100);
    v_type      VARCHAR(100);
    v_name      VARCHAR(500);
    v_status    BOOLEAN;
BEGIN
    -- Extraer filtros desde el JSONB
    SELECT  
        x.id,
        x.code,
        x.type,
        x.name,
        x.status
    INTO
        v_id,
        v_code,
        v_type,
        v_name,
        v_status
    FROM JSONB_TO_RECORD(p_json_data) AS x(
        id      INT,
        code    VARCHAR(100),
        type    VARCHAR(100),
        name    VARCHAR(500),
        status  BOOLEAN
    );

    RETURN QUERY
    SELECT 
        t.id,
        t.code,
        t.type,
        t.name,
        t.description,
        t.status,
        t.created_at,
        t.created_by,
        t.updated_at
    FROM types t
    WHERE (v_id IS NULL OR t.id = v_id)
      AND (v_code IS NULL OR t.code ILIKE '%' || v_code || '%')
      AND (v_type IS NULL OR t.type ILIKE '%' || v_type || '%')
      AND (v_name IS NULL OR t.name ILIKE '%' || v_name || '%')
      AND (v_status IS NULL OR t.status = v_status);

END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

COMMENT ON FUNCTION public.fx_sel_types(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Consultar registros de types con filtros opcionales
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.15
* SISTEMA / MODULO : [Sistema] / Catálogos
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_sel_types(
*     ''{"id": 1}''
* );
* SELECT * FROM public.fx_sel_types(
*     ''{"code": "GENERO", "status": true}''
* );
***************************************************************************************************/';


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

DROP FUNCTION IF EXISTS public.fx_sel_periods(JSONB);
CREATE FUNCTION public.fx_sel_periods(JSONB)
    RETURNS TABLE (
        id                 INT,
        code               VARCHAR,
        name               VARCHAR,
        duration_in_months INT,
        status             BOOLEAN,
        created_at         TIMESTAMP WITH TIME ZONE,
        created_by         INT,
        updated_at         TIMESTAMP WITH TIME ZONE
    )
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    RETURN QUERY
    WITH filtros AS (
        SELECT 
            x.id,
            x.code,
            x.name,
            x.duration_in_months,
            x.status,
            x.created_by,
            x.created_at
        FROM JSONB_TO_RECORDSET(COALESCE(p_json_data, '[]'::JSONB)) AS x(
            id                 INT,
            code               VARCHAR(25),
            name               VARCHAR(500),
            duration_in_months INT,
            status             BOOLEAN,
            created_by         INT,
            created_at         TIMESTAMP WITH TIME ZONE
        )
    )
    SELECT 
        p.id,
        p.code,
        p.name,
        p.duration_in_months,
        p.status,
        p.created_at,
        p.created_by,
        p.updated_at
    FROM periods p
    LEFT JOIN filtros f ON TRUE
    WHERE
        (f.id IS NULL OR p.id = f.id)
        AND (f.code IS NULL OR p.code ILIKE '%' || f.code || '%')
        AND (f.name IS NULL OR p.name ILIKE '%' || f.name || '%')
        AND (f.duration_in_months IS NULL OR p.duration_in_months = f.duration_in_months)
        AND (f.status IS NULL OR p.status = f.status)
        AND (f.created_by IS NULL OR p.created_by = f.created_by)
        AND (f.created_at IS NULL OR DATE(p.created_at) = DATE(f.created_at));

END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

COMMENT ON FUNCTION public.fx_sel_periods(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Consultar registros en periods con filtros opcionales en JSONB
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.16
* SISTEMA / MODULO : Académico / Periodos
* SINTAXIS DE EJEMPLO:
* -- Todos los periodos
* SELECT * FROM public.fx_sel_periods(NULL);
*
* -- Filtrar por código y estado
* SELECT * FROM public.fx_sel_periods(
*     ''[{"code":"2025-01","status":true}]''
* );
***************************************************************************************************/';


-- ELIMINAR FUNCIÓN SI EXISTE
DROP FUNCTION IF EXISTS public.fx_ins_periods(JSONB);
CREATE FUNCTION public.fx_ins_periods(JSONB)
    RETURNS TABLE (
        id INT,
        code VARCHAR(25)
    )
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- 1. Crear tabla temporal para recibir los datos del JSONB
    DROP TABLE IF EXISTS tmp_periods;
    CREATE TEMPORARY TABLE tmp_periods AS
    SELECT 
        x.code,
        x.name,
        x.duration_in_months,
        x.status,
        x.created_at,
        x.created_by,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x(
        code                VARCHAR(25),
        name                VARCHAR(500),
        duration_in_months  INT,
        status              BOOL,
        created_at          TIMESTAMP WITH TIME ZONE,
        created_by          INT,
        updated_at          TIMESTAMP WITH TIME ZONE
    );

    -- 2. Insertar en tabla periods
    RETURN QUERY
    INSERT INTO periods AS A(
        code,
        name,
        duration_in_months,
        status,
        created_at,
        created_by,
        updated_at
    )
    SELECT  
        UPPER(TRIM(B.code)),
        INITCAP(TRIM(B.name)),
        B.duration_in_months,
        COALESCE(B.status, TRUE),
        COALESCE(B.created_at, CURRENT_TIMESTAMP),
        B.created_by,
        B.updated_at
    FROM tmp_periods AS B
    RETURNING A.id,
              A.code;

END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

COMMENT ON FUNCTION public.fx_ins_periods(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Insertar nuevo registro en periods
* ESCRITO POR : 16131-BD - Developers
* FECHA CREACIÓN : 2025.08.15
* SISTEMA / MODULO : PRINCIPAL / Periodos
* MODIFICACIONES :
* FECHA   RESPONSABLE  DESCRIPCIÓN DEL CAMBIO
*
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_ins_periods(
*     ''[{"code":"2025A","name":"Periodo Académico 2025-A","duration_in_months":5,"created_by":1}]''
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
DROP FUNCTION IF EXISTS public.fx_sel_courses(JSONB);
CREATE FUNCTION public.fx_sel_courses(JSONB)
    RETURNS TABLE (
        id          INT,
        code        VARCHAR,
        name        VARCHAR,
        description VARCHAR,
        status      BOOLEAN,
        created_at  TIMESTAMP WITH TIME ZONE,
        created_by  INT,
        updated_at  TIMESTAMP WITH TIME ZONE
    )
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    RETURN QUERY
    WITH filtros AS (
        SELECT 
            x.id,
            x.code,
            x.name,
            x.status,
            x.created_by,
            x.created_at
        FROM JSONB_TO_RECORDSET(COALESCE(p_json_data, '[]'::JSONB)) AS x(
            id          INT,
            code        VARCHAR(50),
            name        VARCHAR(500),
            status      BOOLEAN,
            created_by  INT,
            created_at  TIMESTAMP WITH TIME ZONE
        )
    )
    SELECT 
        c.id,
        c.code,
        c.name,
        c.description,
        c.status,
        c.created_at,
        c.created_by,
        c.updated_at
    FROM courses c
    LEFT JOIN filtros f ON TRUE
    WHERE
        (f.id IS NULL OR c.id = f.id)
        AND (f.code IS NULL OR c.code ILIKE '%' || f.code || '%')
        AND (f.name IS NULL OR c.name ILIKE '%' || f.name || '%')
        AND (f.status IS NULL OR c.status = f.status)
        AND (f.created_by IS NULL OR c.created_by = f.created_by)
        AND (f.created_at IS NULL OR DATE(c.created_at) = DATE(f.created_at));
END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

COMMENT ON FUNCTION public.fx_sel_courses(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Consultar registros en courses con filtros opcionales enviados en formato JSONB
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.16
* SISTEMA / MODULO : [Sistema] / Cursos
* SINTAXIS DE EJEMPLO:
* -- Todos los cursos
* SELECT * FROM public.fx_sel_courses(NULL);
*
* -- Filtrar por código y estado
* SELECT * FROM public.fx_sel_courses(
*     ''[{"code":"MAT101","status":true}]''
* );
***************************************************************************************************/';

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

DROP FUNCTION IF EXISTS public.fx_sel_students(JSONB);
CREATE FUNCTION public.fx_sel_students(JSONB)
    RETURNS TABLE (
        id              INT,
        code			VARCHAR(25),
        person_id       INT,
        father_last_name	VARCHAR(500),
        mother_last_name	VARCHAR(500),
        names			VARCHAR(500),
        gender			VARCHAR(500),
        status          INT,
        created_at      TIMESTAMP WITH TIME ZONE,
        created_by      INT,
        updated_at      TIMESTAMP WITH TIME ZONE
    )
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
    v_person_id INT;
    v_status    INT;
BEGIN
    -- Extraer filtros desde el JSONB
    SELECT  
        x.person_id,
        x.status
    INTO
        v_person_id,
        v_status
    FROM JSONB_TO_RECORD(p_json_data) AS x(
        person_id INT,
        status    INT
    );

    RETURN QUERY
    SELECT 
        s.id,
		p.code,
        s.person_id,
		p.father_last_name,
		p.mother_last_name,
		p.names,
		t.name as gender,
        s.status,
        s.created_at,
        s.created_by,
        s.updated_at
    FROM students as s
		INNER JOIN persons as p
		on s.person_id = p.id
		INNER JOIN types as t
		on p.gender = t.code
		and t.type = 'GENERO'
    WHERE (v_person_id IS NULL OR s.person_id = v_person_id)
      AND (v_status IS NULL OR s.status = v_status);

END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

COMMENT ON FUNCTION public.fx_sel_students(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Consultar registros de students con filtros opcionales
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.14
* SISTEMA / MODULO : [Sistema] / Académico
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_sel_students(
*     ''{"person_id": 10, "status": 1}''
* );
***************************************************************************************************/';


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

-- FUNCIÓN SELECT PARA GRADES
DROP FUNCTION IF EXISTS public.fx_sel_grades(JSONB);
CREATE FUNCTION public.fx_sel_grades(JSONB)
    RETURNS TABLE (
        id         INT,
        abbr       VARCHAR,
        name       VARCHAR,
        status     BOOL,
        created_at TIMESTAMP WITH TIME ZONE,
        created_by INT,
        updated_at TIMESTAMP WITH TIME ZONE
    )
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    RETURN QUERY
    WITH filtros AS (
        SELECT 
            x.id,
            x.abbr,
            x.name,
            x.status,
            x.created_by,
            x.created_at
        FROM JSONB_TO_RECORDSET(COALESCE(p_json_data, '[]'::JSONB)) AS x(
            id         INT,
            abbr       VARCHAR(50),
            name       VARCHAR(5000),
            status     BOOL,
            created_by INT,
            created_at TIMESTAMP WITH TIME ZONE
        )
    )
    SELECT 
        g.id,
        g.abbr,
        g.name,
        g.status,
        g.created_at,
        g.created_by,
        g.updated_at
    FROM grades g
    LEFT JOIN filtros f ON TRUE
    WHERE
        (f.id IS NULL OR g.id = f.id)
        AND (f.abbr IS NULL OR g.abbr ILIKE '%' || f.abbr || '%')
        AND (f.name IS NULL OR g.name ILIKE '%' || f.name || '%')
        AND (f.status IS NULL OR g.status = f.status)
        AND (f.created_by IS NULL OR g.created_by = f.created_by)
        AND (f.created_at IS NULL OR DATE(g.created_at) = DATE(f.created_at));

END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

COMMENT ON FUNCTION public.fx_sel_grades(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Consultar registros en grades con filtros opcionales enviados en formato JSONB
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.16
* SISTEMA / MODULO : [Sistema] / Grados
* SINTAXIS DE EJEMPLO:
* -- Todos los registros
* SELECT * FROM public.fx_sel_grades(NULL);
*
* -- Filtrar por abreviatura y estado
* SELECT * FROM public.fx_sel_grades(
*     ''[{"abbr":"1ERO","status":true}]''
* );
***************************************************************************************************/';

-- FUNCIÓN INSERT PARA GRADES
DROP FUNCTION IF EXISTS public.fx_ins_grades(JSONB);
CREATE FUNCTION public.fx_ins_grades(JSONB)
    RETURNS table (
        id   INT,
        abbr VARCHAR(50)
    )
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- 1. Crear tabla temporal para recibir los datos del JSONB
    DROP TABLE IF EXISTS tmp_grades;
    CREATE TEMPORARY TABLE tmp_grades AS
    SELECT 
        x.abbr,
        x.name,
        x.status,
        x.created_at,
        x.created_by,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x( 
        abbr       VARCHAR(50),
        name       VARCHAR(5000),
        status     BOOL,
        created_at TIMESTAMP WITH TIME ZONE,
        created_by INT,
        updated_at TIMESTAMP WITH TIME ZONE
    );

    -- 2. Insertar en tabla grades
    RETURN QUERY
    INSERT INTO grades as A(
        abbr,
        name,
        status,
        created_at,
        created_by,
        updated_at
    )
    SELECT  
        UPPER(TRIM(B.abbr)),
        TRIM(B.name),
        COALESCE(B.status, true),
        COALESCE(B.created_at, CURRENT_TIMESTAMP),
        B.created_by,
        B.updated_at
    FROM tmp_grades AS B
    RETURNING A.id,
        A.abbr;

END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

COMMENT ON FUNCTION public.fx_ins_grades(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Insertar nuevo registro en grades
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.16
* SISTEMA / MODULO : PRINCIPAL / Grados
* MODIFICACIONES :
* FECHA   RESPONSABLE  DESCRIPCIÓN DEL CAMBIO
*
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_ins_grades(
*     ''[{"abbr":"1ERO","name":"Primer Grado de Primaria","created_by":1}]''
* );
***************************************************************************************************/';

-- FUNCIÓN UPDATE PARA GRADES
DROP FUNCTION IF EXISTS public.fx_upd_grades(JSONB);
CREATE FUNCTION public.fx_upd_grades(JSONB)
    RETURNS BOOLEAN
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- 1) Cargar datos a una tabla temporal desde el JSONB
    DROP TABLE IF EXISTS tmp_grades_upd;
    CREATE TEMPORARY TABLE tmp_grades_upd AS
    SELECT 
        x.id,
        x.abbr,
        x.name,
        x.status,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x(
        id         INT,
        abbr       VARCHAR(50),
        name       VARCHAR(5000),
        status     BOOL,
        updated_at TIMESTAMP WITH TIME ZONE
    );

    -- 2) Actualizar grades (solo columnas provistas; COALESCE conserva valor actual si viene NULL)
    UPDATE grades g
    SET
        abbr       = COALESCE(UPPER(TRIM(t.abbr)), g.abbr),
        name       = COALESCE(TRIM(t.name), g.name),
        status     = COALESCE(t.status, g.status),
        updated_at = COALESCE(t.updated_at, CURRENT_TIMESTAMP)
    FROM tmp_grades_upd t
    WHERE g.id = t.id;

    RETURN TRUE;
END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

COMMENT ON FUNCTION public.fx_upd_grades(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Actualizar registro(s) en grades (actualización parcial por campos)
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.16
* SISTEMA / MODULO : [Sistema] / Grados
* MODIFICACIONES :
* FECHA   RESPONSABLE  DESCRIPCIÓN DEL CAMBIO
*
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_upd_grades(
*   ''[
*      {"id":1, "name":"Primer Grado de Educación Primaria", "updated_at":"2025-08-16T10:00:00Z"},
*      {"id":2, "abbr":"2DO","name":"Segundo Grado","status":true}
*   ]''
* );
***************************************************************************************************/';

-- FUNCIÓN SELECT PARA ACADEMIC_PERIODS
DROP FUNCTION IF EXISTS public.fx_sel_academic_periods(JSONB);
CREATE FUNCTION public.fx_sel_academic_periods(JSONB)
    RETURNS TABLE (
        id          INT,
        year        INT,
        period_id   INT,
        period_code varchar(25),
        period		varchar(500),
        init_date   DATE,
        finish_date DATE,
        status      BOOL,
        is_current   BOOL,
        created_at  TIMESTAMP WITH TIME ZONE,
        created_by  INT,
        updated_at  TIMESTAMP WITH TIME ZONE
    )
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    RETURN QUERY
    WITH filtros AS (
        SELECT 
            x.id,
            x.year,
            x.period_id,
            x.init_date,
            x.finish_date,
            x.status,
            x.is_current,
            x.created_by,
            x.created_at
        FROM JSONB_TO_RECORDSET(COALESCE(p_json_data, '[]'::JSONB)) AS x(
            id          INT,
            year        INT,
            period_id   INT,
            init_date   DATE,
            finish_date DATE,
            status      BOOL,
            is_current   BOOL,
            created_by  INT,
            created_at  TIMESTAMP WITH TIME ZONE
        )
    )
    SELECT 
        ap.id,
        ap.year,
        ap.period_id,
		p.code as period,
		p.name as period,
        ap.init_date,
        ap.finish_date,
        ap.status,
        ap.is_current,
        ap.created_at,
        ap.created_by,
        ap.updated_at
    FROM academic_periods as ap
		INNER JOIN periods as p
		on ap.period_id = p.id
    LEFT JOIN filtros f ON TRUE
    WHERE
        (f.id IS NULL OR ap.id = f.id)
        AND (f.year IS NULL OR ap.year = f.year)
        AND (f.period_id IS NULL OR ap.period_id = f.period_id)
        AND (f.init_date IS NULL OR ap.init_date = f.init_date)
        AND (f.finish_date IS NULL OR ap.finish_date = f.finish_date)
        AND (f.status IS NULL OR ap.status = f.status)
        AND (f.is_current IS NULL OR ap.is_current = f.is_current)
        AND (f.created_by IS NULL OR ap.created_by = f.created_by)
        AND (f.created_at IS NULL OR DATE(ap.created_at) = DATE(f.created_at));

END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

COMMENT ON FUNCTION public.fx_sel_academic_periods(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Consultar registros en academic_periods con filtros opcionales enviados en formato JSONB
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.16
* SISTEMA / MODULO : [Sistema] / Periodos Academicos
* SINTAXIS DE EJEMPLO:
* -- Todos los registros
* SELECT * FROM public.fx_sel_academic_periods(NULL);
*
* -- Filtrar por año y estado actual
* SELECT * FROM public.fx_sel_academic_periods(
*     ''[{"year":2025,"is_current":true}]''
* );
*
* -- Filtrar por periodo activo
* SELECT * FROM public.fx_sel_academic_periods(
*     ''[{"status":true,"period_id":1}]''
* );
***************************************************************************************************/';

-- FUNCIÓN INSERT PARA ACADEMIC_PERIODS
DROP FUNCTION IF EXISTS public.fx_ins_academic_periods(JSONB);
CREATE FUNCTION public.fx_ins_academic_periods(JSONB)
    RETURNS table (
        id   INT,
        year INT
    )
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- 1. Crear tabla temporal para recibir los datos del JSONB
    DROP TABLE IF EXISTS tmp_academic_periods;
    CREATE TEMPORARY TABLE tmp_academic_periods AS
    SELECT 
        x.year,
        x.period_id,
        x.init_date,
        x.finish_date,
        x.status,
        x.is_current,
        x.created_at,
        x.created_by,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x( 
        year        INT,
        period_id   INT,
        init_date   DATE,
        finish_date DATE,
        status      BOOL,
        is_current   BOOL,
        created_at  TIMESTAMP WITH TIME ZONE,
        created_by  INT,
        updated_at  TIMESTAMP WITH TIME ZONE
    );

    -- 2. Insertar en tabla academic_periods
    RETURN QUERY
    INSERT INTO academic_periods as A(
        year,
        period_id,
        init_date,
        finish_date,
        status,
        is_current,
        created_at,
        created_by,
        updated_at
    )
    SELECT  
        B.year,
        B.period_id,
        B.init_date,
        B.finish_date,
        COALESCE(B.status, true),
        COALESCE(B.is_current, false),
        COALESCE(B.created_at, CURRENT_TIMESTAMP),
        B.created_by,
        B.updated_at
    FROM tmp_academic_periods AS B
    RETURNING A.id,
        A.year;

END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

COMMENT ON FUNCTION public.fx_ins_academic_periods(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Insertar nuevo registro en academic_periods
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.16
* SISTEMA / MODULO : PRINCIPAL / Periodos Academicos
* MODIFICACIONES :
* FECHA   RESPONSABLE  DESCRIPCIÓN DEL CAMBIO
*
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_ins_academic_periods(
*     ''[{"year":2025,"period_id":1,"init_date":"2025-03-01","finish_date":"2025-07-31","is_current":true,"created_by":1}]''
* );
***************************************************************************************************/';

-- FUNCIÓN UPDATE PARA ACADEMIC_PERIODS
DROP FUNCTION IF EXISTS public.fx_upd_academic_periods(JSONB);
CREATE FUNCTION public.fx_upd_academic_periods(JSONB)
    RETURNS BOOLEAN
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- 1) Cargar datos a una tabla temporal desde el JSONB
    DROP TABLE IF EXISTS tmp_academic_periods_upd;
    CREATE TEMPORARY TABLE tmp_academic_periods_upd AS
    SELECT 
        x.id,
        x.year,
        x.period_id,
        x.init_date,
        x.finish_date,
        x.status,
        x.is_current,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x(
        id          INT,
        year        INT,
        period_id   INT,
        init_date   DATE,
        finish_date DATE,
        status      BOOL,
        is_current   BOOL,
        updated_at  TIMESTAMP WITH TIME ZONE
    );

    -- 2) Actualizar academic_periods (solo columnas provistas; COALESCE conserva valor actual si viene NULL)
    UPDATE academic_periods ap
    SET
        year        = COALESCE(t.year, ap.year),
        period_id   = COALESCE(t.period_id, ap.period_id),
        init_date   = COALESCE(t.init_date, ap.init_date),
        finish_date = COALESCE(t.finish_date, ap.finish_date),
        status      = COALESCE(t.status, ap.status),
        is_current   = COALESCE(t.is_current, ap.is_current),
        updated_at  = COALESCE(t.updated_at, CURRENT_TIMESTAMP)
    FROM tmp_academic_periods_upd t
    WHERE ap.id = t.id;

    RETURN TRUE;
END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

COMMENT ON FUNCTION public.fx_upd_academic_periods(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Actualizar registro(s) en academic_periods (actualización parcial por campos)
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.16
* SISTEMA / MODULO : [Sistema] / Periodos Academicos
* MODIFICACIONES :
* FECHA   RESPONSABLE  DESCRIPCIÓN DEL CAMBIO
*
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_upd_academic_periods(
*   ''[
*      {"id":1, "finish_date":"2025-08-15", "updated_at":"2025-08-16T10:00:00Z"},
*      {"id":2, "is_current":false, "status":true}
*   ]''
* );
***************************************************************************************************/';


DROP FUNCTION IF EXISTS public.fx_sel_grade_in_academic_periods(JSONB);
CREATE FUNCTION public.fx_sel_grade_in_academic_periods(JSONB)
    RETURNS TABLE (
        id                 INT,
        academic_period_id INT,
        grade_id           INT,
        vacancies          INT,
        status             BOOLEAN,
        created_at         TIMESTAMP WITH TIME ZONE,
        created_by         INT,
        updated_at         TIMESTAMP WITH TIME ZONE
    )
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    RETURN QUERY
    WITH filtros AS (
        SELECT 
            x.id,
            x.academic_period_id,
            x.grade_id,
            x.vacancies,
            x.status,
            x.created_by,
            x.created_at
        FROM JSONB_TO_RECORDSET(COALESCE(p_json_data, '[]'::JSONB)) AS x(
            id                 INT,
            academic_period_id INT,
            grade_id           INT,
            vacancies          INT,
            status             BOOLEAN,
            created_by         INT,
            created_at         TIMESTAMP WITH TIME ZONE
        )
    )
    SELECT 
        g.id,
        g.academic_period_id,
        g.grade_id,
        g.vacancies,
        g.status,
        g.created_at,
        g.created_by,
        g.updated_at
    FROM grade_in_academic_periods g
    LEFT JOIN filtros f ON TRUE
    WHERE
        (f.id IS NULL OR g.id = f.id)
        AND (f.academic_period_id IS NULL OR g.academic_period_id = f.academic_period_id)
        AND (f.grade_id IS NULL OR g.grade_id = f.grade_id)
        AND (f.vacancies IS NULL OR g.vacancies = f.vacancies)
        AND (f.status IS NULL OR g.status = f.status)
        AND (f.created_by IS NULL OR g.created_by = f.created_by)
        AND (f.created_at IS NULL OR DATE(g.created_at) = DATE(f.created_at));

END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

COMMENT ON FUNCTION public.fx_sel_grade_in_academic_periods(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Consultar registros en grade_in_academic_periods con filtros opcionales en formato JSONB
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.16
* SISTEMA / MODULO : Académico / Grados en Periodos
* SINTAXIS DE EJEMPLO:
* -- Todos los registros
* SELECT * FROM public.fx_sel_grade_in_academic_periods(NULL);
*
* -- Filtrar por periodo y grado
* SELECT * FROM public.fx_sel_grade_in_academic_periods(
*     ''[{"academic_period_id":1,"grade_id":2}]''
* );
***************************************************************************************************/';

DROP FUNCTION IF EXISTS public.fx_ins_grade_in_academic_periods(JSONB);
CREATE FUNCTION public.fx_ins_grade_in_academic_periods(JSONB)
    RETURNS TABLE (
        id INT,
        academic_period_id INT,
        grade_id INT
    )
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- Crear tabla temporal
    DROP TABLE IF EXISTS tmp_grade_in_academic_periods;
    CREATE TEMPORARY TABLE tmp_grade_in_academic_periods AS
    SELECT 
        x.academic_period_id,
        x.grade_id,
        x.vacancies,
        x.status,
        x.created_at,
        x.created_by,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x(
        academic_period_id INT,
        grade_id           INT,
        vacancies          INT,
        status             BOOLEAN,
        created_at         TIMESTAMP WITH TIME ZONE,
        created_by         INT,
        updated_at         TIMESTAMP WITH TIME ZONE
    );
	
	-- Eliminamos todos los registros (grados del periodo academico)
	DELETE FROM grade_in_academic_periods as g
	USING 	tmp_grade_in_academic_periods t
	WHERE 	g.academic_period_id = t.academic_period_id;

    -- Insertar registros
    RETURN QUERY
    INSERT INTO grade_in_academic_periods AS g(
        academic_period_id,
        grade_id,
        vacancies,
        status,
        created_at,
        created_by,
        updated_at
    )
    SELECT  
        t.academic_period_id,
        t.grade_id,
        t.vacancies,
        COALESCE(t.status, TRUE),
        COALESCE(t.created_at, CURRENT_TIMESTAMP),
        t.created_by,
        t.updated_at
    FROM tmp_grade_in_academic_periods as t
    RETURNING g.id, g.academic_period_id, g.grade_id;

END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

COMMENT ON FUNCTION public.fx_ins_grade_in_academic_periods(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Insertar nuevo registro en grade_in_academic_periods
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.16
* SISTEMA / MODULO : Académico / Grados en Periodos
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_ins_grade_in_academic_periods(
*     ''[{"academic_period_id":1,"grade_id":3,"vacancies":40,"created_by":1}]''
* );
***************************************************************************************************/';

DROP FUNCTION IF EXISTS public.fx_upd_grade_in_academic_periods(JSONB);
CREATE FUNCTION public.fx_upd_grade_in_academic_periods(JSONB)
    RETURNS BOOLEAN
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    DROP TABLE IF EXISTS tmp_grade_in_academic_periods_upd;
    CREATE TEMPORARY TABLE tmp_grade_in_academic_periods_upd AS
    SELECT 
        x.id,
        x.academic_period_id,
        x.grade_id,
        x.vacancies,
        x.status,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x(
        id                 INT,
        academic_period_id INT,
        grade_id           INT,
        vacancies          INT,
        status             BOOLEAN,
        updated_at         TIMESTAMP WITH TIME ZONE
    );

    UPDATE grade_in_academic_periods g
    SET
        academic_period_id = COALESCE(t.academic_period_id, g.academic_period_id),
        grade_id           = COALESCE(t.grade_id, g.grade_id),
        vacancies          = COALESCE(t.vacancies, g.vacancies),
        status             = COALESCE(t.status, g.status),
        updated_at         = COALESCE(t.updated_at, CURRENT_TIMESTAMP)
    FROM tmp_grade_in_academic_periods_upd t
    WHERE g.id = t.id;

    RETURN TRUE;
END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

COMMENT ON FUNCTION public.fx_upd_grade_in_academic_periods(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA/ORG] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Actualizar registro(s) en grade_in_academic_periods (actualización parcial)
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.16
* SISTEMA / MODULO : Académico / Grados en Periodos
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_upd_grade_in_academic_periods(
*   ''[
*      {"id":1,"vacancies":35,"status":true},
*      {"id":2,"grade_id":4,"updated_at":"2025-08-16T10:30:00Z"}
*   ]''
* );
***************************************************************************************************/';

DROP FUNCTION IF EXISTS public.fx_sel_students_in_grade(JSONB);
CREATE FUNCTION public.fx_sel_students_in_grade(JSONB)
    RETURNS TABLE (
        id                        INT,
        grade_in_academic_period_id INT,
        student_id                INT,
        father_last_name		  varchar(500),
        mother_last_name		  varchar(500),
        names					  varchar(500),
        obs                       VARCHAR,
        status                    BOOLEAN,
        created_at                TIMESTAMP WITH TIME ZONE,
        created_by                INT,
        updated_at                TIMESTAMP WITH TIME ZONE
    )
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    RETURN QUERY
    WITH filtros AS (
        SELECT 
            x.id,
            x.grade_in_academic_period_id,
            x.student_id,
            x.obs,
            x.status,
            x.created_by,
            x.created_at
        FROM JSONB_TO_RECORDSET(COALESCE(p_json_data, '[]'::JSONB)) AS x(
            id                          INT,
            grade_in_academic_period_id INT,
            student_id                  INT,
            obs                         VARCHAR(5000),
            status                      BOOLEAN,
            created_by                  INT,
            created_at                  TIMESTAMP WITH TIME ZONE
        )
    )
    SELECT 
        s.id,
        s.grade_in_academic_period_id,
        s.student_id,
		p.father_last_name,
		p.mother_last_name,
		p.names,
        s.obs,
        s.status,
        s.created_at,
        s.created_by,
        s.updated_at
    FROM students_in_grade s
		inner join students as e
		on e.id = s.student_id
		inner join persons as p
		on e.person_id = p.id 
    LEFT JOIN filtros f ON TRUE
    WHERE
        (f.id IS NULL OR s.id = f.id)
        AND (f.grade_in_academic_period_id IS NULL OR s.grade_in_academic_period_id = f.grade_in_academic_period_id)
        AND (f.student_id IS NULL OR s.student_id = f.student_id)
        AND (f.obs IS NULL OR s.obs ILIKE '%' || f.obs || '%')
        AND (f.status IS NULL OR s.status = f.status)
        AND (f.created_by IS NULL OR s.created_by = f.created_by)
        AND (f.created_at IS NULL OR DATE(s.created_at) = DATE(f.created_at));

END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

COMMENT ON FUNCTION public.fx_sel_students_in_grade(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Consultar registros en students_in_grade con filtros opcionales en formato JSONB
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.16
* SISTEMA / MODULO : Académico / Estudiantes en Grados
* SINTAXIS DE EJEMPLO:
* -- Todos los registros
* SELECT * FROM public.fx_sel_students_in_grade(NULL);
*
* -- Filtrar por estudiante y estado
* SELECT * FROM public.fx_sel_students_in_grade(
*     ''[{"student_id":5,"status":true}]''
* );
***************************************************************************************************/';


DROP FUNCTION IF EXISTS public.fx_ins_students_in_grade(JSONB);
CREATE FUNCTION public.fx_ins_students_in_grade(JSONB)
    RETURNS TABLE (
        id INT,
        student_id INT
    )
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- Crear tabla temporal
    DROP TABLE IF EXISTS tmp_students_in_grade;
    CREATE TEMPORARY TABLE tmp_students_in_grade AS
    SELECT 
        x.grade_in_academic_period_id,
        x.student_id,
        x.obs,
        x.status,
        x.created_at,
        x.created_by,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x(
        grade_in_academic_period_id INT,
        student_id                  INT,
        obs                         VARCHAR(5000),
        status                      BOOLEAN,
        created_at                  TIMESTAMP WITH TIME ZONE,
        created_by                  INT,
        updated_at                  TIMESTAMP WITH TIME ZONE
    );

    -- Insertar registros
    RETURN QUERY
    INSERT INTO students_in_grade AS s(
        grade_in_academic_period_id,
        student_id,
        obs,
        status,
        created_at,
        created_by,
        updated_at
    )
    SELECT  
        t.grade_in_academic_period_id,
        t.student_id,
        TRIM(t.obs),
        COALESCE(t.status, TRUE),
        COALESCE(t.created_at, CURRENT_TIMESTAMP),
        t.created_by,
        t.updated_at
    FROM tmp_students_in_grade as t
    RETURNING s.id, s.student_id;

END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

COMMENT ON FUNCTION public.fx_ins_students_in_grade(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Insertar nuevo registro en students_in_grade
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.16
* SISTEMA / MODULO : Académico / Estudiantes en Grados
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_ins_students_in_grade(
*     ''[{"grade_in_academic_period_id":1,"student_id":10,"obs":"Asignado al grado","created_by":2}]''
* );
***************************************************************************************************/';


DROP FUNCTION IF EXISTS public.fx_upd_students_in_grade(JSONB);
CREATE FUNCTION public.fx_upd_students_in_grade(JSONB)
    RETURNS BOOLEAN
AS $BODY$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    -- Cargar datos a tabla temporal
    DROP TABLE IF EXISTS tmp_students_in_grade_upd;
    CREATE TEMPORARY TABLE tmp_students_in_grade_upd AS
    SELECT 
        x.id,
        x.grade_in_academic_period_id,
        x.student_id,
        x.obs,
        x.status,
        x.updated_at
    FROM JSONB_TO_RECORDSET(p_json_data) AS x(
        id                          INT,
        grade_in_academic_period_id INT,
        student_id                  INT,
        obs                         VARCHAR(5000),
        status                      BOOLEAN,
        updated_at                  TIMESTAMP WITH TIME ZONE
    );

    -- Actualizar registros
    UPDATE students_in_grade s
    SET
        grade_in_academic_period_id = COALESCE(t.grade_in_academic_period_id, s.grade_in_academic_period_id),
        student_id                  = COALESCE(t.student_id, s.student_id),
        obs                         = COALESCE(TRIM(t.obs), s.obs),
        status                      = COALESCE(t.status, s.status),
        updated_at                  = COALESCE(t.updated_at, CURRENT_TIMESTAMP)
    FROM tmp_students_in_grade_upd t
    WHERE s.id = t.id;

    RETURN TRUE;
END;
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 1000;

COMMENT ON FUNCTION public.fx_upd_students_in_grade(JSONB)
IS '
/***************************************************************************************************
* COPYRIGHT © 2025 [TU EMPRESA] - ALL RIGHTS RESERVED.
*
* OBJETIVO : Actualizar registro(s) en students_in_grade (actualización parcial por campos)
* ESCRITO POR : Jorge Mayo
* FECHA CREACIÓN : 2025.08.16
* SISTEMA / MODULO : Académico / Estudiantes en Grados
* SINTAXIS DE EJEMPLO:
* SELECT * FROM public.fx_upd_students_in_grade(
*   ''[
*      {"id":1,"obs":"Cambiado de grado","status":false},
*      {"id":2,"grade_in_academic_period_id":3,"updated_at":"2025-08-16T12:00:00Z"}
*   ]''
* );
***************************************************************************************************/';


