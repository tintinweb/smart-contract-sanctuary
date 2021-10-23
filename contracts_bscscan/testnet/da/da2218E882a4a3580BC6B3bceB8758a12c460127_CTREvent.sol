// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract CTREvent {
    uint256 counter;

    function get()
    external
    view returns (uint256) {
        return counter;
    }

    function set(uint256 _newValue) 
    external {
        counter = _newValue;
        emit CounterUpdated(_newValue);
    }

    event CounterUpdated(uint256 newCounter);
}