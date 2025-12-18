-- create database company

-- use company


CREATE TABLE DEPARTMENT (
    DNumber  INT PRIMARY KEY,
    DName    NVARCHAR(100) NOT NULL UNIQUE,
    [Location] NVARCHAR(100) NOT NULL
);
-- drop table DEPARTMENT

CREATE TABLE EMPLOYEE (
    SSN              VARCHAR(14) PRIMARY KEY,
    Fname            NVARCHAR(50) NOT NULL,
    Lname            NVARCHAR(50) NOT NULL,
    BirthDate        DATE NOT NULL,
    Gender           CHAR(1) NOT NULL,
    Salary           int NOT NULL DEFAULT 5000,
    DepartmentNumber INT NOT NULL,
    SupervisorSSN    VARCHAR(14) NULL
);


ALTER TABLE EMPLOYEE
ADD CONSTRAINT FK_Employee_Department
FOREIGN KEY (DepartmentNumber)
REFERENCES DEPARTMENT(DNumber)
ON UPDATE CASCADE;


ALTER TABLE [dbo].[EMPLOYEE]
ADD CONSTRAINT FK_Employee_Supervisor
FOREIGN KEY (SupervisorSSN) REFERENCES [dbo].[EMPLOYEE](SSN)
ON DELETE NO ACTION
ON UPDATE NO ACTION;


CREATE TABLE PROJECT (
    PNumber          INT PRIMARY KEY,
    PName            NVARCHAR(100) NOT NULL,
    LocationCity     NVARCHAR(100) NOT NULL,
    DepartmentNumber INT NOT NULL,
    CONSTRAINT FK_Project_Department
        FOREIGN KEY (DepartmentNumber)
        REFERENCES DEPARTMENT(DNumber)
        ON UPDATE CASCADE
);


CREATE TABLE DEPENDENT (
    EmpSSN        VARCHAR(14) NOT NULL,
    DependentName NVARCHAR(100) NOT NULL,
    Gender        CHAR NOT NULL,
    BirthDate     DATE NOT NULL,

    CONSTRAINT PK_Dependent
        PRIMARY KEY (EmpSSN, DependentName),

    CONSTRAINT FK_Dependent_Employee
        FOREIGN KEY (EmpSSN)
        REFERENCES EMPLOYEE(SSN)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

INSERT INTO DEPARTMENT VALUES
(1, 'Research', 'Building A'),
(2, 'Administration', 'Building B'),
(3, 'Sales', 'Building C');


INSERT INTO EMPLOYEE
(SSN, Fname, Lname, BirthDate, Gender, Salary, DepartmentNumber)
VALUES
('15461165461256', 'Amr', 'Soliman', '2005-01-19', 'M', 9000, 1),
('65444651894565', 'Wael', 'Thabet', '1972-11-11', 'M', 8000, 1),
('89465498455689', 'Khaled', 'Soliman', '2007-07-16', 'M', 7000, 2),
('46989845615845', 'Rania', 'Mohamed', '1981-01-10', 'F', 7500, 3),
('54984568965489', 'Ahmed', 'Thabet', '2003-11-1', 'M', 7200, 3);



INSERT INTO PROJECT VALUES
(10, 'AI Platform', 'Cairo', 1),
(20, 'HR System', 'Giza', 2),
(30, 'Sales Optimization', 'Alexandria', 3);


UPDATE EMPLOYEE
SET DepartmentNumber = 2
WHERE SSN = '15461165461256';



CREATE TABLE DEPARTMENT_MANAGER (
    DepartmentNumber INT PRIMARY KEY,
    ManagerSSN       VARCHAR(14) NOT NULL UNIQUE,
    HireDate         DATE NOT NULL,

    CONSTRAINT FK_Manager_Department
        FOREIGN KEY (DepartmentNumber)
        REFERENCES DEPARTMENT(DNumber)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT FK_Manager_Employee
        FOREIGN KEY (ManagerSSN)
        REFERENCES EMPLOYEE(SSN)
);


DELETE FROM DEPENDENT
WHERE EmpSSN = '32165456451231'
AND DependentName = 'Layla';

CREATE TABLE WORKS_ON (
    EmpSSN VARCHAR(14) NOT NULL,
    PNumber INT NOT NULL,
    Hours   DECIMAL(5,2) NOT NULL DEFAULT 0
        CHECK (Hours >= 0),

    CONSTRAINT PK_WorksOn
        PRIMARY KEY (EmpSSN, PNumber),

    CONSTRAINT FK_WorksOn_Employee
        FOREIGN KEY (EmpSSN)
        REFERENCES EMPLOYEE(SSN)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,

    CONSTRAINT FK_WorksOn_Project
        FOREIGN KEY (PNumber)
        REFERENCES PROJECT(PNumber)
        ON UPDATE CASCADE
        ON DELETE NO ACTION
);


SELECT 
    E.Fname,
    E.Lname,
    P.PName,
    W.Hours
FROM EMPLOYEE E
JOIN WORKS_ON W ON E.SSN = W.EmpSSN
JOIN PROJECT P ON W.PNumber = P.PNumber;

