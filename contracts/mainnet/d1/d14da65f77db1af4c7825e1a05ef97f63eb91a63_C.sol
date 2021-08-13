/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

//SPDX-License-Identifier:None
pragma solidity 0.8.7;
contract C {
    function computePair(address token) external pure returns (address) {
        return address(uint160(uint(keccak256(abi.encodePacked(hex"ff",
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,
            keccak256(abi.encodePacked(token, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)),
            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" 
        )))));
    }
}