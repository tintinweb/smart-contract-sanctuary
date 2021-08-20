/**
 *Submitted for verification at polygonscan.com on 2021-08-20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract LoanManager {
    
    address public aaveLendingPoolAddress = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;
    
    address private owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function getHealthFactor() public view {
        LendingPool lp = LendingPool(aaveLendingPoolAddress);
        lp.getUserAccountData(owner);
    }
    
    function getLoan() internal {
        
    }
    
    function repayLoan() internal {
        
    }
}

contract FarmManager {
    
    function depositToFarm() internal {
        
    }
    
    
    function withdrawFromFarm() internal {
        
    }
}

contract LendingPool {
    
    function getUserAccountData(address user) external view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    ) {}
}