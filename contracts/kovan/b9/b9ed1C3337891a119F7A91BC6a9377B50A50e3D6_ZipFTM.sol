/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract ZipFTM {
    event Deposit(address indexed _from, uint _amount, address _asset, uint256 _time, uint256 _block);

    function depositBridge(address _asset, uint256 _amount) public {
        address from = msg.sender;
        address asset = _asset;
        uint256 amount = _amount;
        uint256 time = block.timestamp;
        uint256 blockNumber = block.number;
        emit Deposit(from, amount, asset, time, blockNumber);
    }
}