/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ECDSA {
    bytes32 internal constant MAKER_ORDER_HASH = 0x40261ade532fa1d2c7293df30aaadb9b3c616fae525a0b56d3d411c841a85028;

    bytes32 public immutable DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                0xda9101ba92939daf4bb2e18cd5f942363b9297fbc3232c9dd964abb1fb70ed71, // keccak256("LooksRareExchange")
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
                1,
                0x59728544B08AB483533076417FbBB2fD0B17CE3a
            )
        );

    function recover(bytes32 hash, bytes memory signature)
        external
        view
        returns (address signer, bytes32 r, bytes32 s, uint8 v)
    {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0), r, s, v);
        }

        // Divide the signature in r, s and v variables with inline assembly.
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0), r, s, v);
        } else {
            bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash));
            // solium-disable-next-line arg-overflow
            return (ecrecover(digest, v, r, s), r, s, v);
        }
    }

    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // additional parameters
        bytes signature;
    }

    function getHash(MakerOrder memory makerOrder) external pure returns (bytes32 hash, bytes memory abiEncoded, bytes32 paramsHash) {
        paramsHash = keccak256(makerOrder.params);

        abiEncoded = abi.encode(
                        MAKER_ORDER_HASH,
                        makerOrder.isOrderAsk,
                        makerOrder.signer,
                        makerOrder.collection,
                        makerOrder.price,
                        makerOrder.tokenId,
                        makerOrder.amount,
                        makerOrder.strategy,
                        makerOrder.currency,
                        makerOrder.nonce,
                        makerOrder.startTime,
                        makerOrder.endTime,
                        makerOrder.minPercentageToAsk,
                        paramsHash
                    );

        hash = keccak256(abiEncoded);
    }
}