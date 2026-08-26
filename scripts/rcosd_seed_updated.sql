DROP USER rcosd CASCADE;
CREATE USER rcosd IDENTIFIED BY Changeme0;
ALTER USER rcosd QUOTA UNLIMITED ON USERS;
GRANT CREATE SESSION TO rcosd WITH ADMIN OPTION;
GRANT CONNECT TO rcosd;
ALTER SESSION SET current_schema = rcosd;
DROP TABLE person CASCADE CONSTRAINTS;
DROP TABLE login CASCADE CONSTRAINTS;
DROP TABLE offense CASCADE CONSTRAINTS;
DROP TABLE disciplinaryAction CASCADE CONSTRAINTS;
DROP TABLE employee CASCADE CONSTRAINTS;
DROP TABLE student CASCADE CONSTRAINTS;
DROP TABLE disciplinaryStatus CASCADE CONSTRAINTS;
DROP TABLE enrollment CASCADE CONSTRAINTS;
DROP TABLE record CASCADE CONSTRAINTS;
DROP TABLE appeal CASCADE CONSTRAINTS;
DROP TABLE request CASCADE CONSTRAINTS;
DROP TABLE guardian CASCADE CONSTRAINTS;
DROP TABLE studentGuardian CASCADE CONSTRAINTS;
DROP TABLE AUDIT_LOG CASCADE CONSTRAINTS;
-- PERSON ENTITY
CREATE TABLE person (
   personID number(20,0) generated as identity
       constraint PERSON_NOT_NULL not null,
   lastName VARCHAR(50) NOT NULL,
   firstName VARCHAR(100) NOT NULL,
   middleName VARCHAR(30),
   dateOfBirth DATE,
   primary key (personID)
);
-- LOGIN ENTITY
CREATE TABLE login (
   id number(20,0) generated as identity
       constraint LOGIN_NOT_NULL not null,
   personID number(20,0) unique,
   username varchar2(25 char)
       constraint LOGIN_USERNAME_NOT_NULL not null,
   password varchar2(255 char)
       constraint LOGIN_PASSWORD_NOT_NULL not null,
   join_date timestamp(6) NOT NULL,
   last_login_date timestamp(6),
   role varchar2(255 char) NOT NULL,
   authorities varchar2(255 char),
   is_active number(1,0) NOT NULL,
   is_locked number(1,0) NOT NULL,
   primary key (id)
);
-- OFFENSE ENTITY
CREATE TABLE offense (
   offenseID number(20,0) generated as identity
       constraint OFFENSE_NOT_NULL not null,
   offense VARCHAR(100),
   type VARCHAR(50),
   description VARCHAR(500),
   PRIMARY KEY (offenseID)
);
-- DISCIPLINARY ACTION ENTITY
CREATE TABLE disciplinaryAction (
   actionID number(20,0) PRIMARY KEY,
   action VARCHAR(100),
   description VARCHAR(500)
);
-- EMPLOYEE ENTITY
CREATE TABLE employee (
   employeeID VARCHAR(10) PRIMARY KEY,
   personID number(20,0) UNIQUE,
   department varchar(20),
   employeeRole VARCHAR(30)
);
-- STUDENT ENTITY
CREATE TABLE student (
   studentID VARCHAR(10) PRIMARY KEY,
   personID number(20,0) UNIQUE,
   address VARCHAR(255),
   studentType VARCHAR(20),
   department VARCHAR(20),
   contactNumber VARCHAR(20)
);
-- DISCIPLINARY STATUS ENTITY
CREATE TABLE disciplinaryStatus (
   disciplinaryStatusID number(20,0) PRIMARY KEY,
   status VARCHAR(30),
   description VARCHAR(255)
);
-- ENROLLMENT ENTITY
CREATE TABLE enrollment (
   enrollmentID number(20,0) generated as identity
       constraint ENROLLMENT_NOT_NULL not null,
   studentID VARCHAR(10),
   schoolYear VARCHAR(9),
   studentLevel VARCHAR(30),
   section VARCHAR(50),
   department VARCHAR(20),
   disciplinaryStatusID number(20,0),
   primary key (enrollmentID)
);
-- RECORD ENTITY
CREATE TABLE record (
   recordID number(20,0) generated as identity
       constraint RECORD_NOT_NULL not null,
   enrollmentID number(20,0),
   employeeID VARCHAR(10),
   offenseID number(20,0),
   dateOfViolation DATE,
   actionID number(20,0),
   dateOfResolution DATE,
   remarks VARCHAR(500),
   status VARCHAR(30),
   primary key (recordID)
);
-- APPEAL ENTITY
CREATE TABLE appeal (
   appealID number(20,0) generated as identity
       constraint APPEAL_NOT_NULL not null,
   recordID number(20,0),
   enrollmentID number(20,0),
   documentID number(20,0),
   message VARCHAR(500),
   dateFiled DATE,
   status VARCHAR(20),
   dateProcessed DATE,
   remarks VARCHAR(500),
   primary key (appealID)
);
--REQUEST ENTITY
CREATE TABLE request (
   requestID number(20,0) generated as identity
       constraint REQUEST_NOT_NULL not null,
   employeeID VARCHAR(10) NOT NULL,
   details VARCHAR(100) NOT NULL,
   message VARCHAR(500) NOT NULL,
   type VARCHAR(100) NOT NULL,
   status VARCHAR(10) NOT NULL,
   dateFiled DATE,
   dateProcessed DATE,
   remarks VARCHAR(500),
   primary key (requestID)
);
-- GUARDIAN ENTITY
CREATE TABLE guardian (
   guardianID number(20,0) generated as identity
       constraint GUARDIAN_NOT_NULL not null,
   personID number(20,0) UNIQUE,
   contactNumber VARCHAR2(20),
   relationship VARCHAR2(50),
   primary key (guardianID)
);
CREATE TABLE studentGuardian (
   studentID VARCHAR2(10),
   guardianID NUMBER(20,0),
   primary key (studentID, guardianID)
);
-- AI SUPPORT MODULE ENTITIES (Tables 14-16 in the thesis paper: Document,
-- Suggestion, Generated Suggestion)
CREATE TABLE document (
   documentID number(20,0) generated as identity
       constraint DOCUMENT_NOT_NULL not null,
   studentID VARCHAR2(10),
   extractedText CLOB,
   primary key (documentID)
);
CREATE TABLE suggestion (
   suggestionID number(20,0) generated as identity
       constraint SUGGESTION_NOT_NULL not null,
   type VARCHAR2(50),
   suggestionText CLOB,
   primary key (suggestionID)
);
CREATE TABLE generatedSuggestion (
   generatedSuggestionID number(20,0) generated as identity
       constraint GENSUGGESTION_NOT_NULL not null,
   suggestionID number(20,0),
   documentID number(20,0),
   generatedText CLOB,
   generatedAt TIMESTAMP,
   primary key (generatedSuggestionID)
);
-- CONSTRAINTS
ALTER TABLE login ADD CONSTRAINT FK_LOGIN_PERSON FOREIGN KEY (personID) REFERENCES person(personID);
ALTER TABLE employee ADD CONSTRAINT FK_EMPLOYEE_PERSON FOREIGN KEY (personID) REFERENCES person(personID);
ALTER TABLE student ADD CONSTRAINT FK_STUDENT_PERSON FOREIGN KEY (personID) REFERENCES person(personID);
ALTER TABLE enrollment ADD CONSTRAINT FK_ENROLL_STUDENT FOREIGN KEY (studentID) REFERENCES student(studentID);
ALTER TABLE enrollment ADD CONSTRAINT FK_ENROLL_STATUS FOREIGN KEY (disciplinaryStatusID) REFERENCES disciplinaryStatus(disciplinaryStatusID);
ALTER TABLE record ADD CONSTRAINT FK_RECORD_ENROLLMENT FOREIGN KEY (enrollmentID) REFERENCES enrollment(enrollmentID);
ALTER TABLE record ADD CONSTRAINT FK_RECORD_EMPLOYEE FOREIGN KEY (employeeID) REFERENCES employee(employeeID);
ALTER TABLE record ADD CONSTRAINT FK_RECORD_OFFENSE FOREIGN KEY (offenseID) REFERENCES offense(offenseID);
ALTER TABLE record ADD CONSTRAINT FK_RECORD_ACTION FOREIGN KEY (actionID) REFERENCES disciplinaryAction(actionID);
ALTER TABLE appeal ADD CONSTRAINT FK_APPEAL_RECORD FOREIGN KEY (recordID) REFERENCES record(recordID);
ALTER TABLE appeal ADD CONSTRAINT FK_APPEAL_ENROLLMENT FOREIGN KEY (enrollmentID) REFERENCES enrollment(enrollmentID);
ALTER TABLE request ADD CONSTRAINT FK_REQUEST_EMPLOYEE FOREIGN KEY (employeeID) REFERENCES employee(employeeID);
ALTER TABLE guardian ADD CONSTRAINT FK_GUARDIAN_PERSON FOREIGN KEY (personID) REFERENCES person(personID);
ALTER TABLE studentGuardian ADD CONSTRAINT FK_SG_STUDENT FOREIGN KEY (studentID) REFERENCES student(studentID);
ALTER TABLE studentGuardian ADD CONSTRAINT FK_SG_GUARDIAN FOREIGN KEY (guardianID) REFERENCES guardian(guardianID);
ALTER TABLE document ADD CONSTRAINT FK_DOCUMENT_STUDENT FOREIGN KEY (studentID) REFERENCES student(studentID);
ALTER TABLE appeal ADD CONSTRAINT FK_APPEAL_DOCUMENT FOREIGN KEY (documentID) REFERENCES document(documentID);
ALTER TABLE generatedSuggestion ADD CONSTRAINT FK_GENSUGG_SUGGESTION FOREIGN KEY (suggestionID) REFERENCES suggestion(suggestionID);
ALTER TABLE generatedSuggestion ADD CONSTRAINT FK_GENSUGG_DOCUMENT FOREIGN KEY (documentID) REFERENCES document(documentID);
ALTER TABLE record ADD CONSTRAINT CHK_RECORD_STATUS CHECK (status IN ('PENDING', 'RESOLVED', 'APPEALED'));
ALTER TABLE employee ADD CONSTRAINT CHK_EMPLOYEE_DEPT CHECK (department IN ('JHS', 'SHS', 'COLLEGE'));
ALTER TABLE student ADD CONSTRAINT CHK_STUDENT_DEPT CHECK (department IN ('JHS', 'SHS', 'COLLEGE'));
ALTER TABLE enrollment ADD CONSTRAINT CHK_ENROLL_DEPT CHECK (department IN ('JHS', 'SHS', 'COLLEGE'));
ALTER TABLE guardian ADD CONSTRAINT CHK_GUARDIAN_RELATIONSHIP CHECK (relationship IN ('FATHER', 'MOTHER', 'GUARDIAN'));
-- AUDIT_LOG ENTITY (added for BE-44 audit logging; not part of the
-- original DDL script, since it was built before the schema-alignment
-- pass - see AuditLog.java)
CREATE TABLE AUDIT_LOG (
   AUDIT_LOG_ID number(20,0) generated as identity
       constraint AUDIT_LOG_NOT_NULL not null,
   ACTOR_USERNAME VARCHAR2(255 char) NOT NULL,
   ACTION VARCHAR2(255 char) NOT NULL,
   ENTITY_TYPE VARCHAR2(255 char) NOT NULL,
   ENTITY_ID VARCHAR2(255 char) NOT NULL,
   DETAILS VARCHAR2(4000 char),
   OCCURRED_AT TIMESTAMP NOT NULL,
   primary key (AUDIT_LOG_ID)
);
-- TEST DATA
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Bayona', 'Wilrow', 'Reosa', TO_DATE('2003-02-01', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Cain', 'Carl Justine', 'Dela Cruz', TO_DATE('2003-05-08', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Camama', 'Mark Joshua', 'Reyes', TO_DATE('2007-03-24', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Cruz', 'John Zenith', 'Pasion', TO_DATE('2008-11-24', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('De Gala', 'Angel Lowyza', 'Resurreccion', TO_DATE('2004-02-19', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('De Rojas', 'Geoffrey Allen', 'Villanueva', TO_DATE('2005-01-01', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Quevada', 'Keith Jasper', 'Brioso', TO_DATE('2008-04-08', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Reyes', 'Leeane Glazel', 'Nialda', TO_DATE('2004-10-01', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Santos', 'Juan', 'Dela Cruz', TO_DATE('2004-04-23', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Reyes', 'Maria', 'Lopez', TO_DATE('2003-12-18', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Cruz', 'Angelo', 'Perez', TO_DATE('2005-04-15', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Garcia', 'Sophia', 'Martinez', TO_DATE('2004-05-26', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Mendoza', 'Daniel', 'Rivera', TO_DATE('2008-03-23', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Flores', 'Camille', 'Torres', TO_DATE('2005-06-09', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Navarro', 'Joshua', 'Bautista', TO_DATE('2007-04-25', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Ramos', 'Patricia', 'King', TO_DATE('2006-02-03', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Villanueva', 'Mark', 'Andres', TO_DATE('2005-02-12', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Castillo', 'Nicole', 'Santiago', TO_DATE('2006-10-09', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Delgado', 'Anthony', 'Reyes', TO_DATE('2014-12-15', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Cabrera', 'Elaine', 'Torres', TO_DATE('2014-07-03', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Molina', 'Francis', 'Alcantara', TO_DATE('2012-11-20', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Torralba', 'Bianca', 'Lopez', TO_DATE('2012-10-07', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Villanueva', 'Rafael', 'Castillo', TO_DATE('2014-01-22', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Sarmiento', 'Nicole', 'Garcia', TO_DATE('2013-05-03', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Dizon', 'Kevin', 'Bautista', TO_DATE('2013-02-13', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Alcantara', 'Jasmine', 'Perez', TO_DATE('2012-08-21', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Ramirez', 'Carlos', 'Morales', TO_DATE('2012-03-12', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Lozada', 'Patricia', 'Santos', TO_DATE('2012-04-22', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Estrella', 'Leah', 'Montero', TO_DATE('2009-12-22', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Padilla', 'Miguel', 'Sarmiento', TO_DATE('2008-02-20', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Torres', 'Isabelle', 'Delos Santos', TO_DATE('2008-03-18', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Reyes', 'Christian', 'Alvarez', TO_DATE('2008-04-06', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Salvador', 'Ariana', 'Villanueva', TO_DATE('2009-07-09', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Cruz', 'Nathan', 'Lopez', TO_DATE('2008-12-18', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Velasco', 'Sophia', 'Garcia', TO_DATE('2010-11-11', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Martinez', 'Joshua', 'Perez', TO_DATE('2010-04-27', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Ortega', 'Patricia', 'Dela Rosa', TO_DATE('2010-06-13', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Javier', 'Rico', 'Perez', TO_DATE('2009-02-07', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Aguilar', 'Bryan', 'Castro', TO_DATE('2012-04-21', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Bautista', 'Angela', 'Reyes', TO_DATE('2011-07-21', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Castro', 'John Paul', 'Santos', TO_DATE('2011-03-09', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Domingo', 'Liza', 'Garcia', TO_DATE('2013-04-24', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Espino', 'Carlo', 'Mendoza', TO_DATE('2012-12-19', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Fajardo', 'Katrina', 'Lopez', TO_DATE('2011-10-13', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Galvez', 'Nathan', 'Torres', TO_DATE('2012-04-05', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Herrera', 'Bea', 'Villanueva', TO_DATE('2011-02-25', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Isidro', 'Mark Anthony', 'Ramos', TO_DATE('2014-02-05', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Jimenez', 'Claire', 'Navarro', TO_DATE('2013-11-14', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Aquino', 'Renz', 'Dela Cruz', TO_DATE('2008-02-13', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Balagtas', 'Mikaela', 'Santos', TO_DATE('2009-10-15', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Cunanan', 'Paolo', 'Garcia', TO_DATE('2008-05-18', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('De Guzman', 'Aira', 'Lopez', TO_DATE('2010-11-24', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Eusebio', 'Christian', 'Reyes', TO_DATE('2010-11-18', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Francisco', 'Joy', 'Torres', TO_DATE('2009-11-11', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Gatchalian', 'Kyle', 'Mendoza', TO_DATE('2010-05-14', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Hilario', 'Trisha', 'Villanueva', TO_DATE('2010-08-01', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Ignacio', 'Jerome', 'Ramos', TO_DATE('2008-12-09', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Lacsamana', 'Danica', 'Navarro', TO_DATE('2008-03-17', 'YYYY-MM-DD'));
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Cadorna', 'Jun', 'Pineda', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Pantilanan', 'Anano', 'Riva', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Pacifico', 'Allana', 'Klein', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Belardo', 'Jed', 'Madela', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Demetillo', 'Winibelle', 'Torres', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Montana', 'Danny', 'Belle', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Bayona', 'Wilson', 'Reosa', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Cain', 'Emilyn', 'Dela Cruz', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Camama', 'Belinda', 'Reyes', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Pasion', 'Edith', 'Dugayo', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('De Gala', 'Vilma', 'Resurreccion', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('James', 'Lebron', 'Jim', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Quevada', 'Rochelle', 'Brioso', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Reyes', 'Ghe', 'Nialda', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Santos', 'Pedro', 'Dela Cruz', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Reyes', 'Ana', 'Lopez', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Cruz', 'Roberto', 'Perez', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Garcia', 'Elena', 'Martinez', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Mendoza', 'Carlos', 'Rivera', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Flores', 'Liza', 'Torres', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Navarro', 'Ramon', 'Bautista', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Ramos', 'Cynthia', 'King', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Villanueva', 'Jose', 'Andres', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Castillo', 'Marilyn', 'Santiago', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Delgado', 'Manuel', 'Reyes', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Cabrera', 'Rosa', 'Torres', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Molina', 'Ernesto', 'Alcantara', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Torralba', 'Grace', 'Lopez', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Villanueva', 'Antonio', 'Castillo', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Sarmiento', 'Lourdes', 'Garcia', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Dizon', 'Ricardo', 'Bautista', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Alcantara', 'Teresita', 'Perez', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Ramirez', 'Danilo', 'Morales', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Lozada', 'Evelyn', 'Santos', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Estrella', 'Carlos', 'Montero', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Padilla', 'Rosa', 'Sarmiento', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Torres', 'Antonio', 'Delos Santos', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Reyes', 'Luz', 'Alvarez', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Salvador', 'Eduardo', 'Villanueva', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Cruz', 'Maribel', 'Lopez', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Velasco', 'Fernando', 'Garcia', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Martinez', 'Elena', 'Perez', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Ortega', 'Ricardo', 'Dela Rosa', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Javier', 'Alfredo', 'Perez', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Aguilar', 'Hector', 'Castro', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Bautista', 'Josephine', 'Reyes', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Castro', 'Felix', 'Santos', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Domingo', 'Susan', 'Garcia', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Espino', 'Rolando', 'Mendoza', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Fajardo', 'Daisy', 'Lopez', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Galvez', 'Benigno', 'Torres', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Herrera', 'Cristina', 'Villanueva', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Isidro', 'Oscar', 'Ramos', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Jimenez', 'Teresa', 'Navarro', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Aquino', 'Benito', 'Dela Cruz', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Balagtas', 'Veronica', 'Santos', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Cunanan', 'Mario', 'Garcia', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('De Guzman', 'Angelita', 'Lopez', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Eusebio', 'Norberto', 'Reyes', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Francisco', 'Belinda', 'Torres', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Gatchalian', 'Rogelio', 'Mendoza', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Hilario', 'Rowena', 'Villanueva', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Ignacio', 'Edgardo', 'Ramos', NULL);
INSERT INTO person ( lastName, firstName, middleName, dateOfBirth) VALUES ('Lacsamana', 'Norma', 'Navarro', NULL);
-- Passwords below are BCrypt hashes (cost 10) of the plaintext values from
-- the original script: 'admin' -> admin account, '1234' -> everyone else.
-- The app authenticates via Spring Security's BCryptPasswordEncoder, which
-- cannot match plaintext, so these replace the original plaintext INSERTs.
insert into login (personID, username, password, join_date, last_login_date, role, authorities, is_active, is_locked)
values (1, 'admin', '$2b$10$zK.tj3kKAp6N9J7z.lMC8.X7nOfOru8XtuyDZK1mzpj1biLF6np/.', to_timestamp('2024-01-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), to_timestamp('2024-10-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), 'ROLE_ADMIN', 'user:read,user:create,user:update,user:delete', 1, 0);
insert into login (personID,username, password, join_date, last_login_date, role, authorities, is_active, is_locked)
values (9, 'prefect', '$2b$10$T8VCsavGpS/.Wz/cfDVjHuM4bfnVAUuCnSRXzST2bAPdoRJNVujF.', to_timestamp('2024-01-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), to_timestamp('2024-10-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), 'ROLE_PREFECT', 'user:read,user:create,user:update,user:delete', 1, 0);
insert into login (personID, username, password, join_date, last_login_date, role, authorities, is_active, is_locked)
values (61, 'deptHead','$2b$10$T8VCsavGpS/.Wz/cfDVjHuM4bfnVAUuCnSRXzST2bAPdoRJNVujF.', to_timestamp('2024-01-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), to_timestamp('2024-10-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), 'ROLE_STAFF', 'user:read,user:create,user:update', 1, 0);
insert into login (personID, username, password, join_date, last_login_date, role, authorities, is_active, is_locked)
values (2, 'CT23-0002','$2b$10$T8VCsavGpS/.Wz/cfDVjHuM4bfnVAUuCnSRXzST2bAPdoRJNVujF.', to_timestamp('2024-01-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), to_timestamp('2024-10-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), 'ROLE_USER', 'user:read,user:create,user:update', 1, 0);
insert into login (personID, username, password, join_date, last_login_date, role, authorities, is_active, is_locked)
values (3, 'CT23-0003','$2b$10$T8VCsavGpS/.Wz/cfDVjHuM4bfnVAUuCnSRXzST2bAPdoRJNVujF.', to_timestamp('2024-01-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), to_timestamp('2024-10-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), 'ROLE_USER', 'user:read,user:create,user:update', 1, 0);
insert into login (personID, username, password, join_date, last_login_date, role, authorities, is_active, is_locked)
values (1, 'CT23-0001','$2b$10$T8VCsavGpS/.Wz/cfDVjHuM4bfnVAUuCnSRXzST2bAPdoRJNVujF.', to_timestamp('2024-01-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), to_timestamp('2024-10-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), 'ROLE_USER', 'user:read,user:create,user:update', 1, 0);
insert into login (personID, username, password, join_date, last_login_date, role, authorities, is_active, is_locked)
values (4, 'CT23-0004','$2b$10$T8VCsavGpS/.Wz/cfDVjHuM4bfnVAUuCnSRXzST2bAPdoRJNVujF.', to_timestamp('2024-01-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), to_timestamp('2024-10-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), 'ROLE_USER', 'user:read,user:create,user:update', 1, 0);
insert into login (personID, username, password, join_date, last_login_date, role, authorities, is_active, is_locked)
values (5, 'CT23-0005','$2b$10$T8VCsavGpS/.Wz/cfDVjHuM4bfnVAUuCnSRXzST2bAPdoRJNVujF.', to_timestamp('2024-01-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), to_timestamp('2024-10-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), 'ROLE_USER', 'user:read,user:create,user:update', 1, 0);
insert into login (personID, username, password, join_date, last_login_date, role, authorities, is_active, is_locked)
values (6, 'CT23-0006','$2b$10$T8VCsavGpS/.Wz/cfDVjHuM4bfnVAUuCnSRXzST2bAPdoRJNVujF.', to_timestamp('2024-01-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), to_timestamp('2024-10-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), 'ROLE_USER', 'user:read,user:create,user:update', 1, 0);
insert into login (personID, username, password, join_date, last_login_date, role, authorities, is_active, is_locked)
values (7, 'CT23-0007','$2b$10$T8VCsavGpS/.Wz/cfDVjHuM4bfnVAUuCnSRXzST2bAPdoRJNVujF.', to_timestamp('2024-01-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), to_timestamp('2024-10-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), 'ROLE_USER', 'user:read,user:create,user:update', 1, 0);
insert into login (personID, username, password, join_date, last_login_date, role, authorities, is_active, is_locked)
values (8, 'CT23-0008','$2b$10$T8VCsavGpS/.Wz/cfDVjHuM4bfnVAUuCnSRXzST2bAPdoRJNVujF.', to_timestamp('2024-01-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), to_timestamp('2024-10-01 00:00:00.00', 'yyyy-mm-dd hh24:mi:ss:ff'), 'ROLE_USER', 'user:read,user:create,user:update', 1, 0);
INSERT INTO offense (offense, type, description) VALUES ('Vaping', 'Major Offense', 'Bringing vape');
INSERT INTO offense (offense, type, description) VALUES ('Punching', 'Major Offense', 'Punching another student');
INSERT INTO offense (offense, type, description) VALUES ('Stealing', 'Major Offense', 'Stealing things from another student');
INSERT INTO offense (offense, type, description) VALUES ('Bullying', 'Major Offense', 'Student delivers disrespectful messages to another student that includes threats and intimidation');
INSERT INTO offense (offense, type, description) VALUES ('PDA', 'Major Offense', 'Student engages in inappropriate consensual verbal and/or physical gestures/contact, of a sexual nature to another student.');
INSERT INTO offense (offense, type, description) VALUES ('Cheating', 'Major Offense', 'Student deliberately violates rules or engages in plagiarism or copying anothers work');
INSERT INTO offense (offense, type, description) VALUES ('Skip Class', 'Major Offense', 'Student leaves or misses class without permission');
INSERT INTO offense (offense, type, description) VALUES ('Tardiness', 'Major Offense', 'Student is repeatedly late to class');
INSERT INTO offense (offense, type, description) VALUES ('Technology Violation', 'Major Offense', 'Inappropriate use of gadgets');
INSERT INTO offense (offense, type, description) VALUES ('Use/Possession of Alcohol', 'Major Offense', 'Student is in possession of or is using alcohol');
INSERT INTO offense (offense, type, description) VALUES ('Use/Possession of Drugs', 'Major Offense', 'Student is in possession of or is using illegal drugs');
INSERT INTO offense (offense, type, description) VALUES ('Use/Possession of Tobacco', 'Major Offense', 'Student is in possession of or is using tobacco');
INSERT INTO offense (offense, type, description) VALUES ('Use/Possession of Weapons', 'Major Offense', 'Student is in possession of knives or gun or other object readily capable of causing bodily harm');
INSERT INTO offense (offense, type, description) VALUES ('Use/Possession of Drugs', 'Major Offense', 'Student is in possession of or is using illegal drugs');
INSERT INTO offense (offense, type, description) VALUES ('Disrespect', 'Minor Offense', 'Student engages in brief or low-intensity failure to respond to adult requests');
INSERT INTO offense (offense, type, description) VALUES ('Dress Code', 'Minor Offense', 'Student wears clothing that not within the dress code guidelines');
INSERT INTO offense (offense, type, description) VALUES ('Inappropriate Language', 'Minor Offense', 'Student engages in low-intensity instance of appropriate language');
INSERT INTO offense (offense, type, description) VALUES ('Dress Code', 'Minor Offense', 'Student wears clothing that not within the dress code guidelines');
INSERT INTO disciplinaryAction (actionID, action, description) VALUES (1, 'Community Service', 'A service component where the student spends time serving in the community meeting actual needs');
INSERT INTO disciplinaryAction (actionID, action, description) VALUES (2, 'Probation', 'a warning status given to a student whose academic performance or behavior falls below the institutions standards');
INSERT INTO employee (employeeID, personID, department, employeeRole) VALUES ('EMP-001', 61, 'JHS', 'DEPT_HEAD');
INSERT INTO employee (employeeID, personID, department, employeeRole) VALUES ('EMP-002', 60, 'JHS', 'PREFECT');
INSERT INTO employee (employeeID, personID, department, employeeRole) VALUES ('EMP-003', 59, 'COLLEGE', 'PREFECT');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('CT23-0001', 1, 'Malabag', 'Extern', 'COLLEGE', '09148932528');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('CT23-0002', 2, 'Malabag', 'Extern', 'COLLEGE', '09809570154');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('CT23-0003', 3, 'Malabag', 'Extern', 'COLLEGE', '09303911718');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('CT23-0004', 4, 'Malabag', 'Extern', 'COLLEGE', '09227824896');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('CT23-0005', 5, 'Alfonso', 'Extern', 'COLLEGE', '09383465787');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('CT23-0006', 6, 'Malabag', 'Extern', 'COLLEGE', '09133150983');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('CT23-0007', 7, 'Buho', 'Extern', 'COLLEGE', '09930103105');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('CT23-0008', 8, 'Malabag', 'Extern', 'COLLEGE', '09183473829');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('CT23-0009', 9, 'Bacoor', 'Extern', 'COLLEGE', '09973763116');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('CT23-0010', 10, 'Bacoor', 'Extern', 'COLLEGE', '09566701065');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('CT23-0011', 11, 'Dasmariñas', 'Extern', 'COLLEGE', '09133387262');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('CT23-0012', 12, 'Dasmariñas', 'Extern', 'COLLEGE', '09473178108');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('CT23-0013', 13, 'Dasmariñas', 'Extern', 'COLLEGE', '09013267736');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('CT23-0014', 14, 'Batangas', 'Extern', 'COLLEGE', '09026064746');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('CT23-0015', 15, 'Tagaytay', 'Intern', 'COLLEGE', '09872343098');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('CT23-0016', 16, 'Tagaytay', 'Extern', 'COLLEGE', '09050097882');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('CT23-0017', 17, 'Buho', 'Extern', 'COLLEGE', '09081219136');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('CT23-0018', 18, 'Silang', 'Extern', 'COLLEGE', '09193990916');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('JHS-0019', 19, 'Alfonso', 'Intern', 'JHS', '09998543534');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('JHS-0020', 20, 'Nasugbu', 'Extern', 'JHS', '09624751079');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('JHS-0021', 21, 'Amuyong', 'Extern', 'JHS', '09911838425');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('JHS-0022', 22, 'Tagaytay', 'Extern', 'JHS', '09135427849');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('JHS-0023', 23, 'Tagaytay', 'Extern', 'JHS', '09808412411');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('JHS-0024', 24, 'Buho', 'Extern', 'JHS', '09824493534');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('JHS-0025', 25, 'Buho', 'Intern', 'JHS', '09874016400');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('JHS-0026', 26, 'Malabag', 'Extern', 'JHS', '09524278680');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('JHS-0027', 27, 'Malabag', 'Intern', 'JHS', '09112805982');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('JHS-0028', 28, 'Malabag', 'Extern', 'JHS', '09620450533');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('SHS-0029', 29, 'Malabag', 'Extern', 'SHS', '09158692322');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('SHS-0030', 30, 'Malabag', 'Extern', 'SHS', '09602563421');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('SHS-0031', 31, 'Buho', 'Extern', 'SHS', '09607337543');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('SHS-0032', 32, 'Tagaytay', 'Extern', 'SHS', '09303654145');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('SHS-0033', 33, 'Tagaytay', 'Extern', 'SHS', '09868501429');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('SHS-0034', 34, 'Alfonso', 'Extern', 'SHS', '09401965569');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('SHS-0035', 35, 'Dasmariñas', 'Extern', 'SHS', '09816934060');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('SHS-0036', 36, 'Malabag', 'Extern', 'SHS', '09883561595');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('SHS-0037', 37, 'Malabag', 'Extern', 'SHS', '09148465648');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('SHS-0038', 38, 'Malabag', 'Extern', 'SHS', '09236629946');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('JHS-0039', 39, 'Malabag', 'Extern', 'JHS', '09804436995');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('JHS-0040', 40, 'Malabag', 'Extern', 'JHS', '09777387214');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('JHS-0041', 41, 'Alfonso', 'Extern', 'JHS', '09895134332');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('JHS-0042', 42, 'Malabag', 'Extern', 'JHS', '09003791769');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('JHS-0043', 43, 'Tagaytay', 'Extern', 'JHS', '09367632016');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('JHS-0044', 44, 'Lalaan II', 'Extern', 'JHS', '09328708317');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('JHS-0045', 45, 'Buho', 'Extern', 'JHS', '09278895798');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('JHS-0046', 46, 'Tagaytay', 'Extern', 'JHS', '09687277434');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('JHS-0047', 47, 'Malabag', 'Extern', 'JHS', '09873471434');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('JHS-0048', 48, 'Malabag', 'Extern', 'JHS', '09558122362');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('SHS-0049', 49, 'Malabag', 'Extern', 'SHS', '09316658760');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('SHS-0050', 50, 'Malabag', 'Extern', 'SHS', '09366909670');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('SHS-0051', 51, 'Malabag', 'Extern', 'SHS', '09546688937');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('SHS-0052', 52, 'Malabag', 'Extern', 'SHS', '09346706562');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('SHS-0053', 53, 'Malabag', 'Extern', 'SHS', '09729806990');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('SHS-0054', 54, 'Malabag', 'Extern', 'SHS', '09162720465');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('SHS-0055', 55, 'Malabag', 'Extern', 'SHS', '09375564641');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('SHS-0056', 56, 'Malabag', 'Extern', 'SHS', '09708053100');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('SHS-0057', 57, 'Malabag', 'Extern', 'SHS', '09330923271');
INSERT INTO student (studentID, personID, address, studentType, department, contactNumber) VALUES ('SHS-0058', 58, 'Malabag', 'Extern', 'SHS', '09937452991');
INSERT INTO disciplinaryStatus (disciplinaryStatusID, status, description) VALUES (1, 'Good Standing', 'Student has no disciplinary issues and maintains good behavior.');
INSERT INTO disciplinaryStatus (disciplinaryStatusID, status, description) VALUES (2, 'Conduct Monitoring', 'Student is under observation due to minor conduct issues.');
INSERT INTO disciplinaryStatus (disciplinaryStatusID, status, description) VALUES (3, 'Conduct Probation', 'Student is on probation due to repeated or serious conduct violations.');
INSERT INTO disciplinaryStatus (disciplinaryStatusID, status, description) VALUES (4, 'Attendance Monitoring', 'Student is under observation due to attendance issues.');
INSERT INTO disciplinaryStatus (disciplinaryStatusID, status, description) VALUES (5, 'Attendance Probation', 'Student is on probation due to repeated attendance violations.');
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0001', '2025-2026', '3rd Year', 'IT501', 'COLLEGE', 4);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0001', '2024-2025', '2nd Year', 'IT301', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0001', '2023-2024', '1st Year', 'IT101', 'COLLEGE', 4);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0002', '2025-2026', '3rd Year', 'IT501', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0002', '2024-2025', '2nd Year', 'IT301', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0002', '2023-2024', '1st Year', 'IT101', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0003', '2025-2026', '3rd Year', 'IT501', 'COLLEGE', 4);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0003', '2024-2025', '2nd Year', 'IT301', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0003', '2023-2024', '1st Year', 'IT101', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0004', '2025-2026', '3rd Year', 'IT501', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0004', '2024-2025', '2nd Year', 'IT301', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0004', '2023-2024', '1st Year', 'IT101', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0005', '2025-2026', '3rd Year', 'IT501', 'COLLEGE', 4);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0005', '2024-2025', '2nd Year', 'IT301', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0005', '2023-2024', '1st Year', 'IT101', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0006', '2025-2026', '3rd Year', 'IT501', 'COLLEGE', 4);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0006', '2024-2025', '2nd Year', 'IT301', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0006', '2023-2024', '1st Year', 'IT101', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0007', '2025-2026', '3rd Year', 'IT501', 'COLLEGE', 4);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0007', '2024-2025', '3rd Year', 'IT301', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0007', '2023-2024', '3rd Year', 'IT101', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0008', '2025-2026', '3rd Year', 'IT501', 'COLLEGE', 4);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0008', '2024-2025', '2nd Year', 'IT301', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0008', '2023-2024', '1st Year', 'IT101', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0009', '2025-2026', '2nd Year', 'ECE301', 'COLLEGE', 4);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0009', '2024-2025', '1st Year', 'ECE101', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0010', '2025-2026', '2nd Year', 'ECE301', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0010', '2024-2025', '1st Year', 'ECE101', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0011', '2025-2026', '2nd Year', 'ECE301', 'COLLEGE', 4);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0011', '2024-2025', '1st Year', 'ECE101', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0012', '2025-2026', '2nd Year', 'ECE301', 'COLLEGE', 4);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0012', '2024-2025', '1st Year', 'ECE101', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0013', '2025-2026', '2nd Year', 'ECE301', 'COLLEGE', 2);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0013', '2024-2025', '1st Year', 'ECE101', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0014', '2025-2026', '4th Year', 'ECE701', 'COLLEGE', 5);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0014', '2024-2025', '3rd Year', 'ECE501', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0014', '2023-2024', '2nd Year', 'ECE301', 'COLLEGE', 5);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0014', '2022-2023', '1st Year', 'ECE101', 'COLLEGE', 5);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0015', '2025-2026', '4th Year', 'ECE701', 'COLLEGE', 5);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0015', '2024-2025', '3rd Year', 'ECE501', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0015', '2023-2024', '2nd Year', 'ECE301', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0015', '2022-2023', '1st Year', 'ECE101', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0016', '2025-2026', '4th Year', 'ECE701', 'COLLEGE', 3);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0016', '2024-2025', '3rd Year', 'ECE501', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0016', '2023-2024', '2nd Year', 'ECE301', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0016', '2022-2023', '1st Year', 'ECE101', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0017', '2025-2026', '4th Year', 'ECE701', 'COLLEGE', 3);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0017', '2024-2025', '3rd Year', 'ECE501', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0017', '2023-2024', '2nd Year', 'ECE301', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0017', '2022-2023', '1st Year', 'ECE101', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0018', '2025-2026', '4th Year', 'ECE701', 'COLLEGE', 3);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0018', '2024-2025', '3rd Year', 'ECE501', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0018', '2023-2024', '2nd Year', 'ECE301', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('CT23-0018', '2022-2023', '1st Year', 'ECE101', 'COLLEGE', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0019', '2025-2026', 'Grade-8', 'St. Hannibal', 'JHS', 3);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0019', '2024-2025', 'Grade-7', 'St. Raphael', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0020', '2025-2026', 'Grade-8', 'St. Hannibal', 'JHS', 3);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0020', '2024-2025', 'Grade-7', 'St. Raphael', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0021', '2025-2026', 'Grade-8', 'St. Hannibal', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0021', '2024-2025', 'Grade-7', 'St. Raphael', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0022', '2025-2026', 'Grade-8', 'St. Hannibal', 'JHS', 3);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0022', '2024-2025', 'Grade-7', 'St. Raphael', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0023', '2025-2026', 'Grade-8', 'St. Hannibal', 'JHS', 4);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0023', '2024-2025', 'Grade-7', 'St. Raphael', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0024', '2025-2026', 'Grade-9', 'St. Anthony', 'JHS', 4);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0024', '2024-2025', 'Grade-8', 'St. Hannibal', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0024', '2023-2024', 'Grade-7', 'St. Raphael', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0025', '2025-2026', 'Grade-9', 'St. Anthony', 'JHS', 3);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0025', '2024-2025', 'Grade-8', 'St. Hannibal', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0025', '2023-2024', 'Grade-7', 'St. Raphael', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0026', '2025-2026', 'Grade-9', 'St. Anthony', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0026', '2024-2025', 'Grade-8', 'St. Hannibal', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0026', '2023-2024', 'Grade-7', 'St. Raphael', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0027', '2025-2026', 'Grade-9', 'St. Anthony', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0027', '2024-2025', 'Grade-8', 'St. Hannibal', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0027', '2023-2024', 'Grade-7', 'St. Raphael', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0028', '2025-2026', 'Grade-9', 'St. Anthony', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0028', '2024-2025', 'Grade-8', 'St. Hannibal', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0028', '2023-2024', 'Grade-7', 'St. Raphael', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0029', '2025-2026', 'Grade-12', 'St. Mary Magdalene', 'SHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0029', '2024-2025', 'Grade-11', 'St. Charles Borromeo', 'SHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0030', '2025-2026', 'Grade-12', 'St. Mary Magdalene', 'SHS', 4);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0030', '2024-2025', 'Grade-11', 'St. Charles Borromeo', 'SHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0031', '2025-2026', 'Grade-12', 'St. Mary Magdalene', 'SHS', 4);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0031', '2024-2025', 'Grade-11', 'St. Charles Borromeo', 'SHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0032', '2025-2026', 'Grade-12', 'St. Mary Magdalene', 'SHS', 3);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0032', '2024-2025', 'Grade-11', 'St. Charles Borromeo', 'SHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0033', '2025-2026', 'Grade-12', 'St. Mary Magdalene', 'SHS', 4);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0033', '2024-2025', 'Grade-11', 'St. Charles Borromeo', 'SHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0034', '2025-2026', 'Grade-12', 'St. Teresa of Calcutta', 'SHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0034', '2024-2025', 'Grade-11', 'St. Charles Borromeo', 'SHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0035', '2025-2026', 'Grade-12', 'St. Teresa of Calcutta', 'SHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0035', '2024-2025', 'Grade-11', 'St. Charles Borromeo', 'SHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0036', '2025-2026', 'Grade-12', 'St. Teresa of Calcutta', 'SHS', 4);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0036', '2024-2025', 'Grade-11', 'St. Charles Borromeo', 'SHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0037', '2025-2026', 'Grade-12', 'St. Teresa of Calcutta', 'SHS', 4);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0037', '2024-2025', 'Grade-11', 'St. Charles Borromeo', 'SHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0038', '2025-2026', 'Grade-12', 'St. Teresa of Calcutta', 'SHS', 3);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0038', '2024-2025', 'Grade-11', 'St. Charles Borromeo', 'SHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0039', '2025-2026', 'Grade-7', 'St. Raphael', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0039', '2025-2026', 'Grade-9', 'St. Anthony', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0039', '2024-2025', 'Grade-8', 'St. Hannibal', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0039', '2023-2024', 'Grade-7', 'St. Raphael', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0040', '2025-2026', 'Grade-7', 'St. Raphael', 'JHS', 2);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0041', '2025-2026', 'Grade-7', 'St. Raphael', 'JHS', 2);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0042', '2025-2026', 'Grade-7', 'St. Raphael', 'JHS', 2);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0043', '2025-2026', 'Grade-7', 'St. Raphael', 'JHS', 4);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0044', '2025-2026', 'Grade-10', 'St. Augustine', 'JHS', 4);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0044', '2025-2026', 'Grade-9', 'St. Anthony', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0044', '2024-2025', 'Grade-8', 'St. Hannibal', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0044', '2023-2024', 'Grade-7', 'St. Raphael', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0045', '2025-2026', 'Grade-10', 'St. Augustine', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0045', '2025-2026', 'Grade-9', 'St. Anthony', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0045', '2024-2025', 'Grade-8', 'St. Hannibal', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0045', '2023-2024', 'Grade-7', 'St. Raphael', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0046', '2025-2026', 'Grade-10', 'St. Augustine', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0046', '2025-2026', 'Grade-9', 'St. Anthony', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0046', '2024-2025', 'Grade-8', 'St. Hannibal', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0046', '2023-2024', 'Grade-7', 'St. Raphael', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0047', '2025-2026', 'Grade-10', 'St. Augustine', 'JHS', 3);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0047', '2025-2026', 'Grade-9', 'St. Anthony', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0047', '2024-2025', 'Grade-8', 'St. Hannibal', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0047', '2023-2024', 'Grade-7', 'St. Raphael', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0048', '2025-2026', 'Grade-10', 'St. Augustine', 'JHS', 3);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0048', '2025-2026', 'Grade-9', 'St. Anthony', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0048', '2024-2025', 'Grade-8', 'St. Hannibal', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('JHS-0048', '2023-2024', 'Grade-7', 'St. Raphael', 'JHS', 1);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0049', '2025-2026', 'Grade-11', 'St. Charles Borromeo', 'SHS', 3);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0050', '2025-2026', 'Grade-11', 'St. Charles Borromeo', 'SHS', 3);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0051', '2025-2026', 'Grade-11', 'St. Charles Borromeo', 'SHS', 3);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0052', '2025-2026', 'Grade-11', 'St. Charles Borromeo', 'SHS', 3);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0053', '2025-2026', 'Grade-11', 'St. Charles Borromeo', 'SHS', 3);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0054', '2025-2026', 'Grade-11', 'St. Joseph', 'SHS', 3);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0055', '2025-2026', 'Grade-11', 'St. Joseph', 'SHS', 3);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0056', '2025-2026', 'Grade-11', 'St. Joseph', 'SHS', 3);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0057', '2025-2026', 'Grade-11', 'St. Joseph', 'SHS', 3);
INSERT INTO enrollment (studentID, schoolYear, studentLevel, section, department, disciplinaryStatusID) VALUES ('SHS-0058', '2025-2026', 'Grade-11', 'St. Joseph', 'SHS', 3);
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (57, 'EMP-002', 8, TO_DATE('2025-09-15', 'YYYY-MM-DD'), 1, TO_DATE('2025-09-17', 'YYYY-MM-DD'), 'Repeatedly late to class', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (51, 'EMP-003', 5, TO_DATE('2025-01-12', 'YYYY-MM-DD'), 2, TO_DATE('2025-01-20', 'YYYY-MM-DD'), 'Caught holding hands', 'APPEALED');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (31, 'EMP-003', 10, TO_DATE('2025-04-28', 'YYYY-MM-DD'), 2, TO_DATE('2025-04-30', 'YYYY-MM-DD'), 'She was seen bringing alcohol to the acquintace party.', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (96, 'EMP-002', 15, TO_DATE('2025-01-20', 'YYYY-MM-DD'), 2, TO_DATE('2025-01-25', 'YYYY-MM-DD'), 'He raised his voice at his teacher.', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (33, 'EMP-003', 10, TO_DATE('2025-04-28', 'YYYY-MM-DD'), 2, TO_DATE('2025-04-30', 'YYYY-MM-DD'), 'He was seen bringing alcohol to the acquintace party.', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (55, 'EMP-002', 18, TO_DATE('2025-09-01', 'YYYY-MM-DD'), 2, TO_DATE('2025-09-10', 'YYYY-MM-DD'), 'She is not in her uniform', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (84, 'EMP-002', 2, TO_DATE('2025-10-11', 'YYYY-MM-DD'), 2, TO_DATE('2025-10-18', 'YYYY-MM-DD'), 'He punched his classmate', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (77, 'EMP-002', 6, TO_DATE('2025-11-11', 'YYYY-MM-DD'), 2, TO_DATE('2025-11-18', 'YYYY-MM-DD'), 'Caught cheating during exam', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (65, 'EMP-002', 9, TO_DATE('2025-02-14', 'YYYY-MM-DD'), 2, TO_DATE('2025-02-14', 'YYYY-MM-DD'), 'Seen using phone during break', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (98, 'EMP-002', 17, TO_DATE('2025-03-17', 'YYYY-MM-DD'), 2, TO_DATE('2025-02-14', 'YYYY-MM-DD'), 'Heard cursing', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (90, 'EMP-002', 9, TO_DATE('2025-01-14', 'YYYY-MM-DD'), 2, TO_DATE('2025-02-14', 'YYYY-MM-DD'), 'Seen using phone during break', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (61, 'EMP-002', 7, TO_DATE('2025-02-28', 'YYYY-MM-DD'), 2, TO_DATE('2025-03-05', 'YYYY-MM-DD'), 'The guard saw the student trying to sneak out of the school', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (80, 'EMP-002', 7, TO_DATE('2025-01-13', 'YYYY-MM-DD'), 2, TO_DATE('2025-01-17', 'YYYY-MM-DD'), 'The guard saw the student trying to sneak out of the school', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (88, 'EMP-002', 8, TO_DATE('2025-01-13', 'YYYY-MM-DD'), 2, TO_DATE('2025-01-17', 'YYYY-MM-DD'), 'Repeatedly late to class', 'APPEALED');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (1, 'EMP-003', 8, TO_DATE('2025-01-13', 'YYYY-MM-DD'), 2, TO_DATE('2025-01-17', 'YYYY-MM-DD'), 'Repeatedly late to class', 'APPEALED');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (29, 'EMP-003', 18, TO_DATE('2025-01-13', 'YYYY-MM-DD'), 2, TO_DATE('2025-01-17', 'YYYY-MM-DD'), 'She is not in her uniform', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (43, 'EMP-003', 6, TO_DATE('2024-11-13', 'YYYY-MM-DD'), 2, TO_DATE('2024-11-17', 'YYYY-MM-DD'), 'Caught cheating during exam', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (4, 'EMP-003', 2, TO_DATE('2024-08-15', 'YYYY-MM-DD'), 2, TO_DATE('2024-08-16', 'YYYY-MM-DD'), 'Punched his classmate', 'APPEALED');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (7, 'EMP-003', 17, TO_DATE('2024-10-01', 'YYYY-MM-DD'), 2, TO_DATE('2024-10-05', 'YYYY-MM-DD'), 'Not wearing proper uniform', 'APPEALED');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (10, 'EMP-003', 17, TO_DATE('2024-08-20', 'YYYY-MM-DD'), 2, TO_DATE('2024-08-20', 'YYYY-MM-DD'), 'Heard cursing', 'APPEALED');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (13, 'EMP-003', 9, TO_DATE('2025-01-20', 'YYYY-MM-DD'), 2, TO_DATE('2025-01-23', 'YYYY-MM-DD'), 'Using her phone during discussion', 'APPEALED');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (16, 'EMP-003', 8, TO_DATE('2024-11-14', 'YYYY-MM-DD'), 2, TO_DATE('2024-11-17', 'YYYY-MM-DD'), 'Always late to class', 'APPEALED');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (19, 'EMP-003', 3, TO_DATE('2025-04-09', 'YYYY-MM-DD'), 2, TO_DATE('2025-04-09', 'YYYY-MM-DD'), 'Stealing money', 'APPEALED');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (22, 'EMP-003', 15, TO_DATE('2025-10-01', 'YYYY-MM-DD'), 2, TO_DATE('2025-10-01', 'YYYY-MM-DD'), 'Did not follow her proffessor instruction', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (106, 'EMP-002', 7, TO_DATE('2024-11-18', 'YYYY-MM-DD'), 2, TO_DATE('2024-11-19', 'YYYY-MM-DD'), 'The guard saw the student trying to sneak out of the school', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (100, 'EMP-002', 17, TO_DATE('2025-09-18', 'YYYY-MM-DD'), 2, TO_DATE('2025-09-19', 'YYYY-MM-DD'), 'Heard cursing', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (106, 'EMP-002', 5, TO_DATE('2025-02-14', 'YYYY-MM-DD'), 2, TO_DATE('2025-02-17', 'YYYY-MM-DD'), 'Caught holding hands', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (74, 'EMP-003', 3, TO_DATE('2024-11-18', 'YYYY-MM-DD'), 2, TO_DATE('2024-11-19', 'YYYY-MM-DD'), 'Stealing money', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (137, 'EMP-003', 7, TO_DATE('2024-11-18', 'YYYY-MM-DD'), 2, TO_DATE('2024-11-19', 'YYYY-MM-DD'), 'The guard saw the student trying to sneak out of the school', 'APPEALED');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (133, 'EMP-003', 3, TO_DATE('2024-11-18', 'YYYY-MM-DD'), 2, TO_DATE('2024-11-19', 'YYYY-MM-DD'), 'Stealing money', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (80, 'EMP-003', 17, TO_DATE('2024-11-18', 'YYYY-MM-DD'), 2, TO_DATE('2024-11-19', 'YYYY-MM-DD'), 'Not wearing proper uniform', 'PENDING');
-- Extra test data for CT23-0002 (enrollmentID 4 = the 2025-2026 COLLEGE
-- enrollment), added to exercise every status/appeal-outcome color and
-- populate the Dashboard's "Most Frequent Offenses" chart for Mobile/Web
-- QA. CT23-0002 already had one seeded record (recordID 18, Punching,
-- PENDING with an appeal filed) before these were added.
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (4, 'EMP-003', 8, TO_DATE('2025-09-05', 'YYYY-MM-DD'), 2, NULL, 'Late to first period again', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (4, 'EMP-003', 16, TO_DATE('2025-09-20', 'YYYY-MM-DD'), 1, TO_DATE('2025-09-22', 'YYYY-MM-DD'), 'Not wearing proper uniform', 'RESOLVED');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (4, 'EMP-003', 17, TO_DATE('2025-10-02', 'YYYY-MM-DD'), 1, TO_DATE('2025-10-12', 'YYYY-MM-DD'), 'Heard cursing at a classmate', 'APPEALED');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (4, 'EMP-003', 6, TO_DATE('2025-10-15', 'YYYY-MM-DD'), 2, TO_DATE('2025-10-25', 'YYYY-MM-DD'), 'Caught cheating during exam', 'APPEALED');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (4, 'EMP-003', 9, TO_DATE('2025-11-01', 'YYYY-MM-DD'), 1, NULL, 'Seen using phone during discussion', 'APPEALED');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (4, 'EMP-003', 7, TO_DATE('2025-11-20', 'YYYY-MM-DD'), 2, NULL, 'Left campus without a gate pass', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (4, 'EMP-003', 8, TO_DATE('2025-12-05', 'YYYY-MM-DD'), 1, NULL, 'Late to first period, second time', 'PENDING');
INSERT INTO record (enrollmentID, employeeID, offenseID, dateOfViolation, actionID, dateOfResolution, remarks, status) VALUES (16, 'EMP-003', 9, TO_DATE('2026-08-20', 'YYYY-MM-DD'), 1, NULL, 'Caught using phone during lecture - QA test record for appeal flow, CT23-0006', 'PENDING');
INSERT INTO appeal (recordID, enrollmentID, message, dateFiled, status, dateProcessed, remarks) VALUES (34, 4, 'I was answering an urgent call from home, not cursing at anyone.', TO_DATE('2025-10-05','YYYY-MM-DD'), 'APPROVED', TO_DATE('2025-10-12','YYYY-MM-DD'), 'Reviewed with the teacher present - excused.');
INSERT INTO appeal (recordID, enrollmentID, message, dateFiled, status, dateProcessed, remarks) VALUES (35, 4, 'I was not copying, I finished early and was just reviewing my own answers.', TO_DATE('2025-10-18','YYYY-MM-DD'), 'DENIED', TO_DATE('2025-10-25','YYYY-MM-DD'), 'Proctor witness statement was conclusive - appeal denied.');
INSERT INTO appeal (recordID, enrollmentID, message, dateFiled, status) VALUES (36, 4, 'I was checking the time, not using my phone during the discussion.', TO_DATE('2025-11-05','YYYY-MM-DD'), 'PENDING');
INSERT INTO appeal (recordID, enrollmentID, message, dateFiled, status) VALUES (15, 1, 'I swear not to be late to class again', TO_DATE('2025-07-29','YYYY-MM-DD'), 'PENDING');
INSERT INTO appeal (recordID, enrollmentID, message, dateFiled, status) VALUES (18, 4, 'I did not punch my classmate', TO_DATE('2025-07-29','YYYY-MM-DD'), 'PENDING');
INSERT INTO appeal (recordID, enrollmentID, message, dateFiled, status) VALUES (19, 7, 'We do not have classes that day', TO_DATE('2025-07-29','YYYY-MM-DD'), 'PENDING');
INSERT INTO appeal (recordID, enrollmentID, message, dateFiled, status) VALUES (20, 10, 'Sorry, I swear not to do it again', TO_DATE('2025-07-29','YYYY-MM-DD'), 'PENDING');
INSERT INTO appeal (recordID, enrollmentID, message, dateFiled, status) VALUES (21, 13, 'I used my phone during class because my mom text me', TO_DATE('2025-07-29','YYYY-MM-DD'), 'PENDING');
INSERT INTO appeal (recordID, enrollmentID, message, dateFiled, status) VALUES (2, 51, 'I am just holding her/his hand', TO_DATE('2025-07-29','YYYY-MM-DD'), 'PENDING');
INSERT INTO appeal (recordID, enrollmentID, message, dateFiled, status) VALUES (29, 137, 'I am not skipping class', TO_DATE('2025-07-29','YYYY-MM-DD'), 'PENDING');
INSERT INTO appeal (recordID, enrollmentID, message, dateFiled, status) VALUES (22, 16, 'I swear not to be late to class again', TO_DATE('2025-07-29','YYYY-MM-DD'), 'PENDING');
INSERT INTO appeal (recordID, enrollmentID, message, dateFiled, status) VALUES (23, 19, 'It was my money', TO_DATE('2025-07-29','YYYY-MM-DD'), 'PENDING');
INSERT INTO appeal (recordID, enrollmentID, message, dateFiled, status) VALUES (14, 22, 'I swear to listen to my teacher', TO_DATE('2025-07-29','YYYY-MM-DD'), 'PENDING');
INSERT INTO request (employeeID, details, type, message, status, dateFiled) VALUES ('EMP-001', 'St. Andrew', 'By Section', 'Requesting for the conduct record of all students in St. Andrew', 'PENDING', TO_DATE('2026-08-10','YYYY-MM-DD'));
INSERT INTO request (employeeID, details, type, message, status, dateFiled) VALUES ('EMP-001', 'Grade 10', 'By Batch', 'Requesting for the conduct record of the graduating class of 2025-2026', 'PENDING', TO_DATE('2026-08-12','YYYY-MM-DD'));
INSERT INTO request (employeeID, details, type, message, status, dateFiled) VALUES ('EMP-001', 'St. Raphael', 'By Section', 'Requesting for the conduct record of all students in St. Raphael', 'PENDING', TO_DATE('2026-08-14','YYYY-MM-DD'));
INSERT INTO request (employeeID, details, type, message, status, dateFiled) VALUES ('EMP-001', 'IT601', 'By Section', 'Requesting for the conduct record of all students in IT601', 'PENDING', TO_DATE('2026-08-17','YYYY-MM-DD'));
INSERT INTO request (employeeID, details, type, message, status, dateFiled) VALUES ('EMP-001', 'St. Augustine', 'By Section', 'Requesting for the conduct record of all students in St. Augustine', 'PENDING', TO_DATE('2026-08-19','YYYY-MM-DD'));
INSERT INTO request (employeeID, details, type, message, status, dateFiled) VALUES ('EMP-001', 'ECE701', 'By Section', 'Requesting for the conduct record of all students in ECE701', 'PENDING', TO_DATE('2026-08-21','YYYY-MM-DD'));
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (65, '09241904966', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (66, '09319314919', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (67, '09058651850', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (68, '09671657262', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (69, '09849877694', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (70, '09531473799', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (71, '09650752735', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (72, '09454948083', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (73, '09136783777', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (74, '09014363495', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (75, '09788568557', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (76, '09444313518', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (77, '09233749894', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (78, '09134352408', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (79, '09240084271', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (80, '09094777520', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (81, '09471167190', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (82, '09229413186', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (83, '09999386774', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (84, '09964990913', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (85, '09341232812', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (86, '09067974034', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (87, '09471349361', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (88, '09832421024', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (89, '09994717464', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (90, '09887719065', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (91, '09940139904', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (92, '09902787429', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (93, '09671756551', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (94, '09256746807', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (95, '09154516808', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (96, '09760385977', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (97, '09034824771', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (98, '09093248086', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (99, '09131712748', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (100, '09467737826', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (101, '09398214658', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (102, '09404499727', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (103, '09875588675', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (104, '09339636057', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (105, '09662702895', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (106, '09171870262', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (107, '09174596158', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (108, '09657809134', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (109, '09316117240', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (110, '09050455623', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (111, '09869222196', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (112, '09937923747', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (113, '09407482175', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (114, '09946474367', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (115, '09136959440', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (116, '09640909743', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (117, '09953394210', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (118, '09470952145', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (119, '09623285884', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (120, '09247451712', 'MOTHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (121, '09368516048', 'FATHER');
INSERT INTO guardian (personID, contactNumber, relationship) VALUES (122, '09175496513', 'MOTHER');
INSERT INTO studentGuardian VALUES ('CT23-0001', 1);
INSERT INTO studentGuardian VALUES ('CT23-0002', 2);
INSERT INTO studentGuardian VALUES ('CT23-0003', 3);
INSERT INTO studentGuardian VALUES ('CT23-0004', 4);
INSERT INTO studentGuardian VALUES ('CT23-0005', 5);
INSERT INTO studentGuardian VALUES ('CT23-0006', 6);
INSERT INTO studentGuardian VALUES ('CT23-0007', 7);
INSERT INTO studentGuardian VALUES ('CT23-0008', 8);
INSERT INTO studentGuardian VALUES ('CT23-0009', 9);
INSERT INTO studentGuardian VALUES ('CT23-0010', 10);
INSERT INTO studentGuardian VALUES ('CT23-0011', 11);
INSERT INTO studentGuardian VALUES ('CT23-0012', 12);
INSERT INTO studentGuardian VALUES ('CT23-0013', 13);
INSERT INTO studentGuardian VALUES ('CT23-0014', 14);
INSERT INTO studentGuardian VALUES ('CT23-0015', 15);
INSERT INTO studentGuardian VALUES ('CT23-0016', 16);
INSERT INTO studentGuardian VALUES ('CT23-0017', 17);
INSERT INTO studentGuardian VALUES ('CT23-0018', 18);
INSERT INTO studentGuardian VALUES ('JHS-0019', 19);
INSERT INTO studentGuardian VALUES ('JHS-0020', 20);
INSERT INTO studentGuardian VALUES ('JHS-0021', 21);
INSERT INTO studentGuardian VALUES ('JHS-0022', 22);
INSERT INTO studentGuardian VALUES ('JHS-0023', 23);
INSERT INTO studentGuardian VALUES ('JHS-0024', 24);
INSERT INTO studentGuardian VALUES ('JHS-0025', 25);
INSERT INTO studentGuardian VALUES ('JHS-0026', 26);
INSERT INTO studentGuardian VALUES ('JHS-0027', 27);
INSERT INTO studentGuardian VALUES ('JHS-0028', 28);
INSERT INTO studentGuardian VALUES ('SHS-0029', 29);
INSERT INTO studentGuardian VALUES ('SHS-0030', 30);
INSERT INTO studentGuardian VALUES ('SHS-0031', 31);
INSERT INTO studentGuardian VALUES ('SHS-0032', 32);
INSERT INTO studentGuardian VALUES ('SHS-0033', 33);
INSERT INTO studentGuardian VALUES ('SHS-0034', 34);
INSERT INTO studentGuardian VALUES ('SHS-0035', 35);
INSERT INTO studentGuardian VALUES ('SHS-0036', 36);
INSERT INTO studentGuardian VALUES ('SHS-0037', 37);
INSERT INTO studentGuardian VALUES ('SHS-0038', 38);
INSERT INTO studentGuardian VALUES ('JHS-0039', 39);
INSERT INTO studentGuardian VALUES ('JHS-0040', 40);
INSERT INTO studentGuardian VALUES ('JHS-0041', 41);
INSERT INTO studentGuardian VALUES ('JHS-0042', 42);
INSERT INTO studentGuardian VALUES ('JHS-0043', 43);
INSERT INTO studentGuardian VALUES ('JHS-0044', 44);
INSERT INTO studentGuardian VALUES ('JHS-0045', 45);
INSERT INTO studentGuardian VALUES ('JHS-0046', 46);
INSERT INTO studentGuardian VALUES ('JHS-0047', 47);
INSERT INTO studentGuardian VALUES ('JHS-0048', 48);
INSERT INTO studentGuardian VALUES ('SHS-0049', 49);
INSERT INTO studentGuardian VALUES ('SHS-0050', 50);
INSERT INTO studentGuardian VALUES ('SHS-0051', 51);
INSERT INTO studentGuardian VALUES ('SHS-0052', 52);
INSERT INTO studentGuardian VALUES ('SHS-0053', 53);
INSERT INTO studentGuardian VALUES ('SHS-0054', 54);
INSERT INTO studentGuardian VALUES ('SHS-0055', 55);
INSERT INTO studentGuardian VALUES ('SHS-0056', 56);
INSERT INTO studentGuardian VALUES ('SHS-0057', 57);
INSERT INTO studentGuardian VALUES ('SHS-0058', 58);

-- AI SUPPORT MODULE: predefined suggestion templates. The AI Support Module
-- never writes new suggestion text itself -- it only decides, via spaCy
-- keyword extraction + BM25 scoring against an appeal letter's extracted
-- text, which of these existing templates are relevant enough to surface to
-- the Prefect. Add more rows here as real cases come in; the matching logic
-- works against whatever is in this table, no code change needed.
INSERT INTO suggestion (type, suggestionText) VALUES ('POLICY_REFERENCE', 'This appeal appears to reference a uniform or dress code violation. Review the Student Handbook section on Dress Code and Uniform Compliance before deciding.');
INSERT INTO suggestion (type, suggestionText) VALUES ('POLICY_REFERENCE', 'This appeal appears to reference tardiness or attendance. Check the student''s attendance history for a repeated pattern before deciding.');
INSERT INTO suggestion (type, suggestionText) VALUES ('POLICY_REFERENCE', 'This appeal appears to reference academic dishonesty or cheating. Review the Student Handbook section on Academic Integrity and any supporting evidence submitted with the case.');
INSERT INTO suggestion (type, suggestionText) VALUES ('POLICY_REFERENCE', 'This appeal appears to reference public display of affection. Review the Student Handbook section on Conduct and Behavior for the applicable disciplinary level.');
INSERT INTO suggestion (type, suggestionText) VALUES ('POLICY_REFERENCE', 'This appeal appears to reference an unauthorized absence. Confirm whether a valid excuse letter or medical certificate was submitted along with this appeal.');
INSERT INTO suggestion (type, suggestionText) VALUES ('CASE_HISTORY', 'Consider checking whether this is the student''s first recorded offense of this type. First-time offenses may warrant a lighter disciplinary action under the Student Handbook''s graduated sanctions policy.');
INSERT INTO suggestion (type, suggestionText) VALUES ('CASE_HISTORY', 'This student has multiple prior violations on record. Consider reviewing the offense history for an escalating pattern before finalizing a decision.');
INSERT INTO suggestion (type, suggestionText) VALUES ('EVIDENCE_GAP', 'The appeal letter provided limited detail or supporting explanation. Consider requesting additional documentation from the student before making a final decision.');
INSERT INTO suggestion (type, suggestionText) VALUES ('EVIDENCE_GAP', 'A medical certificate, parent/guardian letter, or other supporting document appears to be referenced but may not have been attached. Confirm all supporting documents were received.');
INSERT INTO suggestion (type, suggestionText) VALUES ('GENERAL', 'Review the applicable Student Handbook section for this offense type to confirm the recommended disciplinary action matches the case details.');

COMMIT;