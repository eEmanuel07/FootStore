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