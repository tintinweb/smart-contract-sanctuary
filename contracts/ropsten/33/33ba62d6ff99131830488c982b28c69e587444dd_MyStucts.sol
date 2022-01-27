/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

contract MyStucts {

    function myPureFunc(uint256 _x, uint256 _y) public pure returns (uint256 xy) {
        return _x + _y;
    }
}