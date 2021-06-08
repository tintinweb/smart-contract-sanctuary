/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity ^0.8.4;

interface contract2{
    function editData(address user, uint256 lockedRewards, uint256 firstBlock) external ;
    function definiteStats(address user) external view returns(uint256 firstBlock, uint256 lockedRewards, uint256 totalLockedRewards);
    function claimRewards(address user) external returns(bool);
    function userStats(address user) external view returns(uint256 firstBlock, uint256 claimedDays, uint256 lockedRewards, uint256 claimableRewards);
    
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
    
    address _owner;

    uint256 private _currentBlock;
    mapping(address => uint256) private claimedMonths;

    
    function setCurrentBlock(uint256 number) external {
        _currentBlock = number;
    }
    
    function currentBlock() external view returns(uint256){
        return _currentBlock;
    }
    
    constructor(address contract2Address, address MCFaddress){
        _owner = msg.sender;
        SC2 = contract2(contract2Address);
        MCF = IERC20(MCFaddress);
    }
    
    function claimedRewards(address user) external view returns(uint256){
        (, , uint256 totalLockedRewards) = SC2.definiteStats(user);
        uint256 totalLocked = totalLockedRewards/10;
        return claimedMonths[user] * totalLocked;
    }
    
    function claimableRewards(address user) external view returns(uint256){
        (, , uint256 totalLockedRewards) = SC2.definiteStats(user);
        (,,uint256 lockedRewards,) = SC2.userStats(user);
        
        if(lockedRewards > totalLockedRewards) {totalLockedRewards = lockedRewards;}
        uint256 rewards;
        if(_currentBlock < 12954838){return 0;}
        uint256 month = (_currentBlock - 12954838) / 199384;
        while(month > claimedMonths[user]){
        
        if(lockedRewards == 0){break;}
        uint256 totalLocked = totalLockedRewards/10;
        
        if(lockedRewards < totalLocked){rewards += lockedRewards; break;}
        else{rewards += totalLocked; lockedRewards -=totalLocked; }
        
        }
        
        return rewards;
    }
    function withdrawLockedRewards() external override {
        SC2.claimRewards(msg.sender);
        (uint256 firstBlock, uint256 lockedRewards, uint256 totalLockedRewards) = SC2.definiteStats(msg.sender);
        require(_currentBlock > 13154223 && lockedRewards > 0);
        ////////////////////////12755454
        uint256 claimedRewards;
        uint256 month = (_currentBlock - 12954838) / 199384;
        uint256 total;
        while(month > claimedMonths[msg.sender]){
        
        if(lockedRewards == 0){break;}
        uint256 totalLocked = totalLockedRewards/10;
        
        if(lockedRewards < totalLocked){total += lockedRewards; claimedRewards += lockedRewards; lockedRewards = 0;}
        else{total += totalLocked; claimedRewards += lockedRewards; lockedRewards -=totalLocked; }
        
        ++claimedMonths[msg.sender];
        }
        
        MCF.transfer(msg.sender, total);
        SC2.editData(msg.sender, lockedRewards, firstBlock);
        
        emit WithdrawLockedRewards(msg.sender, claimedRewards);
    }
    
    function emergencyWithdraw(uint256 amount) external {
        require(msg.sender == _owner);
        MCF.transfer(msg.sender, amount);
    }
}