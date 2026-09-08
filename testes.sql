
SET STATISTICS IO ON;

EXEC BuscarClientes @LastName = 'Yang';

EXEC BuscarClientes @LastName = 'Zhu';

EXEC BuscarClientes @Gender = 'F', @MaritalStatus = 'M';

EXEC BuscarClientes @Gender = 'F', @PageNumber = 1, @PageSize = 5;
EXEC BuscarClientes @Gender = 'F', @PageNumber = 2, @PageSize = 5;


EXEC sp_helpindex 'DimCustomer';