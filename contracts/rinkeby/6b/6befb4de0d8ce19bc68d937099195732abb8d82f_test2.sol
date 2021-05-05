/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
contract test2 {
    address public senderAddress;
    uint public value;
    uint public sum = 0;
    
    function search(uint m) public payable {
        senderAddress = msg.sender;
        value = msg.value;
        sum = sum;
        if(value >= 1) {
            uint i = 0;
            for(i = 1; i <= m; i++) {
                sum = sum + i;
            }
        }
    }
}