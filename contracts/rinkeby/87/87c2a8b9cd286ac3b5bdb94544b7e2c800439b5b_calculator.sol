/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
contract calculator{
    address public sender;
    uint public value;
    int public pro;
    function op(int n) public payable{
        pro=1;
        for(int i = 1; i<=n; i++){
            pro =pro*i;
        }
        sender = msg.sender;
        value = msg.value;
    }
}