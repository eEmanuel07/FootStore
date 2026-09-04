-- Creación de tipos enumerados para dominios cerrados
CREATE TYPE forma_pago_enum AS ENUM ('Efectivo', 'Tarjeta de Débito', 'Tarjeta de Crédito', 'Mercado Pago');

-- Tabla Categoria
CREATE TABLE categoria (
    id_categoria BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE
);

-- Tabla Cliente
CREATE TABLE cliente (
    id_cliente BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE, -- Restricción UNIQUE que refleja clave candidata (Parte 1)
    direccion VARCHAR(150) NOT NULL
);

-- Tabla Producto
CREATE TABLE producto (
    id_producto BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    precio NUMERIC(10, 2) NOT NULL,
    id_categoria BIGINT NOT NULL,
    CONSTRAINT fk_producto_categoria FOREIGN KEY (id_categoria) 
        REFERENCES categoria(id_categoria) 
        ON DELETE RESTRICT, -- RESTRICT: evita borrar una categoría si todavía tiene productos asociados en el menú
    CONSTRAINT chk_producto_precio_positivo CHECK (precio > 0) -- Check de regla de negocio: precio positivo
);

-- Tabla Pedido
CREATE TABLE pedido (
    id_pedido BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fecha TIMESTAMPTZ NOT NULL DEFAULT now(), -- DEFAULT: fecha de creación automática en la inserción
    forma_pago forma_pago_enum NOT NULL,
    id_cliente BIGINT NOT NULL,
    CONSTRAINT fk_pedido_cliente FOREIGN KEY (id_cliente) 
        REFERENCES cliente(id_cliente) 
        ON DELETE RESTRICT -- RESTRICT: no se puede eliminar un cliente que posee historial de pedidos
);

-- Tabla Intermedia Detalle_Pedido (Relación N:M entre Pedido y Producto)
CREATE TABLE detalle_pedido (
    id_detalle BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pedido BIGINT NOT NULL,
    id_producto BIGINT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario NUMERIC(10, 2) NOT NULL,
    CONSTRAINT fk_detalle_pedido FOREIGN KEY (id_pedido) 
        REFERENCES pedido(id_pedido) 
        ON DELETE CASCADE, -- CASCADE: si se elimina el pedido, se eliminan sus líneas de detalle asociadas
    CONSTRAINT fk_detalle_producto FOREIGN KEY (id_producto) 
        REFERENCES producto(id_producto) 
        ON DELETE RESTRICT, -- RESTRICT: no se puede borrar un producto si figura en algún detalle histórico de venta
    CONSTRAINT chk_detalle_cantidad_positiva CHECK (cantidad > 0), -- Check de regla de negocio: cantidad mayor a cero
    CONSTRAINT chk_detalle_precio_unitario CHECK (precio_unitario >= 0) -- Check de regla de negocio: precio unitario no negativo
);

-- Índices recomendados para optimizar consultas frecuentes

-- Índice para acelerar la búsqueda y listado de los pedidos realizados por un cliente específico
CREATE INDEX idx_pedido_id_cliente ON pedido(id_cliente);

-- Índice para acelerar el filtrado y listado de productos vigentes que pertenecen a una categoría concreta
CREATE INDEX idx_producto_id_categoria ON producto(id_categoria);