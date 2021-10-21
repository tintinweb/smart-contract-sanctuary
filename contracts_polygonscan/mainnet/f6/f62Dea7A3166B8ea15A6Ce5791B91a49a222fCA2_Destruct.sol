// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Destruct {
    /**
     * @dev Transfer multiple tokens.
     */
    function destruct() external {
        selfdestruct(payable(address(0)));
    }
}