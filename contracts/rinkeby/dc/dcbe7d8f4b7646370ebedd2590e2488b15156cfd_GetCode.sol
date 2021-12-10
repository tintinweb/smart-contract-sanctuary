/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

pragma solidity ^0.4.26;


library GetCode {
    function atReturningHash(address _addr) public view returns (bytes32 hash) {
        bytes memory o_code;
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(_addr)
            if gt(size, 0) {
                // allocate output byte array - this could also be done without assembly
                // by using o_code = new bytes(size)
                o_code := mload(0x40)
                // new "memory end" including padding
                mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
                // store length in memory
                mstore(o_code, size)
                // actually retrieve the code, this needs assembly
                extcodecopy(_addr, add(o_code, 0x20), 0, size)
            }
        }
        hash = keccak256(o_code);
    }
    function at(address _addr) public view returns (bytes o_code) {
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(_addr)
            if gt(size, 0) {
                // allocate output byte array - this could also be done without assembly
                // by using o_code = new bytes(size)
                o_code := mload(0x40)
                // new "memory end" including padding
                mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
                // store length in memory
                mstore(o_code, size)
                // actually retrieve the code, this needs assembly
                extcodecopy(_addr, add(o_code, 0x20), 0, size)
            }
        }
    }
}

contract CheckerV2 {
    constructor () public {}
    
    function getCodeHashed(address _contractAddress) public view returns (bytes32) {
        return GetCode.atReturningHash(_contractAddress);
    }
    
    function getCode(address _contractAddress) public view returns (bytes) {
        return GetCode.at(_contractAddress);
    }
}