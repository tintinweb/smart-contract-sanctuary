/**
 *Submitted for verification at polygonscan.com on 2021-12-11
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

contract GamingOraclePoly {

    address impl;
    address admin;

    mapping (address => bool)  public auth;
    mapping (uint256 => bytes32) hashes;

    function setAuth(address who, bool status) external {
        require(msg.sender == admin, "not authorized");
        auth[who] = status;        
    }

    function update(uint256 blc, bytes32 hsh) external {
        require(auth[msg.sender], "not authorized");
        hashes[blc] = hsh;
    }

    function update(uint256[] calldata blcs, bytes32[] calldata hshs) external {
        require(blcs.length == hshs.length, "mismatched inputs");
        require(auth[msg.sender], "not authorized");
        for (uint256 i = 0; i < blcs.length; i++) {
            hashes[blcs[i]] = hshs[i];
        }
    }

    function seedFor(uint256 blc) external view returns(bytes32 hs) {
        hs = hashes[blc];
        require(hs != bytes32(""), "not present");
    }
    
}