pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./LibValidator.sol";

library LibAtomic {
    using ECDSA for bytes32;

    struct LockOrder {
        address sender;
        address receiver;
        address asset;
        uint64 amount;
        uint64 expiration;
        bytes32 secretHash;
        bool used;
    }

    struct RedeemOrder {
        address sender;
        address receiver;
        address asset;
        uint64 amount;
        uint64 expiration;
        bytes32 secretHash;
        bytes signature;
    }

    function doValidateRedeemOrder(
                RedeemOrder calldata order,
                bytes calldata secret,
                mapping(bytes32 => bytes) storage secrets) public view {
        require(msg.sender == order.receiver, "E3C");
        require(secrets[order.secretHash].length == 0, "E17R");
        validatelAtomic(order, block.timestamp);
        require(order.secretHash == keccak256(secret), "E17");
    }

    function doValidateClaimAtomic(
            bytes calldata secret,
            bytes calldata matcherSignature,
            address allowedMatcher,
            mapping(bytes32 => LockOrder) storage atomicSwaps)
                public view returns(LockOrder storage swap) {
        bytes32 secretHash = keccak256(secret);
        require(secretHash.toEthSignedMessageHash().recover(matcherSignature) == allowedMatcher, "E2");

        swap = atomicSwaps[secretHash];
        require(swap.sender != address(0x0), "E17I");
        require(swap.receiver == msg.sender, "E3C");
        require(swap.expiration/1000 >= block.timestamp, "E17E");
        require(!swap.used, "E17U");
    }

    function doValidateRefundAtomic(
            bytes32 secretHash,
            mapping(bytes32 => LockOrder) storage atomicSwaps)
                public view returns(LockOrder storage swap) {
        swap = atomicSwaps[secretHash];
        require(swap.expiration/1000 < block.timestamp, "E17NE");
        require(!swap.used, "E17U");
    }

    function getEthSignedAtomicOrderHash(RedeemOrder calldata _order) internal pure returns (bytes32) {
        return
        keccak256(
            abi.encodePacked(
                "atomicOrder",
                _order.sender,
                _order.receiver,
                _order.asset,
                _order.amount,
                _order.expiration,
                _order.secretHash
            )
        ).toEthSignedMessageHash();
    }

    function validatelAtomic(RedeemOrder calldata order, uint currentTime) internal pure returns (bool) {
        require(getEthSignedAtomicOrderHash(order).recover(order.signature) == order.sender, "E2");
        // Check Expiration Time. Convert to seconds first
        require(order.expiration/1000 >= currentTime, "E4A");
        return true;
    }
}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";

