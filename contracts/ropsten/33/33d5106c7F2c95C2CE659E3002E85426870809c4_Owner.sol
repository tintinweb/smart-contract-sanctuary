/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    uint256 public numberb;

    function test1(uint256 num) public {
        numberb = num;
    }

    function test2(address a, uint256 num) public {
        a.delegatecall(abi.encodeWithSignature("store(uint256)", num));
    }
}