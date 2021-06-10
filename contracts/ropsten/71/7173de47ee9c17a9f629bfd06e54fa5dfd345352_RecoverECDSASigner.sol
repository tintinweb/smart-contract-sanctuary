/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity >=0.7.0 <0.9.0;

contract RecoverECDSASigner {

    constructor() {}

    
    /// signature methods.
    function splitSignature(bytes memory sig)
        private
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        // require(sig.length == 65, "Invalid signature length");

        if (sig.length == 65) {
            assembly {
                // first 32 bytes, after the length prefix.
                r := mload(add(sig, 32))
                // second 32 bytes.
                s := mload(add(sig, 64))
                // final byte (first byte of the next 32 bytes).
                v := byte(0, mload(add(sig, 96)))
            }
        }
        else if (sig.length == 64) {
          assembly {
                let vs := mload(add(sig, 0x40))
                r := mload(add(sig, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }  
        }
        else {
            revert("ECDSA: invalid signature length");
        }

        return (v, r, s);
    }


    function recoverSigner(bytes32 message, bytes memory sig)
        public
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, message));
    
        return ecrecover(prefixedHash, v, r, s);
    }
    
}