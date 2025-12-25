
select * from restaurant.training_hours;

select * from restaurant.employee_list1;
select * from restaurant.department;

#1. Headcount wise description

# Headcount description by racial distribution for diversity
SELECT
    department,
    jobtitle AS role,
    race,
    COUNT(*) AS headcount
FROM restaurant.employee_list1
WHERE Exit_date IS NULL OR Exit_date = '' OR Exit_date = '0000-00-00'
GROUP BY department, jobtitle, race
ORDER BY department, role, race;

# Total active headcount with jobtitle wise description
SELECT 
    department,
    jobtitle,
    COUNT(*) AS total_active_employees
FROM restaurant.employee_list1
WHERE Exit_date = ''
GROUP BY department, jobtitle
ORDER BY department, total_active_employees DESC;

# Headcount by Department
SELECT 
    department,
    COUNT(*) AS headcount
FROM restaurant.employee_list1
WHERE Exit_date = ''
GROUP BY department
ORDER BY headcount DESC;

# Headcount by Department, Job Title, Gender & Location
SELECT 
    department,
    jobtitle,
    gender,
    location,
    COUNT(*) AS headcount
FROM restaurant.employee_list1
WHERE Exit_date = ''
GROUP BY department, jobtitle, gender, location
ORDER BY department, headcount DESC;


#2. Training Impact by Department

SELECT 
    e.department,
    ROUND(AVG(t.training_hours), 2) AS avg_training_hours,
    ROUND(AVG(e.performance_rating), 2) AS avg_performance_rating,
    CASE
        WHEN AVG(e.performance_rating) < 2.7 THEN 'need to improve training'
        WHEN AVG(e.performance_rating) BETWEEN 2.7 AND 3.5 THEN 'better results'
        ELSE 'training has +ve impact'
    END AS performance_impact
FROM restaurant.employee_list1 e
JOIN restaurant.training_hours t
    ON e.id = t.employee_id
WHERE e.performance_rating IS NOT NULL
GROUP BY e.department
ORDER BY e.department;

#3. Attrition description
#Attrition Rate by Department, Role & Overtime Band
SELECT
    department,
    jobtitle AS role,
    overtime_band,
    COUNT(*) AS attrition_count
FROM (
    SELECT
        department,
        jobtitle,
        overtime_hours,
        CASE
            WHEN overtime_hours < 10 THEN 'Low OT'
            WHEN overtime_hours BETWEEN 10 AND 30 THEN 'Medium OT'
            ELSE 'High OT'
        END AS overtime_band
    FROM restaurant.employee_list1
    WHERE attrition_flag = 'yes'
) ot_calc
GROUP BY department, role, overtime_band
ORDER BY department, role, overtime_band;

# Attrition by salary

SELECT
    department,
    jobtitle AS role,
    salary_band,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN attrition_flag = 'yes' THEN 1 ELSE 0 END) AS attritions,
    ROUND(SUM(CASE WHEN attrition_flag = 'yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM (
    SELECT
        department,
        jobtitle,
        salary,
        attrition_flag,
        CASE
            WHEN salary < 30000 THEN 'Low Salary'
            WHEN salary BETWEEN 30000 AND 60000 THEN 'Medium Salary'
            ELSE 'High Salary'
        END AS salary_band
    FROM restaurant.employee_list1
) sal_calc
GROUP BY department, role, salary_band
ORDER BY department, role, salary_band;

# View created for attrition by Department & Role
CREATE OR REPLACE VIEW restaurant.vw_attrition_department_role AS
SELECT
    department,
    jobtitle AS role,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN attrition_flag = 'yes' THEN 1 ELSE 0 END) AS attritions,
    ROUND(SUM(CASE WHEN attrition_flag = 'yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM restaurant.employee_list1
GROUP BY department, jobtitle
ORDER BY department, attrition_rate_pct DESC;

SELECT * FROM restaurant.vw_attrition_department_role;

#4. Stored procedues
DELIMITER $$

CREATE PROCEDURE restaurant.sp_training_performance_by_department()
BEGIN
    SELECT 
        e.department,
        ROUND(AVG(t.training_hours), 2) AS avg_training_hours,
        ROUND(AVG(e.performance_rating), 2) AS avg_performance_rating,
        CASE
            WHEN AVG(e.performance_rating) < 2.7 THEN 'need to improve training'
            WHEN AVG(e.performance_rating) BETWEEN 2.7 AND 3.5 THEN 'better results'
            ELSE 'training has +ve impact'
        END AS performance_impact
    FROM restaurant.employee_list1 e
    JOIN restaurant.training_hours t
        ON e.id = t.employee_id
    WHERE e.Exit_date IS NULL OR e.Exit_date = '' OR e.Exit_date = '0000-00-00'
    GROUP BY e.department
    ORDER BY e.department;
END $$

DELIMITER ;

CALL restaurant.sp_training_performance_by_department();

# Department Performance & Engagement by Salary Band

DELIMITER $$

CREATE PROCEDURE restaurant.sp_performance_engagement_by_salary()
BEGIN
    SELECT
        department,
        salary_band,
        ROUND(AVG(performance_rating), 2) AS avg_performance_rating,
        ROUND(AVG(engagement_score), 2) AS avg_engagement_score,
        COUNT(*) AS employee_count
    FROM (
        SELECT
            department,
            performance_rating,
            engagement_score,
            salary,
            CASE
                WHEN salary < 30000 THEN 'Low Salary'
                WHEN salary BETWEEN 30000 AND 60000 THEN 'Medium Salary'
                ELSE 'High Salary'
            END AS salary_band
        FROM restaurant.employee_list1
        WHERE Exit_date IS NULL OR Exit_date = '' OR Exit_date = '0000-00-00'
    ) AS sal_calc
    GROUP BY department, salary_band
    ORDER BY department, salary_band;
END $$

DELIMITER ;

CALL restaurant.sp_performance_engagement_by_salary();








