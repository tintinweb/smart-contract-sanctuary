/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

pragma solidity 0.5.17;


contract Ownable {


  address newOwner;
  mapping (address=>bool) owners;
  address public owner;


   constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }

}


contract SZOCalcRewardSP is Ownable{
    uint256 public version = 1;
    uint256 public  amountPerToken;
    uint256 public  rewardPerSec;
    uint256 public startTime;
    uint256 public endTime;
    
    
    constructor() public{
        amountPerToken = 50 ether;
        rewardPerSec = 1 ether;// / 2592000; // 30 day
        rewardPerSec /= 2592000;
        
        startTime = 1613325600;  // Mon Feb 15 2021 01:00:00 GMT+0700 (+08) Singapore Time;
        endTime =   1617040800;  // Tue Mar 30 2021 01:00:00 GMT+0700 (+08) Singapore Time;
    }
    
    function setEndRewardTime(uint256 _newTime) external onlyOwner{
        require(_newTime > now,"Can't set to pass time");
        endTime = _newTime;
    }
    
    
    function getReward(uint256 _depositTime,uint256 _amount) public view returns(uint256){
         uint256 _time;
         if(_depositTime > now) return 0;
         if(_depositTime < startTime) _depositTime = startTime;
         if(_depositTime > endTime) return 0;
         
         if(now < endTime)
             _time = now - _depositTime;
        else
            _time = endTime - _depositTime;
            
         uint256 _reward = (_amount * (_time * rewardPerSec)) / amountPerToken;  
         return _reward;
    }
    
    function setRewardRatio(uint256 _amount) public onlyOwner{
        amountPerToken = _amount;
    }
    
}