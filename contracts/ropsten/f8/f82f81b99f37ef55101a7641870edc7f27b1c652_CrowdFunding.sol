/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

// SPDX-License-Identifier: GPL-3.0
 pragma solidity ^0.8.7;

 contract CrowdFunding{

     mapping(address=>uint) public contributors;
     address public manager;
     uint public minimumContribution;
     uint public deadline;
     uint public target;
     uint public raisedAmount;
     uint public noOfContributors;

     constructor(uint _target,uint _deadline){
         target= _target;
         deadline= block.timestamp + _deadline;
         minimumContribution= 100 wei;
         manager= msg.sender;
     } 

     function sendEth() public payable{
         require(block.timestamp<deadline,"Deadline has passed");
         require(msg.value>= minimumContribution,"minimum contribution not met");

         if(contributors[msg.sender]==0){
             noOfContributors++;
         }
         contributors[msg.sender]+= msg.value;
         raisedAmount+= msg.value;
     }

     function getConractBalance() public view returns(uint){
         return address(this).balance;
     }

     function refund() public {
         require(block.timestamp>deadline && raisedAmount<target,"not eligible for refund");
         require(contributors[msg.sender]>0,"you are not contributor");

         address payable user= payable(msg.sender);
         user.transfer(contributors[msg.sender]);
         contributors[msg.sender]= 0;
     }

     function SendtoManager() public {
         require(block.timestamp> deadline && raisedAmount>target,"yet target or deadline not reached");
         require(msg.sender == manager, "only manager have acess to this function");
         address payable _manager = payable(manager);
         _manager.transfer(raisedAmount);
     }
 }