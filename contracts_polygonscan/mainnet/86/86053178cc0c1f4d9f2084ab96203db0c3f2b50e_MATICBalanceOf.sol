/**
 *Submitted for verification at polygonscan.com on 2021-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


interface MATICBalanceOfInterface {
    function balance() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}


/// Quickly check the Matic balance for an account.
contract MATICBalanceOf is MATICBalanceOfInterface {
    function balance() external view override returns (uint256) {
        return msg.sender.balance;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return account.balance;
    }
}