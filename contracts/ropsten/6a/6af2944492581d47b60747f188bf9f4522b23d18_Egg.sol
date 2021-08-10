/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

pragma solidity 0.8.4;


contract Egg {
    
    uint256 public currentPrice;
    address payable public currentOwner;
    address payable dev;
    
    constructor() {
        dev = payable(msg.sender);
        currentPrice = 0.05 ether;
    }
    
    function buy() public payable {
        require(msg.value == currentPrice, "Wrong Amount");
        uint256 devFee = currentPrice * 10 / 100;
        currentOwner.transfer(currentPrice - devFee);
        dev.transfer(devFee);
        currentOwner = payable(msg.sender);
        currentPrice = currentPrice * 2;
    }
    
}