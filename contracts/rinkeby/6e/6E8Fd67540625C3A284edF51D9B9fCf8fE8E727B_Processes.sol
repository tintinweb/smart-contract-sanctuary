/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

// File: IERC20.sol

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

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
// File: common.sol

/// @notice The `IProcessStore` interface allows different versions of the contract to talk to each other. Not all methods in the contract need to be future proof.
/// @notice Should operations be updated, then two versions should be kept, one for the old version and one for the new.
interface IProcessStore {
    enum Status {READY, ENDED, CANCELED, PAUSED, RESULTS}

    // GET
    function getEntityProcessCount(address entityAddress) external view returns (uint256);
    function getNextProcessId(address entityAddress) external view returns (bytes32);
    function getProcessId(address entityAddress, uint256 processCountIndex, uint32 namespaceId, uint32 chainId) external pure returns (bytes32);
    function get(bytes32 processId) external view returns (
        uint8[3] memory mode_envelopeType_censusOrigin,
        address entityAddress,
        string[3] memory metadata_censusRoot_censusUri,
        uint32[2] memory startBlock_blockCount,
        Status status,
        uint8[5] memory questionIndex_questionCount_maxCount_maxValue_maxVoteOverwrites,
        uint16[2] memory maxTotalCost_costExponent,
        uint256 evmBlockHeight // EVM only
    );
    function getParamsSignature(bytes32 processId) external view returns (bytes32);
    function getCreationInstance(bytes32 processId) external view returns (address);

    // SET
    function newProcess(
        uint8[3] memory mode_envelopeType_censusOrigin,
        address tokenContractAddress,
        string[3] memory metadata_censusRoot_censusUri,
        uint32[2] memory startBlock_blockCount,
        uint8[4] memory questionCount_maxCount_maxValue_maxVoteOverwrites,
        uint16[2] memory maxTotalCost_costExponent,
        uint256 evmBlockHeight, // EVM only
        bytes32 paramsSignature
    ) payable external;
    function setStatus(bytes32 processId, Status newStatus) external;
    function incrementQuestionIndex(bytes32 processId) external;
    function setCensus(bytes32 processId, string memory censusRoot, string memory censusUri) external;
    function setProcessPrice(uint256 processPrice) external;
    function withdraw(address payable to, uint256 amount) external;

    // EVENTS
    event NewProcess(bytes32 processId, uint32 namespace);
    event StatusUpdated(bytes32 processId, uint32 namespace, Status status);
    event QuestionIndexUpdated(
        bytes32 processId,
        uint32 namespace,
        uint8 newIndex
    );
    event CensusUpdated(bytes32 processId, uint32 namespace);
    event ProcessPriceUpdated(uint256 processPrice);
    event Withdraw(address to, uint256 amount);
}

/// @notice The `IResultsStore` interface allows different versions of the contract to talk to each other. Not all methods in the contract need to be future proof.
/// @notice Should operations be updated, then two versions should be kept, one for the old version and one for the new.
interface IResultsStore {
    modifier onlyOracle(uint32 vochainId) virtual;

    // GET
    function getResults(bytes32 processId) external view returns (uint32[][] memory tally, uint32 height);

    // SET
    function setProcessesAddress(address processesAddr) external;
    function setResults(bytes32 processId, uint32[][] memory tally, uint32 height, uint32 vochainId) external;

    // EVENTS
    event ResultsAvailable(bytes32 processId);
}

/// @notice The `INamespaceStore` interface defines the contract methods that allow process contracts to self register to a namespace ID
interface INamespaceStore {
    // SETTERS
    function register() external returns(uint32);

    // GETTERS
    function processContractAt(uint32 namespaceId) external view returns (address);

    // EVENTS
    event NamespaceRegistered(uint32 namespace);
}

/// @notice The `IGenesisStore` interface defines the standard methods that allow querying and updating the details of each namespace.
interface IGenesisStore {
    // SETTERS
    function newChain(string memory genesis, bytes[] memory validators, address[] memory oracles) external returns (uint32);
    function setGenesis(uint32 chainId, string memory newGenesis) external;
    function addValidator(uint32 chainId, bytes memory validatorPublicKey) external;
    function removeValidator(uint32 chainId, uint256 idx, bytes memory validatorPublicKey) external;
    function addOracle(uint32 chainId, address oracleAddress) external;
    function removeOracle(uint32 chainId, uint256 idx, address oracleAddress) external;

    // GETTERS
    function get(uint32 chainId) view external returns ( string memory genesis, bytes[] memory validators, address[] memory oracles);
    function isValidator(uint32 chainId, bytes memory validatorPublicKey) external view returns (bool);
    function isOracle(uint32 chainId, address oracleAddress) external view returns (bool);
    function getChainCount() external view returns(uint32);

    // EVENTS
    event ChainRegistered(uint32 chainId);
    event GenesisUpdated(uint32 chainId);
    event ValidatorAdded(uint32 chainId, bytes validatorPublicKey);
    event ValidatorRemoved(uint32 chainId, bytes validatorPublicKey);
    event OracleAdded(uint32 chainId, address oracleAddress);
    event OracleRemoved(uint32 chainId, address oracleAddress);
}

/// @notice The `ITokenStorageProof` interface defines the standard methods that allow checking ERC token balances.
interface ITokenStorageProof {
    /// @notice Checks that the given contract is an ERC token, validates that the balance of the sender matches the one obtained from the storage position and registers the token address
    function registerToken(
        address tokenAddress,
        uint256 balanceMappingPosition,
        uint256 blockNumber,
        bytes memory blockHeaderRLP,
        bytes memory accountStateProof,
        bytes memory storageProof) external;

    /// @notice Determines whether the given address is registered as an ERC token contract
    function isRegistered(address tokenAddress) external view returns (bool);
  
    /// @notice Determines the balance slot of a holder of an ERC20 token given a balance slot
    function getHolderBalanceSlot(address holder, uint256 balanceMappingPosition) external pure returns(bytes32);

    /// @notice Returns the balance mapping position of a token for users to generate proofs
    function getBalanceMappingPosition(address tokenAddress) external view returns (uint256);
}
// File: lib.sol

