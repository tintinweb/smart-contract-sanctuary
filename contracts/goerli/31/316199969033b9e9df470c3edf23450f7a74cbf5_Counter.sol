/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract Counter {

    event Increment (
        address indexed sender,
        uint256 oldValue,
        uint256 newValue
    );

    uint256 private counter;

    function increment() public {
        emit Increment(msg.sender, counter, counter + 1);
        counter++;
    }

    function read() public view returns (uint256) {
        return counter;
    }

    
}