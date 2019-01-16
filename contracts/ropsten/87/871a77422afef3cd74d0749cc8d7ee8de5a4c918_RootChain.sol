pragma solidity ^0.4.24;

// File: contracts/Math.sol

/**
 * @title Math
 * @dev Basic math operations.
 */
library Math {
    /*
     * Internal functions.
     */

    /**
     * @dev Returns the maximum of two numbers.
     * @param _a uint256 number.
     * @param _b uint256 number.
     * @return The greater of _a or _b.
     */
    function max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a >= _b ? _a : _b;
    }
}

// File: contracts/Merkle.sol

/**
 * @title Merkle
 * @dev Operations regarding Merkle trees.
 */
library Merkle {
    /*
     * Internal function
     */
    
    /**
     * @dev Checks that a leaf is actually in a Merkle tree.
     * @param _leaf Leaf to verify.
     * @param _index Index of the leaf in the tree.
     * @param _rootHash Root of the tree.
     * @param _proof Merkle proof showing the leaf is in the tree.
     * @return True if the leaf is in the tree, false otherwise.
     */
    function checkMembership(
        bytes32 _leaf,
        uint256 _index,
        bytes32 _rootHash,
        bytes _proof
    ) internal pure returns (bool) {
        // Check that the proof length is valid.
        require(_proof.length % 32 == 0);

        // Compute the merkle root.
        bytes32 proofElement;
        bytes32 computedHash = _leaf;
        uint256 index = _index;
        for (uint256 i = 32; i <= _proof.length; i += 32) {
            assembly {
                proofElement := mload(add(_proof, i))
            }
            if (_index % 2 == 0) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
            index = index / 2;
        }

        // Check that the computer root and specified root match.
        return computedHash == _rootHash;
    }
}

// File: contracts/ECRecovery.sol

/**
 * @title Eliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d.
 */
library ECRecovery {
    /*
     * Internal functions
     */

    /**
     * @dev Recover signer address from a message by using their signature.
     * @param _hash Hash of the signed message 
     * @param _sig Signature over the signed message.
     * @return Address that signed the hash.
     */
    function recover(bytes32 _hash, bytes _sig) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length.
        if (_sig.length != 65) {
            return address(0);
        }

        // Divide the signature in v, r, and s variables.
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions.
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address.
        if (v != 27 && v != 28) {
            return address(0);
        } else {
            return ecrecover(_hash, v, r, s);
        }
    }
}

// File: contracts/ByteUtils.sol

/**
 * @title Bytes operations
 * @dev Based on https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
 */
library ByteUtils {
    /*
     * Internal functions
     */
    
    /**
     * @dev Concatenates two bytes.
     * @param _preBytes First byte string.
     * @param _postBytes Second byte string.
     * @return Both byte string combined.
     */
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes) {
        bytes memory tempBytes;

        assembly {
            tempBytes := mload(0x40)

            let length := mload(_preBytes)
            mstore(tempBytes, length)

            let mc := add(tempBytes, 0x20)
            let end := add(mc, length)

            for {
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            mc := end
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31)
            ))
        }

        return tempBytes;
    }

    /**
     * @dev Slices off bytes from a byte string.
     * @param _bytes Byte string to slice.
     * @param _start Starting index of the slice.
     * @param _length Length of the slice.
     * @return The slice of the byte string.
     */
    function slice(bytes _bytes, uint _start, uint _length) internal pure returns (bytes) {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                tempBytes := mload(0x40)

                let lengthmod := and(_length, 31)

                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                mstore(0x40, and(add(mc, 31), not(31)))
            }
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}

// File: contracts/RLPDecode.sol

/**
 * @title RLP
 * @dev Library for RLP decoding.
 * Based off of https://github.com/androlo/standard-contracts/blob/master/contracts/src/codec/RLP.sol.
 */
