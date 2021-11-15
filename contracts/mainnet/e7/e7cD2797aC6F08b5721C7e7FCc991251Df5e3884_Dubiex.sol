// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@prps/solidity/contracts/EIP712Boostable.sol";
import "./DubiexLib.sol";

/**
 * @dev Dubiex Boostable primitives following the EIP712 standard
 */
abstract contract Boostable is EIP712Boostable {
    bytes32 private constant BOOSTED_MAKE_ORDER_TYPEHASH = keccak256(
        "BoostedMakeOrder(MakeOrderInput input,address maker,BoosterFuel fuel,BoosterPayload boosterPayload)BoosterFuel(uint96 dubi,uint96 unlockedPrps,uint96 lockedPrps,uint96 intrinsicFuel)BoosterPayload(address booster,uint64 timestamp,uint64 nonce,bool isLegacySignature)MakeOrderInput(uint96 makerValue,uint96 takerValue,OrderPair pair,uint32 orderId,uint32 ancestorOrderId,uint128 updatedRatioWei)OrderPair(address makerContractAddress,address takerContractAddress,uint8 makerCurrencyType,uint8 takerCurrencyType)"
    );

    bytes32 private constant BOOSTED_TAKE_ORDER_TYPEHASH = keccak256(
        "BoostedTakeOrder(TakeOrderInput input,address taker,BoosterFuel fuel,BoosterPayload boosterPayload)BoosterFuel(uint96 dubi,uint96 unlockedPrps,uint96 lockedPrps,uint96 intrinsicFuel)BoosterPayload(address booster,uint64 timestamp,uint64 nonce,bool isLegacySignature)TakeOrderInput(uint32 id,address maker,uint96 takerValue,uint256 maxTakerMakerRatio)"
    );

    bytes32 private constant BOOSTED_CANCEL_ORDER_TYPEHASH = keccak256(
        "BoostedCancelOrder(CancelOrderInput input,BoosterFuel fuel,BoosterPayload boosterPayload)BoosterFuel(uint96 dubi,uint96 unlockedPrps,uint96 lockedPrps,uint96 intrinsicFuel)BoosterPayload(address booster,uint64 timestamp,uint64 nonce,bool isLegacySignature)CancelOrderInput(uint32 id,address maker)"
    );

    bytes32 private constant MAKE_ORDER_INPUT_TYPEHASH = keccak256(
        "MakeOrderInput(uint96 makerValue,uint96 takerValue,OrderPair pair,uint32 orderId,uint32 ancestorOrderId,uint128 updatedRatioWei)OrderPair(address makerContractAddress,address takerContractAddress,uint8 makerCurrencyType,uint8 takerCurrencyType)"
    );

    bytes32 private constant TAKE_ORDER_INPUT_TYPEHASH = keccak256(
        "TakeOrderInput(uint32 id,address maker,uint96 takerValue,uint256 maxTakerMakerRatio)"
    );

    bytes32 private constant CANCEL_ORDER_INPUT_TYPEHASH = keccak256(
        "CancelOrderInput(uint32 id,address maker)"
    );

    bytes32 private constant ORDER_PAIR_TYPEHASH = keccak256(
        "OrderPair(address makerContractAddress,address takerContractAddress,uint8 makerCurrencyType,uint8 takerCurrencyType)"
    );

    constructor(address optIn)
        public
        EIP712Boostable(
            optIn,
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256("Dubiex"),
                    keccak256("1"),
                    _getChainId(),
                    address(this)
                )
            )
        )
    {}

    /**
     * @dev A struct representing the payload of `boostedMakeOrder`.
     */
    struct BoostedMakeOrder {
        DubiexLib.MakeOrderInput input;
        address payable maker;
        BoosterFuel fuel;
        BoosterPayload boosterPayload;
    }

    /**
     * @dev A struct representing the payload of `boostedTakeOrder`.
     */
    struct BoostedTakeOrder {
        DubiexLib.TakeOrderInput input;
        address payable taker;
        BoosterFuel fuel;
        BoosterPayload boosterPayload;
    }

    /**
     * @dev A struct representing the payload of `boostedCancelOrder`.
     */
    struct BoostedCancelOrder {
        DubiexLib.CancelOrderInput input;
        BoosterFuel fuel;
        BoosterPayload boosterPayload;
    }

    function hashBoostedMakeOrder(
        BoostedMakeOrder memory boostedMakeOrder,
        address booster
    ) internal view returns (bytes32) {
        return
            BoostableLib.hashWithDomainSeparator(
                _DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        BOOSTED_MAKE_ORDER_TYPEHASH,
                        hashMakeOrderInput(boostedMakeOrder.input),
                        boostedMakeOrder.maker,
                        BoostableLib.hashBoosterFuel(boostedMakeOrder.fuel),
                        BoostableLib.hashBoosterPayload(
                            boostedMakeOrder.boosterPayload,
                            booster
                        )
                    )
                )
            );
    }

    function hashBoostedTakeOrder(
        BoostedTakeOrder memory boostedTakeOrder,
        address booster
    ) internal view returns (bytes32) {
        return
            BoostableLib.hashWithDomainSeparator(
                _DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        BOOSTED_TAKE_ORDER_TYPEHASH,
                        hashTakeOrderInput(boostedTakeOrder.input),
                        boostedTakeOrder.taker,
                        BoostableLib.hashBoosterFuel(boostedTakeOrder.fuel),
                        BoostableLib.hashBoosterPayload(
                            boostedTakeOrder.boosterPayload,
                            booster
                        )
                    )
                )
            );
    }

    function hashBoostedCancelOrder(
        BoostedCancelOrder memory boostedCancelOrder,
        address booster
    ) internal view returns (bytes32) {
        return
            BoostableLib.hashWithDomainSeparator(
                _DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        BOOSTED_CANCEL_ORDER_TYPEHASH,
                        hashCancelOrderInput(boostedCancelOrder.input),
                        BoostableLib.hashBoosterFuel(boostedCancelOrder.fuel),
                        BoostableLib.hashBoosterPayload(
                            boostedCancelOrder.boosterPayload,
                            booster
                        )
                    )
                )
            );
    }

    function hashMakeOrderInput(DubiexLib.MakeOrderInput memory input)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    MAKE_ORDER_INPUT_TYPEHASH,
                    input.makerValue,
                    input.takerValue,
                    hashOrderPair(input.pair),
                    input.orderId,
                    input.ancestorOrderId,
                    input.updatedRatioWei
                )
            );
    }

    function hashOrderPair(DubiexLib.OrderPair memory pair)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    ORDER_PAIR_TYPEHASH,
                    pair.makerContractAddress,
                    pair.takerContractAddress,
                    pair.makerCurrencyType,
                    pair.takerCurrencyType
                )
            );
    }

    function hashTakeOrderInput(DubiexLib.TakeOrderInput memory input)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    TAKE_ORDER_INPUT_TYPEHASH,
                    input.id,
                    input.maker,
                    input.takerValue,
                    input.maxTakerMakerRatio
                )
            );
    }

    function hashCancelOrderInput(DubiexLib.CancelOrderInput memory input)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(CANCEL_ORDER_INPUT_TYPEHASH, input.id, input.maker)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./IOptIn.sol";
import "./BoostableLib.sol";
import "./IBoostableERC20.sol";

/**
 * @dev Boostable base contract
 *
 * All deriving contracts are expected to implement EIP712 for the message signing.
 *
 */
