/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.8.5;

contract Calculator {
    uint256 public calculateResult;
    address public user;
    uint256 public addActionCount;
    
    event AddEvent(address txOrigin, address msgSenderAddress, address _this);

    function add(uint256 a, uint256 b) public returns (uint256) {
        addActionCount++;

        calculateResult = a + b;
        
        emit AddEvent(tx.origin, msg.sender, address(this));
        user = msg.sender;
        
        return calculateResult;
    }
}