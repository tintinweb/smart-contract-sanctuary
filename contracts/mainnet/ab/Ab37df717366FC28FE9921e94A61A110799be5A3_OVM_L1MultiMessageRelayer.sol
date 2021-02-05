// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;
/* Interface Imports */
import { iOVM_L1CrossDomainMessenger } from "../../iOVM/bridge/iOVM_L1CrossDomainMessenger.sol";
import { iOVM_L1MultiMessageRelayer } from "../../iOVM/bridge/iOVM_L1MultiMessageRelayer.sol";

/* Contract Imports */
import { Lib_AddressResolver } from "../../libraries/resolver/Lib_AddressResolver.sol";


/**
 * @title OVM_L1MultiMessageRelayer
 * @dev The L1 Multi-Message Relayer contract is a gas efficiency optimization which enables the 
 * relayer to submit multiple messages in a single transaction to be relayed by the L1 Cross Domain
 * Message Sender.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_L1MultiMessageRelayer is iOVM_L1MultiMessageRelayer, Lib_AddressResolver {

    /***************
     * Constructor *
     ***************/
    constructor(
        address _libAddressManager
    ) 
        Lib_AddressResolver(_libAddressManager)
    {}

    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyBatchRelayer() {
        require(
            msg.sender == resolve("OVM_L2BatchMessageRelayer"),
            "OVM_L1MultiMessageRelayer: Function can only be called by the OVM_L2BatchMessageRelayer"
        );
        _;
    }

    /********************
     * Public Functions *
     ********************/

    /**
     * @notice Forwards multiple cross domain messages to the L1 Cross Domain Messenger for relaying
     * @param _messages An array of L2 to L1 messages
     */
    function batchRelayMessages(L2ToL1Message[] calldata _messages) 
        override
        external
        onlyBatchRelayer 
    {
        iOVM_L1CrossDomainMessenger messenger = iOVM_L1CrossDomainMessenger(resolve("Proxy__OVM_L1CrossDomainMessenger"));
        for (uint256 i = 0; i < _messages.length; i++) {
            L2ToL1Message memory message = _messages[i];
            messenger.relayMessage(
                message.target,
                message.sender,
                message.message,
                message.messageNonce,
                message.proof
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";

/* Interface Imports */
import { iOVM_BaseCrossDomainMessenger } from "./iOVM_BaseCrossDomainMessenger.sol";

/**
 * @title iOVM_L1CrossDomainMessenger
 */
interface iOVM_L1CrossDomainMessenger is iOVM_BaseCrossDomainMessenger {

    /*******************
     * Data Structures *
     *******************/

    struct L2MessageInclusionProof {
        bytes32 stateRoot;
        Lib_OVMCodec.ChainBatchHeader stateRootBatchHeader;
        Lib_OVMCodec.ChainInclusionProof stateRootProof;
        bytes stateTrieWitness;
        bytes storageTrieWitness;
    }


    /********************
     * Public Functions *
     ********************/

    /**
     * Relays a cross domain message to a contract.
     * @param _target Target contract address.
     * @param _sender Message sender address.
     * @param _message Message to send to the target.
     * @param _messageNonce Nonce for the provided message.
     * @param _proof Inclusion proof for the given message.
     */
    function relayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _messageNonce,
        L2MessageInclusionProof memory _proof
    ) external;

    /**
     * Replays a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _sender Original sender address.
     * @param _message Message to send to the target.
     * @param _messageNonce Nonce for the provided message.
     * @param _gasLimit Gas limit for the provided message.
     */
    function replayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _messageNonce,
        uint32 _gasLimit
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_RLPReader } from "../rlp/Lib_RLPReader.sol";
import { Lib_RLPWriter } from "../rlp/Lib_RLPWriter.sol";
import { Lib_BytesUtils } from "../utils/Lib_BytesUtils.sol";
import { Lib_Bytes32Utils } from "../utils/Lib_Bytes32Utils.sol";
import { Lib_SafeExecutionManagerWrapper } from "../../libraries/wrappers/Lib_SafeExecutionManagerWrapper.sol";

/**
 * @title Lib_OVMCodec
 */
library Lib_OVMCodec {

    /*************
     * Constants *
     *************/

    bytes constant internal RLP_NULL_BYTES = hex'80';
    bytes constant internal NULL_BYTES = bytes('');

    // Ring buffer IDs
    bytes32 constant internal RING_BUFFER_SCC_BATCHES = keccak256("RING_BUFFER_SCC_BATCHES");
    bytes32 constant internal RING_BUFFER_CTC_BATCHES = keccak256("RING_BUFFER_CTC_BATCHES");
    bytes32 constant internal RING_BUFFER_CTC_QUEUE = keccak256("RING_BUFFER_CTC_QUEUE");


    /*********
     * Enums *
     *********/

    enum EOASignatureType {
        EIP155_TRANSACTON,
        ETH_SIGNED_MESSAGE
    }

    enum QueueOrigin {
        SEQUENCER_QUEUE,
        L1TOL2_QUEUE
    }


    /***********
     * Structs *
     ***********/

    struct Account {
        uint256 nonce;
        uint256 balance;
        bytes32 storageRoot;
        bytes32 codeHash;
        address ethAddress;
        bool isFresh;
    }

    struct EVMAccount {
        uint256 nonce;
        uint256 balance;
        bytes32 storageRoot;
        bytes32 codeHash;
    }

    struct ChainBatchHeader {
        uint256 batchIndex;
        bytes32 batchRoot;
        uint256 batchSize;
        uint256 prevTotalElements;
        bytes extraData;
    }

    struct ChainInclusionProof {
        uint256 index;
        bytes32[] siblings;
    }

    struct Transaction {
        uint256 timestamp;
        uint256 blockNumber;
        QueueOrigin l1QueueOrigin;
        address l1TxOrigin;
        address entrypoint;
        uint256 gasLimit;
        bytes data;
    }

    struct TransactionChainElement {
        bool isSequenced;
        uint256 queueIndex;  // QUEUED TX ONLY
        uint256 timestamp;   // SEQUENCER TX ONLY
        uint256 blockNumber; // SEQUENCER TX ONLY
        bytes txData;        // SEQUENCER TX ONLY
    }

    struct QueueElement {
        bytes32 queueRoot;
        uint40 timestamp;
        uint40 blockNumber;
    }

    struct EIP155Transaction {
        uint256 nonce;
        uint256 gasPrice;
        uint256 gasLimit;
        address to;
        uint256 value;
        bytes data;
        uint256 chainId;
    }


    /*********************************************
     * Internal Functions: Encoding and Decoding *
     *********************************************/

    /**
     * Decodes an EOA transaction (i.e., native Ethereum RLP encoding).
     * @param _transaction Encoded EOA transaction.
     * @return _decoded Transaction decoded into a struct.
     */
    function decodeEIP155Transaction(
        bytes memory _transaction,
        bool _isEthSignedMessage
    )
        internal
        pure
        returns (
            EIP155Transaction memory _decoded
        )
    {
        if (_isEthSignedMessage) {
            (
                uint256 _nonce,
                uint256 _gasLimit,
                uint256 _gasPrice,
                uint256 _chainId,
                address _to,
                bytes memory _data
            ) = abi.decode(
                _transaction,
                (uint256, uint256, uint256, uint256, address ,bytes)
            );
            return EIP155Transaction({
                nonce: _nonce,
                gasPrice: _gasPrice,
                gasLimit: _gasLimit,
                to: _to,
                value: 0,
                data: _data,
                chainId: _chainId
            });
        } else {
            Lib_RLPReader.RLPItem[] memory decoded = Lib_RLPReader.readList(_transaction);

            return EIP155Transaction({
                nonce: Lib_RLPReader.readUint256(decoded[0]),
                gasPrice: Lib_RLPReader.readUint256(decoded[1]),
                gasLimit: Lib_RLPReader.readUint256(decoded[2]),
                to: Lib_RLPReader.readAddress(decoded[3]),
                value: Lib_RLPReader.readUint256(decoded[4]),
                data: Lib_RLPReader.readBytes(decoded[5]),
                chainId:  Lib_RLPReader.readUint256(decoded[6])
            });
        }
    }

    function decompressEIP155Transaction(
        bytes memory _transaction
    )
        internal
        returns (
            EIP155Transaction memory _decompressed
        )
    {
        return EIP155Transaction({
            gasLimit: Lib_BytesUtils.toUint24(_transaction, 0),
            gasPrice: uint256(Lib_BytesUtils.toUint24(_transaction, 3)) * 1000000,
            nonce: Lib_BytesUtils.toUint24(_transaction, 6),
            to: Lib_BytesUtils.toAddress(_transaction, 9),
            data: Lib_BytesUtils.slice(_transaction, 29),
            chainId: Lib_SafeExecutionManagerWrapper.safeCHAINID(),
            value: 0
        });
    }

    /**
     * Encodes an EOA transaction back into the original transaction.
     * @param _transaction EIP155transaction to encode.
     * @param _isEthSignedMessage Whether or not this was an eth signed message.
     * @return Encoded transaction.
     */
    function encodeEIP155Transaction(
        EIP155Transaction memory _transaction,
        bool _isEthSignedMessage
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        if (_isEthSignedMessage) {
            return abi.encode(
                _transaction.nonce,
                _transaction.gasLimit,
                _transaction.gasPrice,
                _transaction.chainId,
                _transaction.to,
                _transaction.data
            );
        } else {
            bytes[] memory raw = new bytes[](9);

            raw[0] = Lib_RLPWriter.writeUint(_transaction.nonce);
            raw[1] = Lib_RLPWriter.writeUint(_transaction.gasPrice);
            raw[2] = Lib_RLPWriter.writeUint(_transaction.gasLimit);
            if (_transaction.to == address(0)) {
                raw[3] = Lib_RLPWriter.writeBytes('');
            } else {
                raw[3] = Lib_RLPWriter.writeAddress(_transaction.to);
            }
            raw[4] = Lib_RLPWriter.writeUint(0);
            raw[5] = Lib_RLPWriter.writeBytes(_transaction.data);
            raw[6] = Lib_RLPWriter.writeUint(_transaction.chainId);
            raw[7] = Lib_RLPWriter.writeBytes(bytes(''));
            raw[8] = Lib_RLPWriter.writeBytes(bytes(''));

            return Lib_RLPWriter.writeList(raw);
        }
    }

    /**
     * Encodes a standard OVM transaction.
     * @param _transaction OVM transaction to encode.
     * @return _encoded Encoded transaction bytes.
     */
    function encodeTransaction(
        Transaction memory _transaction
    )
        internal
        pure
        returns (
            bytes memory _encoded
        )
    {
        return abi.encodePacked(
            _transaction.timestamp,
            _transaction.blockNumber,
            _transaction.l1QueueOrigin,
            _transaction.l1TxOrigin,
            _transaction.entrypoint,
            _transaction.gasLimit,
            _transaction.data
        );
    }

    /**
     * Hashes a standard OVM transaction.
     * @param _transaction OVM transaction to encode.
     * @return _hash Hashed transaction
     */
    function hashTransaction(
        Transaction memory _transaction
    )
        internal
        pure
        returns (
            bytes32 _hash
        )
    {
        return keccak256(encodeTransaction(_transaction));
    }

    /**
     * Converts an OVM account to an EVM account.
     * @param _in OVM account to convert.
     * @return _out Converted EVM account.
     */
    function toEVMAccount(
        Account memory _in
    )
        internal
        pure
        returns (
            EVMAccount memory _out
        )
    {
        return EVMAccount({
            nonce: _in.nonce,
            balance: _in.balance,
            storageRoot: _in.storageRoot,
            codeHash: _in.codeHash
        });
    }

    /**
     * @notice RLP-encodes an account state struct.
     * @param _account Account state struct.
     * @return _encoded RLP-encoded account state.
     */
    function encodeEVMAccount(
        EVMAccount memory _account
    )
        internal
        pure
        returns (
            bytes memory _encoded
        )
    {
        bytes[] memory raw = new bytes[](4);

        // Unfortunately we can't create this array outright because
        // Lib_RLPWriter.writeList will reject fixed-size arrays. Assigning
        // index-by-index circumvents this issue.
        raw[0] = Lib_RLPWriter.writeBytes(
            Lib_Bytes32Utils.removeLeadingZeros(
                bytes32(_account.nonce)
            )
        );
        raw[1] = Lib_RLPWriter.writeBytes(
            Lib_Bytes32Utils.removeLeadingZeros(
                bytes32(_account.balance)
            )
        );
        raw[2] = Lib_RLPWriter.writeBytes(abi.encodePacked(_account.storageRoot));
        raw[3] = Lib_RLPWriter.writeBytes(abi.encodePacked(_account.codeHash));

        return Lib_RLPWriter.writeList(raw);
    }

    /**
     * @notice Decodes an RLP-encoded account state into a useful struct.
     * @param _encoded RLP-encoded account state.
     * @return _account Account state struct.
     */
    function decodeEVMAccount(
        bytes memory _encoded
    )
        internal
        pure
        returns (
            EVMAccount memory _account
        )
    {
        Lib_RLPReader.RLPItem[] memory accountState = Lib_RLPReader.readList(_encoded);

        return EVMAccount({
            nonce: Lib_RLPReader.readUint256(accountState[0]),
            balance: Lib_RLPReader.readUint256(accountState[1]),
            storageRoot: Lib_RLPReader.readBytes32(accountState[2]),
            codeHash: Lib_RLPReader.readBytes32(accountState[3])
        });
    }

    /**
     * Calculates a hash for a given batch header.
     * @param _batchHeader Header to hash.
     * @return _hash Hash of the header.
     */
    function hashBatchHeader(
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader
    )
        internal
        pure
        returns (
            bytes32 _hash
        )
    {
        return keccak256(
            abi.encode(
                _batchHeader.batchRoot,
                _batchHeader.batchSize,
                _batchHeader.prevTotalElements,
                _batchHeader.extraData
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title Lib_RLPReader
 * @dev Adapted from "RLPReader" by Hamdi Allam ([email protected]).
 */
library Lib_RLPReader {

    /*************
     * Constants *
     *************/

    uint256 constant internal MAX_LIST_LENGTH = 32;


    /*********
     * Enums *
     *********/

    enum RLPItemType {
        DATA_ITEM,
        LIST_ITEM
    }

    
    /***********
     * Structs *
     ***********/

    struct RLPItem {
        uint256 length;
        uint256 ptr;
    }
    

    /**********************
     * Internal Functions *
     **********************/
    
    /**
     * Converts bytes to a reference to memory position and length.
     * @param _in Input bytes to convert.
     * @return Output memory reference.
     */
    function toRLPItem(
        bytes memory _in
    )
        internal
        pure
        returns (
            RLPItem memory
        )
    {
        uint256 ptr;
        assembly {
            ptr := add(_in, 32)
        }

        return RLPItem({
            length: _in.length,
            ptr: ptr
        });
    }

    /**
     * Reads an RLP list value into a list of RLP items.
     * @param _in RLP list value.
     * @return Decoded RLP list items.
     */
    function readList(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            RLPItem[] memory
        )
    {
        (
            uint256 listOffset,
            ,
            RLPItemType itemType
        ) = _decodeLength(_in);

        require(
            itemType == RLPItemType.LIST_ITEM,
            "Invalid RLP list value."
        );

        // Solidity in-memory arrays can't be increased in size, but *can* be decreased in size by
        // writing to the length. Since we can't know the number of RLP items without looping over
        // the entire input, we'd have to loop twice to accurately size this array. It's easier to
        // simply set a reasonable maximum list length and decrease the size before we finish.
        RLPItem[] memory out = new RLPItem[](MAX_LIST_LENGTH);

        uint256 itemCount = 0;
        uint256 offset = listOffset;
        while (offset < _in.length) {
            require(
                itemCount < MAX_LIST_LENGTH,
                "Provided RLP list exceeds max list length."
            );

            (
                uint256 itemOffset,
                uint256 itemLength,
            ) = _decodeLength(RLPItem({
                length: _in.length - offset,
                ptr: _in.ptr + offset
            }));

            out[itemCount] = RLPItem({
                length: itemLength + itemOffset,
                ptr: _in.ptr + offset
            });

            itemCount += 1;
            offset += itemOffset + itemLength;
        }

        // Decrease the array size to match the actual item count.
        assembly {
            mstore(out, itemCount)
        }

        return out;
    }

    /**
     * Reads an RLP list value into a list of RLP items.
     * @param _in RLP list value.
     * @return Decoded RLP list items.
     */
    function readList(
        bytes memory _in
    )
        internal
        pure
        returns (
            RLPItem[] memory
        )
    {
        return readList(
            toRLPItem(_in)
        );
    }

    /**
     * Reads an RLP bytes value into bytes.
     * @param _in RLP bytes value.
     * @return Decoded bytes.
     */
    function readBytes(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        (
            uint256 itemOffset,
            uint256 itemLength,
            RLPItemType itemType
        ) = _decodeLength(_in);

        require(
            itemType == RLPItemType.DATA_ITEM,
            "Invalid RLP bytes value."
        );

        return _copy(_in.ptr, itemOffset, itemLength);
    }

    /**
     * Reads an RLP bytes value into bytes.
     * @param _in RLP bytes value.
     * @return Decoded bytes.
     */
    function readBytes(
        bytes memory _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        return readBytes(
            toRLPItem(_in)
        );
    }

    /**
     * Reads an RLP string value into a string.
     * @param _in RLP string value.
     * @return Decoded string.
     */
    function readString(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            string memory
        )
    {
        return string(readBytes(_in));
    }

    /**
     * Reads an RLP string value into a string.
     * @param _in RLP string value.
     * @return Decoded string.
     */
    function readString(
        bytes memory _in
    )
        internal
        pure
        returns (
            string memory
        )
    {
        return readString(
            toRLPItem(_in)
        );
    }

    /**
     * Reads an RLP bytes32 value into a bytes32.
     * @param _in RLP bytes32 value.
     * @return Decoded bytes32.
     */
    function readBytes32(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        require(
            _in.length <= 33,
            "Invalid RLP bytes32 value."
        );

        (
            uint256 itemOffset,
            uint256 itemLength,
            RLPItemType itemType
        ) = _decodeLength(_in);

        require(
            itemType == RLPItemType.DATA_ITEM,
            "Invalid RLP bytes32 value."
        );

        uint256 ptr = _in.ptr + itemOffset;
        bytes32 out;
        assembly {
            out := mload(ptr)

            // Shift the bytes over to match the item size.
            if lt(itemLength, 32) {
                out := div(out, exp(256, sub(32, itemLength)))
            }
        }

        return out;
    }

    /**
     * Reads an RLP bytes32 value into a bytes32.
     * @param _in RLP bytes32 value.
     * @return Decoded bytes32.
     */
    function readBytes32(
        bytes memory _in
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return readBytes32(
            toRLPItem(_in)
        );
    }

    /**
     * Reads an RLP uint256 value into a uint256.
     * @param _in RLP uint256 value.
     * @return Decoded uint256.
     */
    function readUint256(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            uint256
        )
    {
        return uint256(readBytes32(_in));
    }

    /**
     * Reads an RLP uint256 value into a uint256.
     * @param _in RLP uint256 value.
     * @return Decoded uint256.
     */
    function readUint256(
        bytes memory _in
    )
        internal
        pure
        returns (
            uint256
        )
    {
        return readUint256(
            toRLPItem(_in)
        );
    }

    /**
     * Reads an RLP bool value into a bool.
     * @param _in RLP bool value.
     * @return Decoded bool.
     */
    function readBool(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            bool
        )
    {
        require(
            _in.length == 1,
            "Invalid RLP boolean value."
        );

        uint256 ptr = _in.ptr;
        uint256 out;
        assembly {
            out := byte(0, mload(ptr))
        }

        return out != 0;
    }

    /**
     * Reads an RLP bool value into a bool.
     * @param _in RLP bool value.
     * @return Decoded bool.
     */
    function readBool(
        bytes memory _in
    )
        internal
        pure
        returns (
            bool
        )
    {
        return readBool(
            toRLPItem(_in)
        );
    }

    /**
     * Reads an RLP address value into a address.
     * @param _in RLP address value.
     * @return Decoded address.
     */
    function readAddress(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            address
        )
    {
        if (_in.length == 1) {
            return address(0);
        }

        require(
            _in.length == 21,
            "Invalid RLP address value."
        );

        return address(readUint256(_in));
    }

    /**
     * Reads an RLP address value into a address.
     * @param _in RLP address value.
     * @return Decoded address.
     */
    function readAddress(
        bytes memory _in
    )
        internal
        pure
        returns (
            address
        )
    {
        return readAddress(
            toRLPItem(_in)
        );
    }

    /**
     * Reads the raw bytes of an RLP item.
     * @param _in RLP item to read.
     * @return Raw RLP bytes.
     */
    function readRawBytes(
        RLPItem memory _in
    )
        internal
        pure
        returns (
            bytes memory
        )
    {
        return _copy(_in);
    }


    /*********************
     * Private Functions *
     *********************/

    /**
     * Decodes the length of an RLP item.
     * @param _in RLP item to decode.
     * @return Offset of the encoded data.
     * @return Length of the encoded data.
     * @return RLP item type (LIST_ITEM or DATA_ITEM).
     */
    function _decodeLength(
        RLPItem memory _in
    )
        private
        pure
        returns (
            uint256,
            uint256,
            RLPItemType
        )
    {
        require(
            _in.length > 0,
            "RLP item cannot be null."
        );

        uint256 ptr = _in.ptr;
        uint256 prefix;
        assembly {
            prefix := byte(0, mload(ptr))
        }

        if (prefix <= 0x7f) {
            // Single byte.

            return (0, 1, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xb7) {
            // Short string.

            uint256 strLen = prefix - 0x80;
            
            require(
                _in.length > strLen,
                "Invalid RLP short string."
            );

            return (1, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xbf) {
            // Long string.
            uint256 lenOfStrLen = prefix - 0xb7;

            require(
                _in.length > lenOfStrLen,
                "Invalid RLP long string length."
            );

            uint256 strLen;
            assembly {
                // Pick out the string length.
                strLen := div(
                    mload(add(ptr, 1)),
                    exp(256, sub(32, lenOfStrLen))
                )
            }

            require(
                _in.length > lenOfStrLen + strLen,
                "Invalid RLP long string."
            );

            return (1 + lenOfStrLen, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xf7) {
            // Short list.
            uint256 listLen = prefix - 0xc0;

            require(
                _in.length > listLen,
                "Invalid RLP short list."
            );

            return (1, listLen, RLPItemType.LIST_ITEM);
        } else {
            // Long list.
            uint256 lenOfListLen = prefix - 0xf7;

            require(
                _in.length > lenOfListLen,
                "Invalid RLP long list length."
            );

            uint256 listLen;
            assembly {
                // Pick out the list length.
                listLen := div(
                    mload(add(ptr, 1)),
                    exp(256, sub(32, lenOfListLen))
                )
            }

            require(
                _in.length > lenOfListLen + listLen,
                "Invalid RLP long list."
            );

            return (1 + lenOfListLen, listLen, RLPItemType.LIST_ITEM);
        }
    }

    /**
     * Copies the bytes from a memory location.
     * @param _src Pointer to the location to read from.
     * @param _offset Offset to start reading from.
     * @param _length Number of bytes to read.
     * @return Copied bytes.
     */
    function _copy(
        uint256 _src,
        uint256 _offset,
        uint256 _length
    )
        private
        pure
        returns (
            bytes memory
        )
    {
        bytes memory out = new bytes(_length);
        if (out.length == 0) {
            return out;
        }

        uint256 src = _src + _offset;
        uint256 dest;
        assembly {
            dest := add(out, 32)
        }

        // Copy over as many complete words as we can.
        for (uint256 i = 0; i < _length / 32; i++) {
            assembly {
                mstore(dest, mload(src))
            }

            src += 32;
            dest += 32;
        }

        // Pick out the remaining bytes.
        uint256 mask = 256 ** (32 - (_length % 32)) - 1;
        assembly {
            mstore(
                dest,
                or(
                    and(mload(src), not(mask)),
                    and(mload(dest), mask)
                )
            )
        }

        return out;
    }

    /**
     * Copies an RLP item into bytes.
     * @param _in RLP item to copy.
     * @return Copied bytes.
     */
    function _copy(
        RLPItem memory _in
    )
        private
        pure
        returns (
            bytes memory
        )
    {
        return _copy(_in.ptr, 0, _in.length);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_BytesUtils } from "../utils/Lib_BytesUtils.sol";

/**
 * @title Lib_RLPWriter
 * @author Bakaoh (with modifications)
 */
library Lib_RLPWriter {

    /**********************
     * Internal Functions *
     **********************/

    /**
     * RLP encodes a byte string.
     * @param _in The byte string to encode.
     * @return _out The RLP encoded string in bytes.
     */
    function writeBytes(
        bytes memory _in
    )
        internal
        pure
        returns (
            bytes memory _out
        )
    {
        bytes memory encoded;

        if (_in.length == 1 && uint8(_in[0]) < 128) {
            encoded = _in;
        } else {
            encoded = Lib_BytesUtils.concat(_writeLength(_in.length, 128), _in);
        }

        return encoded;
    }

    /**
     * RLP encodes a list of RLP encoded byte byte strings.
     * @param _in The list of RLP encoded byte strings.
     * @return _out The RLP encoded list of items in bytes.
     */
    function writeList(
        bytes[] memory _in
    )
        internal
        pure
        returns (
            bytes memory _out
        )
    {
        bytes memory list = _flatten(_in);
        return Lib_BytesUtils.concat(_writeLength(list.length, 192), list);
    }

    /**
     * RLP encodes a string.
     * @param _in The string to encode.
     * @return _out The RLP encoded string in bytes.
     */
    function writeString(
        string memory _in
    )
        internal
        pure
        returns (
            bytes memory _out
        )
    {
        return writeBytes(bytes(_in));
    }

    /**
     * RLP encodes an address.
     * @param _in The address to encode.
     * @return _out The RLP encoded address in bytes.
     */
    function writeAddress(
        address _in
    )
        internal
        pure
        returns (
            bytes memory _out
        )
    {
        return writeBytes(abi.encodePacked(_in));
    }

    /**
     * RLP encodes a uint.
     * @param _in The uint256 to encode.
     * @return _out The RLP encoded uint256 in bytes.
     */
    function writeUint(
        uint256 _in
    )
        internal
        pure
        returns (
            bytes memory _out
        )
    {
        return writeBytes(_toBinary(_in));
    }

    /**
     * RLP encodes a bool.
     * @param _in The bool to encode.
     * @return _out The RLP encoded bool in bytes.
     */
    function writeBool(
        bool _in
    )
        internal
        pure
        returns (
            bytes memory _out
        )
    {
        bytes memory encoded = new bytes(1);
        encoded[0] = (_in ? bytes1(0x01) : bytes1(0x80));
        return encoded;
    }


    /*********************
     * Private Functions *
     *********************/

    /**
     * Encode the first byte, followed by the `len` in binary form if `length` is more than 55.
     * @param _len The length of the string or the payload.
     * @param _offset 128 if item is string, 192 if item is list.
     * @return _encoded RLP encoded bytes.
     */
    function _writeLength(
        uint256 _len,
        uint256 _offset
    )
        private
        pure
        returns (
            bytes memory _encoded
        )
    {
        bytes memory encoded;

        if (_len < 56) {
            encoded = new bytes(1);
            encoded[0] = byte(uint8(_len) + uint8(_offset));
        } else {
            uint256 lenLen;
            uint256 i = 1;
            while (_len / i != 0) {
                lenLen++;
                i *= 256;
            }

            encoded = new bytes(lenLen + 1);
            encoded[0] = byte(uint8(lenLen) + uint8(_offset) + 55);
            for(i = 1; i <= lenLen; i++) {
                encoded[i] = byte(uint8((_len / (256**(lenLen-i))) % 256));
            }
        }

        return encoded;
    }

    /**
     * Encode integer in big endian binary form with no leading zeroes.
     * @notice TODO: This should be optimized with assembly to save gas costs.
     * @param _x The integer to encode.
     * @return _binary RLP encoded bytes.
     */
    function _toBinary(
        uint256 _x
    )
        private
        pure
        returns (
            bytes memory _binary
        )
    {
        bytes memory b = abi.encodePacked(_x);

        uint256 i = 0;
        for (; i < 32; i++) {
            if (b[i] != 0) {
                break;
            }
        }

        bytes memory res = new bytes(32 - i);
        for (uint256 j = 0; j < res.length; j++) {
            res[j] = b[i++];
        }

        return res;
    }

    /**
     * Copies a piece of memory to another location.
     * @notice From: https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol.
     * @param _dest Destination location.
     * @param _src Source location.
     * @param _len Length of memory to copy.
     */
    function _memcpy(
        uint256 _dest,
        uint256 _src,
        uint256 _len
    )
        private
        pure
    {
        uint256 dest = _dest;
        uint256 src = _src;
        uint256 len = _len;

        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        uint256 mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /**
     * Flattens a list of byte strings into one byte string.
     * @notice From: https://github.com/sammayo/solidity-rlp-encoder/blob/master/RLPEncode.sol.
     * @param _list List of byte strings to flatten.
     * @return _flattened The flattened byte string.
     */
    function _flatten(
        bytes[] memory _list
    )
        private
        pure
        returns (
            bytes memory _flattened
        )
    {
        if (_list.length == 0) {
            return new bytes(0);
        }

        uint256 len;
        uint256 i = 0;
        for (; i < _list.length; i++) {
            len += _list[i].length;
        }

        bytes memory flattened = new bytes(len);
        uint256 flattenedPtr;
        assembly { flattenedPtr := add(flattened, 0x20) }

        for(i = 0; i < _list.length; i++) {
            bytes memory item = _list[i];

            uint256 listPtr;
            assembly { listPtr := add(item, 0x20)}

            _memcpy(flattenedPtr, listPtr, item.length);
            flattenedPtr += _list[i].length;
        }

        return flattened;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title Lib_BytesUtils
 */
library Lib_BytesUtils {

    /**********************
     * Internal Functions *
     **********************/

    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function slice(
        bytes memory _bytes,
        uint256 _start
    )
        internal
        pure
        returns (bytes memory)
    {
        if (_bytes.length - _start == 0) {
            return bytes('');
        }

        return slice(_bytes, _start, _bytes.length - _start);
    }

    function toBytes32PadLeft(
        bytes memory _bytes
    )
        internal
        pure
        returns (bytes32)
    {
        bytes32 ret;
        uint256 len = _bytes.length <= 32 ? _bytes.length : 32;
        assembly {
            ret := shr(mul(sub(32, len), 8), mload(add(_bytes, 32)))
        }
        return ret;
    }

    function toBytes32(
        bytes memory _bytes
    )
        internal
        pure
        returns (bytes32)
    {
        if (_bytes.length < 32) {
            bytes32 ret;
            assembly {
                ret := mload(add(_bytes, 32))
            }
            return ret;
        }

        return abi.decode(_bytes,(bytes32)); // will truncate if input length > 32 bytes
    }

    function toUint256(
        bytes memory _bytes
    )
        internal
        pure
        returns (uint256)
    {
        return uint256(toBytes32(_bytes));
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3 , "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toNibbles(
        bytes memory _bytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory nibbles = new bytes(_bytes.length * 2);

        for (uint256 i = 0; i < _bytes.length; i++) {
            nibbles[i * 2] = _bytes[i] >> 4;
            nibbles[i * 2 + 1] = bytes1(uint8(_bytes[i]) % 16);
        }

        return nibbles;
    }

    function fromNibbles(
        bytes memory _bytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory ret = new bytes(_bytes.length / 2);

        for (uint256 i = 0; i < ret.length; i++) {
            ret[i] = (_bytes[i * 2] << 4) | (_bytes[i * 2 + 1]);
        }

        return ret;
    }

    function equal(
        bytes memory _bytes,
        bytes memory _other
    )
        internal
        pure
        returns (bool)
    {
        return keccak256(_bytes) == keccak256(_other);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title Lib_Byte32Utils
 */
library Lib_Bytes32Utils {

    /**********************
     * Internal Functions *
     **********************/

    function toBool(
        bytes32 _in
    )
        internal
        pure
        returns (
            bool _out
        )
    {
        return _in != 0;
    }

    function fromBool(
        bool _in
    )
        internal
        pure
        returns (
            bytes32 _out
        )
    {
        return bytes32(uint256(_in ? 1 : 0));
    }

    function toAddress(
        bytes32 _in
    )
        internal
        pure
        returns (
            address _out
        )
    {
        return address(uint160(uint256(_in)));
    }

    function fromAddress(
        address _in
    )
        internal
        pure
        returns (
            bytes32 _out
        )
    {
        return bytes32(uint256(_in));
    }

    function removeLeadingZeros(
        bytes32 _in
    )
        internal
        pure
        returns (
            bytes memory _out
        )
    {
        bytes memory out;

        assembly {
            // Figure out how many leading zero bytes to remove.
            let shift := 0
            for { let i := 0 } and(lt(i, 32), eq(byte(i, _in), 0)) { i := add(i, 1) } {
                shift := add(shift, 1)
            }

            // Reserve some space for our output and fix the free memory pointer.
            out := mload(0x40)
            mstore(0x40, add(out, 0x40))

            // Shift the value and store it into the output bytes.
            mstore(add(out, 0x20), shl(mul(shift, 8), _in))

            // Store the new size (with leading zero bytes removed) in the output byte size.
            mstore(out, sub(32, shift))
        }

        return out;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title Lib_SafeExecutionManagerWrapper
 * @dev The Safe Execution Manager Wrapper provides functions which facilitate writing OVM safe 
 * code using the standard solidity compiler, by routing all its operations through the Execution 
 * Manager.
 * 
 * Compiler used: solc
 * Runtime target: OVM
 */
library Lib_SafeExecutionManagerWrapper {

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Performs a safe ovmCALL.
     * @param _gasLimit Gas limit for the call.
     * @param _target Address to call.
     * @param _calldata Data to send to the call.
     * @return _success Whether or not the call reverted.
     * @return _returndata Data returned by the call.
     */
    function safeCALL(
        uint256 _gasLimit,
        address _target,
        bytes memory _calldata
    )
        internal
        returns (
            bool _success,
            bytes memory _returndata
        )
    {
        bytes memory returndata = _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmCALL(uint256,address,bytes)",
                _gasLimit,
                _target,
                _calldata
            )
        );

        return abi.decode(returndata, (bool, bytes));
    }

    /**
     * Performs a safe ovmDELEGATECALL.
     * @param _gasLimit Gas limit for the call.
     * @param _target Address to call.
     * @param _calldata Data to send to the call.
     * @return _success Whether or not the call reverted.
     * @return _returndata Data returned by the call.
     */
    function safeDELEGATECALL(
        uint256 _gasLimit,
        address _target,
        bytes memory _calldata
    )
        internal
        returns (
            bool _success,
            bytes memory _returndata
        )
    {
        bytes memory returndata = _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmDELEGATECALL(uint256,address,bytes)",
                _gasLimit,
                _target,
                _calldata
            )
        );

        return abi.decode(returndata, (bool, bytes));
    }

    /**
     * Performs a safe ovmCREATE call.
     * @param _gasLimit Gas limit for the creation.
     * @param _bytecode Code for the new contract.
     * @return _contract Address of the created contract.
     */
    function safeCREATE(
        uint256 _gasLimit,
        bytes memory _bytecode
    )
        internal
        returns (
            address _contract
        )
    {
        bytes memory returndata = _safeExecutionManagerInteraction(
            _gasLimit,
            abi.encodeWithSignature(
                "ovmCREATE(bytes)",
                _bytecode
            )
        );

        return abi.decode(returndata, (address));
    }

    /**
     * Performs a safe ovmEXTCODESIZE call.
     * @param _contract Address of the contract to query the size of.
     * @return _EXTCODESIZE Size of the requested contract in bytes.
     */
    function safeEXTCODESIZE(
        address _contract
    )
        internal
        returns (
            uint256 _EXTCODESIZE
        )
    {
        bytes memory returndata = _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmEXTCODESIZE(address)",
                _contract
            )
        );

        return abi.decode(returndata, (uint256));
    }

    /**
     * Performs a safe ovmCHAINID call.
     * @return _CHAINID Result of calling ovmCHAINID.
     */
    function safeCHAINID()
        internal
        returns (
            uint256 _CHAINID
        )
    {
        bytes memory returndata = _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmCHAINID()"
            )
        );

        return abi.decode(returndata, (uint256));
    }

    /**
     * Performs a safe ovmCALLER call.
     * @return _CALLER Result of calling ovmCALLER.
     */
    function safeCALLER()
        internal
        returns (
            address _CALLER
        )
    {
        bytes memory returndata = _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmCALLER()"
            )
        );

        return abi.decode(returndata, (address));
    }

    /**
     * Performs a safe ovmADDRESS call.
     * @return _ADDRESS Result of calling ovmADDRESS.
     */
    function safeADDRESS()
        internal
        returns (
            address _ADDRESS
        )
    {
        bytes memory returndata = _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmADDRESS()"
            )
        );

        return abi.decode(returndata, (address));
    }

    /**
     * Performs a safe ovmGETNONCE call.
     * @return _nonce Result of calling ovmGETNONCE.
     */
    function safeGETNONCE()
        internal
        returns (
            uint256 _nonce
        )
    {
        bytes memory returndata = _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmGETNONCE()"
            )
        );

        return abi.decode(returndata, (uint256));
    }

    /**
     * Performs a safe ovmSETNONCE call.
     * @param _nonce New account nonce.
     */
    function safeSETNONCE(
        uint256 _nonce
    )
        internal
    {
        _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmSETNONCE(uint256)",
                _nonce
            )
        );
    }

    /**
     * Performs a safe ovmCREATEEOA call.
     * @param _messageHash Message hash which was signed by EOA
     * @param _v v value of signature (0 or 1)
     * @param _r r value of signature
     * @param _s s value of signature
     */
    function safeCREATEEOA(
        bytes32 _messageHash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        internal
    {
        _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmCREATEEOA(bytes32,uint8,bytes32,bytes32)",
                _messageHash,
                _v,
                _r,
                _s
            )
        );
    }

    /**
     * Performs a safe REVERT.
     * @param _reason String revert reason to pass along with the REVERT.
     */
    function safeREVERT(
        string memory _reason
    )
        internal
    {
        _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmREVERT(bytes)",
                bytes(_reason)
            )
        );
    }

    /**
     * Performs a safe "require".
     * @param _condition Boolean condition that must be true or will revert.
     * @param _reason String revert reason to pass along with the REVERT.
     */
    function safeREQUIRE(
        bool _condition,
        string memory _reason
    )
        internal
    {
        if (!_condition) {
            safeREVERT(
                _reason
            );
        }
    }

    /**
     * Performs a safe ovmSLOAD call.
     */
    function safeSLOAD(
        bytes32 _key
    )
        internal
        returns (
            bytes32
        )
    {
        bytes memory returndata = _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmSLOAD(bytes32)",
                _key
            )
        );

        return abi.decode(returndata, (bytes32));
    }

    /**
     * Performs a safe ovmSSTORE call.
     */
    function safeSSTORE(
        bytes32 _key,
        bytes32 _value
    )
        internal
    {
        _safeExecutionManagerInteraction(
            abi.encodeWithSignature(
                "ovmSSTORE(bytes32,bytes32)",
                _key,
                _value
            )
        );
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * Performs an ovm interaction and the necessary safety checks.
     * @param _gasLimit Gas limit for the interaction.
     * @param _calldata Data to send to the OVM_ExecutionManager (encoded with sighash).
     * @return _returndata Data sent back by the OVM_ExecutionManager.
     */
    function _safeExecutionManagerInteraction(
        uint256 _gasLimit,
        bytes memory _calldata
    )
        private
        returns (
            bytes memory _returndata
        )
    {
        address ovmExecutionManager = msg.sender;
        (
            bool success,
            bytes memory returndata
        ) = ovmExecutionManager.call{gas: _gasLimit}(_calldata);

        if (success == false) {
            assembly {
                revert(add(returndata, 0x20), mload(returndata))
            }
        } else if (returndata.length == 1) {
            assembly {
                return(0, 1)
            }
        } else {
            return returndata;
        }
    }

    function _safeExecutionManagerInteraction(
        bytes memory _calldata
    )
        private
        returns (
            bytes memory _returndata
        )
    {
        return _safeExecutionManagerInteraction(
            gasleft(),
            _calldata
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title iOVM_BaseCrossDomainMessenger
 */
interface iOVM_BaseCrossDomainMessenger {

    /**********
     * Events *
     **********/
    event SentMessage(bytes message);
    event RelayedMessage(bytes32 msgHash);

    /**********************
     * Contract Variables *
     **********************/
    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Interface Imports */
import { iOVM_L1CrossDomainMessenger } from "../../iOVM/bridge/iOVM_L1CrossDomainMessenger.sol";
interface iOVM_L1MultiMessageRelayer {

    struct L2ToL1Message {
        address target;
        address sender;
        bytes message;
        uint256 messageNonce;
        iOVM_L1CrossDomainMessenger.L2MessageInclusionProof proof;
    }

    function batchRelayMessages(L2ToL1Message[] calldata _messages) external; 
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Library Imports */
import { Lib_AddressManager } from "./Lib_AddressManager.sol";

/**
 * @title Lib_AddressResolver
 */
contract Lib_AddressResolver {

    /*******************************************
     * Contract Variables: Contract References *
     *******************************************/

    Lib_AddressManager internal libAddressManager;


    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Lib_AddressManager.
     */
    constructor(
        address _libAddressManager
    ) public {
        libAddressManager = Lib_AddressManager(_libAddressManager);
    }


    /********************
     * Public Functions *
     ********************/

    function resolve(
        string memory _name
    )
        public
        view
        returns (
            address _contract
        )
    {
        return libAddressManager.getAddress(_name);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Contract Imports */
import { Ownable } from "./Lib_Ownable.sol";

/**
 * @title Lib_AddressManager
 */
contract Lib_AddressManager is Ownable {

    /**********
     * Events *
     **********/

    event AddressSet(
        string _name,
        address _newAddress
    );

    /*******************************************
     * Contract Variables: Internal Accounting *
     *******************************************/

    mapping (bytes32 => address) private addresses;


    /********************
     * Public Functions *
     ********************/

    function setAddress(
        string memory _name,
        address _address
    )
        public
        onlyOwner
    {
        emit AddressSet(_name, _address);
        addresses[_getNameHash(_name)] = _address;
    }

    function getAddress(
        string memory _name
    )
        public
        view
        returns (address)
    {
        return addresses[_getNameHash(_name)];
    }


    /**********************
     * Internal Functions *
     **********************/

    function _getNameHash(
        string memory _name
    )
        internal
        pure
        returns (
            bytes32 _hash
        )
    {
        return keccak256(abi.encodePacked(_name));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title Ownable
 * @dev Adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */
abstract contract Ownable {

    /*************
     * Variables *
     *************/

    address public owner;


    /**********
     * Events *
     **********/

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /***************
     * Constructor *
     ***************/

    constructor() internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }


    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "Ownable: caller is not the owner"
        );
        _;
    }


    /********************
     * Public Functions *
     ********************/

    function renounceOwnership()
        public
        virtual
        onlyOwner
    {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address _newOwner)
        public
        virtual
        onlyOwner
    {
        require(
            _newOwner != address(0),
            "Ownable: new owner cannot be the zero address"
        );

        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}