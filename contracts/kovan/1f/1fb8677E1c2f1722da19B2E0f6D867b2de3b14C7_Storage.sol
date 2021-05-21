/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve hash
 */
contract Storage {
    mapping (string => string) public tagHash;
    /**
     * @dev Store value in variable
     * @param tag value of zortag
     * @param hash value to store
     */
    function store(string memory tag, string memory hash) public {
        tagHash[tag] = hash;
    }
}