// contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract {

    mapping(address => uint256) private _balance;

    function demo() external {

        _balance[msg.sender] = 100;
    }

    function getBalance() external view returns (uint256){
        return _balance[msg.sender];
    }
}