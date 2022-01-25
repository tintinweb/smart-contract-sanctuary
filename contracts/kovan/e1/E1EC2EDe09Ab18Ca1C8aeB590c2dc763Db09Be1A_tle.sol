/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract tle{

    uint public amount;
    address owner;

    constructor() {
      owner = msg.sender;
    }

    function sendEther() payable public{
        amount = msg.value;
    }

    function Balance() public view returns (uint256) { 
        return address(this).balance;
    }

    function getAddressContract() public view returns (address){
        return address(this);
    }

    function withdrawAmount(uint256 amount) public {
        payable(msg.sender).transfer(amount);
    }

}