library RLPDecode {
    /*
     * Storage
     */

    uint internal constant DATA_SHORT_START = 0x80;
    uint internal constant DATA_LONG_START = 0xB8;
    uint internal constant LIST_SHORT_START = 0xC0;
    uint internal constant LIST_LONG_START = 0xF8;

    uint internal constant DATA_LONG_OFFSET = 0xB7;
    uint internal constant LIST_LONG_OFFSET = 0xF7;

    struct RLPItem {
        uint _unsafe_memPtr;    // Pointer to the RLP-encoded bytes.
        uint _unsafe_length;    // Number of bytes. This is the full length of the string.
    }

    struct Iterator {
        RLPItem _unsafe_item;   // Item that&#39;s being iterated over.
        uint _unsafe_nextPtr;   // Position of the next item in the list.
    }


    /*
     * Internal functions
     */

    /**
     * @dev Creates an RLPItem from an array of RLP encoded bytes.
     * @param self The RLP encoded bytes.
     * @return An RLPItem.
     */
    function toRLPItem(bytes memory self)
        internal
        pure
        returns (RLPItem memory)
    {
        uint len = self.length;
        if (len == 0) {
            return RLPItem(0, 0);
        }
        uint memPtr;
        assembly {
            memPtr := add(self, 0x20)
        }
        return RLPItem(memPtr, len);
    }

    /**
     * @dev Creates an RLPItem from an array of RLP encoded bytes.
     * @param self The RLP encoded bytes.
     * @param strict Will throw if the data is not RLP encoded.
     * @return An RLPItem
     */
    function toRLPItem(bytes memory self, bool strict)
        internal
        pure
        returns (RLPItem memory)
    {
        RLPItem memory item = toRLPItem(self);
        if (strict) {
            uint len = self.length;
            if (_payloadOffset(item) > len) {
                revert();
            }
            if (_itemLength(item._unsafe_memPtr) != len) {
                revert();
            }
            if (!_validate(item)) {
                revert();
            }
        }
        return item;
    }

    /**
     * @dev Check if the RLP item is null.
     * @param self The RLP item.
     * @return &#39;true&#39; if the item is null.
     */
    function isNull(RLPItem memory self)
        internal
        pure
        returns (bool ret)
    {
        return self._unsafe_length == 0;
    }

    /**
     * @dev Check if the RLP item is a list.
     * @param self The RLP item.
     * @return &#39;true&#39; if the item is a list.
     */
    function isList(RLPItem memory self)
        internal
        pure
        returns (bool ret)
    {
        if (self._unsafe_length == 0) {
            return false;
        }
        uint memPtr = self._unsafe_memPtr;
        assembly {
            ret := iszero(lt(byte(0, mload(memPtr)), 0xC0))
        }
    }

    /**
     * @dev Check if the RLP item is data.
     * @param self The RLP item.
     * @return &#39;true&#39; if the item is data.
     */
    function isData(RLPItem memory self)
        internal
        pure
        returns (bool ret)
    {
        if (self._unsafe_length == 0) {
            return false;
        }
        uint memPtr = self._unsafe_memPtr;
        assembly {
            ret := lt(byte(0, mload(memPtr)), 0xC0)
        }
    }

    /**
     * @dev Check if the RLP item is empty (string or list).
     * @param self The RLP item.
     * @return &#39;true&#39; if the item is null.
     */
    function isEmpty(RLPItem memory self)
        internal
        pure
        returns (bool ret)
    {
        if (isNull(self)) {
            return false;
        }
        uint b0;
        uint memPtr = self._unsafe_memPtr;
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        return (b0 == DATA_SHORT_START || b0 == LIST_SHORT_START);
    }

    /**
     * @dev Get the number of items in an RLP encoded list.
     * @param self The RLP item.
     * @return The number of items.
     */
    function items(RLPItem memory self)
        internal
        pure
        returns (uint)
    {
        if (!isList(self)) {
            return 0;
        }
        uint b0;
        uint memPtr = self._unsafe_memPtr;
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        uint pos = memPtr + _payloadOffset(self);
        uint last = memPtr + self._unsafe_length - 1;
        uint itms;
        while (pos <= last) {
            pos += _itemLength(pos);
            itms++;
        }
        return itms;
    }

    /**
     * @dev Create an iterator.
     * @param self The RLP item.
     * @return An &#39;Iterator&#39; over the item.
     */
    function iterator(RLPItem memory self)
        internal
        pure
        returns (Iterator memory it)
    {
        if (!isList(self)) {
            revert();
        }
        uint ptr = self._unsafe_memPtr + _payloadOffset(self);
        it._unsafe_item = self;
        it._unsafe_nextPtr = ptr;
    }

    /**
     * @dev Return the RLP encoded bytes.
     * @param self The RLPItem.
     * @return The bytes.
     */
    function toBytes(RLPItem memory self)
        internal
        view
        returns (bytes memory bts)
    {
        uint len = self._unsafe_length;
        if (len == 0) {
            return;
        }
        bts = new bytes(len);
        _copyToBytes(self._unsafe_memPtr, bts, len);
    }

    /**
     * @dev Decode an RLPItem into bytes. This will not work if the RLPItem is a list.
     * @param self The RLPItem.
     * @return The decoded string.
     */
    function toData(RLPItem memory self)
        internal
        view
        returns (bytes memory bts)
    {
        if (!isData(self)) {
            revert();
        }
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        bts = new bytes(len);
        _copyToBytes(rStartPos, bts, len);
    }

    /**
     * @dev Get the list of sub-items from an RLP encoded list.
     * Warning: This is inefficient, as it requires that the list is read twice.
     * @param self The RLP item.
     * @return Array of RLPItems.
     */
    function toList(RLPItem memory self)
        internal
        pure
        returns (RLPItem[] memory list)
    {
        if (!isList(self)) {
            revert();
        }
        uint numItems = items(self);
        list = new RLPItem[](numItems);
        Iterator memory it = iterator(self);
        uint idx;
        while (_hasNext(it)) {
            list[idx] = _next(it);
            idx++;
        }
    }

    /**
     * @dev Decode an RLPItem into an ascii string. This will not work if the RLPItem is a list.
     * @param self The RLPItem.
     * @return The decoded string.
     */
    function toAscii(RLPItem memory self)
        internal
        view
        returns (string memory str)
    {
        if (!isData(self)) {
            revert();
        }
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        bytes memory bts = new bytes(len);
        _copyToBytes(rStartPos, bts, len);
        str = string(bts);
    }

    /**
     * @dev Decode an RLPItem into a uint. This will not work if the RLPItem is a list.
     * @param self The RLPItem.
     * @return The decoded string.
     */
    function toUint(RLPItem memory self)
        internal
        pure
        returns (uint data)
    {
        if (!isData(self)) {
            revert();
        }
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        if (len > 32) {
            revert();
        }
        assembly {
            data := div(mload(rStartPos), exp(256, sub(32, len)))
        }
    }

    /**
     * @dev Decode an RLPItem into a boolean. This will not work if the RLPItem is a list.
     * @param self The RLPItem.
     * @return The decoded string.
     */
    function toBool(RLPItem memory self)
        internal
        pure
        returns (bool data)
    {
        if (!isData(self)) {
            revert();
        }
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        if (len != 1) {
            revert();
        }
        uint temp;
        assembly {
            temp := byte(0, mload(rStartPos))
        }
        if (temp > 1) {
            revert();
        }
        return temp == 1 ? true : false;
    }

    /**
     * @dev Decode an RLPItem into a byte. This will not work if the RLPItem is a list.
     * @param self The RLPItem.
     * @return The decoded string.
     */
    function toByte(RLPItem memory self)
        internal
        pure
        returns (byte data)
    {
        if (!isData(self)) {
            revert();
        }
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        if (len != 1) {
            revert();
        }
        uint temp;
        assembly {
            temp := byte(0, mload(rStartPos))
        }
        return byte(temp);
    }

    /**
     * @dev Decode an RLPItem into an int. This will not work if the RLPItem is a list.
     * @param self The RLPItem.
     * @return The decoded string.
     */
    function toInt(RLPItem memory self)
        internal
        pure
        returns (int data)
    {
        return int(toUint(self));
    }

    /**
     * @dev Decode an RLPItem into a bytes32. This will not work if the RLPItem is a list.
     * @param self The RLPItem.
     * @return The decoded string.
     */
    function toBytes32(RLPItem memory self)
        internal
        pure
        returns (bytes32 data)
    {
        return bytes32(toUint(self));
    }

    /**
     * @dev Decode an RLPItem into an address. This will not work if the RLPItem is a list.
     * @param self The RLPItem.
     * @return The decoded string.
     */
    function toAddress(RLPItem memory self)
        internal
        pure
        returns (address data)
    {
        if (!isData(self)) {
            revert();
        }
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        if (len != 20) {
            revert();
        }
        assembly {
            data := div(mload(rStartPos), exp(256, 12))
        }
    }


    /*
     * Private functions
     */

    /**
     * @dev Returns the next RLP item for some iterator.
     * @param self The iterator.
     * @return The next RLP item.
     */
    function _next(Iterator memory self)
        private
        pure
        returns (RLPItem memory subItem)
    {
        if (_hasNext(self)) {
            uint ptr = self._unsafe_nextPtr;
            uint itemLength = _itemLength(ptr);
            subItem._unsafe_memPtr = ptr;
            subItem._unsafe_length = itemLength;
            self._unsafe_nextPtr = ptr + itemLength;
        } else {
            revert();
        }
    }

    /**
     * @dev Returns the next RLP item for some iterator and validates it.
     * @param self The iterator.
     * @return The next RLP item.
     */
    function _next(Iterator memory self, bool strict)
        private
        pure
        returns (RLPItem memory subItem)
    {
        subItem = _next(self);
        if (strict && !_validate(subItem)) {
            revert();
        }
        return;
    }

    /**
     * @dev Checks if an iterator has a next RLP item.
     * @param self The iterator.
     * @return True if the iterator has an RLP item. False otherwise.
     */
    function _hasNext(Iterator memory self)
        private
        pure
        returns (bool)
    {
        RLPItem memory item = self._unsafe_item;
        return self._unsafe_nextPtr < item._unsafe_memPtr + item._unsafe_length;
    }

    /**
     * @dev Determines the payload offset of some RLP item.
     * @param self RLP item to query.
     * @return The payload offset for that item.
     */
    function _payloadOffset(RLPItem memory self)
        private 
        pure
        returns (uint)
    {
        if (self._unsafe_length == 0) {
            return 0;
        }
        uint b0;
        uint memPtr = self._unsafe_memPtr;
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        if (b0 < DATA_SHORT_START) {
            return 0;
        }
        if (b0 < DATA_LONG_START || (b0 >= LIST_SHORT_START && b0 < LIST_LONG_START)) {
            return 1;
        }
        if (b0 < LIST_SHORT_START) {
            return b0 - DATA_LONG_OFFSET + 1;
        }
        return b0 - LIST_LONG_OFFSET + 1;
    }

    /**
     * @dev Determines the length of an RLP item.
     * @param memPtr Pointer to the start of the item.
     * @return Length of the item.
     */
    function _itemLength(uint memPtr)
        private
        pure
        returns (uint len)
    {
        uint b0;
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        if (b0 < DATA_SHORT_START) {
            len = 1;
        }
        else if (b0 < DATA_LONG_START) {
            len = b0 - DATA_SHORT_START + 1;
        }
        else if (b0 < LIST_SHORT_START) {
            assembly {
                let bLen := sub(b0, 0xB7) // bytes length (DATA_LONG_OFFSET)
                let dLen := div(mload(add(memPtr, 1)), exp(256, sub(32, bLen))) // data length
                len := add(1, add(bLen, dLen)) // total length
            }
        }
        else if (b0 < LIST_LONG_START) {
            len = b0 - LIST_SHORT_START + 1;
        }
        else {
            assembly {
                let bLen := sub(b0, 0xF7) // bytes length (LIST_LONG_OFFSET)
                let dLen := div(mload(add(memPtr, 1)), exp(256, sub(32, bLen))) // data length
                len := add(1, add(bLen, dLen)) // total length
            }
        }
    }

    /**
     * @dev Determines the start position and length of some RLP item.
     * @param self RLP item to query.
     * @return A pointer to the beginning of the item and the length of that item.
     */
    function _decode(RLPItem memory self)
        private
        pure
        returns (uint memPtr, uint len)
    {
        if (!isData(self)) {
            revert();
        }
        uint b0;
        uint start = self._unsafe_memPtr;
        assembly {
            b0 := byte(0, mload(start))
        }
        if (b0 < DATA_SHORT_START) {
            memPtr = start;
            len = 1;
            return;
        }
        if (b0 < DATA_LONG_START) {
            len = self._unsafe_length - 1;
            memPtr = start + 1;
        } else {
            uint bLen;
            assembly {
                bLen := sub(b0, 0xB7) // DATA_LONG_OFFSET
            }
            len = self._unsafe_length - 1 - bLen;
            memPtr = start + bLen + 1;
        }
        return;
    }

    /**
     * @dev Copies some data to a certain target.
     * @param btsPtr Pointer to the data to copy.
     * @param tgt Place to copy.
     * @param btsLen How many bytes to copy.
     */
    function _copyToBytes(uint btsPtr, bytes memory tgt, uint btsLen)
        private
        view
    {
        // Exploiting the fact that &#39;tgt&#39; was the last thing to be allocated,
        // we can write entire words, and just overwrite any excess.
        assembly {
            {
                let i := 0 // Start at arr + 0x20
                let words := div(add(btsLen, 31), 32)
                let rOffset := btsPtr
                let wOffset := add(tgt, 0x20)
                tag_loop:
                    jumpi(end, eq(i, words))
                    {
                        let offset := mul(i, 0x20)
                        mstore(add(wOffset, offset), mload(add(rOffset, offset)))
                        i := add(i, 1)
                    }
                    jump(tag_loop)
                end:
                    mstore(add(tgt, add(0x20, mload(tgt))), 0)
            }
        }
    }

    /**
     * @dev Checks that an RLP item is valid.
     * @param self RLP item to validate.
     * @return True if the RLP item is well-formed. False otherwise.
     */
    function _validate(RLPItem memory self)
        private
        pure
        returns (bool ret)
    {
        // Check that RLP is well-formed.
        uint b0;
        uint b1;
        uint memPtr = self._unsafe_memPtr;
        assembly {
            b0 := byte(0, mload(memPtr))
            b1 := byte(1, mload(memPtr))
        }
        if (b0 == DATA_SHORT_START + 1 && b1 < DATA_SHORT_START) {
            return false;
        }
        return true;
    }
}

