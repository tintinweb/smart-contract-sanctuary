pragma solidity ^0.4.18;


contract FreeNapkins{
  mapping (address => uint256) public napkinCount;
  address[4] public potatoOwners;
  uint[4] public potatoPrices;

  uint public lastNapkinTime=now;
  uint public NAPKIN_VALUE=0.001 ether;
  uint public COUNTDOWN_TIME=5 minutes;
  string public message="test message";
  function FreeNapkins(){
    lastNapkinTime=now;
  }
  function getFreeNapkins() public{
    require(napkinCount[msg.sender]<=50);
    napkinCount[msg.sender]+=10;
    lastNapkinTime=now;
  }
  function countdownIsUp() public view returns(bool){
    return lastNapkinTime+COUNTDOWN_TIME<now;
  }
  function countdownTimeLeft() public view returns(uint){
    if(countdownIsUp()){
      return 0;
    }
    else{
      return (lastNapkinTime+COUNTDOWN_TIME)-now;
    }
  }
  function buyNapkins(address referral) public payable{
    napkinCount[msg.sender]+=msg.value / NAPKIN_VALUE;
    napkinCount[referral]+=msg.value / NAPKIN_VALUE /10; //referral address gets napkins too
  }
  function sellNapkins(uint napkins){
    require(napkinCount[msg.sender]>=napkins);
    napkinCount[msg.sender]-=napkins;
    msg.sender.transfer(napkins*NAPKIN_VALUE);
  }
  function moveNapkinsTo(uint napkins,address addr){
    require(napkinCount[msg.sender]>napkins);
    napkinCount[msg.sender]-=napkins;
    napkinCount[addr]+=napkins;
  }
  function buyPotato(uint index) public payable{
    require(msg.value==potatoPrices[index]);
    potatoOwners[index].send(potatoPrices[index]);
    potatoOwners[index]=msg.sender;
    potatoPrices[index]+=0.01 ether;
  }
  function balance() public view returns(uint256){
    return address(this).balance;
  }
}