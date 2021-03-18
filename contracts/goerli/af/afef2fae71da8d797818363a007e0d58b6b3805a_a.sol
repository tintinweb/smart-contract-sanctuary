/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

pragma solidity >=0.7.6 <0.8.0;





//SPDX-License-Identifier: UNLICENSED
contract a {
 function verify(address p, bytes32 hash, uint8 v, bytes32 r, bytes32 s) public view  returns(bool) {
        // Note: this only verifies that signer is correct.
        // You'll also need to verify that the hash of the data
        // is also correct.
        return ecrecover(hash, v, r, s) == p;
    }
    
    function splitSignature(bytes memory sig)
        public view  returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
          

            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

}