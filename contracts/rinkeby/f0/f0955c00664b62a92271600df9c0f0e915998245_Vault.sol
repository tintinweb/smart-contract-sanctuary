/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Vault {
    
    struct VaultDetails {
        address owner;
        uint256 collateral;
        uint256 debt;
    }
    
    mapping (uint256 => VaultDetails) public vaults;
    
    uint256 public ltvRatio = 5e17;
    
    uint256 public collateralPrice = 1e18;
    
    uint256 public vaultsCount = 1;
    
    event DetailsUpdated(
        uint256 _ltvRatio, 
        uint256 _collateralPrice
    );
    
    event VaultCreated(
        address _user, 
        uint256 _vaultId, 
        uint256 _collateral,
        uint256 _debt
    );
    
    function setVariables(
        uint256 _ltvRatio,
        uint256 _collateralPrice
    )
        public
    {
        ltvRatio = _ltvRatio;
        collateralPrice= _collateralPrice;
        
        emit DetailsUpdated(
            _ltvRatio,
            _collateralPrice
        );
    }
    
    function deposit(
        uint256 _debt
    ) 
        public 
        payable 
    {
        
        uint256 collateralValue = msg.value * collateralPrice;
        uint256 userRatio = collateralValue / _debt;
        
        require(
            userRatio >= ltvRatio,
            "You must meet the minimum LTV ratio requirements"
        );
        
        vaults[vaultsCount] = VaultDetails(
            msg.sender,
            msg.value,
            _debt
        );
        
        emit VaultCreated(
            msg.sender,
            vaultsCount,
            msg.value,
            _debt
        );
        
        vaultsCount++;

    }

    
    
}