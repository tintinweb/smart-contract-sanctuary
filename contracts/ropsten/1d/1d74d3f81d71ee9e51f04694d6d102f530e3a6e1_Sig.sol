/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.4.24;


contract Sig {

    function getTwoArgsHash(
        uint commitLastBlock, 
        uint commit
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(commitLastBlock, commit));
    }

     function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

            v = 28;

    }
    
    function getNewHash(bytes32 _hash) public pure returns(bytes32) {
       return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    }
    
    function getAddress(bytes32 _hash, bytes32 r, bytes32 s, uint8 v) public pure returns(address){
       return ecrecover(_hash, v, r, s);
    }

}