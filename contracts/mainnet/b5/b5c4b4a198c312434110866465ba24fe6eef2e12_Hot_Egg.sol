/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

/*

   
          ,'` |        _.-.
         ,`   |      ,',' /
         :    |    ,','  ;
          \   :   / /   /
           \   `.' (  ,'
          ,''     _  `.
        ,'      (o_)  `\
     . (,.)   _.--     :
   -..`/(  .-'_..-    `|
    .-'\,`. `-._       ;
        `._           /__
        ,':)-.._   _.(:::`.
        |'\         / /`:::|
      ,' \ :       : :   `:|
     /   : |       | |     \
    :    | |       : :..---.:
    |    | ;       ,`._`-.|_ `.
    |    |'      ,'._  `. `. |_\
    |    :      /`-. `.  `. `.  :
    :     \    : __ `. `.  `. \ ;
     \     \   |.  /  `. \   \ /
     |\     `..: `. __  \ \   /
     ' `  .:::::\  `. /  \ \,'
       .::::::::::-..'_..-'  



*/


contract Hot_Egg {
    
    uint256 public currentPrice;
    uint256 public devFee;
    address payable public currentOwner;
    address payable dev;
    
    constructor() {
        dev = payable(msg.sender);
        currentOwner = dev;
        currentPrice = 0.05 ether;
        devFee = 20;
    }
    
    function buy() external payable {
        require(msg.sender == tx.origin, "No bots");
        require(msg.value == currentPrice, "Wrong Amount");
        uint256 fee = currentPrice * devFee / 100;
        currentOwner.transfer(currentPrice - fee);
        dev.transfer(fee);
        currentOwner = payable(msg.sender);
        currentPrice = currentPrice * 2;
    }
    
    function lowerDevFee(uint256 amount) external {
        require(msg.sender == dev, "You are not the dev");
        require(amount <= 20, "Fee is too high");
        devFee = amount;
    }
    
}