# Laboratorio de Concurrencia (Parte 2)

## Escenario 1: Espera por bloqueo (Lock wait)

### 1. Scripts Ejecutados
**Sesión A:**
```sql
BEGIN;
SELECT * FROM cliente WHERE id_cliente = 1 FOR UPDATE;
-- (Se ejecuta COMMIT luego de la prueba en B)
COMMIT;
```

**Sesión B:**
```sql
BEGIN;
SELECT * FROM cliente WHERE id_cliente = 1 FOR UPDATE;
-- (La sesión queda en espera hasta la liberación de A)
COMMIT;
```

### 2. Justificación Teórica
Cuando una Sesión A ejecuta un SELECT ... FOR UPDATE dentro de una transacción, PostgreSQL adquiere un bloqueo exclusivo a nivel de fila (Exclusive Row-Level Lock) sobre las tuplas seleccionadas. Si una Sesión B intenta ejecutar simultáneamente otro SELECT ... FOR UPDATE (o cualquier sentencia UPDATE/DELETE) sobre ese mismo registro antes de que la primera transacción finalice, el motor detecta un conflicto de bloqueos incompatibles. La Sesión B pasa automáticamente a un estado de espera por bloqueo (Lock Wait), quedando pausada encolada en el gestor de bloqueos hasta que la Sesión A libere el recurso mediante un COMMIT o ROLLBACK.

Una vez que la Sesión A confirma sus cambios (COMMIT), el bloqueo se libera y PostgreSQL reactiva de inmediato a la Sesión B. Bajo el modelo MVCC de PostgreSQL, la Sesión B reevalúa la fila obteniendo la versión más reciente del registro ya modificado por la Sesión A y adquiere su propio bloqueo exclusivo para proceder de manera ordenada y determinista sin arrojar errores de concurrencia.

Este mecanismo de bloqueo pesimista es indispensable en sistemas transaccionales (OLTP) para preservar las propiedades ACID (especialmente Aislamiento y Consistencia). Previene anomalías graves como actualizaciones perdidas (Lost Updates) y condiciones de carrera (Race Conditions) en operaciones críticas concurrentes (por ejemplo, descuento de stock o transferencias de saldo), garantizando que las modificaciones sobre un mismo recurso se serialicen y procesen con absoluta integridad de datos.

### 3. Declaración de Uso de IA (DUIA) - Escenario 1

| Campo | Completar |
| :--- | :--- |
| **Herramienta** | OpenCode (Gemini 3.5 Flash) |
| **Spec o prompt utilizado** | Escribí una breve justificación teórica explicando qué sucede a nivel de concurrencia y bloqueos cuando una Sesión A ejecuta un SELECT ... FOR UPDATE y una Sesión B intenta hacer lo mismo. Explicá el concepto de Lock wait y su utilidad en un sistema transaccional. |
| **Qué generó** | Una explicación técnica detallando el bloqueo exclusivo a nivel de fila, el estado de espera (Lock Wait) y la importancia del bloqueo pesimista para preservar las propiedades ACID. |
| **Qué se aceptó** | Se aceptó el texto íntegramente. |
| **Qué se modificó o descartó, y por qué** | No se realizaron modificaciones, la explicación es precisa y responde al comportamiento observado en PostgreSQL. |
| **Verificación realizada** | La justificación teórica coincide exactamente con la prueba empírica realizada en DBeaver, donde la Sesión B quedó bloqueada hasta el COMMIT de la Sesión A. |


## Escenario 2: Interbloqueo cruzado (Deadlock)

### 1. Scripts Ejecutados
**Paso 1 - Sesión A:**
```sql
BEGIN;
SELECT * FROM cliente WHERE id_cliente = 2 FOR UPDATE;
```

**Paso 2 - Sesión B:**
```sql
BEGIN;
SELECT * FROM cliente WHERE id_cliente = 4 FOR UPDATE;
```

**Paso 3 - Sesión A:**
```sql
-- La sesión queda en espera por bloqueo
SELECT * FROM cliente WHERE id_cliente = 4 FOR UPDATE;
```

**Paso 4 - Sesión B:**
```sql
-- Genera dependencia circular y el motor aborta la transacción
SELECT * FROM cliente WHERE id_cliente = 2 FOR UPDATE;
```

**Limpieza (Ambas sesiones):**
```sql
ROLLBACK;
```

### 2. Justificación Teórica
Un interbloqueo o Deadlock (identificado en PostgreSQL con el código de error SQLSTATE 40P01) ocurre cuando dos o más transacciones concurrentes generan una dependencia circular sobre recursos protegidos por bloqueos incompatibles. Por ejemplo, si la Transacción A bloquea la fila 1 y solicita un bloqueo sobre la fila 2 (en poder de la Transacción B), mientras que la Transacción B solicita simultáneamente la fila 1, ninguna de las dos transacciones puede avanzar ni liberar sus propios bloqueos. Esta condición de espera circular cruzada —conocida conceptualmente como "abrazo mortal"— provocaría que ambos procesos quedaran congelados indefinidamente en un estado de Lock Wait mutuo si el motor no interviniera.

Para gestionar esta situación, PostgreSQL cuenta con un proceso detector de interbloqueos (Deadlock Detector) que se dispara automáticamente cuando una transacción permanece bloqueada durante un tiempo superior al parámetro configurable deadlock_timeout (por defecto, 1 segundo). El motor construye e inspecciona un grafo de dependencias de espera (Wait-For Graph), donde los nodos representan transacciones activas y las aristas dirigidas indican qué transacción está esperando a cuál. Si el detector identifica un ciclo cerrado en el grafo, confirma la existencia del interbloqueo irresoluble por vías normales.

Para romper el ciclo, el motor selecciona automáticamente una de las transacciones involucradas (denominada transacción "víctima"), interrumpe su ejecución y le envía una señal de error ERROR: deadlock detected (SQLSTATE 40P01), forzando su aborto (ROLLBACK) y liberando de inmediato todos sus bloqueos. De este modo, la otra transacción en disputa obtiene el recurso solicitado, sale del estado de espera y puede completar sus operaciones y hacer COMMIT exitosamente, permitiendo a la aplicación reintentar la transacción fallida de forma segura.

### 3. Declaración de Uso de IA (DUIA) - Escenario 2

| Campo | Completar |
| :--- | :--- |
| **Herramienta** | OpenCode (Gemini 3.5 Flash) |
| **Spec o prompt utilizado** | Escribí una breve justificación teórica explicando por qué ocurre un Deadlock (Error 40P01) cuando dos transacciones concurrentes intentan acceder a recursos cruzados, y cómo el motor aborta uno de los procesos. |
| **Qué generó** | Una explicación detallada sobre dependencias circulares, el funcionamiento del "Deadlock Detector" y el grafo de dependencias (Wait-For Graph) para seleccionar una transacción víctima. |
| **Qué se aceptó** | Se aceptó el texto íntegramente. |
| **Qué se modificó o descartó, y por qué** | No se realizaron modificaciones, la explicación técnica abordó correctamente el error observado (40P01). |
| **Verificación realizada** | Se forzó un abrazo mortal cruzando bloqueos de actualización sobre los IDs 2 y 4 en dos sesiones distintas. Se comprobó que el motor intervino automáticamente cancelando una de las transacciones y emitiendo el error 40P01, tal como indica la teoría. |