library LibValidator {

    using ECDSA for bytes32;

    string public constant DOMAIN_NAME = "Orion Exchange";
    string public constant DOMAIN_VERSION = "1";
    uint256 public constant CHAIN_ID = 97;
    bytes32 public constant DOMAIN_SALT = 0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a557;

    bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256(
        abi.encodePacked(
            "EIP712Domain(string name,string version,uint256 chainId,bytes32 salt)"
        )
    );
    bytes32 public constant ORDER_TYPEHASH = keccak256(
        abi.encodePacked(
            "Order(address senderAddress,address matcherAddress,address baseAsset,address quoteAsset,address matcherFeeAsset,uint64 amount,uint64 price,uint64 matcherFee,uint64 nonce,uint64 expiration,uint8 buySide)"
        )
    );

    bytes32 public constant DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes(DOMAIN_NAME)),
            keccak256(bytes(DOMAIN_VERSION)),
            CHAIN_ID,
            DOMAIN_SALT
        )
    );

    struct Order {
        address senderAddress;
        address matcherAddress;
        address baseAsset;
        address quoteAsset;
        address matcherFeeAsset;
        uint64 amount;
        uint64 price;
        uint64 matcherFee;
        uint64 nonce;
        uint64 expiration;
        uint8 buySide; // buy or sell
        bool isPersonalSign;
        bytes signature;
    }

    /**
     * @dev validate order signature
     */
    function validateV3(Order memory order) public pure returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getTypeValueHash(order)
            )
        );

        return digest.recover(order.signature) == order.senderAddress;
    }

    /**
     * @return hash order
     */
    function getTypeValueHash(Order memory _order)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    _order.senderAddress,
                    _order.matcherAddress,
                    _order.baseAsset,
                    _order.quoteAsset,
                    _order.matcherFeeAsset,
                    _order.amount,
                    _order.price,
                    _order.matcherFee,
                    _order.nonce,
                    _order.expiration,
                    _order.buySide
                )
            );
    }

    /**
     * @dev basic checks of matching orders against each other
     */
    function checkOrdersInfo(
        Order memory buyOrder,
        Order memory sellOrder,
        address sender,
        uint256 filledAmount,
        uint256 filledPrice,
        uint256 currentTime,
        address allowedMatcher
    ) public pure returns (bool success) {
        buyOrder.isPersonalSign ? require(validatePersonal(buyOrder), "E2BP") : require(validateV3(buyOrder), "E2B");
        sellOrder.isPersonalSign ? require(validatePersonal(sellOrder), "E2SP") : require(validateV3(sellOrder), "E2S");

        // Same matcher address
        require(
            buyOrder.matcherAddress == sender &&
                sellOrder.matcherAddress == sender,
            "E3M"
        );

        if(allowedMatcher != address(0)) {
          require(buyOrder.matcherAddress == allowedMatcher, "E3M2");
        }


        // Check matching assets
        require(
            buyOrder.baseAsset == sellOrder.baseAsset &&
                buyOrder.quoteAsset == sellOrder.quoteAsset,
            "E3As"
        );

        // Check order amounts
        require(filledAmount <= buyOrder.amount, "E3AmB");
        require(filledAmount <= sellOrder.amount, "E3AmS");

        // Check Price values
        require(filledPrice <= buyOrder.price, "E3");
        require(filledPrice >= sellOrder.price, "E3");

        // Check Expiration Time. Convert to seconds first
        require(buyOrder.expiration/1000 >= currentTime, "E4B");
        require(sellOrder.expiration/1000 >= currentTime, "E4S");

        require( buyOrder.buySide==1 && sellOrder.buySide==0, "E3D");
        success = true;
    }

    function getEthSignedOrderHash(Order memory _order) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "order",
                    _order.senderAddress,
                    _order.matcherAddress,
                    _order.baseAsset,
                    _order.quoteAsset,
                    _order.matcherFeeAsset,
                    _order.amount,
                    _order.price,
                    _order.matcherFee,
                    _order.nonce,
                    _order.expiration,
                    _order.buySide
                )
            ).toEthSignedMessageHash();
    }

    function validatePersonal(Order memory order) public pure returns (bool) {

        bytes32 digest = getEthSignedOrderHash(order);
        return digest.recover(order.signature) == order.senderAddress;
    }

    function checkOrderSingleMatch(
        Order memory buyOrder,
        address sender,
        address allowedMatcher,
        uint112 filledAmount,
        uint256 currentTime,
        address[] memory path,
        uint8 isBuySide
    ) public pure returns (bool success) {
        buyOrder.isPersonalSign ? require(validatePersonal(buyOrder), "E2BP") : require(validateV3(buyOrder), "E2B");
        require(buyOrder.matcherAddress == sender && buyOrder.matcherAddress == allowedMatcher, "E3M2");
        if(buyOrder.buySide==1){
            require(
                buyOrder.baseAsset == path[path.length-1] &&
                buyOrder.quoteAsset == path[0],
                "E3As"
            );
        }else{
            require(
                buyOrder.quoteAsset == path[path.length-1] &&
                buyOrder.baseAsset == path[0],
                "E3As"
            );
        }
        require(filledAmount <= buyOrder.amount, "E3AmB");
        require(buyOrder.expiration/1000 >= currentTime, "E4B");
        require( buyOrder.buySide==isBuySide, "E3D");

    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}