library SafeUint8 {
    /// @notice Adds two uint8 integers and fails if an overflow occurs
    function add8(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        require(c >= a, "overflow");

        return c;
    }
}


library ContractSupport {
    // Compatible contract functions signatures
    bytes4 private constant BALANCE_OF_ADDR = bytes4(
        keccak256("balanceOf(address)")
    );

    function isContract(address targetAddress) internal view returns (bool) {
        uint256 size;
        if (targetAddress == address(0)) return false;
        assembly {
            size := extcodesize(targetAddress)
        }
        return size > 0;
    }

    function isSupporting(address targetAddress, bytes memory data)
        private
        returns (bool)
    {
        bool success;
        assembly {
            success := call(
                gas(), // gas remaining
                targetAddress, // destination address
                0, // no ether
                add(data, 32), // input buffer (starts after the first 32 bytes in the `data` array)
                mload(data), // input length (loaded from the first 32 bytes in the `data` array)
                0, // output buffer
                0 // output length
            )
        }
        return success;
    }

    function supportsBalanceOf(address targetAddress) internal returns (bool) {
        bytes memory data = abi.encodeWithSelector(
            BALANCE_OF_ADDR,
            address(0x0)
        );
        return isSupporting(targetAddress, data);
    }
}

/**
* @author Hamdi Allam [email protected]
* Please reach out with any questions or concerns
*/
library RLP {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START  = 0xb8;
    uint8 constant LIST_SHORT_START   = 0xc0;
    uint8 constant LIST_LONG_START    = 0xf8;

    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1, "Invalid RLPItem. Booleans are encoded in 1 byte");
        uint256 result;
        uint256 memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix according to RLP spec
        require(item.len <= 21, "Invalid RLPItem. Addresses are encoded in 20 bytes or less");

        return address(toUint(item));
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset;
        uint256 memPtr = item.memPtr + offset;

        uint256 result;
        assembly {
            result := div(mload(memPtr), exp(256, sub(32, len))) // shift to the correct location
        }

        return result;
    }

    function toRLPBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);

        uint256 ptr;
        assembly {
            ptr := add(0x20, result)
        }

        _copy(item.memPtr, ptr, item.len);
        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint256 destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        _copy(item.memPtr + offset, destPtr, len);
        return result;
    }

    function toRLPItem(bytes memory item) internal pure returns (RLPItem memory) {
        if (item.length == 0)
            return RLPItem(0, 0);

        uint256 memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory result) {
        require(isList(item), "Cannot convert to list a non-list RLPItem.");

        uint256 items = numItems(item);
        result = new RLPItem[](items);

        uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }
    }

    function isList(RLPItem memory item) internal pure returns (bool) {
        uint8 byte0;
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }

    function numItems(RLPItem memory item) internal pure returns (uint256) {
        uint256 count = 0;
        uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            count++;
        }

        return count;
    }

    function _itemLength(uint256 memPtr) private pure returns (uint256 len) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) {
            return 1;
        } else if (byte0 < STRING_LONG_START) {
            return byte0 - STRING_SHORT_START + 1;
        } else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

            /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                len := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < LIST_LONG_START) {
            return byte0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                len := add(dataLen, add(byteLen, 1))
            }
        }
    }

    function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) {
            return 0;
        } else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)) {
            return 1;
        } else if (byte0 < LIST_SHORT_START) {  // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        } else {
            return byte0 - (LIST_LONG_START - 1) + 1;
        }
    }

    // solium-disable security/no-assign-params
    function _copy(uint256 src, uint256 dest, uint256 len) private pure {
        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint256 mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}

