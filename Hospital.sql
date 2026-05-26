CREATE DATABASE Hospital;
USE Hospital;

-- Create tables

CREATE TABLE departments
(	departmentID INT AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(50) NOT NULL
);

CREATE TABLE doctors
(	doctorID INT auto_increment PRIMARY KEY,
	name VARCHAR(50),
	specilaization VARCHAR(100),
	role VARCHAR(50),
	departmentID INT,
	FOREIGN KEY(departmentID) references departments(departmentID)

);

CREATE TABLE patients
(	pateintID INT auto_increment PRIMARY KEY,
	name VARCHAR(50),
    dateofbirth DATE,
    gender VARCHAR(1),
    phoneNo VARCHAR(15),
    CHECK (gender IN('M', 'F', 'O'))
);

CREATE TABLE appointments
(	appointmentID INT auto_increment PRIMARY KEY,
	patientID INT,
    doctorID INT,
    appintmentTime DATETIME,
    status VARCHAR(50),
    FOREIGN KEY (patientID) references patients(pateintID),
    FOREIGN KEY (doctorID) references doctors(doctorID),
    CHECK (status IN('Scheduled', 'Completed', 'Cancelled'))
);

CREATE TABLE prescriptions
(	prescriptionID INT auto_increment PRIMARY KEY,
	appointmentID INT,
    medication VARCHAR(100),
    dosage VARCHAR(100),
    FOREIGN KEY (appointmentID) references appointments(appointmentID)
);

CREATE TABLE bills
(	billID INT auto_increment PRIMARY KEY,
	appointmentID INT,
    amount DECIMAL(10,2),
    paid TINYINT(1),
    billdate DATETIME DEFAULT current_timestamp,
    FOREIGN KEY (appointmentID) references appointments(appointmentID)
);

CREATE TABLE labreports
(	reportID INT auto_increment PRIMARY KEY,
	appointmentID INT,
    reportdata TEXT,
    createdate DATETIME DEFAULT current_timestamp,
    FOREIGN KEY (appointmentID) references appointments(appointmentID)
);


-- Insertion of Data

-- Inserting values into departments table

SELECT * FROM hospital_data;

SELECT `Departments.DepartmentID` FROM hospital_data;


SELECT GROUP_CONCAT(CONCAT('`', COLUMN_NAME, '`'))
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
TABLE_SCHEMA = 'hospital' 
AND table_name = 'hospital_data'
AND COLUMN_NAME LIKE 'Departments.%';


INSERT INTO departments( departmentID, name)
SELECT `Departments.DepartmentID`,`Departments.Name`
FROM hospital_data
WHERE `Departments.DepartmentID`<>'';

SELECT * FROM departments;

-- Inserting values into doctors table

SELECT GROUP_CONCAT(CONCAT('`', COLUMN_NAME, '`'))
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
TABLE_SCHEMA = 'hospital' 
AND table_name = 'hospital_data'
AND COLUMN_NAME LIKE 'doctors.%';

INSERT INTO doctors( departmentID, doctorID, name, role, specilaization  )
SELECT `Doctors.DepartmentID`,`Doctors.DoctorID`,`Doctors.Name`,`Doctors.Role`,`Doctors.Specialization`
FROM hospital_data
WHERE `Doctors.DepartmentID`<>'';



-- Inserting into patient table

SELECT GROUP_CONCAT(CONCAT('`', COLUMN_NAME, '`'))
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
TABLE_SCHEMA = 'hospital' 
AND table_name = 'hospital_data'
AND COLUMN_NAME LIKE 'patients.%';

INSERT INTO patients( dateofbirth, gender, name, pateintID, phoneNo  )
SELECT STR_TO_DATE(`Patients.DateOfBirth`,'%d-%m-%Y'),`Patients.Gender`,`Patients.Name`,`Patients.PatientID`,`Patients.Phone`
FROM hospital_data
WHERE `Patients.PatientID`<>'';

SELECT * FROM bills;

-- Inserting into appointments table

SELECT GROUP_CONCAT(CONCAT('`', COLUMN_NAME, '`'))
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
TABLE_SCHEMA = 'hospital' 
AND table_name = 'hospital_data'
AND COLUMN_NAME LIKE 'appointments.%';

INSERT INTO appointments( appointmentID, appintmentTime, doctorID, patientID, status  )
SELECT `Appointments.AppointmentID`,
STR_TO_DATE(`Appointments.AppointmentTime`, '%d-%m-%Y %H:%i'),`Appointments.DoctorID`,`Appointments.PatientID`,`Appointments.Status`
FROM hospital_data
WHERE `Appointments.AppointmentID`<>'';

SELECT * FROM appointments;

-- Inserting into prescriptions table

SELECT GROUP_CONCAT(CONCAT('`', COLUMN_NAME, '`'))
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
TABLE_SCHEMA = 'hospital' 
AND table_name = 'hospital_data'
AND COLUMN_NAME LIKE 'prescriptions.%';

