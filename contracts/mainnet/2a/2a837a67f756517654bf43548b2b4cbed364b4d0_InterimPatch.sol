/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev This contract is deployed as an interim patch while the DateTime library is upgraded. 
 */
contract InterimPatch {

    function getMonth(uint timestamp) public pure returns (uint8) {
        return 6;
    }

}