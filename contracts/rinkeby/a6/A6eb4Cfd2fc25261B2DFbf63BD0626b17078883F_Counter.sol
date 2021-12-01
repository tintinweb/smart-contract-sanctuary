/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

pragma solidity ^0.5.0;

contract Counter {

    uint256 counter;

    function get() external view returns (uint256) {
        return counter;
    }

    function set(uint256 newValue) external {
        counter = newValue;
        emit CounterUpdated(newValue);
    }

    event CounterUpdated(uint256 newCounter);
}