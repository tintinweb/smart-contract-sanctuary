/**
 *Submitted for verification at BscScan.com on 2021-01-23
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @author sirbeefalot
 * @dev designed to manage matic whitin other BEP20 tokens while using a multicall contract.
 */
contract MulticallMaticShim {
    /**
     * @dev Returns an account's matic balance following a BEP20 call interface.
     */
    function balanceOf(address _address) external view returns (uint256) {
        return _address.balance;
    }

    /**
     * @dev Allowance is not required for matic transfers. It returns a large number to make the UI work.
     */
    function allowance(address, address) external pure returns (uint256) {
        return 100000 ether;
    }
}