// File: contracts/RLPEncode.sol

/**
 * @title A simple RLP encoding library.
 * @author Bakaoh.
 */
library RLPEncode {
    /*
     * Internal functions
     */

    /**
     * @dev RLP encodes a byte string.
     * @param self The byte string to encode.
     * @return The RLP encoded string in bytes.
     */
    function encodeBytes(bytes memory self) internal pure returns (bytes) {
        bytes memory encoded;
        if (self.length == 1 && uint(self[0]) <= 128) {
            encoded = self;
        } else {
            encoded = ByteUtils.concat(encodeLength(self.length, 128), self);
        }
        return encoded;
    }

    /** 
     * @dev RLP encodes an address.
     * @param self The address to encode.
     * @return The RLP encoded address in bytes.
     */
    function encodeAddress(address self) internal pure returns (bytes) {
        bytes memory inputBytes;
        assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, self))
            mstore(0x40, add(m, 52))
            inputBytes := m
        }
        return encodeBytes(inputBytes);
    }

    /** 
     * @dev RLP encodes a uint.
     * @param self The uint to encode.
     * @return The RLP encoded uint in bytes.
     */
    function encodeUint(uint self) internal pure returns (bytes) {
        return encodeBytes(toBinary(self));
    }

    /** 
     * @dev RLP encodes an int.
     * @param self The int to encode.
     * @return The RLP encoded int in bytes.
     */
    function encodeInt(int self) internal pure returns (bytes) {
        return encodeUint(uint(self));
    }

    /** 
     * @dev RLP encodes a bool.
     * @param self The bool to encode.
     * @return The RLP encoded bool in bytes.
     */
    function encodeBool(bool self) internal pure returns (bytes) {
        bytes memory encoded = new bytes(1);
        if (self) {
            encoded[0] = bytes1(1);
        }
        return encoded;
    }

    /**
     * @dev RLP encodes a list of RLP encoded byte byte strings.
     * @param self The list of RLP encoded byte strings.
     * @return The RLP encoded list of items in bytes.
     */
    function encodeList(bytes[] memory self) internal pure returns (bytes) {
        bytes memory list = flatten(self);
        return ByteUtils.concat(encodeLength(list.length, 192), list);
    }

    /**
     * @dev Encode the first byte, followed by the `len` in binary form if `length` is more than 55.
     * @param len The length of the string or the payload.
     * @param offset 128 if item is string, 192 if item is list.
     * @return RLP encoded bytes.
     */
    function encodeLength(uint len, uint offset) private pure returns (bytes) {
        bytes memory encoded;
        if (len < 56) {
            encoded = new bytes(1);
            encoded[0] = byte(len + offset);
        } else {
            uint lenLen;
            uint i = 1;
            while (len / i != 0) {
                lenLen++;
                i *= 256;
            }

            encoded = new bytes(lenLen + 1);
            encoded[0] = byte(lenLen + offset + 55);
            for(i = 1; i <= lenLen; i++) {
                encoded[i] = byte((len / (256**(lenLen-i))) % 256);
            }
        }
        return encoded;
    }

    /**
     * @dev Encode integer in big endian binary form with no leading zeroes.
     * @notice TODO: This should be optimized with assembly to save gas costs.
     * @param x The integer to encode.
     * @return RLP encoded bytes.
     */
    function toBinary(uint x) internal pure returns (bytes) {
        bytes memory b = new bytes(32);
        assembly { 
            mstore(add(b, 32), x) 
        }
        for (uint i = 0; i < 32; i++) {
            if (b[i] != 0) {
                break;
            }
        }
        bytes memory res = new bytes(32 - i);
        for (uint j = 0; j < res.length; j++) {
            res[j] = b[i++];
        }
        return res;
    }

    /**
     * @dev Copies a piece of memory to another location.
     * @notice From: https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol.
     * @param dest Destination location.
     * @param src Source location.
     * @param len Length of memory to copy.
     */
    function memcpy(uint dest, uint src, uint len) private pure {
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /**
     * @dev Flattens a list of byte strings into one byte string.
     * @notice From: https://github.com/sammayo/solidity-rlp-encoder/blob/master/RLPEncode.sol.
     * @param self List of byte strings to flatten.
     * @return The flattened byte string.
     */
    function flatten(bytes[] memory self) private pure returns (bytes) {
        if (self.length == 0) {
            return new bytes(0);
        }

        uint len;
        for (uint i = 0; i < self.length; i++) {
            len += self[i].length;
        }

        bytes memory flattened = new bytes(len);
        uint flattenedPtr;
        assembly { flattenedPtr := add(flattened, 0x20) }

        for(i = 0; i < self.length; i++) {
            bytes memory item = self[i];
            
            uint selfPtr;
            assembly { selfPtr := add(item, 0x20)}

            memcpy(flattenedPtr, selfPtr, item.length);
            flattenedPtr += self[i].length;
        }

        return flattened;
    }
}

