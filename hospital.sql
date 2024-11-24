-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 24, 2024 at 06:20 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `hospital`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_medical_record_timeline` (IN `patientID` INT)   BEGIN
    SELECT
        mr.id AS medical_record_id,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        mr.record_date AS consultation_date,
        CONCAT(s.first_name, ' ', s.last_name) AS doctor_name,
        mr.diagnosis AS diagnosis_result
    FROM
        medical_records mr
    JOIN patients p ON
        mr.patient_id = p.id
    JOIN staffs s ON
        mr.staff_id = s.id
    WHERE
        p.id = patientID
    ORDER BY
        mr.record_date;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `list_all_record_expenses` ()   BEGIN
    select 
        mr.id as record_id,
        concat(patients.first_name, ' ', patients.last_name) as patient_name,
        ifnull(sum(su.price), 0) as service_cost,
        ifnull((select sum(pd.quantity * pd.price) 
                from prescriptions p 
                join prescription_details pd on p.id = pd.prescription_id
                where p.record_id = mr.id), 0) as medication_cost,
        ifnull((select sum((datediff(ru.end_date, ru.start_date)) * ru.daily_rate) 
                from room_usage ru 
                where ru.record_id = mr.id), 0) as room_cost,
        ifnull((select sum(p.original_price) 
                from prepayments p 
                join admissions a on p.admission_id = a.id 
                where a.id = mr.admission_id), 0) as total_prepayments
    from 
        medical_records mr
    join 
        patients on patients.id = mr.patient_id
    left join 
        service_usage su on su.record_id = mr.id
    group by 
        mr.id, patients.first_name, patients.last_name;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `admissions`
--

CREATE TABLE `admissions` (
  `id` int(11) NOT NULL,
  `patient_id` int(11) NOT NULL,
  `staff_id` int(11) NOT NULL,
  `admission_date` date DEFAULT curdate(),
  `initial_diagnosis` varchar(255) DEFAULT NULL,
  `discharge_date` date DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `admissions`
--

INSERT INTO `admissions` (`id`, `patient_id`, `staff_id`, `admission_date`, `initial_diagnosis`, `discharge_date`, `created_at`, `updated_at`) VALUES
(1, 1, 1, '2024-11-01', 'Chest Pain', '2024-11-10', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(2, 2, 2, '2024-11-05', 'Headache', NULL, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(3, 3, 4, '2024-11-08', 'Tumor', '2024-11-18', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(4, 4, 5, '2024-11-09', 'Fever', NULL, '2024-11-14 03:06:08', '2024-11-14 03:06:08');

-- --------------------------------------------------------

--
-- Table structure for table `beds`
--

CREATE TABLE `beds` (
  `id` tinyint(1) NOT NULL,
  `room_id` tinyint(1) DEFAULT NULL,
  `status` tinyint(1) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `beds`
--

INSERT INTO `beds` (`id`, `room_id`, `status`, `created_at`, `updated_at`) VALUES
(1, 1, 1, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(2, 1, 0, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(3, 2, 1, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(4, 3, 0, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(5, 3, 1, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(6, 4, 1, '2024-11-14 03:06:08', '2024-11-14 03:06:08');

-- --------------------------------------------------------

--
-- Table structure for table `billings`
--

CREATE TABLE `billings` (
  `id` int(11) NOT NULL,
  `record_id` int(11) NOT NULL,
  `insurance_coverage_percentage` int(11) DEFAULT NULL,
  `prepayments_total` decimal(15,2) DEFAULT NULL,
  `final_price` decimal(15,0) NOT NULL,
  `billing_date` date DEFAULT curdate(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `billings`
--

INSERT INTO `billings` (`id`, `record_id`, `insurance_coverage_percentage`, `prepayments_total`, `final_price`, `billing_date`, `created_at`, `updated_at`) VALUES
(1, 1, 80, 100.00, 300, '2024-11-10', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(2, 2, 70, 50.00, 600, '2024-11-12', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(3, 3, 90, 200.00, 1300, '2024-11-18', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(4, 4, 85, 100.00, 300, '2024-11-12', '2024-11-14 03:06:08', '2024-11-14 03:06:08');

-- --------------------------------------------------------

--
-- Table structure for table `billing_details`
--

CREATE TABLE `billing_details` (
  `id` int(11) NOT NULL,
  `billing_id` int(11) NOT NULL,
  `type` tinyint(1) NOT NULL COMMENT '(service, lab_test, medication, room_charge',
  `description` varchar(255) NOT NULL,
  `price` decimal(15,2) NOT NULL,
  `quantity` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `billing_details`
--

INSERT INTO `billing_details` (`id`, `billing_id`, `type`, `description`, `price`, `quantity`) VALUES
(1, 1, 1, 'Room Charges', 200.00, 5),
(2, 2, 2, 'CT Scan', 500.00, 1),
(3, 3, 1, 'Room Charges', 400.00, 10),
(4, 4, 2, 'Physical Therapy', 200.00, 1);

-- --------------------------------------------------------

--
-- Table structure for table `clinic_rooms`
--

CREATE TABLE `clinic_rooms` (
  `id` tinyint(1) NOT NULL,
  `department_id` tinyint(1) DEFAULT NULL,
  `service_type` varchar(100) DEFAULT NULL,
  `status` tinyint(1) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `clinic_rooms`
--

INSERT INTO `clinic_rooms` (`id`, `department_id`, `service_type`, `status`, `created_at`, `updated_at`) VALUES
(1, 1, 'Consultation', 1, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(2, 2, 'Lab Testing', 0, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(3, 3, 'Chemotherapy', 1, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(4, 4, 'General Pediatrics', 1, '2024-11-14 03:06:08', '2024-11-14 03:06:08');

-- --------------------------------------------------------

--
-- Table structure for table `departments`
--

CREATE TABLE `departments` (
  `id` tinyint(1) NOT NULL,
  `name` varchar(10) NOT NULL,
  `head_doctor_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `departments`
