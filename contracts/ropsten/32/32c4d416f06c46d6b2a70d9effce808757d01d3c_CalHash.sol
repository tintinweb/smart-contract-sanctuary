/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma solidity =0.8.7;


contract CalHash {
    function getInitHash(bytes memory bytecode) public pure returns(bytes32){
      //  bytes memory bytecode = type(UniswapV2Pair).creationCode;
        return keccak256(abi.encodePacked(bytecode));
    }
}