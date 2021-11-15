// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EventExample {

    event DataStored(uint256 blockNumber, uint256 blockDate, uint256 val);

    uint256 val;

    function storeData(uint256 _val) external {
        val = _val;
        emit DataStored(block.number, block.timestamp, val);
    }

}

