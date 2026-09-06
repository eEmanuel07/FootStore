# Ejercicio de Lectura Crítica (Parte 3)

## Análisis del Script 1

**Script original generado por IA:**
```sql
-- Generado para: dar de baja las funciones de películas retiradas de cartel
UPDATE funcion
SET activa = FALSE;
```

*   **Qué filas afectaría realmente:** Modificaría absolutamente todas las filas de la tabla `funcion`, estableciendo la columna `activa` en `FALSE` para todo el conjunto de datos.
*   **Por qué no coincide con la consigna:** El script carece de una cláusula `WHERE`. En lugar de dar de baja únicamente las películas retiradas de cartel, inactiva toda la cartelera del sistema de forma destructiva.
*   **Versión corregida:** Se debe agregar un filtro condicional (asumiendo que existe un identificador o una relación con la tabla de películas).
```sql
UPDATE funcion 
SET activa = FALSE 
WHERE id_pelicula IN (SELECT id_pelicula FROM pelicula WHERE estado = 'Retirada');
```

---

## Análisis del Script 2

**Script original generado por IA:**
```sql
-- Generado para: limpiar las categorías sin productos asociados
DELETE FROM categoria
WHERE id NOT IN (SELECT categoria_id FROM producto);
```

*   **Qué filas afectaría realmente:** Si en la tabla `producto` existe al menos un registro cuyo `categoria_id` sea `NULL`, la cláusula `NOT IN` evaluará como desconocido (`UNKNOWN`) debido a la lógica trivaluada de SQL. Como resultado, el motor no borrará ninguna fila de la tabla `categoria`, fallando silenciosamente[cite: 1].
*   **Por qué no coincide con la consigna:** No cumple con la limpieza de categorías sin productos asociados si la base de datos contiene algún producto huérfano (sin categoría asignada), lo cual es un escenario común[cite: 1].
*   **Versión corregida:** Se debe filtrar el valor `NULL` en la subconsulta o utilizar el operador `NOT EXISTS`, que es más seguro y eficiente.
```sql
-- Opción 1: Filtrando NULLs en el NOT IN
DELETE FROM categoria
WHERE id NOT IN (SELECT categoria_id FROM producto WHERE categoria_id IS NOT NULL);

-- Opción 2: Usando NOT EXISTS (Recomendada)
DELETE FROM categoria c
WHERE NOT EXISTS (
    SELECT 1 FROM producto p WHERE p.categoria_id = c.id
);
```