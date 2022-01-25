/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract test{




    function getHash(string memory str)
    public
    pure
    returns(bytes32){
        return keccak256(abi.encodePacked(str));
    }

}