library TrieProof {
    using RLP for RLP.RLPItem;
    using RLP for bytes;

    bytes32 internal constant EMPTY_TRIE_ROOT_HASH = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;

    // decoding from compact encoding (hex prefix encoding on the yellow paper)
    function decodeNibbles(bytes memory compact, uint256 skipNibbles)
    internal
    pure
    returns (bytes memory nibbles)
    {
        require(compact.length > 0); // input > 0

        uint256 length = compact.length * 2; // need bytes, compact uses nibbles
        require(skipNibbles <= length);
        length -= skipNibbles;

        nibbles = new bytes(length);
        uint256 nibblesLength = 0;

        for (uint256 i = skipNibbles; i < skipNibbles + length; i += 1) {
            if (i % 2 == 0) {
                nibbles[nibblesLength] = bytes1(
                    (uint8(compact[i / 2]) >> 4) & 0xF
                );
            } else {
                nibbles[nibblesLength] = bytes1(
                    (uint8(compact[i / 2]) >> 0) & 0xF
                );
            }
            nibblesLength += 1;
        }

        assert(nibblesLength == nibbles.length);
    }

    function merklePatriciaCompactDecode(bytes memory compact)
    internal
    pure
    returns (bool isLeaf, bytes memory nibbles)
    {
        require(compact.length > 0, "Empty");

        uint256 first_nibble = (uint8(compact[0]) >> 4) & 0xF;
        uint256 skipNibbles;

        if (first_nibble == 0) {
            skipNibbles = 2;
            isLeaf = false;
        } else if (first_nibble == 1) {
            skipNibbles = 1;
            isLeaf = false;
        } else if (first_nibble == 2) {
            skipNibbles = 2;
            isLeaf = true;
        } else if (first_nibble == 3) {
            skipNibbles = 1;
            isLeaf = true;
        } else {
            // Not supposed to happen!
            revert("failed decoding Trie");
        }

        return (isLeaf, decodeNibbles(compact, skipNibbles));
    }

    function isEmptyByteSequence(RLP.RLPItem memory item)
    internal
    pure
    returns (bool)
    {
        if (item.len != 1) {
            return false;
        }
        uint8 b;
        uint256 memPtr = item.memPtr;
        assembly {
            b := byte(0, mload(memPtr))
        }
        return b == 0x80; /* empty byte string */
    }

    function sharedPrefixLength(
        uint256 xsOffset,
        bytes memory xs,
        bytes memory ys
    ) internal pure returns (uint256) {
        uint256 i;
        for (i = 0; i + xsOffset < xs.length && i < ys.length; i++) {
            if (xs[i + xsOffset] != ys[i]) {
                return i;
            }
        }
        return i;
    }

    /// @dev Computes the hash of the Merkle-Patricia-Trie hash of the input.
    ///      Merkle-Patricia-Tries use a hash function that outputs
    ///      *variable-length* hashes: If the input is shorter than 32 bytes,
    ///      the MPT hash is the input. Otherwise, the MPT hash is the
    ///      Keccak-256 hash of the input.
    ///      The easiest way to compare variable-length byte sequences is
    ///      to compare their Keccak-256 hashes.
    /// @param input The byte sequence to be hashed.
    /// @return Keccak-256(MPT-hash(input))
    function mptHashHash(bytes memory input) internal pure returns (bytes32) {
        if (input.length < 32) {
            return keccak256(input);
        } else {
            return
            keccak256(abi.encodePacked(keccak256(abi.encodePacked(input))));
        }
    }

    /// @dev Validates a Merkle-Patricia-Trie proof.
    ///      If the proof proves the inclusion of some key-value pair in the
    ///      trie, the value is returned. Otherwise, i.e. if the proof proves
    ///      the exclusion of a key from the trie, an empty byte array is
    ///      returned.
    /// @param siblings is the stack of MPT nodes (starting with the root) that need to be traversed during verification.
    /// @param rootHash is the Keccak-256 hash of the root node of the MPT
    /// @param key is the key of the node whose inclusion/exclusion we are proving.
    /// @return value whose inclusion is proved or an empty byte array for a proof of exclusion
    function verify(
        bytes memory siblings, // proofs
        bytes32 rootHash,
        bytes32 key
    ) internal pure returns (bytes memory value) {
        // copy key for convenience
        bytes memory decoded_key = new bytes(32);
        assembly {
            mstore(add(decoded_key, 0x20), key)
        }
        // key consisting on nibbles
        decoded_key = decodeNibbles(decoded_key, 0);

        // siblings to RLP encoding list
        RLP.RLPItem[] memory rlpSiblings = siblings.toRLPItem().toList();
        bytes memory rlpNode;
        bytes32 nodeHashHash;
        RLP.RLPItem[] memory node;
        RLP.RLPItem memory rlpValue;

        uint256 keyOffset = 0; // Offset of the proof

        // if not siblings the root hash is the hash of an empty trie
        if (rlpSiblings.length == 0) {
            // Root hash of empty tx trie
            require(rootHash == EMPTY_TRIE_ROOT_HASH, "Bad empty proof");
            return new bytes(0);
        }

        // Traverse stack of nodes starting at root.
        for (uint256 i = 0; i < rlpSiblings.length; i++) {
            // We use the fact that an rlp encoded list consists of some
            // encoding of its length plus the concatenation of its
            // *rlp-encoded* items.
            rlpNode = rlpSiblings[i].toRLPBytes();

            // The root node is hashed with Keccak-256
            if (i == 0 && rootHash != keccak256(rlpNode)) {
                revert("bad first proof part");
            }
            // All other nodes are hashed with the MPT hash function.
            if (i != 0 && nodeHashHash != mptHashHash(rlpNode)) {
                revert("bad hash");
            }

            node = rlpSiblings[i].toList();

            // Extension or Leaf node
            if (node.length == 2) {
                bool isLeaf;
                bytes memory nodeKey;
                (isLeaf, nodeKey) = merklePatriciaCompactDecode(
                    node[0].toBytes()
                );

                uint256 prefixLength = sharedPrefixLength(
                    keyOffset,
                    decoded_key,
                    nodeKey
                );
                keyOffset += prefixLength;

                if (prefixLength < nodeKey.length) {
                    // Proof claims divergent extension or leaf. (Only
                    // relevant for proofs of exclusion.)
                    // An Extension/Leaf node is divergent if it "skips" over
                    // the point at which a Branch node should have been had the
                    // excluded key been included in the trie.
                    // Example: Imagine a proof of exclusion for path [1, 4],
                    // where the current node is a Leaf node with
                    // path [1, 3, 3, 7]. For [1, 4] to be included, there
                    // should have been a Branch node at [1] with a child
                    // at 3 and a child at 4.

                    // Sanity check
                    if (i < rlpSiblings.length - 1) {
                        // divergent node must come last in proof
                        revert("divergent node must come last in proof");
                    }
                    return new bytes(0);
                }

                if (isLeaf) {
                    // Sanity check
                    if (i < rlpSiblings.length - 1) {
                        // leaf node must come last in proof
                        revert("leaf must come last in proof");
                    }

                    if (keyOffset < decoded_key.length) {
                        return new bytes(0);
                    }

                    rlpValue = node[1];
                    return rlpValue.toBytes();
                } else {
                    // extension node
                    // Sanity check
                    if (i == rlpSiblings.length - 1) {
                        // should not be at last level
                        revert("extension node cannot be at last level");
                    }

                    if (!node[1].isList()) {
                        // rlp(child) was at least 32 bytes. node[1] contains
                        // Keccak256(rlp(child)).
                        nodeHashHash = keccak256(node[1].toBytes());
                    } else {
                        // rlp(child) was at less than 32 bytes. node[1] contains
                        // rlp(child).
                        nodeHashHash = keccak256(node[1].toRLPBytes());
                    }
                }
            } else if (node.length == 17) {
                // Branch node
                if (keyOffset != decoded_key.length) {
                    // we haven't consumed the entire path, so we need to look at a child
                    uint8 nibble = uint8(decoded_key[keyOffset]);
                    keyOffset += 1;
                    if (nibble >= 16) {
                        // each element of the path has to be a nibble
                        revert("if branch node each element has to be a nibble");
                    }

                    if (isEmptyByteSequence(node[nibble])) {
                        // Sanity
                        if (i != rlpSiblings.length - 1) {
                            // leaf node should be at last level
                            revert("leaf nodes only at last level");
                        }
                        return new bytes(0);
                    } else if (!node[nibble].isList()) {
                        nodeHashHash = keccak256(node[nibble].toBytes());
                    } else {
                        nodeHashHash = keccak256(node[nibble].toRLPBytes());
                    }
                } else {
                    // we have consumed the entire mptKey, so we need to look at what's contained in this node.
                    // Sanity

                    if (i != rlpSiblings.length - 1) {
                        // should be at last level
                        revert("should be at last level");
                    }
                    return node[16].toBytes();
                }
            }
        }
    }
}

