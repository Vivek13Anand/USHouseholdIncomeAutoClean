SELECT * FROM US_Household.USHouseholdIncome_AutoClean;

SELECT * FROM US_Household.USHouseholdIncome_CleanedData;

DELIMITER $$
DROP PROCEDURE IF EXISTS Copy_and_Clean_Data;
CREATE PROCEDURE Copy_and_Clean_Data()
BEGIN
CREATE TABLE IF NOT EXISTS USHouseholdIncome_CleanedData(
   row_id     INTEGER  NOT NULL Primary KEY 
  ,id           INTEGER  NOT NULL
  ,State_Code INTEGER  NOT NULL
  ,State_Name VARCHAR(20) NOT NULL
  ,State_ab   VARCHAR(2) NOT NULL
  ,County       VARCHAR(33) NOT NULL
  ,City         VARCHAR(22) NOT NULL
  ,Place        VARCHAR(36)
  ,`Type`         VARCHAR(12) NOT NULL
  ,`Primary`    VARCHAR(5) NOT NULL
  ,Zip_Code   INTEGER  NOT NULL
  ,Area_Code  VARCHAR(3) NOT NULL
  ,ALand        BIGINT  NOT NULL
  ,AWater       BIGINT  NOT NULL
  ,Lat          NUMERIC(10,7) NOT NULL
  ,Lon          NUMERIC(12,7) NOT NULL
  ,TimeStamp TIMESTAMP DEFAULT NULL
); 

-- COPY DATA TO NEW TABLE

INSERT INTO USHouseholdIncome_CleanedData
SELECT * , CURRENT_TIMESTAMP
FROM US_Household.USHouseholdIncome_AutoClean;

-- DATA CLEANING STEPS

-- 1. REMOVING DUPLICATES

DELETE FROM USHouseholdIncome_CleanedData
WHERE 
		row_id IN(
					SELECT row_id
                    FROM(
						SELECT row_id, id, ROW_NUMBER() OVER (PARTITION BY id, `TimeStamp` ORDER BY id, `TimeStamp`) AS row_num
                        FROM USHouseholdIncome_CleanedData
                        ) duplicates
                        WHERE row_num > 1
                        );
                        
-- 2. Standardization

UPDATE USHouseholdIncome_CleanedData
SET State_Name = 'Georgia'
WHERE State_Name = 'georgia'

UPDATE USHouseholdIncome_CleanedData
SET County = UPPER(County);

UPDATE USHouseholdIncome_CleanedData
SET City = UPPER(City);
        
UPDATE USHouseholdIncome_CleanedData
SET Place = UPPER(Place);

UPDATE USHouseholdIncome_CleanedData
SET State_Name = UPPER(State_Name);

UPDATE USHouseholdIncome_CleanedData
SET 'Type' = 'CDP'
WHERE 'Type' = 'CPD';

UPDATE USHouseholdIncome_CleanedData
SET 'Type' = 'Borough'
WHERE 'Type' = 'Boroughs';

END$$
DELIMITER ;

CALL Copy_and_Clean_Data();

-- CREATE TRIGGER

DELIMITER $$
CREATE TRIGGER Transfer_Cleaned_Data
		AFTER INSERT ON US_Household.USHouseholdIncome_AutoClean
        FOR EACH ROW
BEGIN
		CALL Copy_and_Clean_Data();
END $$
DELIMITER ;

-- CREATE EVENT

DROP EVENT run_data_cleaning;
CREATE EVENT run_data_cleaning
		ON SCHEDULE EVERY 30 DAY
        DO CALL Copy_and_Clean_Data();
INSERT INTO US_Household.USHouseholdIncome_AutoClean
(row_id, id, State_Code, State_Name, State_ab, County, City, Place, Type, `Primary`, Zip_Code, Area_Code, ALand, AWater, Lat, Lon )
VALUES
( '1', '1026', '1', 'Alabama', 'AL', 'Autauga County', 'Elmore', 'Autaugaville', 'Track', 'Track', '36025', '334', '8020338', '60048', '32.4473511', '-86.4768097')
;
