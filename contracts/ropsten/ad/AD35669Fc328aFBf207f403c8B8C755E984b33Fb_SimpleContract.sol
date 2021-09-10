/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity > 0.5;

contract SimpleContract {
    uint256 public count;

    function incrementCount() public {
        count++;
    }

    function setCount(uint256 _count) public {
        require(_count > 0);
        count = _count;
    }
}