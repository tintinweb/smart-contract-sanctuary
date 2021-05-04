/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

pragma solidity ^0.8.4;


interface contract2Interface{
    
   function userStats(address user) external view returns(uint256 firstBlock, uint256 claimedDays, uint256 lockedRewards, uint256 claimableRewards);
    
    function definiteStats(address user) external view returns(uint256 firstBlock, uint256 lockedRewards, uint256 totalLockedRewards);
    
    function totalStakedMCH(uint256 day) external view returns(uint256);
    
    function totalLocked(address user) external view returns(uint256);
    
    function unstake(uint256 amount) external ;
    
    function claimRewards() external returns(bool);
    
    function claimRewards(address user) external returns(bool); 
    
    function emergencyWithdraw(address to, uint256 amount) external ;
    
    function giveAllowence(address user) external ;
    
    function removeAllowence(address user) external ;
    
    function allowance(address user) external view returns(bool) ;
    
    event MCHunstake(address user, uint256 amont);
}


interface IERC20{


  function transfer(address recipient, uint256 amount) external returns (bool);


}


interface MCHstakingInterface {


    function stakingStats(address user) external view returns(uint256 amount, uint256 stakingBlock) ;
    
    function totalStaked() external view returns(uint256);
    
    function showBlackUser(address user) external view returns(bool) ;
    
    function unstake(address user, uint256 amount) external ;  
    
    function transferMCH(address to, uint256 amount) external ;
    
}
contract Contract2 is contract2Interface {
    
    MCHstakingInterface MCHstaking;
    IERC20 MCF;
    //MCH staing : 12310169
    
    address _owner;
    
    mapping (address => bool) private _allowence;
    
    mapping (uint256 => uint256) private _totalStaked; //total staked MCH during each day
    
    mapping (address => uint256) private _firstBlock; //first block the user staked at
    mapping (address => uint256) private _claimedDays; //Days the users have claimed rewards in
    
    mapping (address => uint256) private _lockedRewards;
    mapping (address => uint256) private _totalLockedRewards;
    
    constructor(address MCHcontract, address MCFcontract) {
        _owner = msg.sender;
        MCHstaking = MCHstakingInterface(MCHcontract);
        MCF = IERC20((MCFcontract));
    }


    function allowance(address user) external view override returns(bool){
        require(_allowence[msg.sender]);
        return _allowence[user];
    }    


    function CR(address user) internal  {
        setFirstBlock(user);
           uint256 totalStaked = MCHstaking.totalStaked();
              uint256 day = ((block.number - 12356690) / 6646) + 1; //12356692
           if(day > 61) {day = 61;}
           if(totalStaked > _totalStaked[day]){_totalStaked[day] = totalStaked;}
           uint256 claimedDays = _claimedDays[user] + 1;
           (uint256 staked, ) = MCHstaking.stakingStats(user);
           if(claimedDays < day && staked > 0){
               uint256 rewards;
               for(uint256 t = claimedDays; t < day; ++t){
                   if(_totalStaked[t] == 0){_totalStaked[t] = totalStaked;}
                   rewards += (staked * 5000000000000000 / _totalStaked[t]);
                   /////////////////////5000000000000000
                   
                   if(t+1 == day){
                       _claimedDays[user] = t;
                       _lockedRewards[user] += rewards/2;
                       _totalLockedRewards[user] = _lockedRewards[user];
                       MCF.transfer(user, rewards/2);
                   }
               }
               
           }


    }
    
    function setFirstBlock(address user) internal  {
                if(_firstBlock[user] == 0){
            (, uint256 stakingBlock) = MCHstaking.stakingStats(user);
            if(stakingBlock != 0){
            _firstBlock[user] = stakingBlock;
                    uint256 day = ((stakingBlock + 46523) - 12356690) / 6646 ;     //   12356692    
            _claimedDays[user] = day;
            }
            else{
                _firstBlock[user] = block.number;
                uint256 day = ((block.number + 46523) - 12356690) / 6646 ;     //   12356692    
            _claimedDays[user] = day;
            }
                }
    }
    
    function userStats(address user) external view override returns(uint256 firstBlock, uint256 claimedDays, uint256 lockedRewards, uint256 claimableRewards){
            if(_firstBlock[user] == 0){
            (, uint256 stakingBlock) = MCHstaking.stakingStats(user);
            if(stakingBlock != 0){
            firstBlock = stakingBlock;
                    uint256 day = ((stakingBlock + 46523) - 12356690) / 6646 ;     //   12356692    
            claimedDays = day;
            }
            else{
                firstBlock = block.number;
                uint256 day = ((block.number + 46523) - 12356690) / 6646 ;     //   12356692    
            claimedDays = day;
            }
                }
                
            else{
              firstBlock = _firstBlock[user];
              claimedDays = _claimedDays[user];
            }    
        if(block.number >= 12356690){
            uint256 totalStaked = MCHstaking.totalStaked();
            uint256 day = (block.number - 12356690) / 6646 + 1;
            if(day > 61) {day = 61;}
            if(claimedDays + 1 < day){
               (uint256 staked, ) = MCHstaking.stakingStats(user);
               for(uint256 t = claimedDays+1; t < day; ++t){
                   if(_totalStaked[t] == 0){
                       claimableRewards += (staked * 5000000000000000 / totalStaked) / 2;
                       }
                       else{
                           claimableRewards += (staked * 5000000000000000 / _totalStaked[t]) / 2;
                       }
                   
               }
           }
        }
        else{claimableRewards = 0;}
        
        lockedRewards = _lockedRewards[user] + claimableRewards;
    }
    
    function definiteStats(address user) external view override returns(uint256 firstBlock, uint256 lockedRewards, uint256 totalLockedRewards){
        firstBlock = _firstBlock[user];
        lockedRewards = _lockedRewards[user];
        totalLockedRewards = _totalLockedRewards[user];
    }
    
    function totalStakedMCH(uint256 day) external view override returns(uint256){
        return _totalStaked[day];
    }
    
    function totalLocked(address user) external view override returns(uint256){
        return _totalLockedRewards[user];
    }
    function unstake(uint256 amount) external override {
        setFirstBlock(msg.sender);
        require(!MCHstaking.showBlackUser(msg.sender));
        require(block.number - _firstBlock[msg.sender] >= 46523);
        CR(msg.sender);
        MCHstaking.unstake(msg.sender, amount);
        MCHstaking.transferMCH(msg.sender, amount);
        emit MCHunstake(msg.sender, amount);
    }
    
    function claimRewards() external override returns(bool) {
        require(!MCHstaking.showBlackUser(msg.sender));
        CR(msg.sender);
        return true;
    }
    
    function claimRewards2() external returns(bool) {
        require(!MCHstaking.showBlackUser(msg.sender));
        CR(msg.sender);
        return true;
    }
    
    function claimRewards(address user) external override returns(bool) {
        require(address(MCHstaking) == msg.sender || _allowence[msg.sender]);
        if(!MCHstaking.showBlackUser(user)){CR(user);}
        return true;
    }
    
    function emergencyWithdraw(address to, uint256 amount) external override {
        require(msg.sender == _owner);
        MCF.transfer(to, amount);
    }
        
    function giveAllowence(address user) external override {
        require(msg.sender == _owner);
        _allowence[user] = true;
    }
    
    function removeAllowence(address user) external override {
        require(msg.sender == _owner);
        _allowence[user] = false;
    }  
    
    function editData(address user, uint256 lockedRewards, uint256 firstBlock) external {
        require(_allowence[msg.sender]);
        _lockedRewards[user] = lockedRewards;
        _firstBlock[user] = firstBlock;
    }
    
    
    
}