// File: contracts/PlasmaUtils.sol

/**
 * @title PlasmaUtils
 * @dev Utilities for working with and decoding Plasma MVP transactions.
 */
library PlasmaUtils {
    using RLPEncode for bytes;
    using RLPDecode for bytes;
    using RLPDecode for RLPDecode.RLPItem;


    /*
     * Storage
     */

    uint256 constant internal BLOCK_OFFSET = 1000000000;
    uint256 constant internal TX_OFFSET = 10000;

    struct TransactionInput {
        uint256 blknum;
        uint256 txindex;
        uint256 oindex;
    }

    struct TransactionOutput {
        address owner;
        uint256 amount;
    }

    struct Transaction {
        TransactionInput[2] inputs;
        TransactionOutput[2] outputs;
    }

    
    /*
     * Internal functions
     */

    /**
     * @dev Decodes an RLP encoded transaction.
     * @param _tx RLP encoded transaction.
     * @return Decoded transaction.
     */
    function decodeTx(bytes memory _tx) internal pure returns (Transaction) {
        RLPDecode.RLPItem[] memory txList = _tx.toRLPItem().toList();
        RLPDecode.RLPItem[] memory inputs = txList[0].toList();
        RLPDecode.RLPItem[] memory outputs = txList[1].toList();

        Transaction memory decodedTx;
        for (uint i = 0; i < 2; i++) {
            RLPDecode.RLPItem[] memory input = inputs[i].toList();
            decodedTx.inputs[i] = TransactionInput({
                blknum: input[0].toUint(),
                txindex: input[1].toUint(),
                oindex: input[2].toUint()
            });

            RLPDecode.RLPItem[] memory output = outputs[i].toList();
            decodedTx.outputs[i] = TransactionOutput({
                owner: output[0].toAddress(),
                amount: output[1].toUint()
            });
        }

        return decodedTx;
    }

    /**
     * @dev Given a UTXO position, returns the block number.
     * @param _utxoPosition UTXO position to decode.
     * @return The output&#39;s block number.
     */
    function getBlockNumber(uint256 _utxoPosition) internal pure returns (uint256) {
        return _utxoPosition / BLOCK_OFFSET;
    }

    /**
     * @dev Given a UTXO position, returns the transaction index.
     * @param _utxoPosition UTXO position to decode.s
     * @return The output&#39;s transaction index.
     */
    function getTxIndex(uint256 _utxoPosition) internal pure returns (uint256) {
        return (_utxoPosition % BLOCK_OFFSET) / TX_OFFSET;
    }

    /**
     * @dev Given a UTXO position, returns the output index.
     * @param _utxoPosition UTXO position to decode.
     * @return The output&#39;s index.
     */
    function getOutputIndex(uint256 _utxoPosition) internal pure returns (uint8) {
        return uint8(_utxoPosition % TX_OFFSET);
    }

    /**
     * @dev Encodes a UTXO position.
     * @param _blockNumber Block in which the transaction was created.
     * @param _txIndex Index of the transaction inside the block.
     * @param _outputIndex Which output is being referenced.
     * @return The encoded UTXO position.
     */
    function encodeUtxoPosition(
        uint256 _blockNumber,
        uint256 _txIndex,
        uint256 _outputIndex
    ) internal pure returns (uint256) {
        return (_blockNumber * BLOCK_OFFSET) + (_txIndex * TX_OFFSET) + (_outputIndex * 1);
    }

    /**
     * @dev Returns the encoded UTXO position for a given input.
     * @param _txInput Transaction input to encode.
     * @return The encoded UTXO position.
     */
    function getInputPosition(TransactionInput memory _txInput) internal pure returns (uint256) {
        return encodeUtxoPosition(_txInput.blknum, _txInput.txindex, _txInput.oindex); 
    }

    /**
     * @dev Calculates a deposit root given an encoded deposit transaction.
     * @param _encodedDepositTx RLP encoded deposit transaction.
     * @return The deposit root.
     */
    function getDepositRoot(bytes _encodedDepositTx) internal pure returns (bytes32) {
        bytes32 root = keccak256(abi.encodePacked(_encodedDepositTx, new bytes(130)));
        bytes32 zeroHash = keccak256(abi.encodePacked(uint256(0)));
        for (uint256 i = 0; i < 10; i++) {
            root = keccak256(abi.encodePacked(root, zeroHash));
            zeroHash = keccak256(abi.encodePacked(zeroHash, zeroHash));
        }
        return root;
    }

    /**
     * @dev Creates an encoded deposit transaction for an owner and an amount.
     * @param _owner Owner of the deposit.
     * @param _amount Amount to be deposited.
     * @return RLP encoded deposit transaction.
     */
    function getDepositTransaction(address _owner, uint256 _amount) internal pure returns (bytes) {
        // Inputs and second output are constant.
        bytes memory encodedInputs = "\xc8\xc3\x80\x80\x80\xc3\x80\x80\x80";
        bytes memory encodedSecondOutput = "\xd6\x94\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80";
    
        // Encode the first output.
        bytes[] memory firstOutput = new bytes[](2);
        firstOutput[0] = RLPEncode.encodeAddress(_owner);
        firstOutput[1] = RLPEncode.encodeUint(_amount);
        bytes memory encodedFirstOutput = RLPEncode.encodeList(firstOutput);

        // Combine both outputs.
        bytes[] memory outputs = new bytes[](2);
        outputs[0] = encodedFirstOutput;
        outputs[1] = encodedSecondOutput;
        bytes memory encodedOutputs = RLPEncode.encodeList(outputs);

        // Encode the whole transaction;
        bytes[] memory transaction = new bytes[](2);
        transaction[0] = encodedInputs;
        transaction[1] = encodedOutputs;
        return RLPEncode.encodeList(transaction);
    }

    /**
     * @dev Validates signatures on a transaction.
     * @param _txHash Hash of the transaction to be validated.
     * @param _signatures Signatures over the hash of the transaction.
     * @param _confirmationSignatures Signatures attesting that the transaction is in a valid block.
     * @return True if the signatures are valid, false otherwise.
     */
    function validateSignatures(
        bytes32 _txHash,
        bytes _signatures,
        bytes _confirmationSignatures
    ) internal pure returns (bool) {
        // Check that the signature lengths are correct.
        require(_signatures.length % 65 == 0, "Invalid signature length.");
        require(_signatures.length == _confirmationSignatures.length, "Mismatched signature count.");

        for (uint256 offset = 0; offset < _signatures.length; offset += 65) {
            // Slice off one signature at a time.
            bytes memory signature = ByteUtils.slice(_signatures, offset, 65);
            bytes memory confirmationSigature = ByteUtils.slice(_confirmationSignatures, offset, 65);

            // Check that the signatures match.
            bytes32 confirmationHash = keccak256(abi.encodePacked(_txHash));
            if (ECRecovery.recover(_txHash, signature) != ECRecovery.recover(confirmationHash, confirmationSigature)) {
                return false;
            }
        }

        return true;
    }
}

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /*
     * Internal functions
     */

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: contracts/PriorityQueue.sol

