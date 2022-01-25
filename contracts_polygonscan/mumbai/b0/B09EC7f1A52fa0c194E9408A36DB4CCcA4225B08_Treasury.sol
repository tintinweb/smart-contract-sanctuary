/**
 *Submitted for verification at polygonscan.com on 2022-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
contract Treasury {

    uint totalContractBalance = 0;
    address public treasurer;
    constructor(){
        treasurer = msg.sender;
    }
    function getContractBalance() external view returns(uint){
        return totalContractBalance;
    }

    mapping(address => bool) operators;

    event depositEvent(address,uint, uint);
    event withdrawEvent(address,uint, uint);
    event operatorAdded(address);
    event operatorRemoved(address);

     modifier isTreasurer() {
      require( msg.sender==treasurer , "Only treasurer can run this function");
      _;
   }
     modifier istreasurerOrOperator() {
      require( msg.sender==treasurer || operators[msg.sender]==true, "Only An Owner or Operator can run this function");
      _;
   }

    function deposit() external payable {   
        totalContractBalance = totalContractBalance + msg.value;
        emit depositEvent(msg.sender,msg.value,totalContractBalance);
    }
    function withdraw(uint amount) external payable istreasurerOrOperator{
        address payable withdrawTo = payable(msg.sender);
        uint amountToTransfer = amount;
        require(amountToTransfer<= totalContractBalance, "Insufficient funds");
        withdrawTo.transfer(amountToTransfer);
        totalContractBalance = totalContractBalance - amountToTransfer;
        emit withdrawEvent(msg.sender,amountToTransfer,totalContractBalance);
    }
    function addOperator(address a) external isTreasurer
    {
        operators[a]=true;
    emit operatorAdded(a);
    }
    function removeOperator(address a) external isTreasurer
    {
        operators[a]=false;
        emit operatorAdded(a);
    }
}