// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract STest {
    uint256 public val;

    function get() external view returns(uint256) {
        return val;
    }

    function set(uint256 n) external {
        val = n;
    }

    function inc(uint256 n) external {
        val += n;
    }

    function checkSign(
        uint256 param1,
        uint256 param2,
        uint256 param3,
        uint256 param4,
        uint256 salt,
        bytes memory signature
    ) external pure returns(address) {
        bytes32 operationHash = keccak256(abi.encodePacked(param1, param2, param3, param4, salt));
        return verifyMultiSig(operationHash, signature);
    }

    function checkSign2(
        uint256 param1,
        uint256 param2,
        uint256 param3,
        uint256 param4,
        uint256 salt
    ) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(param1, param2, param3, param4, salt));
    }

    function checkSign3(
        uint256 param1,
        uint256 param2,
        uint256 param3,
        uint256 param4,
        uint256 salt
    ) external pure returns(bytes32) {
        bytes32 operationHash = keccak256(abi.encodePacked(param1, param2, param3, param4, salt));
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, operationHash));
    }

    function verifyMultiSig(
        bytes32 operationHash,
        bytes memory signature
    ) private pure returns (address) {
        address signer = recoverAddressFromSignature(operationHash, signature);
        return signer;
    }

    function recoverAddressFromSignature(
        bytes32 operationHash,
        bytes memory signature
    ) private pure returns (address) {
        if (signature.length != 65) {
            revert("invalid signature length");
        }
        // We need to unpack the signature, which is given as an array of 65 bytes (like eth.sign)
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }
        if (v < 27) {
            v += 27;
            // Ethereum versions are 27 or 28 as opposed to 0 or 1 which is submitted by some signing libs
        }
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedProof =
        keccak256(abi.encodePacked(prefix, operationHash));
        return ecrecover(prefixedProof, v, r, s);
    }
}