abstract contract EIP712Boostable {
    using ECDSA for bytes32;

    // solhint-disable-next-line var-name-mixedcase
    IOptIn internal immutable _OPT_IN;
    // solhint-disable-next-line var-name-mixedcase
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 private constant BOOSTER_PAYLOAD_TYPEHASH = keccak256(
        "BoosterPayload(address booster,uint64 timestamp,uint64 nonce,bool isLegacySignature)"
    );

    bytes32 internal constant BOOSTER_FUEL_TYPEHASH = keccak256(
        "BoosterFuel(uint96 dubi,uint96 unlockedPrps,uint96 lockedPrps,uint96 intrinsicFuel)"
    );

    // The boost fuel is capped to 10 of the respective token that will be used for payment.
    uint96 internal constant MAX_BOOSTER_FUEL = 10 ether;

    // A magic booster permission prefix
    bytes6 private constant MAGIC_BOOSTER_PERMISSION_PREFIX = "BOOST-";

    constructor(address optIn, bytes32 domainSeparator) public {
        _OPT_IN = IOptIn(optIn);
        _DOMAIN_SEPARATOR = domainSeparator;
    }

    // A mapping of mappings to keep track of used nonces by address to
    // protect against replays. Each 'Boostable' contract maintains it's own
    // state for nonces.
    mapping(address => uint64) private _nonces;

    //---------------------------------------------------------------

    function getNonce(address account) external virtual view returns (uint64) {
        return _nonces[account];
    }

    function getOptInStatus(address account)
        internal
        view
        returns (IOptIn.OptInStatus memory)
    {
        return _OPT_IN.getOptInStatus(account);
    }

    /**
     * @dev Called by every 'boosted'-function to ensure that `msg.sender` (i.e. a booster) is
     * allowed to perform the call for `from` (the origin) by verifying that `messageHash`
     * has been signed by `from`. Additionally, `from` provides a nonce to prevent
     * replays. Boosts cannot be verified out of order.
     *
     * @param from the address that the boost is made for
     * @param messageHash the reconstructed message hash based on the function input
     * @param payload the booster payload
     * @param signature the signature of `from`
     */
    function verifyBoost(
        address from,
        bytes32 messageHash,
        BoosterPayload memory payload,
        Signature memory signature
    ) internal {
        uint64 currentNonce = _nonces[from];
        require(currentNonce == payload.nonce - 1, "AB-1");

        _nonces[from] = currentNonce + 1;

        _verifyBoostWithoutNonce(from, messageHash, payload, signature);
    }

    /**
     * @dev Verify a boost without verifying the nonce.
     */
    function _verifyBoostWithoutNonce(
        address from,
        bytes32 messageHash,
        BoosterPayload memory payload,
        Signature memory signature
    ) internal view {
        // The sender must be the booster specified in the payload
        require(msg.sender == payload.booster, "AB-2");

        (bool isOptedInToSender, uint256 optOutPeriod) = _OPT_IN.isOptedInBy(
            msg.sender,
            from
        );

        // `from` must be opted-in to booster
        require(isOptedInToSender, "AB-3");

        // The given timestamp must not be greater than `block.timestamp + 1 hour`
        // and at most `optOutPeriod(booster)` seconds old.
        uint64 _now = uint64(block.timestamp);
        uint64 _optOutPeriod = uint64(optOutPeriod);

        bool notTooFarInFuture = payload.timestamp <= _now + 1 hours;
        bool belowMaxAge = true;

        // Calculate the absolute difference. Because of the small tolerance, `payload.timestamp`
        // may be greater than `_now`:
        if (payload.timestamp <= _now) {
            belowMaxAge = _now - payload.timestamp <= _optOutPeriod;
        }

        // Signature must not be expired
        require(notTooFarInFuture && belowMaxAge, "AB-4");

        // NOTE: Currently, hardware wallets (e.g. Ledger, Trezor) do not support EIP712 signing (specifically `signTypedData_v4`).
        // However, a user can still sign the EIP712 hash with the caveat that it's signed using `personal_sign` which prepends
        // the prefix '"\x19Ethereum Signed Message:\n" + len(message)'.
        //
        // To still support that, we add the prefix to the hash if `isLegacySignature` is true.
        if (payload.isLegacySignature) {
            messageHash = messageHash.toEthSignedMessageHash();
        }

        // Valid, if the recovered address from `messageHash` with the given `signature` matches `from`.

        address signer = ecrecover(
            messageHash,
            signature.v,
            signature.r,
            signature.s
        );

        if (!payload.isLegacySignature && signer != from) {
            // As a last resort we try anyway, in case the caller simply forgot the `isLegacySignature` flag.
            signer = ecrecover(
                messageHash.toEthSignedMessageHash(),
                signature.v,
                signature.r,
                signature.s
            );
        }

        require(from == signer, "AB-5");
    }

    /**
     * @dev Returns the hash of `payload` using the provided booster (i.e. `msg.sender`).
     */
    function hashBoosterPayload(BoosterPayload memory payload, address booster)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    BOOSTER_PAYLOAD_TYPEHASH,
                    booster,
                    payload.timestamp,
                    payload.nonce
                )
            );
    }

    function _getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library DubiexLib {
    enum CurrencyType {NULL, ETH, ERC20, BOOSTABLE_ERC20, ERC721}

    // Enum is used to read only a specific part of the order pair from
    // storage, since it is a bad idea to always perform 4 SLOADs.
    enum OrderPairReadStrategy {SKIP, MAKER, TAKER, FULL}

    struct OrderPair {
        address makerContractAddress;
        CurrencyType makerCurrencyType;
        address takerContractAddress;
        CurrencyType takerCurrencyType;
    }

    // To reduce the number of reads, the order pairs
    // are stored packed and on read unpacked as required.
    // Also see `OrderPair` and `OrderPairReadStrategy`.
    struct PackedOrderPair {
        // 20 bytes address + 1 byte currency type
        uint168 makerPair;
        // 20 bytes address + 1 byte currency type
        uint168 takerPair;
    }

    struct PackedOrderBookItem {
        // Serialized `UnpackedOrderBookItem`
        uint256 packedData;
        //
        // Mostly zero
        //
        uint32 successorOrderId;
        uint32 ancestorOrderId;
    }

    struct UnpackedOrderBookItem {
        uint32 id;
        uint96 makerValue;
        uint96 takerValue;
        uint32 orderPairAlias;
        // The resolved pair based on the order pair alias
        OrderPair pair;
        OrderFlags flags;
    }

    // Struct that contains all unpacked data and the additional almost-always zero fields from
    // the packed order bookt item - returned from `getOrder()` to be more user-friendly to consume.
    struct PrettyOrderBookItem {
        uint32 id;
        uint96 makerValue;
        uint96 takerValue;
        uint32 orderPairAlias;
        OrderPair pair;
        OrderFlags flags;
        uint32 successorOrderId;
        uint32 ancestorOrderId;
    }

    struct OrderFlags {
        bool isMakerERC721;
        bool isTakerERC721;
        bool isHidden;
        bool hasSuccessor;
    }

    function packOrderBookItem(UnpackedOrderBookItem memory _unpacked)
        internal
        pure
        returns (uint256)
    {
        // Bitpacking saves gas on read/write:

        // 61287 gas
        // struct Item1 {
        //     uint256 word1;
        //     uint256 word2;
        // }

        // // 62198 gas
        // struct Item2 {
        //     uint256 word1;
        //     uint128 a;
        //     uint128 b;
        // }

        // // 62374 gas
        // struct Item3 {
        //     uint256 word1;
        //     uint64 a;
        //     uint64 b;
        //     uint64 c;
        //     uint64 d;
        // }

        uint256 packedData;
        uint256 offset;

        // 1) Set first 32 bits to id
        uint32 id = _unpacked.id;
        packedData |= id;
        offset += 32;

        // 2) Set next 96 bits to maker value
        uint96 makerValue = _unpacked.makerValue;
        packedData |= uint256(makerValue) << offset;
        offset += 96;

        // 3) Set next 96 bits to taker value
        uint96 takerValue = _unpacked.takerValue;
        packedData |= uint256(takerValue) << offset;
        offset += 96;

        // 4) Set next 28 bits to order pair alias
        // Since it is stored in a uint32 AND it with a bitmask where the first 28 bits are 1
        uint32 orderPairAlias = _unpacked.orderPairAlias;
        uint32 orderPairAliasMask = (1 << 28) - 1;
        packedData |= uint256(orderPairAlias & orderPairAliasMask) << offset;
        offset += 28;

        // 5) Set remaining bits to flags
        OrderFlags memory flags = _unpacked.flags;
        if (flags.isMakerERC721) {
            // Maker currency type is ERC721
            packedData |= 1 << (offset + 0);
        }

        if (flags.isTakerERC721) {
            // Taker currency type is ERC721
            packedData |= 1 << (offset + 1);
        }

        if (flags.isHidden) {
            // Order is hidden
            packedData |= 1 << (offset + 2);
        }

        if (flags.hasSuccessor) {
            // Order has a successor
            packedData |= 1 << (offset + 3);
        }

        offset += 4;

        assert(offset == 256);
        return packedData;
    }

    function unpackOrderBookItem(uint256 packedData)
        internal
        pure
        returns (UnpackedOrderBookItem memory)
    {
        UnpackedOrderBookItem memory _unpacked;
        uint256 offset;

        // 1) Read id from the first 32 bits
        _unpacked.id = uint32(packedData >> offset);
        offset += 32;

        // 2) Read maker value from next 96 bits
        _unpacked.makerValue = uint96(packedData >> offset);
        offset += 96;

        // 3) Read taker value from next 96 bits
        _unpacked.takerValue = uint96(packedData >> offset);
        offset += 96;

        // 4) Read order pair alias from next 28 bits
        uint32 orderPairAlias = uint32(packedData >> offset);
        uint32 orderPairAliasMask = (1 << 28) - 1;
        _unpacked.orderPairAlias = orderPairAlias & orderPairAliasMask;
        offset += 28;

        // NOTE: the caller still needs to read the order pair from storage
        // with the unpacked alias

        // 5) Read order flags from remaining bits
        OrderFlags memory flags = _unpacked.flags;

        flags.isMakerERC721 = (packedData >> (offset + 0)) & 1 == 1;
        flags.isTakerERC721 = (packedData >> (offset + 1)) & 1 == 1;
        flags.isHidden = (packedData >> (offset + 2)) & 1 == 1;
        flags.hasSuccessor = (packedData >> (offset + 3)) & 1 == 1;

        offset += 4;

        assert(offset == 256);

        return _unpacked;
    }

    function packOrderPair(OrderPair memory unpacked)
        internal
        pure
        returns (PackedOrderPair memory)
    {
        uint168 packedMaker = uint160(unpacked.makerContractAddress);
        packedMaker |= uint168(unpacked.makerCurrencyType) << 160;

        uint168 packedTaker = uint160(unpacked.takerContractAddress);
        packedTaker |= uint168(unpacked.takerCurrencyType) << 160;

        return PackedOrderPair(packedMaker, packedTaker);
    }

    function unpackOrderPairAddressType(uint168 packed)
        internal
        pure
        returns (address, CurrencyType)
    {
        // The first 20 bytes of order pair are used for the maker address
        address unpackedAddress = address(packed);
        // The next 8 bits for the maker currency type
        CurrencyType unpackedCurrencyType = CurrencyType(uint8(packed >> 160));

        return (unpackedAddress, unpackedCurrencyType);
    }

    /**
     * @dev A struct representing the payload of `makeOrder`.
     */
    struct MakeOrderInput {
        uint96 makerValue;
        uint96 takerValue;
        OrderPair pair;
        // An id of an existing order can be optionally provided to
        // update the makerValue-takerValue ratio with a single call as opposed to cancel-then-make-new-order.
        uint32 orderId;
        // If specified, this order becomes a successor for the ancestor order and will be hidden until
        // the ancestor has been filled.
        uint32 ancestorOrderId;
        // When calling make order using an existing order id, the `updatedRatio` will be applied on
        // the `makerValue` to calculate the new `takerValue`.
        uint128 updatedRatioWei;
    }

    /**
     * @dev A struct representing the payload of `takeOrder`.
     */
    struct TakeOrderInput {
        uint32 id;
        address payable maker;
        uint96 takerValue;
        // The expected max taker maker ratio of the order to take.
        uint256 maxTakerMakerRatio;
    }

    /**
     * @dev A struct representing the payload of `cancelOrder`.
     */
    struct CancelOrderInput {
        uint32 id;
        address payable maker;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

struct Signature {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

interface IOptIn {
    struct OptInStatus {
        bool isOptedIn;
        bool permaBoostActive;
        address optedInTo;
        uint32 optOutPeriod;
    }

    function getOptInStatusPair(address accountA, address accountB)
        external
        view
        returns (OptInStatus memory, OptInStatus memory);

    function getOptInStatus(address account)
        external
        view
        returns (OptInStatus memory);

    function isOptedInBy(address _sender, address _account)
        external
        view
        returns (bool, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

struct BoosterFuel {
    uint96 dubi;
    uint96 unlockedPrps;
    uint96 lockedPrps;
    uint96 intrinsicFuel;
}

struct BoosterPayload {
    address booster;
    uint64 timestamp;
    uint64 nonce;
    // Fallback for 'personal_sign' when e.g. using hardware wallets that don't support
    // EIP712 signing (yet).
    bool isLegacySignature;
}

// Library for Boostable hash functions that are completely inlined.
library BoostableLib {
    bytes32 private constant BOOSTER_PAYLOAD_TYPEHASH = keccak256(
        "BoosterPayload(address booster,uint64 timestamp,uint64 nonce,bool isLegacySignature)"
    );

    bytes32 internal constant BOOSTER_FUEL_TYPEHASH = keccak256(
        "BoosterFuel(uint96 dubi,uint96 unlockedPrps,uint96 lockedPrps,uint96 intrinsicFuel)"
    );

    /**
     * @dev Returns the hash of the packed DOMAIN_SEPARATOR and `messageHash` and is used for verifying
     * a signature.
     */
    function hashWithDomainSeparator(
        bytes32 domainSeparator,
        bytes32 messageHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, messageHash)
            );
    }

    /**
     * @dev Returns the hash of `payload` using the provided booster (i.e. `msg.sender`).
     */
    function hashBoosterPayload(BoosterPayload memory payload, address booster)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    BOOSTER_PAYLOAD_TYPEHASH,
                    booster,
                    payload.timestamp,
                    payload.nonce,
                    payload.isLegacySignature
                )
            );
    }

    function hashBoosterFuel(BoosterFuel memory fuel)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    BOOSTER_FUEL_TYPEHASH,
                    fuel.dubi,
                    fuel.unlockedPrps,
                    fuel.lockedPrps,
                    fuel.intrinsicFuel
                )
            );
    }

    /**
     * @dev Returns the tag found in the given `boosterMessage`.
     */
    function _readBoosterTag(bytes memory boosterMessage)
        internal
        pure
        returns (uint8)
    {
        // The tag is either the 32th byte or the 64th byte depending on whether
        // the booster message contains dynamic bytes or not.
        //
        // If it contains a dynamic byte array, then the first word points to the first
        // data location.
        //
        // Therefore, we read the 32th byte and check if it's >= 32 and if so,
        // simply read the (32 + first word)th byte to get the tag.
        //
        // This imposes a limit on the number of tags we can support (<32), but
        // given that it is very unlikely for so many tags to exist it is fine.
        //
        // Read the 32th byte to get the tag, because it is a uint8 padded to 32 bytes.
        // i.e.
        // -----------------------------------------------------------------v
        // 0x0000000000000000000000000000000000000000000000000000000000000001
        //   ...
        //
        uint8 tag = uint8(boosterMessage[31]);
        if (tag >= 32) {
            // Read the (32 + tag) byte. E.g. if tag is 32, then we read the 64th:
            // --------------------------------------------------------------------
            // 0x0000000000000000000000000000000000000000000000000000000000000020 |
            //   0000000000000000000000000000000000000000000000000000000000000001 <
            //   ...
            //
            tag = uint8(boosterMessage[31 + tag]);
        }

        return tag;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Token agnostic fuel struct that is passed around when the fuel is burned by a different (token) contract.
// The contract has to explicitely support the desired token that should be burned.
struct TokenFuel {
    // A token alias that must be understood by the target contract
    uint8 tokenAlias;
    uint96 amount;
}

/**
 * @dev Extends the interface of the ERC20 standard as defined in the EIP with
 * `boostedTransferFrom` to perform transfers without having to rely on an allowance.
 */
interface IBoostableERC20 {
    // ERC20
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // Extension

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`.
     *
     * If the caller is known by the callee, then the implementation should skip approval checks.
     * Also accepts a data payload, similar to ERC721's `safeTransferFrom` to pass arbitrary data.
     *
     */
    function boostedTransferFrom(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    /**
     * @dev Burns `fuel` from `from`.
     */
    function burnFuel(address from, TokenFuel memory fuel) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "@openzeppelin/contracts/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@prps/solidity/contracts/IBoostableERC20.sol";
import "./DubiexLib.sol";
import "./Boostable.sol";

/**
 * @dev The Dubiex contract
 *
 * Supported currencies:
 * - ETH
 * - ERC20
 * - BoostedERC20
 * - ERC721
 *
 * Any owner of ERC721 tokens may wish to approve Dubiex for all his/her tokens,
 * by calling `setApprovalForAll()`. Then approval for subsequent trades isn't required either.
 *
 * ERC20 can be approved once with an practically-infinite amount, then Dubiex requires
 * approval only once as well.
 *
 * BoostedERC20 tokens are designed to work without any explicit approval for Dubiex.
 *
 * External functions:
 * - makeOrder(s)
 * - takeOrder(s)
 * - cancelOrder(s)
 * - getOrder()
 * - boostedMakeOrder(Batch)
 * - boostedTakeOrder(Batch)
 * - boostedCanceleOrder(Batch)
 *
 */
contract Dubiex is ReentrancyGuard, ERC721Holder, Boostable {
    using SafeERC20 for IERC20;

    bytes32 private constant _BOOSTABLE_ERC20_TOKEN_HASH = keccak256(
        "BoostableERC20Token"
    );

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.1.0/contracts/token/ERC721/ERC721.sol#L68
    bytes4 private constant _ERC721_INTERFACE_HASH = 0x80ac58cd;

    IERC1820Registry private constant _ERC1820_REGISTRY = IERC1820Registry(
        0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24
    );

    // This is a empty order to workaround:
    // "This variable is of storage pointer type and can be accessed without prior assignment, which would lead to undefined behaviour"
    // In places where we need to return a zero-initialized storage order.
    DubiexLib.PackedOrderBookItem private emptyOrder;

    // Only required for burning fuel
    address private immutable _prps;
    address private immutable _dubi;

    // Security mechanism which anyone can enable if the total supply of PRPS or DUBI should ever go >= 1 billion
    bool private _killSwitchOn;

    function activateKillSwitch() public {
        require(!_killSwitchOn, "Dubiex: kill switch already on");

        uint256 oneBillion = 1000000000 * 1 ether;

        uint256 totalPrpsSupply = IERC20(_prps).totalSupply();
        uint256 totalDubiSupply = IERC20(_dubi).totalSupply();

        require(
            totalPrpsSupply >= oneBillion || totalDubiSupply >= oneBillion,
            "Dubiex: insufficient total supply for kill switch"
        );
        _killSwitchOn = true;
    }

    constructor(
        address optIn,
        address prps,
        address dubi
    ) public ReentrancyGuard() Boostable(optIn) {
        _prps = prps;
        _dubi = dubi;
    }

    event MadeOrder(
        uint32 id,
        address maker,
        // uint96 makerValue, uint96 takerValue, uint32 orderPairAlias, uint32 padding
        uint256 packedData
    );

    event TookOrder(
        uint32 id,
        address maker,
        address taker,
        // uint96 makerValue, uint96 takerValue, uint32 orderPairAlias, uint32 padding
        uint256 packedData
    );
    event CanceledOrder(address maker, uint32 id);

    event UpdatedOrder(address maker, uint32 id);

    /**
     * @dev Order pair aliases are generated by incrementing a number. Although the counter
     * is using 32 bits, we do not support more than 2**28 = 268_435_456 pairs for technical reasons.
     */
    uint32 private _orderPairAliasCounter;

    /**
     * @dev A mapping of order pair alias to a packed order pair.
     */
    mapping(uint32 => DubiexLib.PackedOrderPair) private _orderPairsByAlias;
    /**
     * @dev A reverse mapping of order pair hash to an order pair alias. Required to check if
     * a given pair already exists when creating an order where the full pair information are
     * provided instead of an alias. I.e.
     * MakeOrder {
     *    ...
     *    makerCurrencyType: ...,
     *    takerCurrencyType: ...,
     *    makerContractAddress: ...,
     *    takerContractAddress: ...,
     * }
     *
     * The hash of these four fields is used as the key of the mapping.
     */
    mapping(bytes32 => uint32) private _orderPairAliasesByHash;

    /**
     * @dev Mapping of address to a counter for order ids.
     */
    mapping(address => uint32) private _counters;

    /**
     * @dev Mapping of address to packed order book items.
     */
    mapping(address => DubiexLib.PackedOrderBookItem[])
        private _ordersByAddress;

    /**
     * @dev Get an order by id. If the id doesn't exist (e.g. got cancelled / filled), a default order is returned.
     * The caller should therefore check the id of the returned item. Any non-zero value means the order exists.
     */
    function getOrder(address maker, uint64 id)
        public
        view
        returns (DubiexLib.PrettyOrderBookItem memory)
    {

            DubiexLib.PackedOrderBookItem[] storage orders
         = _ordersByAddress[maker];
        for (uint256 i = 0; i < orders.length; i++) {
            DubiexLib.PackedOrderBookItem storage _packed = orders[i];
            DubiexLib.UnpackedOrderBookItem memory _unpacked = DubiexLib
                .unpackOrderBookItem(_packed.packedData);

            if (_unpacked.id == id) {
                DubiexLib.PrettyOrderBookItem memory pretty;
                pretty.id = _unpacked.id;
                pretty.makerValue = _unpacked.makerValue;
                pretty.takerValue = _unpacked.takerValue;

                pretty.orderPairAlias = _unpacked.orderPairAlias;
                pretty.pair = getOrderPairByAlias(_unpacked.orderPairAlias);

                pretty.flags = _unpacked.flags;

                pretty.successorOrderId = _packed.successorOrderId;
                pretty.ancestorOrderId = _packed.ancestorOrderId;

                return pretty;
            }
        }

        DubiexLib.PrettyOrderBookItem memory empty;
        return empty;
    }

    /**
     * @dev Get an order pair by alias.
     */
    function getOrderPairByAlias(uint32 orderPairAlias)
        public
        view
        returns (DubiexLib.OrderPair memory)
    {
        DubiexLib.OrderPair memory orderPair;


            DubiexLib.PackedOrderPair storage packedOrderPair
         = _orderPairsByAlias[orderPairAlias];

        (
            address makerContractAddress,
            DubiexLib.CurrencyType makerCurrencyType
        ) = DubiexLib.unpackOrderPairAddressType(packedOrderPair.makerPair);

        (
            address takerContractAddress,
            DubiexLib.CurrencyType takerCurrencyType
        ) = DubiexLib.unpackOrderPairAddressType(packedOrderPair.takerPair);

        orderPair.makerContractAddress = makerContractAddress;
        orderPair.makerCurrencyType = makerCurrencyType;
        orderPair.takerContractAddress = takerContractAddress;
        orderPair.takerCurrencyType = takerCurrencyType;

        return orderPair;
    }

    /**
     * @dev Get an order pair by it's hash.
     */
    function getOrderPairByHash(bytes32 orderPairHash)
        public
        view
        returns (DubiexLib.OrderPair memory)
    {
        uint32 orderPairAlias = _orderPairAliasesByHash[orderPairHash];
        return getOrderPairByAlias(orderPairAlias);
    }

    /**
     * @dev Get an order pair alias by it's hash.
     */
    function getOrderPairAliasByHash(bytes32 orderPairHash)
        public
        view
        returns (uint32)
    {
        return _orderPairAliasesByHash[orderPairHash];
    }

    /**
     * @dev Make a single order. Reverts on failure.
     *
     * If an `orderId` is provided, an already existing order will be updated
     * according to `updatedWeiRatio`. For efficiency reasons, the id of the updated order
     * remains the same. Taker orders provide a minimum ratio to protect themselves against
     * front-running by the maker.
     *
     * Returns the assigned order id.
     */
    function makeOrder(DubiexLib.MakeOrderInput memory input)
        external
        payable
        nonReentrant
        returns (uint32)
    {
        require(!_killSwitchOn, "Dubiex: make order prevented by kill switch");

        uint256 excessEth = msg.value;
        uint32 orderId;

        (orderId, excessEth) = _makeOrderInternal({
            input: input,
            maker: msg.sender,
            excessEthAndIntrinsicFuel: excessEth,
            isBoosted: false,
            revertOnUpdateError: true
        });

        _refundExcessEth(excessEth);

        return orderId;
    }

    /**
     * @dev Create multiple orders at once. The transaction won't revert if any make order fails, but
     * silently ignore it. Returns an array of order ids where each item corresponds to an input
     * at the same index and non-zero values indicate success.
     */
    function makeOrders(DubiexLib.MakeOrderInput[] memory inputs)
        external
        payable
        nonReentrant
        returns (uint32[] memory)
    {
        require(!_killSwitchOn, "Dubiex: make order prevented by kill switch");
        require(inputs.length > 0, "Dubiex: empty inputs");

        uint32[] memory orderIds = new uint32[](inputs.length);

        uint256 excessEth = msg.value;

        for (uint256 i = 0; i < inputs.length; i++) {
            uint32 orderId;

            (orderId, excessEth) = _makeOrderInternal({
                input: inputs[i],
                maker: msg.sender,
                excessEthAndIntrinsicFuel: excessEth,
                isBoosted: false,
                revertOnUpdateError: false
            });

            orderIds[i] = orderId;
        }

        _refundExcessEth(excessEth);

        return orderIds;
    }

    /**
     * @dev Take a single order. Reverts on failure.
     */
    function takeOrder(DubiexLib.TakeOrderInput calldata input)
        external
        payable
        nonReentrant
    {
        require(!_killSwitchOn, "Dubiex: take order prevented by kill switch");

        uint256 excessEth = msg.value;

        (, excessEth, ) = _takeOrderInternal({
            input: input,
            taker: msg.sender,
            excessEthAndIntrinsicFuel: excessEth,
            revertOnError: true,
            isBoosted: false
        });

        _refundExcessEth(excessEth);
    }

    /**
     * @dev Take multiple orders at once. The transaction won't revert if any take order fails, but
     * silently ignore it. Check the logs in the receipt to see if any failed.
     *
     * See `takeOrder` for more information about the opt-in.
     *
     * @param inputs the take order inputs
     */
    function takeOrders(DubiexLib.TakeOrderInput[] calldata inputs)
        external
        payable
        nonReentrant
        returns (bool[] memory)
    {
        require(!_killSwitchOn, "Dubiex: take order prevented by kill switch");
        require(inputs.length > 0, "Dubiex: empty inputs");

        bool[] memory result = new bool[](inputs.length);

        uint256 excessEth = msg.value;

        for (uint256 i = 0; i < inputs.length; i++) {
            bool success;
            (success, excessEth, ) = _takeOrderInternal({
                input: inputs[i],
                taker: msg.sender,
                excessEthAndIntrinsicFuel: uint96(excessEth),
                revertOnError: false,
                isBoosted: false
            });

            result[i] = success;
        }

        _refundExcessEth(excessEth);

        return result;
    }

    /**
     * @dev Cancel a single order.
     */
    function cancelOrder(DubiexLib.CancelOrderInput memory input)
        external
        nonReentrant
    {
        _cancelOrderInternal({
            maker: input.maker,
            id: input.id,
            intrinsicFuel: 0,
            isBoosted: false,
            revertOnError: true,
            isKillSwitchOn: _killSwitchOn
        });
    }

    /**
     * @dev Cancel multiple orders at once. It will not revert on error, but ignore failed
     * orders silently. Check the logs in the receipt to see if any failed.
     *
     * @return Array of booleans with `ids.length` items where each item corresponds to an id
     * at the same index and `true` indicate success.
     */
    function cancelOrders(DubiexLib.CancelOrderInput[] calldata inputs)
        external
        nonReentrant
        returns (bool[] memory)
    {
        require(inputs.length > 0, "Dubiex: empty inputs");

        bool[] memory result = new bool[](inputs.length);

        bool isKillSwitchOn = _killSwitchOn;

        for (uint256 i = 0; i < inputs.length; i++) {
            result[i] = _cancelOrderInternal({
                maker: inputs[i].maker,
                id: inputs[i].id,
                intrinsicFuel: 0,
                isBoosted: false,
                revertOnError: false,
                isKillSwitchOn: isKillSwitchOn
            });
        }

        return result;
    }

    /**
     * @dev Create an order for the signer of `signature`.
     */
    function boostedMakeOrder(
        BoostedMakeOrder memory order,
        Signature memory signature
    ) public payable nonReentrant returns (uint32) {
        require(!_killSwitchOn, "Dubiex: make order prevented by kill switch");

        uint32 orderId;
        uint256 excessEth = msg.value;
        (orderId, excessEth) = _boostedMakeOrderInternal(
            order,
            signature,
            excessEth,
            true
        );

        _refundExcessEth(excessEth);
        return orderId;
    }

    function _boostedMakeOrderInternal(
        BoostedMakeOrder memory order,
        Signature memory signature,
        uint256 excessEth,
        bool revertOnUpdateError
    ) private returns (uint32, uint256) {
        uint96 intrinsicFuel = _burnFuel(order.maker, order.fuel);

        // We optimize ERC721 sell orders by not increasing the
        // nonce, because every ERC721 is unique - trying to replay the
        // transaction while the signature hasn't expired yet is almost
        // guaranteed to always fail. The only scenarios where it would be
        // possible is:
        // - if the order gets cancelled
        // - the order is filled by the maker OR the taker sends it back to the maker
        //
        // But this all has to happen in a very short timeframe, so the chance of this happening
        // is really low.
        //
        if (
            order.input.pair.makerCurrencyType == DubiexLib.CurrencyType.ERC721
        ) {
            _verifyBoostWithoutNonce(
                order.maker,
                hashBoostedMakeOrder(order, msg.sender),
                order.boosterPayload,
                signature
            );
        } else {
            verifyBoost(
                order.maker,
                hashBoostedMakeOrder(order, msg.sender),
                order.boosterPayload,
                signature
            );
        }

        uint32 orderId;

        // Encode the intrinsic fuel in the upper bits of the excess eth,
        // because we are hitting 'CompilerError: Stack too deep'.
        uint256 excessEthAndIntrinsicFuel = excessEth;
        excessEthAndIntrinsicFuel |= uint256(intrinsicFuel) << 96;

        (orderId, excessEth) = _makeOrderInternal({
            maker: order.maker,
            input: order.input,
            excessEthAndIntrinsicFuel: excessEthAndIntrinsicFuel,
            isBoosted: true,
            revertOnUpdateError: revertOnUpdateError
        });

        return (orderId, excessEth);
    }

    /**
     * @dev Take an order for the signer of `signature`.
     */
    function boostedTakeOrder(
        BoostedTakeOrder memory order,
        Signature memory signature
    ) public payable nonReentrant {
        require(!_killSwitchOn, "Dubiex: take order prevented by kill switch");

        uint256 excessEth = _boostedTakeOrderInternal({
            order: order,
            signature: signature,
            excessEth: msg.value,
            revertOnError: true
        });

        _refundExcessEth(excessEth);
    }

    function _boostedTakeOrderInternal(
        BoostedTakeOrder memory order,
        Signature memory signature,
        uint256 excessEth,
        bool revertOnError
    ) private returns (uint256) {
        uint96 intrinsicFuel = _burnFuel(order.taker, order.fuel);

        // Encode the intrinsic fuel in the upper bits of the excess eth,
        // because we are hitting 'CompilerError: Stack too deep'.
        uint256 excessEthAndIntrinsicFuel = excessEth;
        excessEthAndIntrinsicFuel |= uint256(intrinsicFuel) << 96;

        DubiexLib.CurrencyType takerCurrencyType;
        (, excessEth, takerCurrencyType) = _takeOrderInternal({
            input: order.input,
            taker: order.taker,
            excessEthAndIntrinsicFuel: excessEthAndIntrinsicFuel,
            revertOnError: revertOnError,
            isBoosted: true
        });

        // We optimize ERC721 take orders by not increasing the
        // nonce, because every ERC721 is unique - trying to replay the
        // transaction will always fail, since once taken - the target order doesn't
        // exist anymore and thus cannot be filled ever again.
        if (takerCurrencyType == DubiexLib.CurrencyType.ERC721) {
            _verifyBoostWithoutNonce(
                order.taker,
                hashBoostedTakeOrder(order, msg.sender),
                order.boosterPayload,
                signature
            );
        } else {
            verifyBoost(
                // The signer of the boosted message
                order.taker,
                hashBoostedTakeOrder(order, msg.sender),
                order.boosterPayload,
                signature
            );
        }

        return excessEth;
    }

    /**
     * @dev Cancel an order for the signer of `signature`.
     */
    function boostedCancelOrder(
        BoostedCancelOrder memory order,
        Signature memory signature
    ) public payable nonReentrant {
        bool isKillSwitchOn = _killSwitchOn;
        _boostedCancelOrderInternal(order, signature, true, isKillSwitchOn);
    }

    function _boostedCancelOrderInternal(
        BoostedCancelOrder memory order,
        Signature memory signature,
        bool reverOnError,
        bool isKillSwitchOn
    ) private {
        uint96 intrinsicFuel = _burnFuel(order.input.maker, order.fuel);

        // We do not need a nonce, since once cancelled the order id can never be re-used again
        _verifyBoostWithoutNonce(
            order.input.maker,
            hashBoostedCancelOrder(order, msg.sender),
            order.boosterPayload,
            signature
        );

        // Encode the intrinsic fuel in the upper bits of the excess eth,
        // (which for cancel order is always 0), because we are hitting 'CompilerError: Stack too deep'.
        uint256 excessEthAndIntrinsicFuel;
        excessEthAndIntrinsicFuel |= uint256(intrinsicFuel) << 96;

        _cancelOrderInternal({
            maker: order.input.maker,
            id: order.input.id,
            isBoosted: true,
            intrinsicFuel: excessEthAndIntrinsicFuel,
            revertOnError: reverOnError,
            isKillSwitchOn: isKillSwitchOn
        });
    }

    /**
     * @dev Perform multiple `boostedMakeOrder` calls in a single transaction.
     */
    function boostedMakeOrderBatch(
        BoostedMakeOrder[] calldata orders,
        Signature[] calldata signatures
    ) external payable nonReentrant {
        require(!_killSwitchOn, "Dubiex: make order prevented by kill switch");
        require(
            orders.length > 0 && orders.length == signatures.length,
            "Dubiex: invalid input lengths"
        );

        uint256 excessEth = msg.value;

        for (uint256 i = 0; i < orders.length; i++) {
            (, excessEth) = _boostedMakeOrderInternal(
                orders[i],
                signatures[i],
                uint96(excessEth),
                false
            );
        }
    }

    /**
     * @dev Perform multiple `boostedTakeOrder` calls in a single transaction.
     */
    function boostedTakeOrderBatch(
        BoostedTakeOrder[] memory boostedTakeOrders,
        Signature[] calldata signatures
    ) external payable nonReentrant {
        require(!_killSwitchOn, "Dubiex: take order prevented by kill switch");
        require(
            boostedTakeOrders.length > 0 &&
                boostedTakeOrders.length == signatures.length,
            "Dubiex: invalid input lengths"
        );

        uint256 excessEth = msg.value;
        for (uint256 i = 0; i < boostedTakeOrders.length; i++) {
            excessEth = _boostedTakeOrderInternal(
                boostedTakeOrders[i],
                signatures[i],
                uint96(excessEth),
                false
            );
        }

        _refundExcessEth(excessEth);
    }

    /**
     * @dev Perform multiple `boostedCancelOrder` calls in a single transaction.
     */
    function boostedCancelOrderBatch(
        BoostedCancelOrder[] memory orders,
        Signature[] calldata signatures
    ) external payable nonReentrant returns (uint32) {
        require(
            orders.length > 0 && orders.length == signatures.length,
            "Dubiex: invalid input lengths"
        );

        bool isKillSwitchOn = _killSwitchOn;

        for (uint256 i = 0; i < orders.length; i++) {
            _boostedCancelOrderInternal(
                orders[i],
                signatures[i],
                false,
                isKillSwitchOn
            );
        }
    }

    /**
     * @dev Create a new single order.
     *
     * @return the assigned order id
     */
    function _makeOrderInternal(
        DubiexLib.MakeOrderInput memory input,
        address payable maker,
        uint256 excessEthAndIntrinsicFuel,
        bool isBoosted,
        bool revertOnUpdateError
    ) private returns (uint32, uint256) {
        require(
            maker != address(this) && maker != address(0),
            "Dubiex: unexpected maker"
        );

        // An explicit id means an existing order should be updated.
        if (input.orderId > 0) {
            return (
                _updateOrder(
                    maker,
                    input.orderId,
                    input.updatedRatioWei,
                    revertOnUpdateError
                ),
                // Update order never uses eth, so we refund everything in case something was mistakenly sent
                uint96(excessEthAndIntrinsicFuel)
            );
        }

        // Reverts if the input is invalid
        require(input.makerValue > 0, "Dubiex: makerValue must be greater 0");
        require(input.takerValue > 0, "Dubiex: takerValue must be greater 0");

        // Reverts if the order pair is incompatible
        uint32 orderPairAlias = _getOrCreateOrderPairAlias(input.pair);

        // Deposit the makerValue, which will fail if no approval has been given
        // or the maker hasn't enough funds.
        // NOTE(reentrancy): safe, because we are using `nonReentrant` for makeOrder(s).
        // NOTE2: _transfer returns the *excessEth* only, but we reuse the 'excessEthAndIntrinsicFuel' variable
        // to work around 'CompilerError: Stack too deep'.
        bool deposited;

        (deposited, excessEthAndIntrinsicFuel) = _transfer({
            from: maker,
            to: payable(address(this)),
            value: input.makerValue,
            valueContractAddress: input.pair.makerContractAddress,
            valueCurrencyType: input.pair.makerCurrencyType,
            excessEthAndIntrinsicFuel: excessEthAndIntrinsicFuel,
            isBoosted: isBoosted
        });

        require(deposited, "Dubiex: failed to deposit. not enough funds?");

        // Create the orderbook item
        DubiexLib.PackedOrderBookItem memory _packed;

        DubiexLib.UnpackedOrderBookItem memory _unpacked;
        _unpacked.id = _getNextOrderId(maker);
        _unpacked.makerValue = input.makerValue;
        _unpacked.takerValue = input.takerValue;
        _unpacked.orderPairAlias = orderPairAlias;
        _unpacked.flags.isMakerERC721 =
            input.pair.makerCurrencyType == DubiexLib.CurrencyType.ERC721;
        _unpacked.flags.isTakerERC721 =
            input.pair.takerCurrencyType == DubiexLib.CurrencyType.ERC721;

        // Update ancestor order if any
        _updateOrderAncestorIfAny(input, maker, _unpacked, _packed);

        // Pack unpacked data and write to storage
        _packed.packedData = DubiexLib.packOrderBookItem(_unpacked);
        _ordersByAddress[maker].push(_packed);

        // Emit event and done

        uint256 packedData;
        packedData |= input.makerValue;
        packedData |= uint256(input.takerValue) << 96;
        packedData |= uint256(orderPairAlias) << (96 + 96);

        emit MadeOrder(_unpacked.id, maker, packedData);

        return (_unpacked.id, excessEthAndIntrinsicFuel);
    }

    function _updateOrderAncestorIfAny(
        DubiexLib.MakeOrderInput memory input,
        address maker,
        DubiexLib.UnpackedOrderBookItem memory unpacked,
        DubiexLib.PackedOrderBookItem memory packed
    ) private {
        // If an ancestor is provided, we check if it exists and try to make this order
        // an successor of it. If it succeeds, then this order ends up being hidden.
        if (input.ancestorOrderId > 0) {
            packed.ancestorOrderId = input.ancestorOrderId;

            bool success = _setSuccessorOfAncestor(
                maker,
                input.ancestorOrderId,
                unpacked.id
            );

            // New successor order must be hidden if it has an existing ancestor now
            unpacked.flags.isHidden = success;
        }
    }

    /**
     * @dev Take a make order.
     * @param input the take order input.
     * @param taker address of the taker
     * @param revertOnError whether to revert on errors or not. True, when taking a single order.
     *
     */
    function _takeOrderInternal(
        address payable taker,
        DubiexLib.TakeOrderInput memory input,
        uint256 excessEthAndIntrinsicFuel,
        bool revertOnError,
        bool isBoosted
    )
        private
        returns (
            bool,
            uint256,
            DubiexLib.CurrencyType
        )
    {
        (
            DubiexLib.PackedOrderBookItem storage _packed,
            DubiexLib.UnpackedOrderBookItem memory _unpacked,
            uint256 index
        ) = _assertTakeOrderInput(input, revertOnError);

        // Order doesn't exist or input is invalid.
        if (_unpacked.id == 0) {
            // Only gets here if 'revertOnError' is false
            return (
                false,
                uint96(excessEthAndIntrinsicFuel),
                DubiexLib.CurrencyType.NULL
            );
        }

        // Get the actual makerValue, which might just be a fraction of the total
        // `takerValue` of the `_makeOrder`.
        (uint96 _makerValue, uint96 _takerValue) = _calculateMakerAndTakerValue(
            _unpacked,
            input.takerValue,
            input.maxTakerMakerRatio
        );
        if (_makerValue == 0 || _takerValue == 0) {
            if (revertOnError) {
                revert("Dubiex: invalid takerValue");
            }

            return (
                false,
                uint96(excessEthAndIntrinsicFuel),
                DubiexLib.CurrencyType.NULL
            );
        }

        // Transfer from taker to maker
        // NOTE(reentrancy): `takeOrder(s)` is marked nonReentrant
        // NOTE2: _transferFromTakerToMaker returns the *excessEth* only, but we reuse the 'excessEthAndIntrinsicFuel' variable
        // to work around 'CompilerError: Stack too deep'.
        excessEthAndIntrinsicFuel = _transferFromTakerToMaker(
            taker,
            input.maker,
            _takerValue,
            _unpacked.pair,
            excessEthAndIntrinsicFuel,
            isBoosted
        );

        // Transfer from maker to taker
        // NOTE(reentrancy): `takeOrder(s)` is marked nonReentrant
        if (
            !_transferFromContractToTaker(
                taker,
                _makerValue,
                _unpacked.pair,
                false,
                0
            )
        ) {
            if (revertOnError) {
                revert("Dubiex: failed to transfer value to taker");
            }

            return (
                false,
                excessEthAndIntrinsicFuel,
                DubiexLib.CurrencyType.NULL
            );
        }

        // If filled, the order can be deleted (without having to update the maker/taker value)
        if (_unpacked.makerValue - _makerValue == 0) {
            // Make successor of filled order visible if any.
            if (_unpacked.flags.hasSuccessor) {
                _setOrderVisible(input.maker, _packed.successorOrderId);
            }

            // Delete the filled order
            _deleteOrder({maker: input.maker, index: index});
        } else {
            // Not filled yet, so update original make order
            _unpacked.makerValue -= _makerValue;
            _unpacked.takerValue -= _takerValue;

            // Write updated item to storage
            _packed.packedData = DubiexLib.packOrderBookItem(_unpacked);
        }

        // NOTE: We write the new taker/maker value to the in-memory struct
        // and pass it to a function that emits 'TookOrder' to avoid the 'Stack too deep' error
        _unpacked.makerValue = _makerValue;
        _unpacked.takerValue = _takerValue;

        return
            _emitTookOrder(
                input.maker,
                taker,
                _unpacked,
                excessEthAndIntrinsicFuel
            );
    }

    /**
     * @dev Emit 'TookOrder' in a separate function to avoid the 'Stack too deep' error
     */
    function _emitTookOrder(
        address maker,
        address taker,
        DubiexLib.UnpackedOrderBookItem memory unpacked,
        uint256 excessEthAndIntrinsicFuel
    )
        private
        returns (
            bool,
            uint256,
            DubiexLib.CurrencyType
        )
    {
        uint256 packedData;
        packedData |= unpacked.makerValue;
        packedData |= uint256(unpacked.takerValue) << 96;
        packedData |= uint256(unpacked.orderPairAlias) << (96 + 96);

        emit TookOrder(unpacked.id, maker, taker, packedData);

        return (
            true,
            excessEthAndIntrinsicFuel,
            unpacked.pair.takerCurrencyType
        );
    }

    /**
     * @dev Cancel an order
     * @param maker the maker of the order
     * @param id the id of the order to cancel
     * @param revertOnError whether to revert on errors or not
     */
    function _cancelOrderInternal(
        address payable maker,
        uint32 id,
        uint256 intrinsicFuel,
        bool isBoosted,
        bool revertOnError,
        bool isKillSwitchOn
    ) private returns (bool) {
        // Anyone can cancel any order if the kill switch is on.
        // For efficiency, we do not need to check the kill switch if this is a boosted cancel order,
        // because in that case we already have the explicit consent of the maker.
        // If it's neither a boosted cancel nor a post-kill switch cancel, the msg.sender must be the maker.
        if (!isBoosted && !isKillSwitchOn) {
            require(maker == msg.sender, "Dubiex: msg.sender must be maker");
        }

        if (!revertOnError && !_orderExists(maker, id)) {
            return false;
        }

        // Get the make order (reverts if order doesn't exist)
        (
            ,
            DubiexLib.UnpackedOrderBookItem memory unpacked,
            uint256 index
        ) = _safeGetOrder(maker, id, DubiexLib.OrderPairReadStrategy.MAKER);

        // Transfer remaining `makerValue` back to maker, by assuming the taker role with the maker.

        // NOTE(reentrancy): `cancelOrder(s)` is marked nonReentrant
        if (
            !_transferFromContractToTaker({
                taker: maker,
                makerValue: unpacked.makerValue,
                pair: unpacked.pair,
                isBoosted: isBoosted,
                excessEthAndIntrinsicFuel: intrinsicFuel
            })
        ) {
            return false;
        }

        // Delete the cancelled order
        _deleteOrder({maker: maker, index: index});

        emit CanceledOrder(maker, id);

        return true;
    }

    /**
     * @dev Update the `takerValue` of an order using the given `updatedRatioWei`
     * @param maker the maker of the order to update
     * @param orderId the id of the existing order
     * @param updatedRatioWei the new ratio in wei
     */
    function _updateOrder(
        address maker,
        uint32 orderId,
        uint128 updatedRatioWei,
        bool revertOnUpdateError
    ) private returns (uint32) {
        (
            DubiexLib.PackedOrderBookItem storage _packed,
            DubiexLib.UnpackedOrderBookItem memory _unpacked,

        ) = _getOrder(maker, orderId, DubiexLib.OrderPairReadStrategy.SKIP);

        // Order doesn't exist
        if (_unpacked.id == 0) {
            if (revertOnUpdateError) {
                revert("Dubiex: order does not exist");
            }

            return 0;
        }

        // We don't prevent reverts here, even if `revertOnUpdateError` is false since
        // they are user errors unlike a non-existing order which a user has no control over.

        require(updatedRatioWei > 0, "Dubiex: ratio is 0");

        require(
            !_unpacked.flags.isMakerERC721 && !_unpacked.flags.isTakerERC721,
            "Dubiex: cannot update ERC721 value"
        );

        // Update the existing order with the new ratio to the takerValue.
        // The makerValue stays untouched.

        uint256 updatedTakerValue = (uint256(_unpacked.makerValue) *
            uint256(updatedRatioWei)) / 1 ether;

        require(updatedTakerValue < 2**96, "Dubiex: takerValue overflow");

        _unpacked.takerValue = uint96(updatedTakerValue);
        _packed.packedData = DubiexLib.packOrderBookItem(_unpacked);

        emit UpdatedOrder(maker, orderId);

        return orderId;
    }

    // If both returned values are > 0, then the provided `takerValue` and `maxTakerMakerRatio` are valid.
    function _calculateMakerAndTakerValue(
        DubiexLib.UnpackedOrderBookItem memory _unpacked,
        uint96 takerValue,
        uint256 maxTakerMakerRatio
    ) private pure returns (uint96, uint96) {
        uint256 calculatedMakerValue = _unpacked.makerValue;
        uint256 calculatedTakerValue = takerValue;

        // ERC721 cannot be bought/sold partially, therefore the `takerValue` must match the requested
        // value exactly.
        if (
            _unpacked.pair.makerCurrencyType == DubiexLib.CurrencyType.ERC721 ||
            _unpacked.pair.takerCurrencyType == DubiexLib.CurrencyType.ERC721
        ) {
            if (takerValue != _unpacked.takerValue) {
                return (0, 0);
            }

            // The order gets filled completely, so we use the values as is.
        } else {
            // Calculate the current takerMakerValue ratio and compare it to `maxTakerMakerRatio`.
            // If it is higher then the order will not be taken.
            uint256 takerMakerRatio = (uint256(_unpacked.takerValue) *
                1 ether) / calculatedMakerValue;

            if (maxTakerMakerRatio < takerMakerRatio) {
                return (0, 0);
            }

            if (calculatedTakerValue > _unpacked.takerValue) {
                calculatedTakerValue = _unpacked.takerValue;
            }

            // Calculate actual makerValue for ETH/ERC20 trades which might only get partially filled by the
            // takerValue. Since we don't have decimals, we need to multiply by 10^18 and divide by it again at the end
            // to not lose any information.
            calculatedMakerValue *= 1 ether;
            calculatedMakerValue *= calculatedTakerValue;
            calculatedMakerValue /= _unpacked.takerValue;
            calculatedMakerValue /= 1 ether;
        }

        // Sanity checks
        assert(
            calculatedMakerValue < 2**96 &&
                calculatedMakerValue <= _unpacked.makerValue
        );
        assert(
            calculatedTakerValue < 2**96 &&
                calculatedTakerValue <= _unpacked.takerValue
        );

        return (uint96(calculatedMakerValue), uint96(calculatedTakerValue));
    }

    /**
     * @dev Assert a take order input and return the order. If a zero-order is returned,
     * then it does not exist and it is up to the caller how to handle it.
     */
    function _assertTakeOrderInput(
        DubiexLib.TakeOrderInput memory input,
        bool revertOnError
    )
        private
        view
        returns (
            DubiexLib.PackedOrderBookItem storage,
            DubiexLib.UnpackedOrderBookItem memory,
            uint256 // index
        )
    {
        (
            DubiexLib.PackedOrderBookItem storage packed,
            DubiexLib.UnpackedOrderBookItem memory unpacked,
            uint256 index
        ) = _getOrder(
            input.maker,
            input.id,
            DubiexLib.OrderPairReadStrategy.FULL
        );

        bool validTakerValue = input.takerValue > 0;
        bool orderExistsAndNotHidden = unpacked.id > 0 &&
            !unpacked.flags.isHidden;
        if (revertOnError) {
            require(validTakerValue, "Dubiex: takerValue must be greater 0");

            require(orderExistsAndNotHidden, "Dubiex: order does not exist");
        } else {
            if (!validTakerValue || !orderExistsAndNotHidden) {
                DubiexLib.UnpackedOrderBookItem memory emptyUnpacked;
                return (emptyOrder, emptyUnpacked, 0);
            }
        }

        return (packed, unpacked, index);
    }

    function _orderExists(address maker, uint32 id)
        private
        view
        returns (bool)
    {
        // Since we don't want to revert for cancelOrders, we have to check that the order
        // (maker, id) exists by looping over the orders of the maker and comparing the id.


            DubiexLib.PackedOrderBookItem[] storage orders
         = _ordersByAddress[maker];

        uint256 length = orders.length;
        for (uint256 i = 0; i < length; i++) {
            // The first 32 bits of the packed data corresponds to the id. By casting to uint32,
            // we can compare the id without having to unpack the entire thing.
            uint32 orderId = uint32(orders[i].packedData);
            if (orderId == id) {
                // Found order
                return true;
            }
        }

        // Doesn't exist
        return false;
    }

    function _refundExcessEth(uint256 excessEth) private {
        // Casting to uint96 to get rid off any of the higher utility bits
        excessEth = uint96(excessEth);

        // Sanity check
        assert(msg.value >= excessEth);

        if (excessEth > 0) {
            msg.sender.transfer(excessEth);
        }
    }

    // Transfer `takerValue` to `maker`.
    function _transferFromTakerToMaker(
        address payable taker,
        address payable maker,
        uint96 takerValue,
        DubiexLib.OrderPair memory pair,
        uint256 excessEthAndIntrinsicFuel,
        bool isBoosted
    ) private returns (uint256) {
        (bool success, uint256 excessEth) = _transfer(
            taker,
            maker,
            takerValue,
            pair.takerContractAddress,
            pair.takerCurrencyType,
            excessEthAndIntrinsicFuel,
            isBoosted
        );

        require(success, "Dubiex: failed to transfer value to maker");

        return excessEth;
    }

    // Transfer `makerValue` to `taker`
    function _transferFromContractToTaker(
        address payable taker,
        uint96 makerValue,
        DubiexLib.OrderPair memory pair,
        bool isBoosted,
        uint256 excessEthAndIntrinsicFuel
    ) private returns (bool) {
        (bool success, ) = _transfer(
            payable(address(this)),
            taker,
            makerValue,
            pair.makerContractAddress,
            pair.makerCurrencyType,
            excessEthAndIntrinsicFuel,
            isBoosted
        );

        return success;
    }

    function _transfer(
        address payable from,
        address payable to,
        uint256 value,
        address valueContractAddress,
        DubiexLib.CurrencyType valueCurrencyType,
        uint256 excessEthAndIntrinsicFuel,
        bool isBoosted
    ) private returns (bool, uint256) {
        uint256 excessEth = uint96(excessEthAndIntrinsicFuel);
        if (valueCurrencyType == DubiexLib.CurrencyType.ETH) {
            // Eth is a bit special, because it's not a token. Therefore we need to ensure
            // that the taker/maker sent enough eth (`excessEth` >= `value`) and also that
            // he is refunded at the end of the transaction properly.
            if (from != address(this)) {
                if (excessEth < value) {
                    return (false, excessEth);
                }

                // Got enough eth, but maybe too much, so we subtract the value from the excessEth. This is important
                // to refund the sender correctly e.g. he mistakenly sent too much or the order
                // was partially filled while his transaction was pending.
                excessEth -= value;
            }

            // Not a deposit, so transfer eth owned by this contract to maker or taker
            if (to != address(this)) {
                to.transfer(value);
            }

            return (true, excessEth);
        }

        if (valueCurrencyType == DubiexLib.CurrencyType.ERC20) {
            IERC20 erc20 = IERC20(valueContractAddress);
            uint256 recipientBalanceBefore = erc20.balanceOf(to);

            if (from == address(this)) {
                // If sending own tokens, use `safeTransfer` because Dubiex doesn't have any allowance
                // for itself which would cause `safeTransferFrom` to fail.
                erc20.safeTransfer(to, value);
            } else {
                erc20.safeTransferFrom(from, to, value);
            }

            uint256 recipientBalanceAfter = erc20.balanceOf(to);
            // Safe guard to minimize the risk of getting buggy orders if the contract
            // deviates from the ERC20 standard.
            require(
                recipientBalanceAfter == recipientBalanceBefore + value,
                "Dubiex: failed to transfer ERC20 token"
            );

            return (true, excessEth);
        }

        if (valueCurrencyType == DubiexLib.CurrencyType.BOOSTABLE_ERC20) {
            IBoostableERC20 erc20 = IBoostableERC20(valueContractAddress);

            if (from == address(this)) {
                // If sending own tokens, use `safeTransfer`, because Dubiex doesn't have any allowance
                // for itself which would cause `permissionSend` to fail.
                IERC20(address(erc20)).safeTransfer(to, value);
            } else {
                bool success = erc20.boostedTransferFrom(
                    from,
                    to,
                    value,
                    abi.encodePacked(isBoosted)
                );

                require(
                    success,
                    "Dubiex: failed to transfer boosted ERC20 token"
                );
            }

            return (true, excessEth);
        }

        if (valueCurrencyType == DubiexLib.CurrencyType.ERC721) {
            IERC721 erc721 = IERC721(valueContractAddress);

            // Pass isBoosted flag + fuel if any
            erc721.safeTransferFrom(
                from,
                to,
                value,
                abi.encodePacked(
                    isBoosted,
                    uint96(excessEthAndIntrinsicFuel >> 96)
                )
            );

            // Safe guard to minimize the risk of getting buggy orders if the contract
            // deviates from the ERC721 standard.
            require(
                erc721.ownerOf(value) == to,
                "Dubiex: failed to transfer ERC721 token"
            );

            return (true, excessEth);
        }

        revert("Dubiex: unexpected currency type");
    }

    /**
     * @dev Validates that the given contract address and currency type are compatible.
     * @param currencyType type of the currency
     * @param contractAddress the contract address associated with currency
     */
    function _validateCurrencyType(
        DubiexLib.CurrencyType currencyType,
        address contractAddress
    ) private returns (bool) {
        if (currencyType == DubiexLib.CurrencyType.ETH) {
            require(
                contractAddress == address(0),
                "Dubiex: expected zero address"
            );
            return true;
        }

        if (currencyType == DubiexLib.CurrencyType.ERC721) {
            // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
            //
            // `contractAddress` must implement the ERC721 standard. According to the ERC721 standard
            // every compliant token is also expected to use ERC165 for that.
            require(
                IERC165(contractAddress).supportsInterface(
                    _ERC721_INTERFACE_HASH
                ),
                "Dubiex: not ERC721 compliant"
            );
            return true;
        }

        if (currencyType == DubiexLib.CurrencyType.BOOSTABLE_ERC20) {
            // The contract must implement the BOOSTABLE_ERC20 interface
            address implementer = _ERC1820_REGISTRY.getInterfaceImplementer(
                contractAddress,
                _BOOSTABLE_ERC20_TOKEN_HASH
            );

            require(
                implementer != address(0),
                "Dubiex: not BoostableERC20 compliant"
            );
            return true;
        }

        if (currencyType == DubiexLib.CurrencyType.ERC20) {
            // Using `call` is our last-resort to check if the given contract implements
            // ERC721, since we can't just call `supportsInterface` directly without reverting
            // if `contractAddress` doesn't implement it. Unlike above, where we want an ERC721,
            // so reverting is fine for non-ERC721 contracts.
            //
            // NOTE: bytes4(keccak256(supportsInterface(bytes4))) => 0x01ffc9a7
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory result) = contractAddress.call(
                abi.encodeWithSelector(0x01ffc9a7, _ERC721_INTERFACE_HASH)
            );

            // The call above must either fail (success = false) or if it succeeds,
            // return false.
            bool isERC721 = false;
            if (result.length > 0) {
                isERC721 = abi.decode(result, (bool));
            }

            require(!success || !isERC721, "Dubiex: ERC20 implements ERC721");

            // Lastly, we heuristically check if it responds to `balanceOf`.
            // If it succeeds, we assume it is an ERC20.
            // NOTE: bytes4(keccak256(balanceOf(address))) => 0x70a08231
            result = Address.functionCall(
                contractAddress,
                abi.encodeWithSelector(0x70a08231, contractAddress)
            );
            require(result.length > 0, "Dubiex: not ERC20 compliant");

            return true;
        }

        return false;
    }

    /**
     * @dev Increment the order id counter and return the new id.
     */
    function _getNextOrderId(address account) private returns (uint32) {
        uint32 currentId = _counters[account];
        assert(currentId < 2**32);

        uint32 nextId = currentId + 1;
        _counters[account] = nextId;

        return nextId;
    }

    /**
     * @dev Get or create order pair alias from the given order pair.
     */
    function _getOrCreateOrderPairAlias(DubiexLib.OrderPair memory pair)
        private
        returns (uint32)
    {
        bytes32 orderPairHash = keccak256(
            abi.encode(
                pair.makerContractAddress,
                pair.takerContractAddress,
                pair.makerCurrencyType,
                pair.takerCurrencyType
            )
        );

        uint32 orderPairAlias = _orderPairAliasesByHash[orderPairHash];
        // If it doesn't exist yet, we create it (which makes the make order for the caller a bit more expensive).
        if (orderPairAlias == 0) {
            require(
                _validateCurrencyType(
                    pair.makerCurrencyType,
                    pair.makerContractAddress
                ),
                "Dubiex: makerContractAddress and currencyType mismatch"
            );
            require(
                _validateCurrencyType(
                    pair.takerCurrencyType,
                    pair.takerContractAddress
                ),
                "Dubiex: takerContractAddress and currencyType mismatch"
            );

            uint32 orderPairAliasCounter = _orderPairAliasCounter;
            orderPairAliasCounter++;

            orderPairAlias = orderPairAliasCounter;

            _orderPairAliasCounter = orderPairAliasCounter;

            // Write mappings
            _orderPairAliasesByHash[orderPairHash] = orderPairAlias;
            _orderPairsByAlias[orderPairAlias] = DubiexLib.packOrderPair(pair);
        }

        return orderPairAlias;
    }

    function _safeGetOrderPairByAlias(
        uint32 orderPairAlias,
        DubiexLib.OrderPairReadStrategy strategy
    ) private view returns (DubiexLib.OrderPair memory) {
        DubiexLib.OrderPair memory _unpackedOrderPair;

        if (strategy == DubiexLib.OrderPairReadStrategy.SKIP) {
            return _unpackedOrderPair;
        }


            DubiexLib.PackedOrderPair storage _pairStorage
         = _orderPairsByAlias[orderPairAlias];

        // Read only maker info if requested
        if (
            strategy == DubiexLib.OrderPairReadStrategy.MAKER ||
            strategy == DubiexLib.OrderPairReadStrategy.FULL
        ) {
            (
                address makerContractAddress,
                DubiexLib.CurrencyType makerCurrencyType
            ) = DubiexLib.unpackOrderPairAddressType(_pairStorage.makerPair);
            _unpackedOrderPair.makerContractAddress = makerContractAddress;
            _unpackedOrderPair.makerCurrencyType = makerCurrencyType;

            require(
                _unpackedOrderPair.makerCurrencyType !=
                    DubiexLib.CurrencyType.NULL,
                "Dubiex: maker order pair not found"
            );
        }

        // Read only taker info if requested
        if (
            strategy == DubiexLib.OrderPairReadStrategy.TAKER ||
            strategy == DubiexLib.OrderPairReadStrategy.FULL
        ) {
            (
                address takerContractAddress,
                DubiexLib.CurrencyType takerCurrencyType
            ) = DubiexLib.unpackOrderPairAddressType(_pairStorage.takerPair);
            _unpackedOrderPair.takerContractAddress = takerContractAddress;
            _unpackedOrderPair.takerCurrencyType = takerCurrencyType;

            require(
                _unpackedOrderPair.takerCurrencyType !=
                    DubiexLib.CurrencyType.NULL,
                "Dubiex: taker order pair not found"
            );
        }

        return _unpackedOrderPair;
    }

    /**
     * @dev Tries to set the successor of the order with `ancestorOrderId`.
     *
     * - Reverts, if the ancestor exists and already has a successor.
     * - Returns false, if the ancestor doesn't exist.
     * - If it succeeds, then it implies that the ancestor hasn't been filled yet and thus
     * the caller has to ensure that the successor gets hidden.
     */
    function _setSuccessorOfAncestor(
        address account,
        uint32 ancestorOrderId,
        uint32 successorOrderId
    ) private returns (bool) {

            DubiexLib.PackedOrderBookItem[] storage orders
         = _ordersByAddress[account];
        uint256 length = orders.length;
        for (uint256 i = 0; i < length; i++) {
            DubiexLib.PackedOrderBookItem storage _packed = orders[i];

            uint256 packedData = _packed.packedData;

            // The first 32 bits of the packed data corresponds to the id. By casting to uint32,
            // we can compare the id without having to unpack the entire thing.
            uint32 orderId = uint32(packedData);
            if (orderId == ancestorOrderId) {
                DubiexLib.UnpackedOrderBookItem memory _unpacked = DubiexLib
                    .unpackOrderBookItem(packedData);

                // Set successor if none yet
                if (!_unpacked.flags.hasSuccessor) {
                    _unpacked.flags.hasSuccessor = true;
                    _packed.successorOrderId = successorOrderId;

                    // Pack data again and update storage
                    _packed.packedData = DubiexLib.packOrderBookItem(_unpacked);

                    return true;
                }

                // Ancestor exists, but has already a successor
                revert("Dubiex: ancestor order already has a successor");
            }
        }

        // Ancestor doesn't exist - so it got filled/cancelled or was never created to begin with.
        return false;
    }

    /**
     * @dev Makes the given successor order visible if it exists.
     */
    function _setOrderVisible(address account, uint32 successorOrderId)
        private
    {

            DubiexLib.PackedOrderBookItem[] storage orders
         = _ordersByAddress[account];

        uint256 length = orders.length;
        for (uint256 i = 0; i < length; i++) {
            DubiexLib.PackedOrderBookItem storage _packed = orders[i];

            uint256 packedData = _packed.packedData;

            // The first 32 bits of the packed data corresponds to the id. By casting to uint32,
            // we can compare the id without having to unpack the entire thing.
            uint32 orderId = uint32(packedData);
            if (orderId == successorOrderId) {
                DubiexLib.UnpackedOrderBookItem memory _unpacked = DubiexLib
                    .unpackOrderBookItem(packedData);
                _unpacked.flags.isHidden = false;

                // Write updated data
                _packed.packedData = DubiexLib.packOrderBookItem(_unpacked);

                break;
            }
        }
    }

    /**
     * @dev Returns the order from `account` with the given id from storage
     * plus the index of it.
     *
     * If it cannot be found, then this function reverts, because we expect the
     * caller to operate on existing orders.
     */
    function _safeGetOrder(
        address account,
        uint32 id,
        DubiexLib.OrderPairReadStrategy strategy
    )
        private
        view
        returns (
            DubiexLib.PackedOrderBookItem storage,
            DubiexLib.UnpackedOrderBookItem memory,
            uint256
        )
    {

            DubiexLib.PackedOrderBookItem[] storage orders
         = _ordersByAddress[account];

        uint256 length = orders.length;
        for (uint256 i = 0; i < length; i++) {
            DubiexLib.PackedOrderBookItem storage _packed = orders[i];

            uint256 packedData = _packed.packedData;

            // The first 32 bits of the packed data corresponds to the id. By casting to uint32,
            // we can compare the id without having to unpack the entire thing.
            uint32 orderId = uint32(packedData);
            if (orderId == id) {
                DubiexLib.UnpackedOrderBookItem memory _unpacked = DubiexLib
                    .unpackOrderBookItem(packedData);

                // Read the order pair with the given strategy
                _unpacked.pair = _safeGetOrderPairByAlias(
                    _unpacked.orderPairAlias,
                    strategy
                );

                return (_packed, _unpacked, i);
            }
        }

        revert("Dubiex: order does not exist");
    }

    /**
     * @dev Returns the order from `account` with the given id from storage
     * plus the index of it.
     *
     * If it cannot be found, then this function does not revert and it's up to the
     * caller to decide.
     */
    function _getOrder(
        address account,
        uint32 id,
        DubiexLib.OrderPairReadStrategy strategy
    )
        private
        view
        returns (
            DubiexLib.PackedOrderBookItem storage,
            DubiexLib.UnpackedOrderBookItem memory,
            uint256
        )
    {

            DubiexLib.PackedOrderBookItem[] storage orders
         = _ordersByAddress[account];

        uint256 length = orders.length;
        for (uint256 i = 0; i < length; i++) {
            DubiexLib.PackedOrderBookItem storage _packed = orders[i];

            uint256 packedData = _packed.packedData;

            // The first 32 bits of the packed data corresponds to the id. By casting to uint32,
            // we can compare the id without having to unpack the entire thing.
            uint32 orderId = uint32(packedData);
            if (orderId == id) {
                DubiexLib.UnpackedOrderBookItem memory _unpacked = DubiexLib
                    .unpackOrderBookItem(packedData);

                // Read the order pair with the given strategy
                // NOTE: This cannot revert when the order exists.
                _unpacked.pair = _safeGetOrderPairByAlias(
                    _unpacked.orderPairAlias,
                    strategy
                );

                return (_packed, _unpacked, i);
            }
        }

        DubiexLib.UnpackedOrderBookItem memory _unpacked;
        return (emptyOrder, _unpacked, 0);
    }

    /**
     * @dev Delete an order of `maker` by index in O(1).
     */
    function _deleteOrder(address maker, uint256 index) private {

            DubiexLib.PackedOrderBookItem[] storage orders
         = _ordersByAddress[maker];

        uint256 length = orders.length;
        // swap and pop, changes the order
        if (index != length - 1) {
            // Move last item to the position of the to-be-deleted item (`index`)
            orders[index] = orders[length - 1];
        }

        orders.pop();
    }

    //---------------------------------------------------------------
    // Fuel
    //---------------------------------------------------------------

    /**
     * @dev Burn `fuel` from `from`.
     */
    function _burnFuel(address from, BoosterFuel memory fuel)
        internal
        returns (uint96)
    {
        // Burn unlocked PRPS
        if (fuel.unlockedPrps > 0) {
            IBoostableERC20(address(_prps)).burnFuel(
                from,
                TokenFuel({
                    tokenAlias: 0, /* UNLOCKED PRPS */
                    amount: fuel.unlockedPrps
                })
            );

            return 0;
        }

        // Burn locked PRPS
        if (fuel.lockedPrps > 0) {
            IBoostableERC20(address(_prps)).burnFuel(
                from,
                TokenFuel({
                    tokenAlias: 1, /* LOCKED PRPS */
                    amount: fuel.lockedPrps
                })
            );

            return 0;
        }

        // Burn DUBI from balance
        if (fuel.dubi > 0) {
            IBoostableERC20(address(_dubi)).burnFuel(
                from,
                TokenFuel({
                    tokenAlias: 2, /* DUBI */
                    amount: fuel.dubi
                })
            );

            return 0;
        }

        // The intrinsic fuel is only supported for ERC721 tokens via
        // the 'safeTransferFrom' payload.
        if (fuel.intrinsicFuel > 0) {
            return fuel.intrinsicFuel;
        }

        // No fuel
        return 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transfered from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     *  @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     *  @param account Address of the contract for which to update the cache.
     *  @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not.
     *  If the result is not cached a direct lookup on the contract address is performed.
     *  If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     *  {updateERC165Cache} with the contract address.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mecanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Only used for testing Dubiex
contract DummyVanillaERC20 is ERC20, Ownable {
    string public constant NAME = "Dummy";
    string public constant SYMBOL = "DUMMY";

    constructor() public ERC20(NAME, SYMBOL) Ownable() {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract DummyVanillaERC721 is ERC721 {
    string public constant NAME = "Vanilla ERC721";
    string public constant SYMBOL = "VANILLA-";

    constructor() public ERC721(NAME, SYMBOL) {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}

