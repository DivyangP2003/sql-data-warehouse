/*
============================================================
Create Database and Schemas
============================================================

Script Purpose:
   This script creates a new database named 'DataWarehouse' after checking if it already exists. 
   If the database exists, it is dropped and recreated. 
   Additionally, the script sets up three schemas within the database: 'bronze', 'silver', and 'gold'.

WARNING:
   Running this script will drop the entire 'DataWarehouse' database if it exists. 
   All data in the database will be permanently deleted. 
   Proceed with caution and ensure you have proper backups before running this script.
*/

USE Master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    -- Force disconnect all sessions and drop the existing DataWarehouse
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- Create a fresh DataWarehouse database
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Ensure required schemas exist for data layers
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'bronze')
BEGIN
    EXEC('CREATE SCHEMA bronze');
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'silver')
BEGIN
    EXEC('CREATE SCHEMA silver');
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold');
END;
GO
