Select * 
From Housing_Data;

---------------------------------------------------------------------------------------------
-- Standarize Date Format

Update Housing_Data
Set SaleDate = CONVERT(Date,SaleDate);

---------------------------------------------------------------------------------------------
-- Populate Property Address Data

Select *
From Housing_Data
--Where PropertyAddress is null;
order by ParcelID;

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From Housing_Data a
JOIN Housing_Data b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From Housing_Data a
JOIN Housing_Data b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null

---------------------------------------------------------------------------------------------
-- Break out address into PropertyAddress(Address, City)

Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as Address
From Housing_Data;

ALTER TABLE Housing_Data
Add PropertySplitAddress nvarchar(255);

Update Housing_Data
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);

ALTER TABLE Housing_Data
Add PropertySplitCity nvarchar(255);

Update Housing_Data
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

---------------------------------------------------------------------------------------------
-- Break out address into OwnerAddress(Address, City, State)

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM Housing_Data;

ALTER TABLE Housing_Data
Add OwnerSplitAddress nvarchar(255);

Update Housing_Data
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

ALTER TABLE Housing_Data
Add OwnerSplitCity nvarchar(255);

Update Housing_Data
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

ALTER TABLE Housing_Data
Add OwnerSplitState nvarchar(255);

Update Housing_Data
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

Select *
From Housing_Data;

---------------------------------------------------------------------------------------------
-- Change 0 and 1 to No and Yes in "Sold as vacant"

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From Housing_Data
Group by SoldAsVacant
Order by SoldAsVacant;

Alter Table Housing_Data
Alter Column SoldAsVacant nvarchar(10);

Update Housing_Data
SET SoldAsVacant = CASE When SoldAsVacant = '0' THEN 'No'
		When SoldAsVacant = '1' THEN 'Yes'
		Else SoldAsVacant
		END;

---------------------------------------------------------------------------------------------
-- Remove Duplicates

WITH RowNumCTE as (
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 Order BY
					UniqueID
					) row_num
From Housing_Data
--Order by ParcelID
)
DELETE
From RowNumCTE
Where row_num > 1;

WITH RowNumCTE as (
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 Order BY
					UniqueID
					) row_num
From Housing_Data
--Order by ParcelID
)
Select *
From RowNumCTE
Where row_num > 1;

---------------------------------------------------------------------------------------------
-- Delete Unsused Columns

Select *
From Housing_Data;

ALTER TABLE Housing_Data
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress;
