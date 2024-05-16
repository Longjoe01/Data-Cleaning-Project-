/*


Cleaning Data in SQL Project


*/

select *
from PortfolioProject..NashVilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Standardize the Date Format
-- I have added a column SaleDateConverted,and converted it to the standardized date format. 
-- Subsequently, the SaleDate column will be deleted and replaced with this.

Alter Table NashVilleHousing
Add SaleDateConverted date;

Update NashVilleHousing
set SaleDateConverted = CONVERT(date, SaleDate)

--------------------------------------------------------------------------------------------------------------------------------------

-- Populate the Property Address

select *
from PortfolioProject..NashVilleHousing
where PropertyAddress is null
order by ParcelID    --- From here, we can see there are similar ParcelID, where one has an address and the other has no address.

-- We'll try to populate the address of the missing one with the filled one where the ParcelID is the same.
-- This is achieved by joining the table to itself

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, isnull(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject..NashVilleHousing a
	join PortfolioProject..NashVilleHousing b      --Where a.PropertyAddress is null, it will be filled with the value
	on a.ParcelID = b.ParcelID                     --in b.PropertyAddress where the UniqueID is not the same.
	and a.[UniqueID ] <> b.[UniqueID ]              
where a.PropertyAddress is null
 

 -- Now we update our table

 Update a
 set PropertyAddress = isnull(a.PropertyAddress, b.PropertyAddress)
 from PortfolioProject..NashVilleHousing a
	join PortfolioProject..NashVilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

-----------------------------------------------------------------------------------------------------------------------------------------
--Breaking out Addresss into individual columns (Address, City, State)

select PropertyAddress
from PortfolioProject..NashVilleHousing

select 
SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress)-1) address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))
from PortfolioProject..NashVilleHousing

Alter Table NashVilleHousing
Add PropertyUpdateAddress nvarchar(255);

Update NashVilleHousing
set PropertyUpdateAddress = SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress)-1)


Alter Table NashVilleHousing
Add PropertyUpdateCity nvarchar(255);

Update NashVilleHousing
set PropertyUpdateCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

select *
from PortfolioProject..NashVilleHousing

-- We can use PARSENAME to achieve the same thing.
Select
Parsename(OwnerAddress, 1)  -- since PARSENAME does not recognise ',' but '.', we replace all commas with fullstop
from PortfolioProject..NashVilleHousing

Select
Parsename(Replace(OwnerAddress, ',', '.'), 3),
Parsename(Replace(OwnerAddress, ',', '.'), 2),
Parsename(Replace(OwnerAddress, ',', '.'), 1)
from PortfolioProject..NashVilleHousing


Alter Table NashVilleHousing
Add OwnerUpdateAddress nvarchar(255);

Update NashVilleHousing
Set OwnerUpdateAddress = Parsename(Replace(OwnerAddress, ',', '.'), 3)


Alter Table NashVilleHousing
Add OwnerUpdateCity nvarchar(255);

Update NashVilleHousing
Set OwnerUpdateCity = Parsename(Replace(OwnerAddress, ',', '.'), 2)

Alter Table NashVilleHousing
Add OwnerUpdateState nvarchar(255);

Update NashVilleHousing
Set OwnerUpdateState = Parsename(Replace(OwnerAddress, ',', '.'), 1)

---------------------------------------------------------------------------------------------------------------------------------------

-- Change 'Y' and 'N' to 'Yes' and 'No' in SoldAsVacant field

Select Distinct SoldAsVacant, count(SoldAsVacant)
from NashVilleHousing
Group by SoldAsVacant
Order by 2

Select SoldAsVacant,
Case
	When SoldAsVacant = 'Y' Then 'Yes'
	When SoldAsVacant = 'N' Then 'No'
	Else SoldAsVacant
End
from NashVilleHousing

Update NashVilleHousing
Set SoldAsVacant = Case
	When SoldAsVacant = 'Y' Then 'Yes'
	When SoldAsVacant = 'N' Then 'No'
	Else SoldAsVacant
End

-----------------------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates
With RowNumCTE as(
Select *,
	ROW_NUMBER() over(
	partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 Order by UniqueID)
				 as row_num
from NashVilleHousing)

Delete
from RowNumCTE
where row_num > 1
------------------------------------------------------------------------------------------------------------------------------------------
---Remove Unused Column
Select *
from NashVilleHousing

Alter Table PortfolioProject..NashVilleHousing
Drop Column SaleDate,PropertyAddress,OwnerAddress,TaxDistrict