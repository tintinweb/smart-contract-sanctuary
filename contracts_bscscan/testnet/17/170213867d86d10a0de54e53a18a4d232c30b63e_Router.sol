/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.5;


contract Router {
    address private owner;
    
    uint public refferalTax;
    mapping(address => uint) private refferalBalances;
    
    uint public airDropPrice;
    
    constructor() {
        owner = msg.sender;

        refferalTax = 25; //do usuniecia
        airDropPrice = 1; // do usunieca
    }
    
    function airDrop(address refferal) external payable {
        require(msg.value >= airDropPrice, 'Wrong price');
        refferalBalances[refferal] += msg.value * refferalTax / 100;
        refferalBalances[address(this)] += msg.value * (100 - refferalTax) / 100;
    }
    
    function setRefferalTax(uint newTax) external {
        require(newTax >= 0 && newTax <= 100, 'Invalid value');
        refferalTax = newTax;
    }
    
    function setAirCropPrice(uint newPrice) external {
        airDropPrice = newPrice;
    }
    
    function refferalBalance(address refferal) external view returns(uint) {
        return refferalBalances[refferal];
    }
}