// File: base.sol

contract Owned {
    address internal contractOwner;

    /// @notice Creates a new instance of the contract and sets the contract owner.
    constructor() public {
        contractOwner = msg.sender;
    }

    /// @notice Fails if the sender is not the contract owner
    modifier onlyContractOwner {
        require(msg.sender == contractOwner, "onlyContractOwner");
        _;
    }
}

contract Chained is Owned {
    address public predecessorAddress; // Instance that we forked
    address public successorAddress; // Instance that forked from us (only when activated)
    uint256 public activationBlock; // Block after which the contract operates. Zero means still inactive.

    event Activated(uint256 blockNumber);
    event ActivatedSuccessor(uint256 blockNumber, address successor);

    /// @notice Fails if the contract is not yet active or if a successor has been activated
    modifier onlyIfActive {
        require(
            activationBlock > 0 && successorAddress == address(0),
            "Inactive"
        );
        _;
    }

    /// @notice When the contract is created, sets the predecessor (if any). Otherwise, sets the contract as active.
    /// @param predecessor The address of the predecessor instance (if any). `0x0` means no predecessor.
    function setUp(address predecessor) internal onlyContractOwner {
        require(
            predecessorAddress == address(0x0),
            "Already has a predecessor"
        );
        require(activationBlock == 0, "Already activated");

        if (predecessor != address(0)) {
            require(predecessor != address(this), "Can't be itself");
            require(
                ContractSupport.isContract(predecessor),
                "Invalid predecessor"
            );

            // Set the predecessor instance and leave ourselves inactive
            predecessorAddress = predecessor;
        } else {
            // Set no predecessor and activate ourselves now
            activationBlock = block.number;
        }
    }

    /// @notice Sets the activation block of the instance, so that it can start operating
    function activate() public {
        require(msg.sender == predecessorAddress, "Unauthorized");
        require(activationBlock == 0, "Already active");

        activationBlock = block.number;

        emit Activated(block.number);
    }

    /// @notice invokes `activate()` on the successor contract and deactivates itself
    function activateSuccessor(address successor) public onlyContractOwner {
        require(activationBlock > 0, "Must be active"); // we can't activate someone else before being active ourselves
        require(successorAddress == address(0), "Already inactive"); // we can't do it twice
        require(successor != address(this), "Can't be itself");
        require(ContractSupport.isContract(successor), "Not a contract"); // we can't activate a non-contract

        // Attach to the instance that will become active
        Chained succInstance = Chained(successor);
        succInstance.activate();
        successorAddress = successor;

        emit ActivatedSuccessor(block.number, successor);
    }
}

// File: processes.sol

