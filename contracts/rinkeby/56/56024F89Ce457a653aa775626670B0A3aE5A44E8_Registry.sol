/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

contract Registry {
    address[] public escrowAddrs;

    function getNumOfEscrow() public view returns(uint256) {
        return escrowAddrs.length;
    }

    function addEscrow(address _escrow) public {
        require(_escrow != address(0), "Escrow should be non-zero address");
        escrowAddrs.push(_escrow);
    }
}