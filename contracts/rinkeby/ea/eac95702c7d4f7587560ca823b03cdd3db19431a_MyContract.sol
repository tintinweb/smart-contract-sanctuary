/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

contract MyContract {
    function addressBalance(address _contract) public view returns(uint256) {
        return address(_contract).balance;
    }
}