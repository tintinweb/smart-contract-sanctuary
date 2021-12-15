/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;
contract Test {
    struct Signature {
        bytes32 r;
        bytes32 s;
        bytes2 vType;
    }
    function verify(bytes32 r, bytes32 s, uint8 v , bytes32 hash) external view  returns (address){
        // Signature memory signature = abi.decode(data, (Signature));
        return ecrecover(
            hash,
            v,
            r,
            s
        );
    }
}