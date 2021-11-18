/**
 *Submitted for verification at polygonscan.com on 2021-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IacPool {
    function transferOwnership(address newOwner) external;
    function setAdmin(address _admin, address _treasury) external;
    function setMigrationPool(address _newPool) external;
}
interface IGovernance {
    function rebalancePools() external;
}

     /**
     * This similar to "migrator rug pull" code in pancakeswap
     * Only available prior to token distribution, when the ownership is highly concentrated
     * At this point it only makes sense to prioritize flexibility over decentralization and security
     * It gives the contract owner permission to make modificiations and updates
     * Once tokens are distributed, the ownership can be renounced by anybody
     * The "migrator" is only available until that point
     */ 
contract XVMCmigrator {
    struct PoolMigration {
        address oldPool;
        address newPool;
        uint256 requestBlock;
    }
    address public immutable admin = 0x35a61fCB88979AA591360D137B5bdB441cC46Ab3;
    
    address public immutable acPool1 = 0x9b6ae196A358Ea81c305D8A32018a4F4C90FC207;
    address public immutable acPool2 = 0x38d2503d751F35c2671cdae6E9011e7Be5CdF174;
    address public immutable acPool3 = 0x418E16d46c66435E72aC646A7bC2a0c286349C55;
    address public immutable acPool4 = 0x321521b99Dbb21705259eA3d84a1d83c37C98D0A;
    address public immutable acPool5 = 0x984981089d06A514AB54Bc3562850aFc75620e26;
    address public immutable acPool6 = 0xfD08FA4a344D147DCcE4f29D258B9F4ae18e6ee0;
    
    PoolMigration[] public migratePoolRequest;
    
    uint256 newGovernorRequestBlock;
    address eligibleNewGovernor;
    address treasury;
    bool changeGovernorActivated;
    
    
    
    event TransferOwner(address newOwner, uint256 timestamp);
    event MigratePools(address oldPool, address migrateIntoPool, uint256 block);
    
    modifier onlyTrustee {
      require(msg.sender == 0x9c36BC6b8C107014B6E86536D809b74C6fdB8cE9);
      _;
    }
    
    function gracePeriodTransferOwner(address newOwnerAddress, address newTreasury) external onlyTrustee {
        require(!changeGovernorActivated, "already activated");
        changeGovernorActivated = true;
        newGovernorRequestBlock = block.number;
        eligibleNewGovernor = newOwnerAddress;
        treasury = newTreasury;
        
        emit TransferOwner(eligibleNewGovernor, newGovernorRequestBlock); //explicit
    }
    
    /**
     * Timelock-equivalent
     */
    function afterDelayOwnership() external onlyTrustee {
        require(changeGovernorActivated, "grace transfer not requested");
        require(newGovernorRequestBlock + 1337 < block.number, "Pending timelock");
        
        IacPool(acPool1).setAdmin(eligibleNewGovernor, treasury);
        IacPool(acPool2).setAdmin(eligibleNewGovernor, treasury);
        IacPool(acPool3).setAdmin(eligibleNewGovernor, treasury);
        IacPool(acPool4).setAdmin(eligibleNewGovernor, treasury);
        IacPool(acPool5).setAdmin(eligibleNewGovernor, treasury);
        IacPool(acPool6).setAdmin(eligibleNewGovernor, treasury);
    }
    
    /**
     * For changing pools individually
     * Slightly sketchy, can set custom admin after time lock
     * This function and afterDelayOwnership likely won't even be used, but is there just in case
     * Only need pool migration
     */
    function afterDelayOwnershipCustom(address _poolAddress, address _admin, address _treasury) external onlyTrustee {
        require(changeGovernorActivated, "grace transfer not requested");
        require(newGovernorRequestBlock + 1337 < block.number, "Pending timelock");
        
        IacPool(_poolAddress).setAdmin(_admin, _treasury);
        emit TransferOwner(eligibleNewGovernor, block.number); 
    }
    
    /**
     * 
     */
    function requestPoolMigration(address _migratingFrom, address _migratingInto) external onlyTrustee {
        migratePoolRequest.push(
            PoolMigration(_migratingFrom, _migratingInto, block.number)
        );
        
        emit MigratePools(_migratingFrom, _migratingInto, block.number);
    }
    
    /**
     * Migration into new pools
     */
    function afterDelaySetMigrationPool(uint256 requestID) external onlyTrustee {
        require(migratePoolRequest[requestID].requestBlock + 1337 < block.number, "Pending timelock");
        
        IacPool(migratePoolRequest[requestID].oldPool).setMigrationPool(migratePoolRequest[requestID].newPool);
    }
    
    //just a proxy into governor
    function rebalancePools() external {
        IGovernance(admin).rebalancePools(); 
    }

}