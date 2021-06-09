/**
 *Submitted for verification at Etherscan.io on 2021-06-09
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
        uint256 month = (_currentBlock - 12954838) / 199384;
        uint256 _claimMonths = claimedMonths[user];
        while(month > _claimMonths){
        
        if(lockedRewards == 0){break;}
        uint256 totalLocked = totalLockedRewards/10;
        
        if(lockedRewards < totalLocked){rewards += lockedRewards; break;}
        else{rewards += totalLocked; lockedRewards -=totalLocked; }
        
        ++_claimMonths;
        }
        
        return rewards;
    }
    function withdrawLockedRewards() external override {
        // SC2.claimRewards(msg.sender);
    }
    
    function emergencyWithdraw(uint256 amount) external {
        require(msg.sender == _owner);
        MCF.transfer(msg.sender, amount);
    }
}