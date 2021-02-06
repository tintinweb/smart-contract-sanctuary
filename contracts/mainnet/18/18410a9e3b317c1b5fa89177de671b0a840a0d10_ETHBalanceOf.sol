/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


interface ETHBalanceOfInterface {
    function balance() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}


/// Quickly check the Ether balance for an account.
contract ETHBalanceOf is ETHBalanceOfInterface {
    function balance() external view override returns (uint256) {
        return msg.sender.balance;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return account.balance;
    }
}