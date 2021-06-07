/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

abstract contract A {
   function transfer(address payable to, uint256 amount) public virtual;
}

contract TestContract2{
    
     A a;

    constructor(address _address) {
       a = A(_address);
    }

    function transfer(address payable to, uint256 amount) public {
        a.transfer(to, amount);
    }

    receive () external payable {
        
    }
}