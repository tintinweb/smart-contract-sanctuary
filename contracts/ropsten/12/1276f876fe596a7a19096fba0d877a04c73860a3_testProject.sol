/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

contract testProject{
//  uint public age;

//  function setAge() public {
//      age = 38;
//  }

// function getAge()public view returns(uint Age){
//     return age;
// }

// }
    
    uint targetFunds = 0.1 ether;
    address public owner = payable(msg.sender);
    modifier limitSend(){
    require (msg.value == 0.001 ether,"Maximum value to send by this transactin is 1 ether"); {
            _;
        }
    }

    modifier limitBalance(){
        require ((address(this).balance) <= 0.1 ether,  "Contract target limit already achived"); {
            _;
        }
    }
    
    modifier isOwner(){
        require(msg.sender == owner,"is not owner");{
            _;
        }
    }
    
    // constructor(){
        
    //     owner = payable(msg.sender);
    // }

    function getFunds() external limitSend() limitBalance() payable {
    }
    
    
    function getbalanceThis()public view returns(uint){
      return address(this).balance;
    }
    
    function contractDestruction() external payable isOwner{
      
      if ((address(this).balance) == 0.1 ether){
        selfdestruct(payable(owner));
    } 
    }
}