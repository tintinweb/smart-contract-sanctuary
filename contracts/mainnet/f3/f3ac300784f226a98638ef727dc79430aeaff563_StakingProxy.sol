/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Staking {
    function depositsOf(address) external view returns (uint256[] memory);
}

contract StakingProxy {
    function balanceOf(address account) public view returns (uint256) {
        return Staking(
            0xd09656a2EE7E5Ee3404fAce234e683D3337dA014
        ).depositsOf(account).length;
    }
}