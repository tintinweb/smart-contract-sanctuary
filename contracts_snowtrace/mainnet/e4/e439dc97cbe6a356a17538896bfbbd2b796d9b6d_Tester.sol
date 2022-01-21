/**
 *Submitted for verification at snowtrace.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Tester {
    address payable Multisig = payable(0x49208f9eEAD9416446cdE53435C6271A0235dDA4);

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawMoneyTo() external {
        Multisig.transfer(getBalance());
    }
}