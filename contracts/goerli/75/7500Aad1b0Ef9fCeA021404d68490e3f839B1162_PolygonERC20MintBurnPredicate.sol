/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

// Sources flattened with hardhat v2.6.6 https://hardhat.org

// File @animoca/ethereum-contracts-core/contracts/metatx/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

/*
 * Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner.
 */
abstract contract ManagedIdentity {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}


// File contracts/token/common/polygon/interfaces/IPolygonTokenPredicate.sol

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title Token Predicate interface for Polygon POS portal.
 */
interface IPolygonTokenPredicate {
    /**
     * Deposit tokens into POS portal.
     * @param depositor Address who wants to deposit tokens
     * @param depositReceiver Address (address) who wants to receive tokens on side chain
     * @param rootToken Token which gets deposited
     * @param depositData Extra data for deposit (amount for ERC20, token id for ERC721 etc.) [ABI encoded]
     */
    function lockTokens(
        address depositor,
        address depositReceiver,
        address rootToken,
        bytes calldata depositData
    ) external;

    /**
     * Validates and processes exit while withdraw process
     * @dev Validates exit log emitted on sidechain. Reverts if validation fails.
     * @dev Processes withdraw based on custom logic. Example: transfer ERC20/ERC721, mint ERC721 if mintable withdraw
     * @param sender Address
     * @param rootToken Token which gets withdrawn
     * @param logRLPList Valid sidechain log for data like amount, token id etc.
     */
    function exitTokens(
        address sender,
        address rootToken,
        bytes calldata logRLPList
    ) external;
}


// File @animoca/ethereum-contracts-core/contracts/utils/[email protected]

/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 * https://github.com/hamdiallam/Solidity-RLP/blob/e681e25a376dbd5426b509380bc03446f05d0f97/contracts/RLPReader.sol
 */
pragma solidity >=0.7.6 <0.8.0;

library RLPReader {
    uint8 private constant _STRING_SHORT_START = 0x80;
    uint8 private constant _STRING_LONG_START = 0xb8;
    uint8 private constant _LIST_SHORT_START = 0xc0;
    uint8 private constant _LIST_LONG_START = 0xf8;
    uint8 private constant _WORD_SIZE = 32;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    /*
     * @param item RLP encoded bytes
     */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        require(item.length > 0, "RLPReader: INVALID_BYTES_LENGTH");
        uint256 memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
     * @param item RLP encoded list in bytes
     */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item), "RLP: ITEM_NOT_LIST");

        uint256 items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);
        uint256 listLength = _itemLength(item.memPtr);
        require(listLength == item.len, "RLP: LIST_LENGTH_MISMATCH");

        uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        uint8 byte0;
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < _LIST_SHORT_START) return false;
        return true;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);

        uint256 ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        require(!isList(item), "RLP: DECODING_LIST_AS_ADDRESS");
        // 1 byte for the length prefix
        require(item.len == 21, "RLP: INVALID_ADDRESS_LEN");

        return address(toUint(item));
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(!isList(item), "RLP: DECODING_LIST_AS_UINT");
        require(item.len <= 33, "RLP: INVALID_UINT_LEN");

        uint256 itemLength = _itemLength(item.memPtr);
        require(itemLength == item.len, "RLP: UINT_LEN_MISMATCH");

        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset;
        uint256 result;
        uint256 memPtr = item.memPtr + offset;
        assembly {
            result := mload(memPtr)

            // shfit to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
        uint256 itemLength = _itemLength(item.memPtr);
        require(itemLength == item.len, "RLP: UINT_STRICT_LEN_MISMATCH");
        // one byte prefix
        require(item.len == 33, "RLP: INVALID_UINT_STRICT_LEN");

        uint256 result;
        uint256 memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        uint256 listLength = _itemLength(item.memPtr);
        require(listLength == item.len, "RLP: BYTES_LEN_MISMATCH");
        uint256 offset = _payloadOffset(item.memPtr);

        uint256 len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint256 destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }

    /*
     * Private Helpers
     */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint256) {
        // add `isList` check if `item` is expected to be passsed without a check from calling function
        // require(isList(item), "RLPReader: NUM_ITEMS_NOT_LIST");

        uint256 count = 0;
        uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            require(currPtr <= endPtr, "RLP: NUM_ITEMS_LEN_MISMATCH");
            count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint256 memPtr) private pure returns (uint256) {
        uint256 itemLen;
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < _STRING_SHORT_START) itemLen = 1;
        else if (byte0 < _STRING_LONG_START) itemLen = byte0 - _STRING_SHORT_START + 1;
        else if (byte0 < _LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < _LIST_LONG_START) {
            itemLen = byte0 - _LIST_SHORT_START + 1;
        } else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < _STRING_SHORT_START) return 0;
        else if (byte0 < _STRING_LONG_START || (byte0 >= _LIST_SHORT_START && byte0 < _LIST_LONG_START)) return 1;
        else if (byte0 < _LIST_SHORT_START)
            // being explicit
            return byte0 - (_STRING_LONG_START - 1) + 1;
        else return byte0 - (_LIST_LONG_START - 1) + 1;
    }

    /*
     * @param src Pointer to source
     * @param dest Pointer to destination
     * @param len Amount of memory to copy from the source
     */
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= _WORD_SIZE; len -= _WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += _WORD_SIZE;
            dest += _WORD_SIZE;
        }

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint256 mask = 256**(_WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}


