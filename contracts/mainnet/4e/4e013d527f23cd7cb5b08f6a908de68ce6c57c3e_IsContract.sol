/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.11;

contract IsContract {
    function isContract(address account) external view returns (bool totally) {
        if (account.code.length != 0) totally = true;
    }
}