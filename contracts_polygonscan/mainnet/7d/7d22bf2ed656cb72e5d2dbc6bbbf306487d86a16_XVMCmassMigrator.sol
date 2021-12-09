/**
 *Submitted for verification at polygonscan.com on 2021-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IacPool {
    function migrateStake(address _staker) external;
    function getUserShares(address wallet) external view returns (uint256);
}

contract XVMCmassMigrator {
   function bulkMigrate(address _poolAddress, address[] calldata _depositorList) public  
   {
      for (uint256 i = 0; i < _depositorList.length; i++) {
		if(IacPool(_poolAddress).getUserShares(_depositorList[i]) > 0) {
			IacPool(_poolAddress).migrateStake(_depositorList[i]);
		}
	   }
    }
}