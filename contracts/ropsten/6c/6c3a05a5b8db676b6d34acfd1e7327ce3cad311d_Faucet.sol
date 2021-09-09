/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Faucet {
    function withdraw(address payable wallet, uint withdraw_amount) public {
        require(withdraw_amount <= 100000000000000000);
        wallet.transfer(withdraw_amount);
    }

    receive () external payable {}
}