/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.22;

contract Car {
    string brand;
    uint public price;
    
    constructor(string b, uint p) public {
        brand = b;
        price = p;
    }
    
    function setBrand(string b) public {
        brand = b;
    }
    
    function setPrice(uint p) public {
        price = p;
    }
    
    function getBrand() public view returns(string) {
        return brand;
    }
}