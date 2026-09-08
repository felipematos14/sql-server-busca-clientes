IF OBJECT_ID('BuscarClientes', 'P') IS NOT NULL
    DROP PROCEDURE BuscarClientes;
GO
CREATE PROCEDURE BuscarClientes
	@FirstName              NVARCHAR(50) = NULL,
	@LastName               NVARCHAR(50) = NULL,
	@MaritalStatus           NCHAR(1)    = NULL, 
	@Gender                 NCHAR(1)     = NULL, 
	@RendaMinima            MONEY        = NULL, 
	@RendaMaxima            MONEY        = NULL,
	@PageNumber             INT          = 1,
    @PageSize               INT          = 20
AS 
BEGIN
	SELECT FirstName, LastName, Gender, MaritalStatus, YearlyIncome
	FROM DimCustomer
	WHERE (FirstName = @FirstName or  @FirstName IS NULL) 
	AND (LastName = @LastName OR  @LastName IS NULL) 
	AND (MaritalStatus = @MaritalStatus OR @MaritalStatus IS NULL) 
	AND (Gender = @Gender OR @Gender IS NULL) 
	AND (YearlyIncome >= @RendaMinima OR @RendaMinima IS NULL)
    AND (YearlyIncome <= @RendaMaxima OR @RendaMaxima IS NULL)
	ORDER BY CustomerKey
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;

END
GO

