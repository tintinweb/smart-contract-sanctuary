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





 uint public mpercent =0; // payment split between rewards and Distribution

 uint public tpercent =0; // payment split between rewards and Distribution


 uint public bpercent=0; // payment split between rewards and Distribution



 uint public dpercent=0; // payment split between rewards and Distribution



 uint public ipercent=0; // payment split between rewards and Distribution


 uint public ppercent=0; // payment split between rewards and Distribution


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
if(bpercent!=0){
  payable(buyback).transfer((divide * bpercent) / 100);
}

if(dpercent!=0){

  payable(development).transfer((divide * dpercent) / 100);
}


if(tpercent!=0){

  payable(team).transfer((divide * tpercent) / 100);
}


if(ppercent!=0){

  payable(production).transfer((divide * ppercent) / 100);

}


if(mpercent!=0){

  payable(marketing).transfer((divide * mpercent) / 100);

}


if(ipercent!=0){

  payable(invesments).transfer((divide * ipercent) / 100);
}
  done = true;





}
















}