// File contracts/token/ERC20/polygon/predicate/PolygonERC20PredicateBase.sol

pragma solidity >=0.7.6 <0.8.0;


/**
 * @title ERC20 Predicate Base (for Polygon).
 * Polygon bridging ERC20 predicate which works with a `Withdrawn(address account, uint256 value)` event.
 * @dev This contract should be deployed on the Root Chain (Ethereum).
 * @dev The functions `lockTokens(address,address,address,bytes)` and `exitTokens(address,address,byte)` need to be implemented by a child contract.
 */
abstract contract PolygonERC20PredicateBase is IPolygonTokenPredicate {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    event LockedERC20(address indexed depositor, address indexed depositReceiver, address indexed rootToken, uint256 amount);

    // keccak256("Withdrawn(address account, uint256 value)");
    bytes32 public constant WITHDRAWN_EVENT_SIG = 0x7084f5476618d8e60b11ef0d7d3f06914655adb8793e28ff7f018d4c76d505d5;

    // see https://github.com/maticnetwork/pos-portal/blob/master/contracts/root/RootChainManager/RootChainManager.sol
    address public rootChainManager;

    /**
     * Constructor
     * @param rootChainManager_ the Polygon/MATIC RootChainManager proxy address.
     */
    constructor(address rootChainManager_) {
        rootChainManager = rootChainManager_;
    }

    //============================================== Helper Internal Functions ==============================================//

    function _requireManagerRole(address account) internal view {
        require(account == rootChainManager, "Predicate: only manager");
    }

    function _verifyWithdrawalLog(bytes memory log) internal pure returns (address withdrawer, uint256 amount) {
        RLPReader.RLPItem[] memory logRLPList = log.toRlpItem().toList();
        RLPReader.RLPItem[] memory logTopicRLPList = logRLPList[1].toList(); // topics

        require(
            bytes32(logTopicRLPList[0].toUint()) == WITHDRAWN_EVENT_SIG, // topic0 is event sig
            "Predicate: invalid signature"
        );

        bytes memory logData = logRLPList[2].toBytes();
        (withdrawer, amount) = abi.decode(logData, (address, uint256));
    }
}


// File contracts/token/ERC20/polygon/predicate/PolygonERC20MintBurnPredicate.sol

pragma solidity >=0.7.6 <0.8.0;


/**
 * @title ERC20 Mint/Burn Predicate (for Polygon).
 * Polygon bridging ERC20 minting/burning predicate which works with a `Withdrawn(address account, uint256 value)` event.
 * @dev This contract should be deployed on the Root Chain (Ethereum).
 * @dev Warning: this predicate must be used only for mintable and burnable tokens.
 */
contract PolygonERC20MintBurnPredicate is ManagedIdentity, PolygonERC20PredicateBase {
    // @inheritdoc PolygonERC20PredicateBase
    constructor(address rootChainManager_) PolygonERC20PredicateBase(rootChainManager_) {}

    //==================================================== TokenPredicate ===================================================//

    /**
     * Burns ERC20 tokens for deposit.
     * @dev Reverts if not called by the manager (RootChainManager).
     * @param depositor Address who wants to deposit tokens.
     * @param depositReceiver Address (address) who wants to receive tokens on child chain.
     * @param rootToken Token which gets deposited.
     * @param depositData ABI encoded amount.
     */
    function lockTokens(
        address depositor,
        address depositReceiver,
        address rootToken,
        bytes calldata depositData
    ) external override {
        _requireManagerRole(_msgSender());
        uint256 amount = abi.decode(depositData, (uint256));
        emit LockedERC20(depositor, depositReceiver, rootToken, amount);
        require(IERC20BurnableMintable(rootToken).burnFrom(depositor, amount), "Predicate: burn failed");
    }

    /**
     * Validates the {Withdrawn} log signature, then mints the correct amount to withdrawer.
     * @dev Reverts if not called only by the manager (RootChainManager).
     * @param rootToken Token which gets withdrawn
     * @param log Valid ERC20 burn log from child chain
     */
    function exitTokens(
        address,
        address rootToken,
        bytes memory log
    ) public override {
        _requireManagerRole(_msgSender());
        (address withdrawer, uint256 amount) = _verifyWithdrawalLog(log);
        IERC20BurnableMintable(rootToken).mint(withdrawer, amount);
    }
}

interface IERC20BurnableMintable {
    function burnFrom(address from, uint256 value) external returns (bool);

    function mint(address to, uint256 value) external;
}