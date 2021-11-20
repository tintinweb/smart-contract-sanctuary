/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

pragma solidity ^0.8.0;



//SPDX-License-Identifier: UNLICENSED


contract distr{


 address public _owner;

 address   public  marketing;

 address  public  invesments;

 address  public  rewards;

 address  public  production;


 uint public split; // payment split between rewards and Distribution

 uint public dsplit; // Distribution among wallets



constructor()  {

_owner = msg.sender;
}


function setmarketing(address wallet) public{

require(msg.sender == _owner, "Not Owner");

marketing = wallet;

}


function setproduction(address payable wallet)public{

require(msg.sender == _owner, "Not Owner");

production = wallet;

}


function setinvestment(address payable wallet)public{

require(msg.sender == _owner, "Not Owner");

invesments = wallet;

}


function setreward(address payable wallet)public{

require(msg.sender == _owner, "Not Owner");

rewards = wallet;

}


function setsplit(uint val)public{

require(msg.sender == _owner, "Not Owner");

split = val;

}



function setdsplit(uint val)public{

require(msg.sender == _owner, "Not Owner");

dsplit = val;

}

receive() external payable{
  require(msg.value > 10, "Insufficient amount");

bool done  = false;
  require(done==false, "already completed transaction");

  uint divide = (msg.value * split)  / 100;

  //send to reward wallets
  payable(rewards).transfer(divide);

  //split wallets
  uint total = ((dsplit * 2) * divide) / 100;
  uint remain = divide - total;

  uint bal = divide - remain;


  payable(production).transfer(remain);

  payable(marketing).transfer(bal/2);

  payable(invesments).transfer(bal/2);

  done = true;





}
















}