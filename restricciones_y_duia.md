# Restricciones de Reglas de Negocio (Parte 1)

## Script SQL Generado
```sql
ALTER TABLE cliente ADD CONSTRAINT chk_cliente_email 
    CHECK (email LIKE '%@%');

ALTER TABLE pedido ADD CONSTRAINT chk_pedido_fecha 
    CHECK (fecha <= now());

ALTER TABLE cliente ADD CONSTRAINT chk_cliente_nombre_valido 
    CHECK (nombre ~ '^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$' AND trim(nombre) <> '');

ALTER TABLE cliente ADD CONSTRAINT chk_cliente_apellido_valido 
    CHECK (apellido ~ '^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$' AND trim(apellido) <> '');
```

## Declaración de Uso de IA (DUIA)

| Campo | Completar |
| :--- | :--- |
| **Herramienta** | OpenCode (Gemini 3.5 Flash) |
| **Spec o prompt utilizado** | Necesito crear un script SQL que agregue tres restricciones usando ALTER TABLE: 1. En `cliente`, validar que `email` contenga '@'. 2. En `pedido`, impedir que `fecha` sea mayor a la actual. 3. En `cliente`, asegurar usando regex que `nombre` y `apellido` solo contengan letras y espacios (no vacíos ni símbolos). |
| **Qué generó** | Un script con cuatro sentencias `ALTER TABLE ... ADD CONSTRAINT CHECK` aplicando `LIKE` para el email, `<= now()` para la fecha, y expresiones regulares (`~`) para los nombres. |
| **Qué se aceptó** | Se aceptó la totalidad del código generado. |
| **Qué se modificó o descartó, y por qué** | No se requirieron modificaciones, la sintaxis fue correcta para PostgreSQL. |
| **Verificación realizada** | Se ejecutó el script dentro de una transacción (`BEGIN;`). Se intentó un `INSERT` con el email "juanperez.com" y el motor abortó la operación (SQL Error [23514]: viola la restricción «chk_cliente_email»). Finalmente, se ejecutó `ROLLBACK;`. |