--

INSERT INTO `departments` (`id`, `name`, `head_doctor_id`, `created_at`, `updated_at`) VALUES
(1, 'Cardiology', 1, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(2, 'Neurology', 2, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(3, 'Oncology', 3, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(4, 'Pediatrics', 4, '2024-11-14 03:06:08', '2024-11-14 03:06:08');

-- --------------------------------------------------------

--
-- Table structure for table `hospital_services`
--

CREATE TABLE `hospital_services` (
  `id` tinyint(1) NOT NULL,
  `service_name` varchar(10) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `unit_cost` decimal(10,2) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `hospital_services`
--

INSERT INTO `hospital_services` (`id`, `service_name`, `description`, `unit_cost`, `created_at`, `updated_at`) VALUES
(1, 'X-Ray', 'X-Ray Imaging', 150.00, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(2, 'CT Scan', 'Computed Tomography Scan', 500.00, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(3, 'Chemothera', 'Cancer treatment', 1000.00, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(4, 'Physical T', 'Recovery therapy', 200.00, '2024-11-14 03:06:08', '2024-11-14 03:06:08');

-- --------------------------------------------------------

--
-- Table structure for table `lab_tests`
--

CREATE TABLE `lab_tests` (
  `id` tinyint(1) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `price` decimal(15,2) DEFAULT NULL,
  `normal_range` varchar(50) DEFAULT NULL,
  `units` varchar(20) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `lab_tests`
--

INSERT INTO `lab_tests` (`id`, `name`, `description`, `price`, `normal_range`, `units`, `created_at`, `updated_at`) VALUES
(1, 'Blood Test', 'Routine blood examination', 75.00, '4.5-5.5', 'million cells/uL', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(2, 'MRI', 'Magnetic Resonance Imaging', 700.00, 'N/A', 'N/A', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(3, 'Biopsy', 'Sample tissue analysis', 500.00, 'N/A', 'N/A', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(4, 'Blood Sugar', 'Glucose levels', 50.00, '70-99 mg/dL', 'mg/dL', '2024-11-14 03:06:08', '2024-11-14 03:06:08');

-- --------------------------------------------------------

--
-- Table structure for table `medical_records`
--

CREATE TABLE `medical_records` (
  `id` int(11) NOT NULL,
  `admission_id` int(11) DEFAULT NULL,
  `patient_id` int(11) DEFAULT NULL,
  `staff_id` int(11) DEFAULT NULL,
  `record_type` tinyint(1) NOT NULL,
  `diagnosis` varchar(255) DEFAULT NULL,
  `record_date` date DEFAULT curdate(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `insurance_coverage_percentage` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `medical_records`
--

INSERT INTO `medical_records` (`id`, `admission_id`, `patient_id`, `staff_id`, `record_type`, `diagnosis`, `record_date`, `created_at`, `updated_at`, `insurance_coverage_percentage`) VALUES
(1, 1, 1, 1, 1, 'Heart Condition', '2024-11-02', '2024-11-14 03:06:08', '2024-11-14 03:06:08', 80),
(2, 2, 2, 2, 1, 'Migraine', '2024-11-06', '2024-11-14 03:06:08', '2024-11-14 03:06:08', 70),
(3, 3, 3, 4, 1, 'Malignant Tumor', '2024-11-10', '2024-11-14 03:06:08', '2024-11-14 03:06:08', 90),
(4, 4, 4, 5, 1, 'Viral Infection', '2024-11-09', '2024-11-14 03:06:08', '2024-11-14 03:06:08', 85);

-- --------------------------------------------------------

--
-- Table structure for table `medical_record_details`
--

CREATE TABLE `medical_record_details` (
  `id` int(11) NOT NULL,
  `record_id` int(11) NOT NULL,
  `type` tinyint(1) NOT NULL COMMENT 'Type of treatment detail: 1 = lab_test, 2 = medication',
  `lab_test_id` tinyint(1) DEFAULT NULL,
  `medication_id` int(11) DEFAULT NULL,
  `usage_date` date DEFAULT curdate(),
  `price` decimal(15,2) DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL COMMENT 'Only for medications',
  `instructions` varchar(255) DEFAULT NULL COMMENT 'Only for medications'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `medical_record_details`
--

INSERT INTO `medical_record_details` (`id`, `record_id`, `type`, `lab_test_id`, `medication_id`, `usage_date`, `price`, `quantity`, `instructions`) VALUES
(1, 1, 1, 1, NULL, '2024-11-04', 75.00, 1, NULL),
(2, 2, 1, 2, NULL, '2024-11-08', 700.00, 1, NULL),
(3, 3, 1, 3, NULL, '2024-11-12', 500.00, 1, 'Special precautions'),
(4, 4, 1, 4, NULL, '2024-11-09', 50.00, 1, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `medications`
--

CREATE TABLE `medications` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `price` decimal(15,2) NOT NULL,
  `unit` varchar(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `medications`
--

INSERT INTO `medications` (`id`, `name`, `description`, `price`, `unit`, `created_at`, `updated_at`) VALUES
(1, 'Aspirin', 'Pain reliever', 10.00, 'tablet', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(2, 'Amoxicillin', 'Antibiotic', 15.00, 'tablet', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(3, 'Paracetamol', 'Fever reducer', 5.00, 'tablet', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(4, 'Ibuprofen', 'Pain reliever', 12.00, 'tablet', '2024-11-14 03:06:08', '2024-11-14 03:06:08');

-- --------------------------------------------------------

--
-- Table structure for table `patients`
--

CREATE TABLE `patients` (
  `id` int(11) NOT NULL,
  `first_name` varchar(15) NOT NULL,
  `last_name` varchar(15) NOT NULL,
  `identity_number` int(11) NOT NULL,
  `gender` tinyint(1) DEFAULT 3,
  `address` varchar(255) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `emergency_contact` varchar(50) NOT NULL,
  `emergency_number` varchar(15) NOT NULL,
  `insurance_coverage_percentage` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `patients`
--

INSERT INTO `patients` (`id`, `first_name`, `last_name`, `identity_number`, `gender`, `address`, `phone_number`, `emergency_contact`, `emergency_number`, `insurance_coverage_percentage`, `created_at`, `updated_at`) VALUES
(1, 'John', 'Doe', 123456789, 1, '123 Main St', '1234567890', 'Jane Doe', '0987654321', 80, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(2, 'Alice', 'Smith', 987654321, 2, '456 Oak St', '0987654321', 'Bob Smith', '1234567890', 70, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(3, 'Emma', 'Wilson', 456789123, 2, '789 Maple St', '3456789012', 'Tom Wilson', '2109876543', 90, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(4, 'Michael', 'Taylor', 321654987, 1, '101 Elm St', '4567890123', 'Sarah Taylor', '3209876543', 85, '2024-11-14 03:06:08', '2024-11-14 03:06:08');

-- --------------------------------------------------------

--
-- Table structure for table `positions`
--

CREATE TABLE `positions` (
  `id` tinyint(1) NOT NULL,
  `name` varchar(50) NOT NULL,
  `department_id` tinyint(1) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `positions`
--

INSERT INTO `positions` (`id`, `name`, `department_id`, `created_at`, `updated_at`) VALUES
(1, 'Head Doctor', 1, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(2, 'Nurse', 1, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(3, 'Head Doctor', 2, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(4, 'Technician', 2, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(5, 'Lab Technician', 3, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(6, 'Nurse', 4, '2024-11-14 03:06:08', '2024-11-14 03:06:08');

-- --------------------------------------------------------

--
-- Table structure for table `prepayments`
--

CREATE TABLE `prepayments` (
  `id` int(11) NOT NULL,
  `record_id` int(11) NOT NULL,
  `admission_id` int(11) NOT NULL,
  `original_price` decimal(15,2) NOT NULL,
  `payment_date` date DEFAULT curdate(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `insurance_coverage_percent` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `prepayments`
--

INSERT INTO `prepayments` (`id`, `record_id`, `admission_id`, `original_price`, `payment_date`, `created_at`, `updated_at`, `insurance_coverage_percent`) VALUES
(1, 1, 1, 100.00, '2024-11-02', '2024-11-14 03:06:08', '2024-11-14 03:06:08', 80),
(2, 2, 2, 50.00, '2024-11-06', '2024-11-14 03:06:08', '2024-11-14 03:06:08', 70),
(3, 3, 3, 200.00, '2024-11-10', '2024-11-14 03:06:08', '2024-11-14 03:06:08', 90),
(4, 4, 4, 100.00, '2024-11-09', '2024-11-14 03:06:08', '2024-11-14 03:06:08', 85);

-- --------------------------------------------------------

--
-- Table structure for table `prescriptions`
--

CREATE TABLE `prescriptions` (
  `id` int(11) NOT NULL,
  `record_type` tinyint(1) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `patient_id` int(11) DEFAULT NULL,
  `staff_id` int(11) DEFAULT NULL,
  `prescription_date` date DEFAULT curdate(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `prescriptions`
--

INSERT INTO `prescriptions` (`id`, `record_type`, `record_id`, `patient_id`, `staff_id`, `prescription_date`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, 1, '2024-11-02', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(2, 1, 2, 2, 2, '2024-11-06', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(3, 1, 3, 3, 4, '2024-11-10', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(4, 1, 4, 4, 5, '2024-11-09', '2024-11-14 03:06:08', '2024-11-14 03:06:08');

-- --------------------------------------------------------

--
-- Table structure for table `prescription_details`
--

CREATE TABLE `prescription_details` (
  `id` int(11) NOT NULL,
  `prescription_id` int(11) NOT NULL,
  `medication_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `price` decimal(15,2) DEFAULT NULL,
  `usage_instructions` varchar(255) DEFAULT NULL,
  `note` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `prescription_details`
--

INSERT INTO `prescription_details` (`id`, `prescription_id`, `medication_id`, `quantity`, `price`, `usage_instructions`, `note`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 2, 20.00, 'Take one tablet every 4 hours', 'Pain relief', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(2, 2, 2, 3, 45.00, 'Take one tablet every 8 hours', 'Antibiotic course', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(3, 3, 3, 2, 10.00, 'Take one tablet every 6 hours', 'For fever', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(4, 4, 4, 3, 36.00, 'Take one tablet every 8 hours', 'Pain relief', '2024-11-14 03:06:08', '2024-11-14 03:06:08');

-- --------------------------------------------------------

--
-- Table structure for table `receptions`
--

CREATE TABLE `receptions` (
  `id` int(11) NOT NULL,
  `patient_id` int(11) DEFAULT NULL,
  `queue_number` int(11) NOT NULL,
  `checkin_time` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `receptions`
--

INSERT INTO `receptions` (`id`, `patient_id`, `queue_number`, `checkin_time`, `created_at`, `updated_at`) VALUES
(1, 1, 101, '2024-11-01 01:00:00', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(2, 2, 102, '2024-11-05 02:30:00', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(3, 3, 103, '2024-11-08 03:00:00', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(4, 4, 104, '2024-11-09 04:00:00', '2024-11-14 03:06:08', '2024-11-14 03:06:08');

-- --------------------------------------------------------

--
-- Table structure for table `rooms`
--

CREATE TABLE `rooms` (
  `id` tinyint(1) NOT NULL,
  `department_id` tinyint(1) DEFAULT NULL,
  `bed_count` tinyint(1) DEFAULT NULL,
  `price` decimal(15,2) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `rooms`
--

INSERT INTO `rooms` (`id`, `department_id`, `bed_count`, `price`, `created_at`, `updated_at`) VALUES
(1, 1, 2, 200.00, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(2, 2, 1, 300.00, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(3, 3, 3, 400.00, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(4, 4, 2, 250.00, '2024-11-14 03:06:08', '2024-11-14 03:06:08');

-- --------------------------------------------------------

--
-- Table structure for table `room_usage`
--

CREATE TABLE `room_usage` (
  `id` int(11) NOT NULL,
  `record_id` int(11) NOT NULL,
  `room_id` tinyint(1) NOT NULL,
  `bed_id` tinyint(1) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date DEFAULT NULL,
  `daily_rate` decimal(15,2) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `room_usage`
--

INSERT INTO `room_usage` (`id`, `record_id`, `room_id`, `bed_id`, `start_date`, `end_date`, `daily_rate`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, '2024-11-01', '2024-11-10', 100.00, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(2, 2, 2, 3, '2024-11-05', NULL, 150.00, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(3, 3, 3, 4, '2024-11-08', '2024-11-18', 150.00, '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(4, 4, 4, 6, '2024-11-09', NULL, 200.00, '2024-11-14 03:06:08', '2024-11-14 03:06:08');

-- --------------------------------------------------------

--
-- Table structure for table `service_usage`
--

CREATE TABLE `service_usage` (
  `id` int(11) NOT NULL,
  `record_id` int(11) NOT NULL,
  `service_id` tinyint(1) NOT NULL,
  `usage_date` date DEFAULT curdate(),
  `price` decimal(15,2) DEFAULT NULL,
  `quantity` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `service_usage`
--

INSERT INTO `service_usage` (`id`, `record_id`, `service_id`, `usage_date`, `price`, `quantity`) VALUES
(1, 1, 1, '2024-11-03', 150.00, 1),
(2, 2, 2, '2024-11-07', 500.00, 1),
(3, 3, 3, '2024-11-11', 1000.00, 1),
(4, 4, 4, '2024-11-10', 200.00, 1);

-- --------------------------------------------------------

--
-- Table structure for table `staffs`
--

CREATE TABLE `staffs` (
  `id` int(11) NOT NULL,
  `first_name` varchar(15) NOT NULL,
  `last_name` varchar(15) NOT NULL,
  `position_id` tinyint(1) NOT NULL,
  `phone` varchar(15) NOT NULL,
  `email` varchar(50) NOT NULL,
  `shift` varchar(20) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `staffs`
--

INSERT INTO `staffs` (`id`, `first_name`, `last_name`, `position_id`, `phone`, `email`, `shift`, `created_at`, `updated_at`) VALUES
(1, 'Dr. Mary', 'Johnson', 1, '1122334455', 'mary.johnson@hospital.com', 'day', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(2, 'Nurse Anna', 'White', 2, '2233445566', 'anna.white@hospital.com', 'night', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(3, 'Dr. Robert', 'Brown', 3, '3344556677', 'robert.brown@hospital.com', 'day', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(4, 'Dr. Linda', 'Martinez', 3, '4455667788', 'linda.martinez@hospital.com', 'day', '2024-11-14 03:06:08', '2024-11-14 03:06:08'),
(5, 'Nurse Brian', 'Scott', 6, '5566778899', 'brian.scott@hospital.com', 'night', '2024-11-14 03:06:08', '2024-11-14 03:06:08');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admissions`
--
ALTER TABLE `admissions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `patient_id` (`patient_id`),
  ADD KEY `staff_id` (`staff_id`);

--
-- Indexes for table `beds`
--
ALTER TABLE `beds`
  ADD PRIMARY KEY (`id`),
  ADD KEY `room_id` (`room_id`);

--
-- Indexes for table `billings`
--
ALTER TABLE `billings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `record_id` (`record_id`);

--
-- Indexes for table `billing_details`
--
ALTER TABLE `billing_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `billing_id` (`billing_id`);

--
-- Indexes for table `clinic_rooms`
--
ALTER TABLE `clinic_rooms`
  ADD PRIMARY KEY (`id`),
  ADD KEY `department_id` (`department_id`);

--
-- Indexes for table `departments`
--
ALTER TABLE `departments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `hospital_services`
--
ALTER TABLE `hospital_services`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `service_name` (`service_name`);

--
-- Indexes for table `lab_tests`
--
ALTER TABLE `lab_tests`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `medical_records`
--
ALTER TABLE `medical_records`
  ADD PRIMARY KEY (`id`),
  ADD KEY `patient_id` (`patient_id`),
  ADD KEY `staff_id` (`staff_id`),
  ADD KEY `admission_id` (`admission_id`);

--
-- Indexes for table `medical_record_details`
--
ALTER TABLE `medical_record_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `medical_record_details_ibfk_1` (`record_id`),
  ADD KEY `medical_record_details_ibfk_2` (`lab_test_id`),
  ADD KEY `medical_record_details_ibfk_3` (`medication_id`);

--
-- Indexes for table `medications`
--
ALTER TABLE `medications`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `patients`
--
ALTER TABLE `patients`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `identity_number` (`identity_number`),
  ADD UNIQUE KEY `phone_number` (`phone_number`);

--
-- Indexes for table `positions`
--
ALTER TABLE `positions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `department_id` (`department_id`);

--
-- Indexes for table `prepayments`
--
ALTER TABLE `prepayments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `record_id` (`record_id`),
  ADD KEY `admission_id` (`admission_id`);

--
-- Indexes for table `prescriptions`
--
ALTER TABLE `prescriptions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `patient_id` (`patient_id`),
  ADD KEY `staff_id` (`staff_id`),
  ADD KEY `inpatient_record_id` (`record_id`);

--
-- Indexes for table `prescription_details`
--
ALTER TABLE `prescription_details`
  ADD KEY `prescription_id` (`prescription_id`),
  ADD KEY `medication_id` (`medication_id`);

--
-- Indexes for table `receptions`
--
ALTER TABLE `receptions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `patient_id` (`patient_id`);

--
-- Indexes for table `rooms`
--
ALTER TABLE `rooms`
  ADD PRIMARY KEY (`id`),
  ADD KEY `department_id` (`department_id`);

--
-- Indexes for table `room_usage`
--
ALTER TABLE `room_usage`
  ADD PRIMARY KEY (`id`),
  ADD KEY `record_id` (`record_id`),
  ADD KEY `room_id` (`room_id`),
  ADD KEY `bed_id` (`bed_id`);

--
-- Indexes for table `service_usage`
--
ALTER TABLE `service_usage`
  ADD PRIMARY KEY (`id`),
  ADD KEY `record_id` (`record_id`),
  ADD KEY `service_id` (`service_id`);

--
-- Indexes for table `staffs`
--
ALTER TABLE `staffs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `phone` (`phone`) USING BTREE,
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `position_id` (`position_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admissions`
--
ALTER TABLE `admissions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `beds`
--
ALTER TABLE `beds`
  MODIFY `id` tinyint(1) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `billings`
--
ALTER TABLE `billings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `billing_details`
--
ALTER TABLE `billing_details`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `clinic_rooms`
--
ALTER TABLE `clinic_rooms`
  MODIFY `id` tinyint(1) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `departments`
--
ALTER TABLE `departments`
  MODIFY `id` tinyint(1) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `hospital_services`
--
ALTER TABLE `hospital_services`
  MODIFY `id` tinyint(1) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `lab_tests`
--
ALTER TABLE `lab_tests`
  MODIFY `id` tinyint(1) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `medical_records`
--
ALTER TABLE `medical_records`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `positions`
--
ALTER TABLE `positions`
  MODIFY `id` tinyint(1) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `prepayments`
--
ALTER TABLE `prepayments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `prescriptions`
--
ALTER TABLE `prescriptions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `receptions`
--
ALTER TABLE `receptions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `rooms`
--
ALTER TABLE `rooms`
  MODIFY `id` tinyint(1) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `room_usage`
--
ALTER TABLE `room_usage`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `service_usage`
--
ALTER TABLE `service_usage`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `admissions`
--
ALTER TABLE `admissions`
  ADD CONSTRAINT `admissions_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`id`),
  ADD CONSTRAINT `admissions_ibfk_2` FOREIGN KEY (`staff_id`) REFERENCES `staffs` (`id`);

--
-- Constraints for table `beds`
--
ALTER TABLE `beds`
  ADD CONSTRAINT `beds_ibfk_1` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`id`);

--
-- Constraints for table `billings`
--
ALTER TABLE `billings`
  ADD CONSTRAINT `billings_ibfk_1` FOREIGN KEY (`record_id`) REFERENCES `medical_records` (`id`);

--
-- Constraints for table `billing_details`
--
ALTER TABLE `billing_details`
  ADD CONSTRAINT `billing_details_ibfk_1` FOREIGN KEY (`billing_id`) REFERENCES `billings` (`id`);

--
-- Constraints for table `clinic_rooms`
--
ALTER TABLE `clinic_rooms`
  ADD CONSTRAINT `clinic_rooms_ibfk_1` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`);

--
-- Constraints for table `medical_records`
--
ALTER TABLE `medical_records`
  ADD CONSTRAINT `medical_records_ibfk_1` FOREIGN KEY (`admission_id`) REFERENCES `admissions` (`id`);

--
-- Constraints for table `medical_record_details`
--
ALTER TABLE `medical_record_details`
  ADD CONSTRAINT `medical_record_details_ibfk_1` FOREIGN KEY (`record_id`) REFERENCES `medical_records` (`id`),
  ADD CONSTRAINT `medical_record_details_ibfk_2` FOREIGN KEY (`lab_test_id`) REFERENCES `lab_tests` (`id`),
  ADD CONSTRAINT `medical_record_details_ibfk_3` FOREIGN KEY (`medication_id`) REFERENCES `medications` (`id`);

--
-- Constraints for table `positions`
--
ALTER TABLE `positions`
  ADD CONSTRAINT `positions_ibfk_1` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`);

--
-- Constraints for table `prepayments`
--
ALTER TABLE `prepayments`
  ADD CONSTRAINT `prepayments_ibfk_1` FOREIGN KEY (`admission_id`) REFERENCES `admissions` (`id`),
  ADD CONSTRAINT `prepayments_ibfk_2` FOREIGN KEY (`record_id`) REFERENCES `medical_records` (`id`);

--
-- Constraints for table `prescriptions`
--
ALTER TABLE `prescriptions`
  ADD CONSTRAINT `prescriptions_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`id`),
  ADD CONSTRAINT `prescriptions_ibfk_2` FOREIGN KEY (`staff_id`) REFERENCES `staffs` (`id`),
  ADD CONSTRAINT `prescriptions_ibfk_3` FOREIGN KEY (`record_id`) REFERENCES `medical_records` (`id`);

--
-- Constraints for table `prescription_details`
--
ALTER TABLE `prescription_details`
  ADD CONSTRAINT `prescription_details_ibfk_1` FOREIGN KEY (`prescription_id`) REFERENCES `prescriptions` (`id`),
  ADD CONSTRAINT `prescription_details_ibfk_2` FOREIGN KEY (`medication_id`) REFERENCES `medications` (`id`);

--
-- Constraints for table `receptions`
--
ALTER TABLE `receptions`
  ADD CONSTRAINT `receptions_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`id`);

--
-- Constraints for table `rooms`
--
ALTER TABLE `rooms`
  ADD CONSTRAINT `rooms_ibfk_1` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`);

--
-- Constraints for table `room_usage`
--
ALTER TABLE `room_usage`
  ADD CONSTRAINT `room_usage_ibfk_1` FOREIGN KEY (`record_id`) REFERENCES `medical_records` (`id`),
  ADD CONSTRAINT `room_usage_ibfk_2` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`id`),
  ADD CONSTRAINT `room_usage_ibfk_3` FOREIGN KEY (`bed_id`) REFERENCES `beds` (`id`);

--
-- Constraints for table `service_usage`
--
ALTER TABLE `service_usage`
  ADD CONSTRAINT `service_usage_ibfk_1` FOREIGN KEY (`record_id`) REFERENCES `medical_records` (`id`),
  ADD CONSTRAINT `service_usage_ibfk_2` FOREIGN KEY (`service_id`) REFERENCES `hospital_services` (`id`);

--
-- Constraints for table `staffs`
--
ALTER TABLE `staffs`
  ADD CONSTRAINT `staffs_ibfk_1` FOREIGN KEY (`position_id`) REFERENCES `positions` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
