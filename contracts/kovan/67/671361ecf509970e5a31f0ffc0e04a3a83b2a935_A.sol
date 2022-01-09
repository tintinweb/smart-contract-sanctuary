/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10 <0.9.0;

contract A {
    uint public num;
    address public sender;
    uint public value;

    function setVars(address _contract, uint _num) public payable {
        // 執行後會發現, 合約A的變數被使用了, 合約B的變數仍為空
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }
}