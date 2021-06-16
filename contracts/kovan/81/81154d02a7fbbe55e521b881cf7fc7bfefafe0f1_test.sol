/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity ^0.7.6;

contract test {
    uint256 public deposited;
    function deposit(uint256 maxAmount) external payable returns(uint256) {
        if (msg.value <= maxAmount) {
            deposited += msg.value;
            return msg.value;
        } else {
            (bool success, ) = msg.sender.call{value: msg.value}("");
            require(success);
            return 0;
        }
    }
    
    function withdraw(uint256 amount) external {
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
    }
}