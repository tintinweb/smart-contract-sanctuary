/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

//SPDX-License-Identifier:None
pragma solidity 0.8.6;
contract C {
    function computePair(address token) external pure returns (address) {
        return address(uint160(uint(keccak256(abi.encodePacked(hex"ff",
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,
            keccak256(abi.encodePacked(token, 0xc778417E063141139Fce010982780140Aa0cD5Ab)),
            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" 
        )))));
    }
}