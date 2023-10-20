-- Actividad 3.1

-- #
-- Ejercicio
-- 1
-- Crear una vista llamada VW_Multas que permita visualizar la información de las multas con los datos del agente incluyendo apellidos y nombres, nombre de la localidad, patente del vehículo, fecha y monto de la multa.

CREATE VIEW VW_Multas
AS
SELECT a.Apellidos, a.Nombres, loc.Localidad, m.Patente, m.FechaHora,m.Monto from Agentes a INNER JOIN Multas m on a.IdAgente=m.IdAgente INNER JOIN Localidades loc on m.IDLocalidad=loc.IDLocalidad
GO

SELECT * FROM VW_Multas

-- 2
-- Modificar la vista VW_Multas para incluir el legajo del agente, la antigüedad en años, el nombre de la provincia junto al de la localidad y la descripción del tipo de multa.
GO
ALTER VIEW VW_Multas
AS
SELECT a.Legajo, DATEDIFF(YEAR,a.FechaIngreso, GETDATE()) Antiguedad , a.Apellidos, a.Nombres , pr.Provincia ,loc.Localidad, m.Patente, m.FechaHora,m.Monto, ti.Descripcion  from Agentes a INNER JOIN Multas m on a.IdAgente=m.IdAgente INNER JOIN Localidades loc on m.IDLocalidad=loc.IDLocalidad INNER JOIN Provincias pr on pr.IDProvincia=loc.IDProvincia INNER JOIN TipoInfracciones ti on m.IdTipoInfraccion=ti.IdTipoInfraccion
GO

-- 3
-- Crear un procedimiento almacenado llamado SP_MultasVehiculo que reciba un parámetro que representa la patente de un vehículo. Listar las multas que registra. Indicando fecha y hora de la multa, descripción del tipo de multa e importe a abonar. También una leyenda que indique si la multa fue abonada o no.

CREATE PROCEDURE SP_MultasVehiculo (
    @Patente varchar(10)
)
AS
BEGIN 
    SELECT m.FechaHora, ti.Descripcion, m.Monto,
    case
    when m.pagada=0 then 'Abonada'
    else 'Sin abonar'
    end as Multa
    FROM Multas m INNER JOIN TipoInfracciones ti on m.IdTipoInfraccion=ti.IdTipoInfraccion WHERE m.Patente=@Patente
END


SELECT Patente FROM Multas
EXEC SP_MultasVehiculo 'AB123CD'

-- 4
-- Crear una funcion que reciba un parametro que representa la patente de un vehiculo y devuelva el total adeudado por ese vehiculo en concepto de multas.
go
CREATE FUNCTION FN_DeudaXPatente (
    @Patente varchar(10)
)
RETURNS money
BEGIN
    DECLARE @total money
    SELECT @total=ISNULL(SUM(m.Monto), 0) FROM Multas m WHERE m.Patente=@Patente

    RETURN @total
end
GO

SELECT dbo.FN_DeudaXPatente(m.Patente), m.Patente from Multas m 

-- 5
-- Crear una funcion que reciba un parametro que representa la patente de un vehiculo y devuelva el total abonado por ese vehiculo en concepto de multas.
GO
CREATE FUNCTION FN_MontoAbonado (
    @Patente VARCHAR(10)
)
RETURNS money
BEGIN
    DECLARE @total money

    select @total=ISNULL(SUM(p.Importe),0) FROM Multas m INNER JOIN Pagos p on m.IdMulta=p.IDMulta WHERE m.Patente=@Patente GROUP BY m.Patente
    
    RETURN @total
END

-- 6
-- Crear un procedimiento almacenado llamado SP_AgregarMulta que reciba IDTipoInfraccion, IDLocalidad, IDAgente, Patente, Fecha y hora, Monto a abonar y registre la multa.
GO
CREATE PROCEDURE SP_AgregarMulta (
    @idtipoinfracion int,
    @idlocalidad int,
    @idagente int, 
    @patente varchar(10),
    @fechahora datetime,
    @monto money
)
AS
BEGIN
    insert into Multas (IdTipoInfraccion, IDLocalidad, IdAgente, Patente, FechaHora, Monto, Pagada) VALUES (@idtipoinfracion, @idlocalidad, @idagente, @patente, @fechahora, @monto, 0)
END


-- 7
-- Crear un procedimiento almacenado llamado SP_ProcesarPagos que determine el estado Pagada de todas las multas a partir de los pagos que se encuentran registrados.
GO
CREATE PROCEDURE SP_ProcesarPagos
AS
BEGIN
    UPDATE Multas set Pagada=1 where IdMulta IN (SELECT m.IdMulta FROM Multas m INNER JOIN Pagos p on m.IdMulta=p.IDMulta GROUP BY m.IdMulta, m.Monto HAVING SUM(p.Importe)>m.Monto)
END


SELECT m.IdMulta FROM Multas m INNER JOIN Pagos p on m.IdMulta=p.IDMulta GROUP BY m.IdMulta, m.Monto HAVING SUM(p.Importe)>m.Monto

EXEC SP_ProcesarPagos
SELECT * FROM Multas