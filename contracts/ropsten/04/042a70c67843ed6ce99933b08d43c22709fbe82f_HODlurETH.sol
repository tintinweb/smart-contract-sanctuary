pragma solidity ^0.4.18;


/**
  Hodl Eth
**/
contract HODlurETH{
  mapping (address => uint) public ethBalance; //HODL here
  mapping (address => uint) public moonTime; //Eth will go to the moon by this time
  function HODL() public payable{
    ethBalance[msg.sender]+=msg.value;//Buy the dip, and hodl
    moonTime[msg.sender]=now+5 minutes;//Your Eth will be in the contract for about 6 months. After that you will be a billionaire.
  }

  /**
  Lambo time
  **/
  function withdraw() public{
    require(now>moonTime[msg.sender]);
    msg.sender.transfer(ethBalance[msg.sender]);
  }
}