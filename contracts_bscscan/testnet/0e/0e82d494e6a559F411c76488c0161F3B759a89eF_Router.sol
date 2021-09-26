/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.5;

contract Router {
    address private owner;
    uint public ownerBalance;
    
    uint public refferalTax;
    mapping(address => uint) private refferalBalances;
    
    uint public airDropPrice;
    
    modifier costs(uint price) {
        require(msg.value >= price, 'Wrong price');
        _;
    }
    
    modifier onlyOwner(){
        require(msg.sender >= owner, 'Only owner');
        _;
    }
    
    constructor() {
        owner = msg.sender;

        refferalTax = 25; //do usuniecia
        airDropPrice = 1; // do usunieca
    }
    
    function _collectPayment(uint value, address refferal) private {
        refferalBalances[refferal] += value * refferalTax / 100;
        ownerBalance += value * (100 - refferalTax) / 100;
    }
    
    function airDrop(address refferal) external payable costs(airDropPrice) {
        _collectPayment(msg.value, refferal);
    }
    
    function withdraw() external onlyOwner {
        payable(owner).transfer(ownerBalance);
        ownerBalance = 0;
    }
    
    function refferalWithdraw() external {
        require(refferalBalances[msg.sender] > 0, 'No funds');
        payable(msg.sender).transfer(refferalBalances[msg.sender]);
        refferalBalances[msg.sender] = 0;
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