INSERT INTO prescriptions( appointmentID, dosage, medication, prescriptionID  )
SELECT `Prescriptions.AppointmentID`,`Prescriptions.Dosage`,`Prescriptions.Medication`,`Prescriptions.PrescriptionID`
FROM hospital_data
WHERE `Prescriptions.PrescriptionID`<>'';

SELECT * FROM prescriptions;

-- Inserting into bills table

SELECT GROUP_CONCAT(CONCAT('`', COLUMN_NAME, '`'))
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
TABLE_SCHEMA = 'hospital' 
AND table_name = 'hospital_data'
AND COLUMN_NAME LIKE 'bills.%';

INSERT INTO bills( amount, appointmentID, billdate, billID, paid  )
SELECT `Bills.Amount`,`Bills.AppointmentID`,`Bills.BillDate`,`Bills.BillID`,`Bills.Paid`
FROM hospital_data
WHERE `Bills.BillID`<>'';

SELECT * FROM bills;

-- Inserting into labreports table

SELECT GROUP_CONCAT(CONCAT('`', COLUMN_NAME, '`'))
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
TABLE_SCHEMA = 'hospital' 
AND table_name = 'hospital_data'
AND COLUMN_NAME LIKE 'LabReports.%';

INSERT INTO labreports( appointmentID, createdate, reportdata, reportID  )
SELECT `LabReports.AppointmentID`,`LabReports.CreatedAt`,`LabReports.ReportData`,`LabReports.ReportID`
FROM hospital_data
WHERE `LabReports.ReportID`<>'';

-- Unregulated Scheduling

DELIMITER $$
CREATE TRIGGER Check_new_appointment
BEFORE INSERT ON appointments
FOR EACH ROW
BEGIN
	IF NEW.appintmentTime< NOW() THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT= 'Error: Appointment cannot be in past';
	END IF;
    
    IF EXISTS
	(	
		SELECT * FROM appointments
        WHERE doctorID=NEW.doctorID AND
        appintmentTime= NEW.appintmentTime
        AND status IN ('Scheduled')
	) THEN 
    SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT= 'Error: Doctor already has an appointment at this time';
    END IF ;

END $$
DELIIMITER; 

-- Access to senisitive information

SELECT * FROM doctor_credentials;

DELIMITER $$
CREATE PROCEDURE View_doctor_data(IN INPUT_USERNAME VARCHAR(100), IN INPUT_PASSWORD VARCHAR(100))
BEGIN
	DECLARE DOC_ROLE VARCHAR(100);
    DECLARE DOC_DEPT INT;
    DECLARE DOC_ID INT;
    
    -- Check credentials of doctor
    SELECT DOCTOR_ID INTO DOC_ID
    FROM doctor_credentials
    WHERE user_name= INPUT_USERNAME
    AND password= INPUT_PASSWORD;
    
    
    
    -- Get role and departments from doctor table
    SELECT role, departmentID 
    INTO DOC_ROLE, DOC_DEPT
    FROM doctors 
    WHERE doctorID= DOC_ID;
    
    -- Show appropriate patient data
    IF DOC_ROLE= 'senior'
    THEN 
		SELECT p.pateintID, p.name as pateint_name, p.gender,a.appintmentTime as Appointment_TIme, pr.medication, l.reportdata
		FROM patients p
		INNER JOIN appointments a
		ON a.patientID=p.pateintID
        JOIN doctors d
		ON a.doctorID= d.doctorID
		LEFT JOIN prescriptions pr
		ON a.appointmentID= pr.appointmentID
		LEFT JOIN labreports l
		ON a.appointmentID=l.appointmentID
        WHERE d.departmentID=DOC_DEPT;
	ELSE 
		SELECT p.pateintID, p.name as pateint_name, p.gender,a.appintmentTime as Appointment_TIme, pr.medication, l.reportdata
		FROM patients p
		INNER JOIN appointments a
		ON a.patientID=p.pateintID
		LEFT JOIN prescriptions pr
		ON a.appointmentID= pr.appointmentID
		LEFT JOIN labreports l
		ON a.appointmentID=l.appointmentID
        WHERE a.doctorID=DOC_ID;
	END IF;
		 
END $$
DELIMITER



-- Departmental revenue report

DELIMITER //

CREATE PROCEDURE MONTHLY_REVENUE(IN P_YEAR int , IN P_MONTH int)
BEGIN 
SELECT dp.name as Department_name, SUM(b.amount)
	FROM bills b
	INNER JOIN appointments a
	ON a.appointmentID=b.appointmentID
	INNER JOIN doctors d 
	ON a.doctorID= d.doctorID
	INNER JOIN departments dp
	ON d.departmentID= dp.departmentID
	WHERE MONTH(b.billdate) =P_MONTH AND YEAR(b.billdate) = P_YEAR
GROUP BY dp.name;

END //
DELIMITER

CALL MONTHLY_REVENUE(2025,5)