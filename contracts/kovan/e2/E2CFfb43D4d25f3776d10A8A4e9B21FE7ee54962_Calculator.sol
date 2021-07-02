/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

pragma solidity ^0.8.5;

contract Calculator {
    uint256 public results;
    address public sender;
    uint256 public counter;

    event Add(address txorigin, address sender, address _this, uint a, uint b);

    function add(uint256 a, uint256 b) public returns (uint256) {
        results = a + b;
        sender = msg.sender;
        counter = counter + 1;
        emit Add(tx.origin, msg.sender, address(this), a, b);
        return results;
    }
}