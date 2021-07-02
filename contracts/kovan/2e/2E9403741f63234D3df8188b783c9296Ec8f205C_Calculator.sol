/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

pragma solidity ^0.8.5;

contract Calculator {
    uint256 public result;
    address public userAddress;
    uint256 public addCount;
    
    event AddToEvent(address txorigin, address sender, address _this, uint256 a, uint256 b);

    function add(uint256 a, uint256 b) public returns (uint256) {
        result = a + b;
        userAddress = msg.sender;
        emit AddToEvent(tx.origin, msg.sender, address(this), a, b);
        addCount++;
        
        return result;
    }
}