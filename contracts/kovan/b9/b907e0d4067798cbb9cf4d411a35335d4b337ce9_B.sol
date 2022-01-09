/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10 <0.9.0;

// [注意] 需要先編譯合約B
contract B {
    // [注意] 變數名需與合約A一致
    uint public num;
    address public sender;
    uint public value;

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
    }
}