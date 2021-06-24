/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

//SPDX-License-Identifier: UNLICENSED

interface Token {
    function mint(address to, uint256 amount) external;
}

pragma solidity ^0.8.0;


contract MintTest {
    function test(address _token, address _to, uint256 _amount) external {
        Token(_token).mint(_to, _amount);
    }
}