/**
 * @title PriorityQueue
 * @dev A priority queue implementation.
 */
contract PriorityQueue {
    using SafeMath for uint256;

    /* 
     *  Storage
     */

    address owner;
    uint256[] heapList;
    uint256 public currentSize;


    /*
     *  Modifiers
     */

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /*
     * Constructor
     */

    constructor() public {
        owner = msg.sender;
        heapList = [0];
        currentSize = 0;
    }


    /*
     * Internal functions
     */

    /**
     * @dev Inserts an element into the priority queue.
     * @param _priority Priority to insert.
     * @param _value Some additional value.
     */
    function insert(uint256 _priority, uint256 _value) public onlyOwner {
        uint256 element = _priority << 128 | _value;
        heapList.push(element);
        currentSize = currentSize.add(1);
        _percUp(currentSize);
    }

    /**
     * @dev Returns the top element of the heap.
     * @return The smallest element in the priority queue.
     */
    function getMin() public view returns (uint256, uint256) {
        return _splitElement(heapList[1]);
    }

    /**
     * @dev Deletes the top element of the heap and shifts everything up.
     * @return The smallest element in the priorty queue.
     */
    function delMin() public onlyOwner returns (uint256, uint256) {
        uint256 retVal = heapList[1];
        heapList[1] = heapList[currentSize];
        delete heapList[currentSize];
        currentSize = currentSize.sub(1);
        _percDown(1);
        heapList.length = heapList.length.sub(1);
        return _splitElement(retVal);
    }


    /*
     * Private functions
     */

    /**
     * @dev Determines the minimum child of a given node in the tree.
     * @param _index Index of the node in the tree.
     * @return The smallest child node.
     */
    function _minChild(uint256 _index) private view returns (uint256) {
        if (_index.mul(2).add(1) > currentSize) {
            return _index.mul(2);
        } else {
            if (heapList[_index.mul(2)] < heapList[_index.mul(2).add(1)]) {
                return _index.mul(2);
            } else {
                return _index.mul(2).add(1);
            }
        }
    }

    /**
     * @dev Bubbles the element at some index up.
     */
    function _percUp(uint256 _index) private {
        uint256 index = _index;
        uint256 j = index;
        uint256 newVal = heapList[index];
        while (newVal < heapList[index.div(2)]) {
            heapList[index] = heapList[index.div(2)];
            index = index.div(2);
        }
        if (index != j) heapList[index] = newVal;
    }

    /**
     * @dev Bubbles the element at some index down.
     */
    function _percDown(uint256 _index) private {
        uint256 index = _index;
        uint256 j = index;
        uint256 newVal = heapList[index];
        uint256 mc = _minChild(index);
        while (mc <= currentSize && newVal > heapList[mc]) {
            heapList[index] = heapList[mc];
            index = mc;
            mc = _minChild(index);
        }
        if (index != j) heapList[index] = newVal;
    }

    /**
     * @dev Split an element into its priority and value.
     * @param _element Element to decode.
     * @return A tuple containing the priority and value.
     */
    function _splitElement(uint256 _element) private pure returns (uint256, uint256) {
        uint256 priority = _element >> 128;
        uint256 value = uint256(uint128(_element));
        return (priority, value);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts/RootChain.sol

/**
 * @title RootChain
 * @dev Plasma Battleship root chain contract implementation.
 */
contract RootChain {
    /*
     * Events
     */

    event DepositCreated(
        address indexed owner,
        uint256 amount,
        uint256 depositBlock
    );

    event PlasmaBlockRootCommitted(
        uint256 blockNumber,
        bytes32 root
    );

    event ExitStarted(
        address indexed owner,
        uint256 utxoPosition,
        uint256 amount
    );


    /*
     * Storage
     */

    uint256 constant public CHALLENGE_PERIOD = 1 weeks;
    uint256 constant public EXIT_BOND = 123456789;

    PriorityQueue exitQueue;
    uint256 public currentPlasmaBlockNumber;
    address public operator;

    mapping (uint256 => PlasmaBlock) public plasmaBlocks;
    mapping (uint256 => PlasmaExit) public plasmaExits;

    IERC20 token;

    struct PlasmaBlock {
        bytes32 root;
        uint256 timestamp;
    }

    struct PlasmaExit {
        address owner;
        uint256 amount;
        bool isStarted;
        bool isValid;
    }


    /*
     * Modifiers
     */

    modifier onlyOperator() {
        require(msg.sender == operator, "Sender must be operator.");
        _;
    }

    modifier onlyWithValue(uint256 value) {
        require(msg.value == value, "Sent value must be equal to requried value.");
        _;
    }


    /*
     * Constructor
     */

    constructor(address _token) public {
        operator = msg.sender;
        currentPlasmaBlockNumber = 1;
        exitQueue = new PriorityQueue();
        token = IERC20(_token);
    }


    /*
     * Public functions
     */

    /**
     * @dev Allows a user to deposit into the Plasma chain.
     */
    function deposit(uint256 _amount) public {
        require(_amount > 0, "Deposit value must be greater than zero.");

        // Transfer the token.
        // Warning, check your ERC20 implementation. TransferFrom should return bool
        require(token.transferFrom(msg.sender, address(this), _amount));

        // Generate the deposit transaction.
        bytes memory encodedDepositTx = PlasmaUtils.getDepositTransaction(msg.sender, _amount);

        // Publish the new deposit block root.
        plasmaBlocks[currentPlasmaBlockNumber] = PlasmaBlock({
            root: PlasmaUtils.getDepositRoot(encodedDepositTx),
            timestamp: block.timestamp
        });

        emit DepositCreated(msg.sender, _amount, currentPlasmaBlockNumber);
        currentPlasmaBlockNumber++;
    }

    /**
     * @dev Allows the operator to commit a block root to Ethereum.
     * @param _root Root to be committed.
     */
    function commitPlasmaBlockRoot(bytes32 _root) public onlyOperator {
        plasmaBlocks[currentPlasmaBlockNumber] = PlasmaBlock({
            root: _root,
            timestamp: block.timestamp
        });

        emit PlasmaBlockRootCommitted(currentPlasmaBlockNumber, _root);
        currentPlasmaBlockNumber++;
    }

    /**
     * @dev Starts an exit for a given UTXO.
     * @param _utxoBlockNumber Block number of the UTXO being exited.
     * @param _utxoTxIndex Transaction index of the UTXO being exited.
     * @param _utxoOutputIndex Output index of the UTXO being exited.
     * @param _encodedTx RLP encoded transaction that created the output.
     * @param _txInclusionProof Proof that the transaction was included in the Plasma chain.
     * @param _txSignatures Signatures that validate the transaction that created the output.
     * @param _txConfirmationSignatures Signatures that confirm the transaction that created the output.
     */
    function startExit(
        uint256 _utxoBlockNumber,
        uint256 _utxoTxIndex,
        uint256 _utxoOutputIndex,
        bytes _encodedTx,
        bytes _txInclusionProof,
        bytes _txSignatures,
        bytes _txConfirmationSignatures
    ) public payable onlyWithValue(EXIT_BOND) {
        uint256 utxoPosition = PlasmaUtils.encodeUtxoPosition(_utxoBlockNumber, _utxoTxIndex, _utxoOutputIndex);
        PlasmaUtils.TransactionOutput memory transactionOutput = PlasmaUtils.decodeTx(_encodedTx).outputs[_utxoOutputIndex];

        // Check that this exit is valid.
        require(transactionOutput.owner == msg.sender, "Only output owner can withdraw this output.");
        require(transactionOutput.amount > 0, "Output value must be greater than zero.");
        require(!plasmaExits[utxoPosition].isStarted, "Exit must not already exist.");

        // Check transaction signatures.
        bytes32 txHash = keccak256(_encodedTx);
        require(PlasmaUtils.validateSignatures(txHash, _txSignatures, _txConfirmationSignatures), "Signatures must match.");

        // Check the transaction is included in the chain.
        PlasmaBlock memory plasmaBlock = plasmaBlocks[_utxoBlockNumber];
        bytes32 merkleHash = keccak256(abi.encodePacked(_encodedTx, _txSignatures));
        require(Merkle.checkMembership(merkleHash, _utxoTxIndex, plasmaBlock.root, _txInclusionProof), "Transaction must be in block.");

        // Must wait at least one week (> 1 week old UTXOs), but might wait up to two weeks (< 1 week old UTXOs).
        uint256 exitableAt = Math.max(plasmaBlock.timestamp + 2 weeks, block.timestamp + 1 weeks);

        exitQueue.insert(exitableAt, utxoPosition);
        plasmaExits[utxoPosition] = PlasmaExit({
            owner: transactionOutput.owner,
            amount: transactionOutput.amount,
            isStarted: true,
            isValid: true
        });

        emit ExitStarted(msg.sender, utxoPosition, transactionOutput.amount);
    }

    /**
     * @dev Blocks an exiting UTXO by proving the UTXO was spent.
     * @param _exitingUtxoBlockNumber Block number of the UTXO being exited.
     * @param _exitingUtxoTxIndex Transaction index of the UTXO being exited.
     * @param _exitingUtxoOutputIndex Output index of the UTXO being exited.
     * @param _encodedSpendingTx RLP encoded transaction that spent the UTXO.
     * @param _spendingTxConfirmationSignature Confirmation signature over the spending transaction.
     */
    function challengeExit(
        uint256 _exitingUtxoBlockNumber,
        uint256 _exitingUtxoTxIndex,
        uint256 _exitingUtxoOutputIndex,
        bytes _encodedSpendingTx,
        bytes _spendingTxConfirmationSignature
    ) public {
        PlasmaUtils.Transaction memory transaction = PlasmaUtils.decodeTx(_encodedSpendingTx);
        uint256 exitingUtxoPosition = PlasmaUtils.encodeUtxoPosition(_exitingUtxoBlockNumber, _exitingUtxoTxIndex, _exitingUtxoOutputIndex);

        // Check that the exiting UTXO was actually spent.
        bool spendsExitingUtxo = false;
        for (uint8 i = 0; i < transaction.inputs.length; i++) {
            if (exitingUtxoPosition == PlasmaUtils.getInputPosition(transaction.inputs[i])) {
                spendsExitingUtxo = true;
                break;
            }
        }
        require(spendsExitingUtxo, "Transaction must spend exiting UTXO.");

        // Check that the spending transaction was confirmed.
        bytes32 confirmationHash = keccak256(abi.encodePacked(keccak256(_encodedSpendingTx)));
        address owner = plasmaExits[exitingUtxoPosition].owner;
        require(owner == ECRecovery.recover(confirmationHash, _spendingTxConfirmationSignature), "Transaction must be confirmed.");

        // The exit is invalid.
        plasmaExits[exitingUtxoPosition].isValid = false;
    }

    /**
     * @dev Processes any exits that have completed the exit period.
     */
    function processExits() public {
        uint256 exitableAt;
        uint256 utxoPosition;

        // Iterate while the queue is not empty.
        while(exitQueue.currentSize() > 0){
            (exitableAt, utxoPosition) = exitQueue.getMin();

            // Check if this exit has finished its challenge period.
            if (exitableAt > block.timestamp){
                return;
            }

            PlasmaExit memory currentExit = plasmaExits[utxoPosition];

            // Only pay out valid exits.
            if (currentExit.isValid){
                require(token.transfer(currentExit.owner, currentExit.amount));

                // Delete owner but keep amount to prevent another exit from the same UTXO.
                delete plasmaExits[utxoPosition].owner;
            }

            exitQueue.delMin();
        }
    }
}