contract Processes is IProcessStore, Chained {
    using SafeUint8 for uint8;

    // CONSTANTS AND ENUMS
    enum CensusOrigin {
        __, // 0
        OFF_CHAIN_TREE, // 1
        OFF_CHAIN_TREE_WEIGHTED, // 2
        OFF_CHAIN_CA, // 3
        __4,
        __5,
        __6,
        __7,
        __8,
        __9,
        __10,
        ERC20, // 11
        ERC721, // 12
        ERC1155, // 13
        ERC777, // 14
        MINI_ME // 15
    } // 256 items max

    /*
    Process Mode flags
    The process mode defines how the process behaves externally. It affects both the Vochain, the contract itself, the metadata and the census origin.

    0b00001111
          ||||
          |||`- autoStart
          ||`-- interruptible
          |`--- dynamicCensus
          `---- encryptedMetadata
    */
    uint8 internal constant MODE_AUTO_START = 1 << 0;
    uint8 internal constant MODE_INTERRUPTIBLE = 1 << 1;
    uint8 internal constant MODE_DYNAMIC_CENSUS = 1 << 2;
    uint8 internal constant MODE_ENCRYPTED_METADATA = 1 << 3;

    /*
    Envelope Type flags
    The envelope type tells how the vote envelope will be formatted and handled. Its value is generated by combining the flags below.

    0b00001111
          ||||
          |||`- serial
          ||`-- anonymous
          |`--- encryptedVote
          `---- uniqueValues
    */
    uint8 internal constant ENV_TYPE_SERIAL = 1 << 0; // Questions are submitted one by one
    uint8 internal constant ENV_TYPE_ANONYMOUS = 1 << 1; // ZK Snarks are used
    uint8 internal constant ENV_TYPE_ENCRYPTED_VOTES = 1 << 2; // Votes are encrypted with the process public key
    uint8 internal constant ENV_TYPE_UNIQUE_VALUES = 1 << 3; // Choices for a question cannot appear twice or more

    // GLOBAL DATA

    uint32 public ethChainId; // Used to salt the process ID's so they don't collide within the same entity on another chain. Could be computed, but not all development tools support that yet.
    uint32 public namespaceId; // Index of the namespace where this contract has been assigned to
    address public namespaceAddress; // Address of the namespace contract instance that holds the current state
    address public resultsAddress; // The address of the contract that will hold the results of the processes from the current instance
    address public tokenStorageProofAddress; // Address of the storage proof contract, used to query ERC token balances and proofs
    uint256 public processPrice; // Price for creating a voting process

    // DATA STRUCTS
    struct Process {
        uint8 mode; // The selected process mode. See: https://vocdoni.io/docs/#/architecture/smart-contracts/process?id=flags
        uint8 envelopeType; // One of valid envelope types, see: https://vocdoni.io/docs/#/architecture/smart-contracts/process?id=flags
        CensusOrigin censusOrigin; // How the census proofs are computed (Off-chain vs EVM Merkle Tree)
        address entity; // The address of the Entity (or contract) holding the process
        uint32 startBlock; // Vochain block number on which the voting process starts
        uint32 blockCount; // Amount of Vochain blocks during which the voting process should be active
        string metadata; // Content Hashed URI of the JSON meta data (See Data Origins)
        string censusRoot; // Hex string with the Census Root. Depending on the census origin, it will be a Merkle Root or a public key.
        string censusUri; // Content Hashed URI of the exported Merkle Tree (not including the public keys)
        Status status; // One of 0 [ready], 1 [ended], 2 [canceled], 3 [paused], 4 [results]
        uint8 questionIndex; // The index of the currently active question (only assembly processes)
        // How many questions are available to vote
        // questionCount >= 1
        uint8 questionCount;
        // How many choices can be made for each question.
        // 1 <= maxCount <= 100
        uint8 maxCount;
        // Determines the acceptable value range.
        // N => valid votes will range from 0 to N (inclusive)
        uint8 maxValue;
        uint8 maxVoteOverwrites; // How many times a vote can be replaced (only the last one counts)
        // Limits up to how much cost, the values of a vote can add up to (if applicable).
        // 0 => No limit / Not applicable
        uint16 maxTotalCost;
        // Defines the exponent that will be used to compute the "cost" of the options voted and compare it against `maxTotalCost`.
        // totalCost = Σ (value[i] ** costExponent) <= maxTotalCost
        //
        // Exponent range:
        // - 0 => 0.0000
        // - 10000 => 1.0000
        // - 65535 => 6.5535
        uint16 costExponent;
        uint256 evmBlockHeight; // EVM block number to use as a snapshot for the on-chain census
        bytes32 paramsSignature; // entity.sign({...}) // fields that the oracle uses to authentify process creation
    }

    /// @notice An entry for each process created by an Entity.
    /// @notice Keeps track of when it was created and what index this process has within the entire history of the Entity.
    /// @notice Use this to determine whether a process index belongs to the current instance or to a predecessor one.
    struct ProcessCheckpoint {
        uint256 index; // The index of this process within the entity's history, including predecessor instances
    }

    // PER-PROCESS DATA

    mapping(address => ProcessCheckpoint[]) internal entityCheckpoints; // Array of ProcessCheckpoint indexed by entity address
    mapping(bytes32 => Process) internal processes; // Mapping of all processes indexed by the Process ID

    // HELPERS

    function getEntityProcessCount(address entityAddress)
        public
        view
        override
        returns (uint256)
    {
        if (entityCheckpoints[entityAddress].length == 0) {
            // Not found locally
            if (predecessorAddress == address(0x0)) return 0; // No predecessor to ask

            // Ask the predecessor
            // Note: The predecessor's method needs to follow the old version's signature
            IProcessStore predecessor = IProcessStore(predecessorAddress);
            return predecessor.getEntityProcessCount(entityAddress);
        }

        return
            entityCheckpoints[entityAddress][
                entityCheckpoints[entityAddress].length - 1
            ]
                .index + 1;
    }

    /// @notice Get the next process ID to use for an entity
    function getNextProcessId(address entityAddress)
        public
        view
        override
        returns (bytes32)
    {
        // From 0 to N-1, the next index is N
        uint256 processCount = getEntityProcessCount(entityAddress);
        return
            getProcessId(entityAddress, processCount, namespaceId, ethChainId);
    }

    /// @notice Compute the process ID from the given parameters, salted with the contract chain ID
    function getProcessId(
        address entityAddress,
        uint256 processCountIndex,
        uint32 namespaceIdNum,
        uint32 ethereumChainId
    ) public pure override returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    entityAddress,
                    processCountIndex,
                    namespaceIdNum,
                    ethereumChainId
                )
            );
    }

    // GLOBAL METHODS

    /// @notice Creates a new instance of the contract and sets the contract owner (see Owned).
    /// @param predecessor The address of the predecessor instance (if any). `0x0` means no predecessor (see Chained).
    constructor(
        address predecessor,
        address namespace,
        address resultsAddr,
        address tokenStorageProof,
        uint32 ethereumChainId,
        uint256 procPrice
    ) public {
        Chained.setUp(predecessor);

        require(ContractSupport.isContract(namespace), "Invalid namespace");
        require(ContractSupport.isContract(resultsAddr), "Invalid results");
        require(
            ContractSupport.isContract(tokenStorageProof),
            "Invalid tokenStorageProof"
        );

        namespaceId = INamespaceStore(namespace).register();
        namespaceAddress = namespace;
        resultsAddress = resultsAddr;
        tokenStorageProofAddress = tokenStorageProof;
        ethChainId = ethereumChainId;
        processPrice = procPrice;
    }

    // GETTERS

    /// @notice Retrieves all the stored fields for the given processId
    function get(bytes32 processId)
        public
        view
        override
        returns (
            uint8[3] memory mode_envelopeType_censusOrigin, // [mode, envelopeType, censusOrigin]
            address entityAddress,
            string[3] memory metadata_censusRoot_censusUri, // [metadata, censusRoot, censusUri]
            uint32[2] memory startBlock_blockCount, // [startBlock, blockCount]
            Status status, // status
            uint8[5]
                memory questionIndex_questionCount_maxCount_maxValue_maxVoteOverwrites, // [questionIndex, questionCount, maxCount, maxValue, maxVoteOverwrites]
            uint16[2] memory maxTotalCost_costExponent,
            uint256 evmBlockHeight
        )
    {
        if (processes[processId].entity == address(0x0)) {
            // Not found locally
            if (predecessorAddress == address(0x0)) revert("Not found"); // No predecessor to ask

            // Ask the predecessor
            // Note: The predecessor's method needs to follow the old version's signature
            IProcessStore predecessor = IProcessStore(predecessorAddress);
            return predecessor.get(processId);
        }

        Process storage proc = processes[processId];
        mode_envelopeType_censusOrigin = [
            proc.mode,
            proc.envelopeType,
            uint8(proc.censusOrigin)
        ];
        entityAddress = proc.entity;
        metadata_censusRoot_censusUri = [
            proc.metadata,
            proc.censusRoot,
            proc.censusUri
        ];
        startBlock_blockCount = [proc.startBlock, proc.blockCount];
        status = proc.status;
        questionIndex_questionCount_maxCount_maxValue_maxVoteOverwrites = [
            proc.questionIndex,
            proc.questionCount,
            proc.maxCount,
            proc.maxValue,
            proc.maxVoteOverwrites
        ];
        maxTotalCost_costExponent = [proc.maxTotalCost, proc.costExponent];
        evmBlockHeight = proc.evmBlockHeight;
    }

    /// @notice Gets the signature of the process parameters, so that authentication can be performed on the Vochain as well
    function getParamsSignature(bytes32 processId)
        public
        view
        override
        returns (bytes32)
    {
        if (processes[processId].entity == address(0x0)) {
            // Not found locally
            if (predecessorAddress == address(0x0)) revert("Not found"); // No predecessor to ask

            // Ask the predecessor
            // Note: The predecessor's method needs to follow the old version's signature
            IProcessStore predecessor = IProcessStore(predecessorAddress);
            return predecessor.getParamsSignature(processId);
        }
        Process storage proc = processes[processId];
        return proc.paramsSignature;
    }

    /// @notice Gets the address of the process instance where the given processId was originally created.
    /// @notice This allows to know where to send update transactions, after a fork has occurred.
    function getCreationInstance(bytes32 processId)
        public
        view
        override
        returns (address)
    {
        if (processes[processId].entity == address(0x0)) {
            // Not found locally
            if (predecessorAddress == address(0x0)) revert("Not found"); // No predecessor to ask

            // Ask the predecessor
            // Note: The predecessor's method needs to follow the old version's signature
            IProcessStore predecessor = IProcessStore(predecessorAddress);
            return predecessor.getCreationInstance(processId);
        }

        // Found locally
        return address(this);
    }

    // ENTITY METHODS

    function newProcess(
        uint8[3] memory mode_envelopeType_censusOrigin, // [mode, envelopeType, censusOrigin]
        address tokenContractAddress,
        string[3] memory metadata_censusRoot_censusUri, //  [metadata, censusRoot, censusUri]
        uint32[2] memory startBlock_blockCount,
        uint8[4] memory questionCount_maxCount_maxValue_maxVoteOverwrites, // [questionCount, maxCount, maxValue, maxVoteOverwrites]
        uint16[2] memory maxTotalCost_costExponent, // [maxTotalCost, costExponent]
        uint256 evmBlockHeight, // EVM only
        bytes32 paramsSignature
    ) public override payable onlyIfActive {
        require (msg.value >= processPrice, "Insufficient funds");

        CensusOrigin origin = CensusOrigin(mode_envelopeType_censusOrigin[2]);
        if (
            origin == CensusOrigin.OFF_CHAIN_TREE ||
            origin == CensusOrigin.OFF_CHAIN_TREE_WEIGHTED ||
            origin == CensusOrigin.OFF_CHAIN_CA
        ) {
            newProcessStd(
                mode_envelopeType_censusOrigin,
                metadata_censusRoot_censusUri,
                startBlock_blockCount,
                questionCount_maxCount_maxValue_maxVoteOverwrites,
                maxTotalCost_costExponent,
                paramsSignature
            );
        } else if (origin == CensusOrigin.ERC20) {
            newProcessEvm(
                mode_envelopeType_censusOrigin,
                metadata_censusRoot_censusUri,
                tokenContractAddress,
                startBlock_blockCount,
                questionCount_maxCount_maxValue_maxVoteOverwrites,
                maxTotalCost_costExponent,
                evmBlockHeight,
                paramsSignature
            );
        } else {
            revert("Unsupported census origin");
        }
    }

    // Creates a new process using an external census
    function newProcessStd(
        uint8[3] memory mode_envelopeType_censusOrigin, // [mode, envelopeType, censusOrigin]
        string[3] memory metadata_censusRoot_censusUri, //  [metadata, censusRoot, censusUri]
        uint32[2] memory startBlock_blockCount,
        uint8[4] memory questionCount_maxCount_maxValue_maxVoteOverwrites, // [questionCount, maxCount, maxValue, maxVoteOverwrites]
        uint16[2] memory maxTotalCost_costExponent, // [maxTotalCost, costExponent]
        bytes32 paramsSignature
    ) internal {
        uint8 mode = mode_envelopeType_censusOrigin[0];

        // Sanity checks

        if (mode & MODE_AUTO_START != 0) {
            require(
                startBlock_blockCount[0] > 0,
                "Auto start requires a start block"
            );
        }
        if (mode & MODE_INTERRUPTIBLE == 0) {
            require(
                startBlock_blockCount[1] > 0,
                "Uninterruptible needs blockCount"
            );
        }
        require(
            bytes(metadata_censusRoot_censusUri[0]).length > 0,
            "No metadata"
        );
        require(
            bytes(metadata_censusRoot_censusUri[1]).length > 0,
            "No censusRoot"
        );
        require(
            bytes(metadata_censusRoot_censusUri[2]).length > 0,
            "No censusUri"
        );
        require(
            questionCount_maxCount_maxValue_maxVoteOverwrites[0] > 0,
            "No questionCount"
        );
        require(
            questionCount_maxCount_maxValue_maxVoteOverwrites[1] > 0 &&
                questionCount_maxCount_maxValue_maxVoteOverwrites[1] <= 100,
            "Invalid maxCount"
        );
        require(
            questionCount_maxCount_maxValue_maxVoteOverwrites[2] > 0,
            "No maxValue"
        );

        // Process creation

        // Index the process for the entity
        uint256 prevCount = getEntityProcessCount(msg.sender);

        entityCheckpoints[msg.sender].push();
        uint256 cIdx = entityCheckpoints[msg.sender].length - 1;
        ProcessCheckpoint storage checkpoint;
        checkpoint = entityCheckpoints[msg.sender][cIdx];
        checkpoint.index = prevCount;

        Status status;
        if (mode & MODE_AUTO_START != 0) {
            // Auto-start enabled processes start in READY state
            status = Status.READY;
        } else {
            // By default, processes start PAUSED (auto start disabled)
            status = Status.PAUSED;
        }

        // Store the new process
        bytes32 processId =
            getProcessId(msg.sender, prevCount, namespaceId, ethChainId);
        Process storage processData = processes[processId];

        processData.mode = mode_envelopeType_censusOrigin[0];
        processData.envelopeType = mode_envelopeType_censusOrigin[1];
        processData.censusOrigin = CensusOrigin(
            mode_envelopeType_censusOrigin[2]
        );

        processData.entity = msg.sender;
        processData.startBlock = startBlock_blockCount[0];
        processData.blockCount = startBlock_blockCount[1];
        processData.metadata = metadata_censusRoot_censusUri[0];

        processData.censusRoot = metadata_censusRoot_censusUri[1];
        processData.censusUri = metadata_censusRoot_censusUri[2];

        processData.status = status;
        // processData.questionIndex = 0;
        processData
            .questionCount = questionCount_maxCount_maxValue_maxVoteOverwrites[
            0
        ];
        processData
            .maxCount = questionCount_maxCount_maxValue_maxVoteOverwrites[1];
        processData
            .maxValue = questionCount_maxCount_maxValue_maxVoteOverwrites[2];
        processData
            .maxVoteOverwrites = questionCount_maxCount_maxValue_maxVoteOverwrites[
            3
        ];
        processData.maxTotalCost = maxTotalCost_costExponent[0];
        processData.costExponent = maxTotalCost_costExponent[1];
        processData.paramsSignature = paramsSignature;

        emit NewProcess(processId, namespaceId);
    }

    function newProcessEvm(
        uint8[3] memory mode_envelopeType_censusOrigin, // [mode, envelopeType, censusOrigin]
        string[3] memory metadata_censusRoot_censusUri, //  [metadata, censusRoot, censusUri]
        address tokenContractAddress,
        uint32[2] memory startBlock_blockCount,
        uint8[4] memory questionCount_maxCount_maxValue_maxVoteOverwrites, // [questionCount, maxCount, maxValue, maxVoteOverwrites]
        uint16[2] memory maxTotalCost_costExponent, // [maxTotalCost, costExponent]
        uint256 evmBlockHeight, // Ethereum block height at which the census will be considered
        bytes32 paramsSignature
    ) internal {
        uint8 mode = mode_envelopeType_censusOrigin[0];

        // Sanity checks

        require(
            mode & MODE_AUTO_START != 0,
            "Auto start is needed on EVM processes"
        );
        require(
            mode & MODE_INTERRUPTIBLE == 0,
            "Interruptible not allowed on EVM processes"
        );
        require(startBlock_blockCount[0] > 0, "Invalid start block");
        require(startBlock_blockCount[1] > 0, "Invalid blockCount");

        require(
            mode_envelopeType_censusOrigin[2] <= uint8(CensusOrigin.MINI_ME),
            "Invalid census origin value"
        );
        require(
            mode & MODE_DYNAMIC_CENSUS == 0,
            "Dynamic census not allowed on EVM processes"
        );
        require(
            tokenContractAddress != msg.sender &&
                tokenContractAddress != address(0x0),
            "Invalid token address"
        );

        // Check the token contract
        require(
            ITokenStorageProof(tokenStorageProofAddress).isRegistered(
                tokenContractAddress
            ),
            "Token not registered"
        );

        // Check that the sender holds tokens
        uint256 balance = IERC20(tokenContractAddress).balanceOf(msg.sender);
        require(balance > 0, "Insufficient funds");

        require(
            bytes(metadata_censusRoot_censusUri[0]).length > 0,
            "No metadata"
        );
        require(
            bytes(metadata_censusRoot_censusUri[1]).length > 0,
            "No censusRoot"
        );
        require(
            questionCount_maxCount_maxValue_maxVoteOverwrites[0] > 0,
            "No questionCount"
        );
        require(
            questionCount_maxCount_maxValue_maxVoteOverwrites[1] > 0 &&
                questionCount_maxCount_maxValue_maxVoteOverwrites[1] <= 100,
            "Invalid maxCount"
        );
        require(
            questionCount_maxCount_maxValue_maxVoteOverwrites[2] > 0,
            "No maxValue"
        );

        // Process creation

        // Index the process for the entity
        uint256 prevCount = getEntityProcessCount(tokenContractAddress);

        entityCheckpoints[tokenContractAddress].push();
        uint256 cIdx = entityCheckpoints[tokenContractAddress].length - 1;
        ProcessCheckpoint storage checkpoint;
        checkpoint = entityCheckpoints[tokenContractAddress][cIdx];
        checkpoint.index = prevCount;

        // Store the new process
        bytes32 processId =
            getProcessId(
                tokenContractAddress,
                prevCount,
                namespaceId,
                ethChainId
            );
        Process storage processData = processes[processId];

        processData.mode = mode_envelopeType_censusOrigin[0];
        processData.envelopeType = mode_envelopeType_censusOrigin[1];
        processData.censusOrigin = CensusOrigin(
            mode_envelopeType_censusOrigin[2]
        );

        processData.censusRoot = metadata_censusRoot_censusUri[1];
        // processData.censusUri = "";

        processData.entity = tokenContractAddress;
        processData.startBlock = startBlock_blockCount[0];
        processData.blockCount = startBlock_blockCount[1];
        processData.metadata = metadata_censusRoot_censusUri[0];

        processData.status = Status.READY;
        // processData.questionIndex = 0;
        processData
            .questionCount = questionCount_maxCount_maxValue_maxVoteOverwrites[
            0
        ];
        processData
            .maxCount = questionCount_maxCount_maxValue_maxVoteOverwrites[1];
        processData
            .maxValue = questionCount_maxCount_maxValue_maxVoteOverwrites[2];
        processData
            .maxVoteOverwrites = questionCount_maxCount_maxValue_maxVoteOverwrites[
            3
        ];
        processData.maxTotalCost = maxTotalCost_costExponent[0];
        processData.costExponent = maxTotalCost_costExponent[1];

        processData.evmBlockHeight = evmBlockHeight;
        processData.paramsSignature = paramsSignature;

        emit NewProcess(processId, namespaceId);
    }

    function setStatus(bytes32 processId, Status newStatus) public override {
        if (processes[processId].entity == address(0x0)) {
            // Not found locally
            if (predecessorAddress == address(0x0)) revert("Not found"); // No predecessor to ask
            revert("Not found: Try on predecessor");
        }

        Status currentStatus = processes[processId].status;

        // Only the results contract can set to RESULTS
        if (msg.sender == resultsAddress) {
            require(currentStatus != Status.CANCELED, "Canceled");
            require(currentStatus != Status.RESULTS, "Already set");
            require(newStatus == Status.RESULTS, "Not results contract");
            processes[processId].status = newStatus;
            emit StatusUpdated(processId, namespaceId, newStatus);
            return;
        }

        // Only the process creator
        require(processes[processId].entity == msg.sender, "Invalid entity");
        require(
            uint8(newStatus) <= uint8(Status.PAUSED), // [READY 0..3 PAUSED] => RESULTS (4) is not allowed
            "Invalid status code"
        );

        // Only processes managed by entities (with an off-chain census) can be updated
        CensusOrigin origin = CensusOrigin(processes[processId].censusOrigin);
        require(
            origin == CensusOrigin.OFF_CHAIN_TREE ||
                origin == CensusOrigin.OFF_CHAIN_TREE_WEIGHTED ||
                origin == CensusOrigin.OFF_CHAIN_CA,
            "Not off-chain"
        );

        if (currentStatus != Status.READY && currentStatus != Status.PAUSED) {
            // When currentStatus is [ENDED, CANCELED, RESULTS], no update is allowed
            revert("Process terminated");
        } else if (currentStatus == Status.PAUSED) {
            // newStatus can only be [READY, ENDED, CANCELED, PAUSED] (see the require above)

            if (processes[processId].mode & MODE_INTERRUPTIBLE == 0) {
                // Is not interruptible, we can only go from PAUSED to READY, the first time
                require(newStatus == Status.READY, "Not interruptible");
            }
        } else {
            // currentStatus is READY

            if (processes[processId].mode & MODE_INTERRUPTIBLE == 0) {
                // If not interruptible, no status update is allowed
                revert("Not interruptible");
            }

            // newStatus can only be [READY, ENDED, CANCELED, PAUSED] (see require above).
        }

        // If currentStatus is READY => Can go to [ENDED, CANCELED, PAUSED].
        // If currentStatus is PAUSED => Can go to [READY, ENDED, CANCELED].
        require(newStatus != currentStatus, "Must differ");

        // Note: the process can also be ended from incrementQuestionIndex
        // If questionIndex is already at the last one
        processes[processId].status = newStatus;

        emit StatusUpdated(processId, namespaceId, newStatus);
    }

    function incrementQuestionIndex(bytes32 processId) public override {
        if (processes[processId].entity == address(0x0)) {
            // Not found locally
            if (predecessorAddress == address(0x0)) revert("Not found"); // No predecessor to ask
            revert("Not found: Try on predecessor");
        }

        // Only the process creator
        require(processes[processId].entity == msg.sender, "Invalid entity");
        // Only if READY
        require(
            processes[processId].status == Status.READY,
            "Process not ready"
        );
        // Only when the envelope is in serial mode
        require(
            processes[processId].envelopeType & ENV_TYPE_SERIAL != 0,
            "Process not serial"
        );

        // Only processes managed by entities (with an off-chain census) can be updated
        CensusOrigin origin = CensusOrigin(processes[processId].censusOrigin);
        require(
            origin == CensusOrigin.OFF_CHAIN_TREE ||
                origin == CensusOrigin.OFF_CHAIN_TREE_WEIGHTED ||
                origin == CensusOrigin.OFF_CHAIN_CA,
            "Not off-chain"
        );

        uint8 nextIdx = processes[processId].questionIndex.add8(1);

        if (nextIdx < processes[processId].questionCount) {
            processes[processId].questionIndex = nextIdx;

            // Not at the last question yet
            emit QuestionIndexUpdated(processId, namespaceId, nextIdx);
        } else {
            // The last question was currently active => End the process
            processes[processId].status = Status.ENDED;

            emit StatusUpdated(processId, namespaceId, Status.ENDED);
        }
    }

    function setCensus(
        bytes32 processId,
        string memory censusRoot,
        string memory censusUri
    ) public override onlyIfActive {
        require(bytes(censusRoot).length > 0, "No Census Root");
        require(bytes(censusUri).length > 0, "No Census URI");

        if (processes[processId].entity == address(0x0)) {
            // Not found locally
            if (predecessorAddress == address(0x0)) revert("Not found"); // No predecessor to ask
            revert("Not found: Try on predecessor");
        }

        // Only the process creator
        require(processes[processId].entity == msg.sender, "Invalid entity");
        // Only if the process is ongoing
        require(
            processes[processId].status == Status.READY ||
                processes[processId].status == Status.PAUSED,
            "Process terminated"
        );
        // Only when the census is dynamic
        require(
            processes[processId].mode & MODE_DYNAMIC_CENSUS != 0,
            "Read-only census"
        );

        // Only processes managed by entities (with an off-chain census) can be updated
        CensusOrigin origin = CensusOrigin(processes[processId].censusOrigin);
        require(
            origin == CensusOrigin.OFF_CHAIN_TREE ||
                origin == CensusOrigin.OFF_CHAIN_TREE_WEIGHTED ||
                origin == CensusOrigin.OFF_CHAIN_CA,
            "Not off-chain"
        );

        processes[processId].censusRoot = censusRoot;
        processes[processId].censusUri = censusUri;

        emit CensusUpdated(processId, namespaceId);
    }

    function setProcessPrice(uint256 newPrice) public override onlyContractOwner {
        if (newPrice == processPrice) return;

        processPrice = newPrice;
        emit ProcessPriceUpdated(newPrice);
    }

    function withdraw(address payable to, uint256 amount) public override onlyContractOwner {
        if (amount == 0) return;
        require(address(this).balance > amount, "Not enough funds");
        require(to != address(0x0), "Invalid address");

        payable(to).transfer(amount);
        emit Withdraw(to, amount);
    }
}