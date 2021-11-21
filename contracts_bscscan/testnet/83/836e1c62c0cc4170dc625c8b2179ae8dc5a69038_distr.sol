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

payout();






}



function payout() public {



  bool done  = false;
  require(done==false, "already completed transaction");

  uint r = split / 100;
  uint divide = address(this).balance * r;

  //send to reward wallets
  payable(rewards).transfer(divide);

  //split wallets
  uint combine = dsplit *2;
  uint percent = combine / 100;
  uint total = percent * divide;
  uint remain = divide - total;

  uint bal = divide - remain;


  payable(production).transfer(remain);

  payable(marketing).transfer(bal/2);

  payable(invesments).transfer(bal/2);

  done = true;

}















}