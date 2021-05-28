/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface contract2{
    function editData(address user, uint256 lockedRewards, uint256 firstBlock) external ;
    function definiteStats(address user) external view returns(uint256 firstBlock, uint256 lockedRewards, uint256 totalLockedRewards);
    function claimRewards(address user) external returns(bool);
    
}

interface IERC20{

  function transfer(address recipient, uint256 amount) external returns (bool);

}

interface MCHstakingInterface {
    
    function showBlackUser(address user) external view returns(bool) ;
}

interface Icontract3{
    function withdrawLockedRewards() external ;
    event WithdrawLockedRewards(address indexed user, uint256 amount);
}
contract contract3 is Icontract3{
    
    IERC20 MCF;
    contract2 SC2;

    uint256 private _currentBlock;
    mapping(address => uint256) private claimedMonths;

    
    function setCurrentBlock(uint256 number) external {
        _currentBlock = number;
    }
    
    function currentBlock() external view returns(uint256){
        return _currentBlock;
    }
    
    constructor(address contract2Address, address MCFaddress){
        SC2 = contract2(contract2Address);
        MCF = IERC20(MCFaddress);
    }

    function withdrawLockedRewards() external override {
        (uint256 firstBlock, uint256 lockedRewards, uint256 totalLockedRewards) = SC2.definiteStats(msg.sender);
        require(_currentBlock > 13154230 && lockedRewards > 0);
        ////////////////////////12755461
        SC2.claimRewards(msg.sender);
        uint256 claimedRewards;
        uint256 month = (_currentBlock - 12762107) / 199384;
        while(month > claimedMonths[msg.sender]){
        
        if(lockedRewards == 0){break;}
        uint256 totalLocked = totalLockedRewards/10;
        
        if(lockedRewards < totalLocked){MCF.transfer(msg.sender, lockedRewards); claimedRewards += lockedRewards; lockedRewards = 0;}
        else{MCF.transfer(msg.sender, totalLocked); claimedRewards += lockedRewards; lockedRewards -=totalLocked; }
        
        ++claimedMonths[msg.sender];
        }
        
        SC2.editData(msg.sender, lockedRewards, firstBlock);
        
        emit WithdrawLockedRewards(msg.sender, claimedRewards);
    }
}