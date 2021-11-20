/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

pragma solidity ^0.8.0;



//SPDX-License-Identifier: UNLICENSED


contract distr{


 address public _owner;

 address   public  marketing;

 address   public team;

 address   public  buyback;


 address   public  development;


 address  public  invesments;

 address  public  rewards;

 address  public  production;





 uint public mpercent; // payment split between rewards and Distribution

 uint public tpercent; // payment split between rewards and Distribution


 uint public bpercent; // payment split between rewards and Distribution



 uint public dpercent; // payment split between rewards and Distribution



 uint public ipercent; // payment split between rewards and Distribution


 uint public ppercent; // payment split between rewards and Distribution


 uint public split; // Distribution among wallets



constructor()  {

_owner = msg.sender;
}


function setmarketing(address wallet, uint percent) public{

require(msg.sender == _owner, "Not Owner");

mpercent = percent;
marketing = wallet;

}


function setproduction(address wallet, uint percent)public{

require(msg.sender == _owner, "Not Owner");

production = wallet;
ppercent = percent;

}


function setdevelopment(address wallet, uint percent)public{

require(msg.sender == _owner, "Not Owner");

development = wallet;
dpercent = percent;

}

function setinvestment(address wallet, uint percent)public{

require(msg.sender == _owner, "Not Owner");

invesments = wallet;
ipercent = percent;

}


function setreward(address wallet)public{

require(msg.sender == _owner, "Not Owner");

rewards = wallet;




}


function setteam(address wallet, uint percent)public{

require(msg.sender == _owner, "Not Owner");

team = wallet;
tpercent = percent;

}



function setbuyback(address wallet, uint percent)public{

require(msg.sender == _owner, "Not Owner");

buyback = wallet;
bpercent = percent;

}


function setsplit(uint val)public{

require(msg.sender == _owner, "Not Owner");

split = val;

}





receive() external payable{
  require(msg.value > 10, "Insufficient amount");

bool done  = false;
  require(done==false, "already completed transaction");

  uint divide = (msg.value * split)  / 100;

  //send to reward wallets
  payable(rewards).transfer(divide);

  //split wallets

  payable(buyback).transfer((divide * bpercent) / 100);
  payable(development).transfer((divide * dpercent) / 100);
  payable(team).transfer((divide * tpercent) / 100);


  payable(production).transfer((divide * ppercent) / 100);

  payable(marketing).transfer((divide * mpercent) / 100);

  payable(invesments).transfer((divide * ipercent) / 100);

  done = true;





}
















}