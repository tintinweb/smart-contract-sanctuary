/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

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

contract contract3{
    
    IERC20 MCF;
    contract2 SC2;
    MCHstakingInterface MCHstaking;
    
    uint256 private _currentBlock;

    function setCurrentBlock(uint256 number) external {
        _currentBlock = number;
    }
    
    function currentBlock() external view returns(uint256){
        return _currentBlock;
    }
    
    constructor(address contract2Address, address MCFaddress, address MCHcontract){
        SC2 = contract2(contract2Address);
        MCF = IERC20(MCFaddress);
        MCHstaking = MCHstakingInterface(MCHcontract);
    }

    function withdrawLockedRewards() external {
        require(!MCHstaking.showBlackUser(msg.sender));
        (uint256 firstBlock, uint256 lockedRewards, uint256 totalLockedRewards) = SC2.definiteStats(msg.sender);
        require(_currentBlock > 12755461 && lockedRewards > 0);
        ////////////////////////12755461
        SC2.claimRewards(msg.sender);
        while(_currentBlock - firstBlock >= 199384){
        
        if(lockedRewards == 0){break;}
        uint256 totalLocked = totalLockedRewards/10;
        
        if(lockedRewards < totalLocked){MCF.transfer(msg.sender, lockedRewards); lockedRewards = 0;}
        else{MCF.transfer(msg.sender, totalLocked); lockedRewards -=totalLocked; }
        
        firstBlock += 199384;
        }
        
        SC2.editData(msg.sender, lockedRewards, firstBlock);
    }
}