/**
 *Submitted for verification at polygonscan.com on 2021-11-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IacPool {
    function transferOwnership(address newOwner) external;
}

     /**
     * This is an equivalent to "migrator rug pull" code in pancakeswap
     * Only available prior to token distribution, when the ownership is highly concentrated
     * At this point it only makes sense to prioritize flexibility over decentralization and security
     * It gives the contract owner permission to make modificiations and updates
     * Once tokens are distributed, the ownership can be renounced by anybody
     * The "migrator" is only available until that point
     */ 
contract XVMCmigrator {
    address public immutable acPool1 = 0x9b6ae196A358Ea81c305D8A32018a4F4C90FC207;
    address public immutable acPool2 = 0x38d2503d751F35c2671cdae6E9011e7Be5CdF174;
    address public immutable acPool3 = 0x418E16d46c66435E72aC646A7bC2a0c286349C55;
    address public immutable acPool4 = 0x321521b99Dbb21705259eA3d84a1d83c37C98D0A;
    address public immutable acPool5 = 0x984981089d06A514AB54Bc3562850aFc75620e26;
    address public immutable acPool6 = 0xfD08FA4a344D147DCcE4f29D258B9F4ae18e6ee0;
    
    uint256 newGovernorRequestBlock;
    address eligibleNewGovernor;
    
    bool changeGovernorActivated;
    
    event TransferOwner(address newOwner, uint256 timestamp);
    
    modifier onlyTrustee {
      require(msg.sender == 0x9c36BC6b8C107014B6E86536D809b74C6fdB8cE9);
      _;
    }
    
    function gracePeriodTransferOwner(address newOwnerAddress) external onlyTrustee {
        require(!changeGovernorActivated, "already activated");
        changeGovernorActivated = true;
        newGovernorRequestBlock = block.number;
        eligibleNewGovernor = newOwnerAddress;
        
        emit TransferOwner(eligibleNewGovernor, newGovernorRequestBlock); //explicit
    }
    
    /**
     * Timelock-equivalent
     */
    function afterDelayOwnership() external onlyTrustee {
        require(changeGovernorActivated, "grace transfer not requested");
        require(newGovernorRequestBlock + 6942 < block.number, "Pending timelock");
        
        IacPool(acPool1).transferOwnership(eligibleNewGovernor);
        IacPool(acPool2).transferOwnership(eligibleNewGovernor);
        IacPool(acPool3).transferOwnership(eligibleNewGovernor);
        IacPool(acPool4).transferOwnership(eligibleNewGovernor);
        IacPool(acPool5).transferOwnership(eligibleNewGovernor);
        IacPool(acPool6).transferOwnership(eligibleNewGovernor);
    }
    
    /**
     * For changing pools individually
     */
    function afterDelayOwnershipCustom(address _poolAddress, address _newOwner) external onlyTrustee {
        require(changeGovernorActivated, "grace transfer not requested");
        require(newGovernorRequestBlock + 6942 < block.number, "Pending timelock");
        
        IacPool(_poolAddress).transferOwnership(_newOwner);
    }

}