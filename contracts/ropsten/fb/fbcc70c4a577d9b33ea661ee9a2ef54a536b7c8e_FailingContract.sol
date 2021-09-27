/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title FailingContract
 * @dev Always fails
 */
contract FailingContract {

    /**
     * @dev Fail this transaction just because
     */
    function fail_on_purpose() public {
        revert("This transaction is failing on purpose!");
    }
}