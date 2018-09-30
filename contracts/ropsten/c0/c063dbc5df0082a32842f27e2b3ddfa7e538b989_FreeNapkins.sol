pragma solidity ^0.4.18;


contract FreeNapkins{
  mapping (address => uint256) public napkinCount;
  uint public lastNapkinTime=now;
  uint public NAPKIN_VALUE=0.001 ether;
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
  function buyNapkins() public payable{
    napkinCount[msg.sender]+=msg.value / NAPKIN_VALUE;
  }
  function sellNapkins(uint napkins){
    require(napkinCount[msg.sender]>napkins);
    napkinCount[msg.sender]-=napkins;
    msg.sender.transfer(napkins*NAPKIN_VALUE);
  }
  function moveNapkinsTo(uint napkins,address addr){
    require(napkinCount[msg.sender]>napkins);
    napkinCount[msg.sender]-=napkins;
    napkinCount[addr]+=napkins;
  }
}