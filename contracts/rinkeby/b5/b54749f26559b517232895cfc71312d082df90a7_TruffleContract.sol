/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0;

contract TruffleContract {
    uint256 numberOfSupply;

    function changeSupply(uint256 supply) public {
        numberOfSupply = supply;
    }

    function getSupply() public view returns (uint256){
        return numberOfSupply;
    }
}