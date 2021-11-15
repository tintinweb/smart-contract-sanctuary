// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Utils {
    function _decryptGenes(
        uint256 genes_, 
        address account,
         uint256 nonce_
    ) 
        internal 
        pure 
        returns(uint256)
    {
        return genes_  ^ nonce_ ^ (uint256(uint160(address(account))) << 96);
    }

    function _recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = _splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function _splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
   }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../common/Utils.sol";

contract SharkVerifyTest is Utils {
    mapping (address => uint256) public nonces;
    constructor () {
    }

    function func1(
        address nftAddress,
        uint256 tokenId,
        bytes calldata signature
    ) 
        external
        pure
        returns(address)
    {
        bytes32 message = keccak256(abi.encodePacked(nftAddress, tokenId));
        address signer = _recoverSigner(message, signature);
        return signer;
    }

    function func2(
        address nftAddress,
        uint256 tokenId,
        uint256[] memory amounts,
        bytes calldata signature
    ) 
        external
        pure
        returns(address)
    {
        bytes32 message = keccak256(abi.encodePacked(nftAddress, tokenId, amounts));
        address signer = _recoverSigner(message, signature);
        return signer;
    }

    function func3(
        address nftAddress,
        uint256 tokenId,
        address[] calldata inviters,
        bytes calldata signature
    ) 
        external
        pure
        returns(address)
    {
        bytes32 message = keccak256(abi.encodePacked(nftAddress, tokenId, inviters));
        address signer = _recoverSigner(message, signature);
        return signer;
    }

    function func4(
        address nftAddress,
        uint256 tokenId,
        address[] calldata inviters,
        uint256[] calldata amounts,
        bytes calldata signature
    ) 
        external
        pure
        returns(address)
    {
        bytes32 message = keccak256(abi.encodePacked(nftAddress, tokenId, inviters, amounts));
        address signer = _recoverSigner(message, signature);
        return signer;
    }
    
    function func5(
        address nftAddress,
        uint256 tokenId,
        address[] calldata inviters,
        uint256[] calldata amounts,
        string memory anyString,
        bytes calldata signature
    ) 
        external
        pure
        returns(address)
    {
        bytes32 message = keccak256(abi.encodePacked(nftAddress, tokenId, inviters, amounts, anyString));
        address signer = _recoverSigner(message, signature);
        return signer;
    }
}

