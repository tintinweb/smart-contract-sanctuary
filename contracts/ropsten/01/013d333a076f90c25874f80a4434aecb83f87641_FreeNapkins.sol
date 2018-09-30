pragma solidity ^0.4.18;


contract FreeNapkins{
  mapping (address => uint256) public napkinCount;
  mapping (address => uint256) public ethStored;
  uint public lastNapkinTime=now;
  uint public COUNTDOWN_TIME=5 minutes;
  string public message="test message";
  function getFreeNapkins() public{
    require(napkinCount[msg.sender]<=50);
    napkinCount[msg.sender]+=10;
    lastNapkinTime=now;
  }
  function countdownIsUp() public view returns(bool){
    return lastNapkinTime+COUNTDOWN_TIME<now;
  }
  function putEth() public payable{
    ethStored[msg.sender]=ethStored[msg.sender]+msg.value;
  }
}