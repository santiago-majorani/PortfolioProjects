SELECT *
FROM PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate Date

-- Populate Property Adress data.
-- We use the Parcels ID to complete the Address data when possible. For that, we self join the table
-- and populate the addresses with the info from the Parcels ID.

--Firstly we check the info.
SELECT N1.ParcelID,N1.PropertyAddress,N2.ParcelID,N2.PropertyAddress, ISNULL(N1.PropertyAddress,N2.PropertyAddress)
FROM PortfolioProject..NashvilleHousing AS N1
JOIN PortfolioProject..NashvilleHousing AS N2
	ON N1.ParcelID=N2.ParcelID
	AND N1.[UniqueID ]=N2.[UniqueID ]

-- Now we run an UPDATE command to populate the nulls when possible.
UPDATE N1
SET PropertyAddress = ISNULL(N1.PropertyAddress,N2.PropertyAddress)
FROM PortfolioProject..NashvilleHousing AS N1
JOIN PortfolioProject..NashvilleHousing AS N2
	ON N1.ParcelID=N2.ParcelID
	AND N1.[UniqueID ]=N2.[UniqueID ]
WHERE N1.PropertyAddress is null

--Breaking out Address into Individual columns (Address, City, State)
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing

-- Let's start with Addess and City

-- For isolating the data, we use the commas as our delimiter.
-- First value is address, which appears right before the first comma, so we use CHARINDEX to search
-- for the commas in each row and grab all the previous characters.
-- For the City we now start in the commas and we go to the end of each row, so we use LEN to determine the
-- end of the SUBSTRING.
SELECT 
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) AS Adress,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing

--We can now add this info to two new columns so we have it for future work.

--Creation of Split Address column.
ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress nvarchar (255);
--Insertion of data.
UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1);

--Creation of Split City column.
ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitCity nvarchar(255);
--Insertion of data.
UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress));

-- We now move on to State info, and for that we use the OwnerAddress column.
SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing

-- We isolate the state with PARSENAME to show a different way to achieve the same.
-- Since this function only works with periods, we also use REPLACE in this query.
SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM PortfolioProject..NashvilleHousing

-- Much easier way to achieve the same than the previous two columns.
-- Let's import this data in a new column.

-- Creation of State column.
ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitState nvarchar(255);
-- Insertion of data.
UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)


-- Change Y and N to 'Yes' and 'No' in Sold as Vacant field.
-- Firstly we check the data.
SELECT SoldAsVacant, COUNT(SoldAsVacant) AS Amount
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

-- We now use CASE to replace the Y and N.
SELECT
	SoldAsVacant,
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END AS SoldAsVacantCorrected	
FROM PortfolioProject..NashvilleHousing

-- Now we replace the values with the corrected ones in our column.
UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END


-- Remove duplicates.
-- Firstly, we will use CTEs and Window Functions to find where there are duplicates.
-- We use ROW_NUMBER to count the appereances where certain fields are identically equal.
-- We will asume that when these fields are equal, then the property is the same and therefore, there is
-- a duplicated row.
 WITH RowNumCTE AS
 (SELECT
	*,
	ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
					 PropertyAddress,
					 SalePrice,
					 SaleDate,
					 LegalReference
					 ORDER BY
						ParcelID) AS Row_num
FROM PortfolioProject..NashvilleHousing)
-- We compliment this CTE with DELETE so we erase all the duplicated values.
DELETE 
FROM RowNumCTE
WHERE Row_num>1


-- Delete unused columns.
-- We will delete the OwnerAddress, TaxDistrict and PropertyAddress columns which won't be used by us in the
-- future. It is important to mention that this procedure should NOT we used with raw data, and should
-- be reserved to duplicates of the original dataset or to temp tables only.
SELECT *
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress