/**
 *Submitted for verification at polygonscan.com on 2022-01-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract StockContract2 {

    mapping (address => uint) balances;

     
    function deposit() public payable{
    }


   
function sendViaCall(address payable _to, uint _amount) public  payable{
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
    
    
    
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }


    
}