-- Onlium Mobile database schema for SQL Server

CREATE DATABASE OnliumMobile;
GO

USE OnliumMobile;
GO

CREATE TABLE Users (
    Id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(255) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(512) NOT NULL,
    StudentType NVARCHAR(50) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2 NULL
);

CREATE TABLE Admins (
    Id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Email NVARCHAR(255) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(512) NOT NULL,
    FullName NVARCHAR(200) NOT NULL,
    Role NVARCHAR(50) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2 NULL
);

CREATE TABLE EnrollmentRequests (
    Id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    StudentId INT NOT NULL,
    StudentName NVARCHAR(200) NOT NULL,
    StudentEmail NVARCHAR(255) NOT NULL,
    StudentType NVARCHAR(50) NOT NULL,
    Program NVARCHAR(200) NOT NULL,
    Status NVARCHAR(50) NOT NULL,
    SubmittedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    ReviewedAt DATETIME2 NULL,
    ReviewedBy INT NULL,
    ReviewNotes NVARCHAR(MAX) NULL,
    CONSTRAINT FK_EnrollmentRequests_Users FOREIGN KEY (StudentId) REFERENCES Users(Id),
    CONSTRAINT FK_EnrollmentRequests_Admins FOREIGN KEY (ReviewedBy) REFERENCES Admins(Id)
);

-- Example admin user (replace password hash with a real hash in production)
INSERT INTO Admins (Email, PasswordHash, FullName, Role)
VALUES ('admin@onlium.edu', 'PLACEHOLDER_HASH', 'System Admin', 'superAdmin');

-- Additional tables for other app functions

CREATE TABLE StudyLoads (
    Id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    Year NVARCHAR(10) NOT NULL,
    Program NVARCHAR(200) NOT NULL,
    Subjects NVARCHAR(MAX) NOT NULL, -- store subject list as JSON or delimited string
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2 NULL,
    CONSTRAINT FK_StudyLoads_Users FOREIGN KEY (UserId) REFERENCES Users(Id)
);

CREATE TABLE Appointments (
    Id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    Title NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    Date DATETIME2 NOT NULL,
    Status NVARCHAR(50) NOT NULL DEFAULT 'scheduled',
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2 NULL,
    CONSTRAINT FK_Appointments_Users FOREIGN KEY (UserId) REFERENCES Users(Id)
);

CREATE TABLE Resources (
    Id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(200) NOT NULL,
    Url NVARCHAR(500) NOT NULL,
    Category NVARCHAR(100) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2 NULL
);
