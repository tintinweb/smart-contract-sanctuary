/**
 *Submitted for verification at polygonscan.com on 2021-10-27
*/

// SPDX-License-Identifier: AGPL-3.0-or-later AND GPL-3.0-or-later AND CC-BY-4.0
// Sources flattened with hardhat v2.6.6 https://hardhat.org

// File @keydonix/uniswap-oracle-contracts/source/[email protected]

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;
library BlockVerifier {
	function extractStateRootAndTimestamp(bytes memory rlpBytes) internal view returns (bytes32 stateRoot, uint256 blockTimestamp, uint256 blockNumber) {
		assembly {
			function revertWithReason(message, length) {
				mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
				mstore(4, 0x20)
				mstore(0x24, length)
				mstore(0x44, message)
				revert(0, add(0x44, length))
			}

			function readDynamic(prefixPointer) -> dataPointer, dataLength {
				let value := byte(0, mload(prefixPointer))
				switch lt(value, 0x80)
				case 1 {
					dataPointer := prefixPointer
					dataLength := 1
				}
				case 0 {
					dataPointer := add(prefixPointer, 1)
					dataLength := sub(value, 0x80)
				}
			}

			// get the length of the data
			let rlpLength := mload(rlpBytes)
			// move pointer forward, ahead of length
			rlpBytes := add(rlpBytes, 0x20)

			// we know the length of the block will be between 483 bytes and 709 bytes, which means it will have 2 length bytes after the prefix byte, so we can skip 3 bytes in
			// CONSIDER: we could save a trivial amount of gas by compressing most of this into a single add instruction
			let parentHashPrefixPointer := add(rlpBytes, 3)
			let parentHashPointer := add(parentHashPrefixPointer, 1)
			let uncleHashPrefixPointer := add(parentHashPointer, 32)
			let uncleHashPointer := add(uncleHashPrefixPointer, 1)
			let minerAddressPrefixPointer := add(uncleHashPointer, 32)
			let minerAddressPointer := add(minerAddressPrefixPointer, 1)
			let stateRootPrefixPointer := add(minerAddressPointer, 20)
			let stateRootPointer := add(stateRootPrefixPointer, 1)
			let transactionRootPrefixPointer := add(stateRootPointer, 32)
			let transactionRootPointer := add(transactionRootPrefixPointer, 1)
			let receiptsRootPrefixPointer := add(transactionRootPointer, 32)
			let receiptsRootPointer := add(receiptsRootPrefixPointer, 1)
			let logsBloomPrefixPointer := add(receiptsRootPointer, 32)
			let logsBloomPointer := add(logsBloomPrefixPointer, 3)
			let difficultyPrefixPointer := add(logsBloomPointer, 256)
			let difficultyPointer, difficultyLength := readDynamic(difficultyPrefixPointer)
			let blockNumberPrefixPointer := add(difficultyPointer, difficultyLength)
			let blockNumberPointer, blockNumberLength := readDynamic(blockNumberPrefixPointer)
			let gasLimitPrefixPointer := add(blockNumberPointer, blockNumberLength)
			let gasLimitPointer, gasLimitLength := readDynamic(gasLimitPrefixPointer)
			let gasUsedPrefixPointer := add(gasLimitPointer, gasLimitLength)
			let gasUsedPointer, gasUsedLength := readDynamic(gasUsedPrefixPointer)
			let timestampPrefixPointer := add(gasUsedPointer, gasUsedLength)
			let timestampPointer, timestampLength := readDynamic(timestampPrefixPointer)

			blockNumber := shr(sub(256, mul(blockNumberLength, 8)), mload(blockNumberPointer))
			let blockHash := blockhash(blockNumber)
			let rlpHash := keccak256(rlpBytes, rlpLength)
			if iszero(eq(blockHash, rlpHash)) { revertWithReason("blockHash != rlpHash", 20) }

			stateRoot := mload(stateRootPointer)
			blockTimestamp := shr(sub(256, mul(timestampLength, 8)), mload(timestampPointer))
		}
	}
}


// File @keydonix/uniswap-oracle-contracts/source/[email protected]

pragma solidity 0.6.8;

library Rlp {
	uint constant DATA_SHORT_START = 0x80;
	uint constant DATA_LONG_START = 0xB8;
	uint constant LIST_SHORT_START = 0xC0;
	uint constant LIST_LONG_START = 0xF8;

	uint constant DATA_LONG_OFFSET = 0xB7;
	uint constant LIST_LONG_OFFSET = 0xF7;


	struct Item {
		uint _unsafe_memPtr;    // Pointer to the RLP-encoded bytes.
		uint _unsafe_length;    // Number of bytes. This is the full length of the string.
	}

	struct Iterator {
		Item _unsafe_item;   // Item that's being iterated over.
		uint _unsafe_nextPtr;   // Position of the next item in the list.
	}

	/* Iterator */

	function next(Iterator memory self) internal pure returns (Item memory subItem) {
		require(hasNext(self), "Rlp.sol:Rlp:next:1");
		uint256 ptr = self._unsafe_nextPtr;
		uint256 itemLength = _itemLength(ptr);
		subItem._unsafe_memPtr = ptr;
		subItem._unsafe_length = itemLength;
		self._unsafe_nextPtr = ptr + itemLength;
	}

	function next(Iterator memory self, bool strict) internal pure returns (Item memory subItem) {
		subItem = next(self);
		require(!strict || _validate(subItem), "Rlp.sol:Rlp:next:2");
	}

	function hasNext(Iterator memory self) internal pure returns (bool) {
		Rlp.Item memory item = self._unsafe_item;
		return self._unsafe_nextPtr < item._unsafe_memPtr + item._unsafe_length;
	}

	/* Item */

	/// @dev Creates an Item from an array of RLP encoded bytes.
	/// @param self The RLP encoded bytes.
	/// @return An Item
	function toItem(bytes memory self) internal pure returns (Item memory) {
		uint len = self.length;
		if (len == 0) {
			return Item(0, 0);
		}
		uint memPtr;
		assembly {
			memPtr := add(self, 0x20)
		}
		return Item(memPtr, len);
	}

	/// @dev Creates an Item from an array of RLP encoded bytes.
	/// @param self The RLP encoded bytes.
	/// @param strict Will throw if the data is not RLP encoded.
	/// @return An Item
	function toItem(bytes memory self, bool strict) internal pure returns (Item memory) {
		Rlp.Item memory item = toItem(self);
		if(strict) {
			uint len = self.length;
			require(_payloadOffset(item) <= len, "Rlp.sol:Rlp:toItem4");
			require(_itemLength(item._unsafe_memPtr) == len, "Rlp.sol:Rlp:toItem:5");
			require(_validate(item), "Rlp.sol:Rlp:toItem:6");
		}
		return item;
	}

	/// @dev Check if the Item is null.
	/// @param self The Item.
	/// @return 'true' if the item is null.
	function isNull(Item memory self) internal pure returns (bool) {
		return self._unsafe_length == 0;
	}

	/// @dev Check if the Item is a list.
	/// @param self The Item.
	/// @return 'true' if the item is a list.
	function isList(Item memory self) internal pure returns (bool) {
		if (self._unsafe_length == 0)
			return false;
		uint memPtr = self._unsafe_memPtr;
		bool result;
		assembly {
			result := iszero(lt(byte(0, mload(memPtr)), 0xC0))
		}
		return result;
	}

	/// @dev Check if the Item is data.
	/// @param self The Item.
	/// @return 'true' if the item is data.
	function isData(Item memory self) internal pure returns (bool) {
		if (self._unsafe_length == 0)
			return false;
		uint memPtr = self._unsafe_memPtr;
		bool result;
		assembly {
			result := lt(byte(0, mload(memPtr)), 0xC0)
		}
		return result;
	}

	/// @dev Check if the Item is empty (string or list).
	/// @param self The Item.
	/// @return result 'true' if the item is null.
	function isEmpty(Item memory self) internal pure returns (bool) {
		if(isNull(self))
			return false;
		uint b0;
		uint memPtr = self._unsafe_memPtr;
		assembly {
			b0 := byte(0, mload(memPtr))
		}
		return (b0 == DATA_SHORT_START || b0 == LIST_SHORT_START);
	}

	/// @dev Get the number of items in an RLP encoded list.
	/// @param self The Item.
	/// @return The number of items.
	function items(Item memory self) internal pure returns (uint) {
		if (!isList(self))
			return 0;
		uint b0;
		uint memPtr = self._unsafe_memPtr;
		assembly {
			b0 := byte(0, mload(memPtr))
		}
		uint pos = memPtr + _payloadOffset(self);
		uint last = memPtr + self._unsafe_length - 1;
		uint itms;
		while(pos <= last) {
			pos += _itemLength(pos);
			itms++;
		}
		return itms;
	}

	/// @dev Create an iterator.
	/// @param self The Item.
	/// @return An 'Iterator' over the item.
	function iterator(Item memory self) internal pure returns (Iterator memory) {
		require(isList(self), "Rlp.sol:Rlp:iterator:1");
		uint ptr = self._unsafe_memPtr + _payloadOffset(self);
		Iterator memory it;
		it._unsafe_item = self;
		it._unsafe_nextPtr = ptr;
		return it;
	}

	/// @dev Return the RLP encoded bytes.
	/// @param self The Item.
	/// @return The bytes.
	function toBytes(Item memory self) internal pure returns (bytes memory) {
		uint256 len = self._unsafe_length;
		require(len != 0, "Rlp.sol:Rlp:toBytes:2");
		bytes memory bts;
		bts = new bytes(len);
		_copyToBytes(self._unsafe_memPtr, bts, len);
		return bts;
	}

	/// @dev Decode an Item into bytes. This will not work if the
	/// Item is a list.
	/// @param self The Item.
	/// @return The decoded string.
	function toData(Item memory self) internal pure returns (bytes memory) {
		require(isData(self));
		(uint256 rStartPos, uint256 len) = _decode(self);
		bytes memory bts;
		bts = new bytes(len);
		_copyToBytes(rStartPos, bts, len);
		return bts;
	}

	/// @dev Get the list of sub-items from an RLP encoded list.
	/// Warning: This is inefficient, as it requires that the list is read twice.
	/// @param self The Item.
	/// @return Array of Items.
	function toList(Item memory self) internal pure returns (Item[] memory) {
		require(isList(self), "Rlp.sol:Rlp:toList:1");
		uint256 numItems = items(self);
		Item[] memory list = new Item[](numItems);
		Rlp.Iterator memory it = iterator(self);
		uint idx;
		while(hasNext(it)) {
			list[idx] = next(it);
			idx++;
		}
		return list;
	}

	/// @dev Decode an Item into an ascii string. This will not work if the
	/// Item is a list.
	/// @param self The Item.
	/// @return The decoded string.
	function toAscii(Item memory self) internal pure returns (string memory) {
		require(isData(self), "Rlp.sol:Rlp:toAscii:1");
		(uint256 rStartPos, uint256 len) = _decode(self);
		bytes memory bts = new bytes(len);
		_copyToBytes(rStartPos, bts, len);
		string memory str = string(bts);
		return str;
	}

	/// @dev Decode an Item into a uint. This will not work if the
	/// Item is a list.
	/// @param self The Item.
	/// @return The decoded string.
	function toUint(Item memory self) internal pure returns (uint) {
		require(isData(self), "Rlp.sol:Rlp:toUint:1");
		(uint256 rStartPos, uint256 len) = _decode(self);
		require(len <= 32, "Rlp.sol:Rlp:toUint:3");
		require(len != 0, "Rlp.sol:Rlp:toUint:4");
		uint data;
		assembly {
			data := div(mload(rStartPos), exp(256, sub(32, len)))
		}
		return data;
	}

	/// @dev Decode an Item into a boolean. This will not work if the
	/// Item is a list.
	/// @param self The Item.
	/// @return The decoded string.
	function toBool(Item memory self) internal pure returns (bool) {
		require(isData(self), "Rlp.sol:Rlp:toBool:1");
		(uint256 rStartPos, uint256 len) = _decode(self);
		require(len == 1, "Rlp.sol:Rlp:toBool:3");
		uint temp;
		assembly {
			temp := byte(0, mload(rStartPos))
		}
		require(temp <= 1, "Rlp.sol:Rlp:toBool:8");
		return temp == 1 ? true : false;
	}

	/// @dev Decode an Item into a byte. This will not work if the
	/// Item is a list.
	/// @param self The Item.
	/// @return The decoded string.
	function toByte(Item memory self) internal pure returns (byte) {
		require(isData(self), "Rlp.sol:Rlp:toByte:1");
		(uint256 rStartPos, uint256 len) = _decode(self);
		require(len == 1, "Rlp.sol:Rlp:toByte:3");
		byte temp;
		assembly {
			temp := byte(0, mload(rStartPos))
		}
		return byte(temp);
	}

	/// @dev Decode an Item into an int. This will not work if the
	/// Item is a list.
	/// @param self The Item.
	/// @return The decoded string.
	function toInt(Item memory self) internal pure returns (int) {
		return int(toUint(self));
	}

	/// @dev Decode an Item into a bytes32. This will not work if the
	/// Item is a list.
	/// @param self The Item.
	/// @return The decoded string.
	function toBytes32(Item memory self) internal pure returns (bytes32) {
		return bytes32(toUint(self));
	}

	/// @dev Decode an Item into an address. This will not work if the
	/// Item is a list.
	/// @param self The Item.
	/// @return The decoded string.
	function toAddress(Item memory self) internal pure returns (address) {
		require(isData(self), "Rlp.sol:Rlp:toAddress:1");
		(uint256 rStartPos, uint256 len) = _decode(self);
		require(len == 20, "Rlp.sol:Rlp:toAddress:3");
		address data;
		assembly {
			data := div(mload(rStartPos), exp(256, 12))
		}
		return data;
	}

	// Get the payload offset.
	function _payloadOffset(Item memory self) private pure returns (uint) {
		if(self._unsafe_length == 0)
			return 0;
		uint b0;
		uint memPtr = self._unsafe_memPtr;
		assembly {
			b0 := byte(0, mload(memPtr))
		}
		if(b0 < DATA_SHORT_START)
			return 0;
		if(b0 < DATA_LONG_START || (b0 >= LIST_SHORT_START && b0 < LIST_LONG_START))
			return 1;
		if(b0 < LIST_SHORT_START)
			return b0 - DATA_LONG_OFFSET + 1;
		return b0 - LIST_LONG_OFFSET + 1;
	}

	// Get the full length of an Item.
	function _itemLength(uint memPtr) private pure returns (uint len) {
		uint b0;
		assembly {
			b0 := byte(0, mload(memPtr))
		}
		if (b0 < DATA_SHORT_START)
			len = 1;
		else if (b0 < DATA_LONG_START)
			len = b0 - DATA_SHORT_START + 1;
		else if (b0 < LIST_SHORT_START) {
			assembly {
				let bLen := sub(b0, 0xB7) // bytes length (DATA_LONG_OFFSET)
				let dLen := div(mload(add(memPtr, 1)), exp(256, sub(32, bLen))) // data length
				len := add(1, add(bLen, dLen)) // total length
			}
		}
		else if (b0 < LIST_LONG_START)
			len = b0 - LIST_SHORT_START + 1;
		else {
			assembly {
				let bLen := sub(b0, 0xF7) // bytes length (LIST_LONG_OFFSET)
				let dLen := div(mload(add(memPtr, 1)), exp(256, sub(32, bLen))) // data length
				len := add(1, add(bLen, dLen)) // total length
			}
		}
	}

	// Get start position and length of the data.
	function _decode(Item memory self) private pure returns (uint memPtr, uint len) {
		require(isData(self), "Rlp.sol:Rlp:_decode:1");
		uint b0;
		uint start = self._unsafe_memPtr;
		assembly {
			b0 := byte(0, mload(start))
		}
		if (b0 < DATA_SHORT_START) {
			memPtr = start;
			len = 1;
			return (memPtr, len);
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
		return (memPtr, len);
	}

	// Assumes that enough memory has been allocated to store in target.
	function _copyToBytes(uint sourceBytes, bytes memory destinationBytes, uint btsLen) internal pure {
		// Exploiting the fact that 'tgt' was the last thing to be allocated,
		// we can write entire words, and just overwrite any excess.
		assembly {
			let words := div(add(btsLen, 31), 32)
			let sourcePointer := sourceBytes
			let destinationPointer := add(destinationBytes, 32)
			for { let i := 0 } lt(i, words) { i := add(i, 1) }
			{
				let offset := mul(i, 32)
				mstore(add(destinationPointer, offset), mload(add(sourcePointer, offset)))
			}
			mstore(add(destinationBytes, add(32, mload(destinationBytes))), 0)
		}
	}

	// Check that an Item is valid.
	function _validate(Item memory self) private pure returns (bool ret) {
		// Check that RLP is well-formed.
		uint b0;
		uint b1;
		uint memPtr = self._unsafe_memPtr;
		assembly {
			b0 := byte(0, mload(memPtr))
			b1 := byte(1, mload(memPtr))
		}
		if(b0 == DATA_SHORT_START + 1 && b1 < DATA_SHORT_START)
			return false;
		return true;
	}

	function rlpBytesToUint256(bytes memory source) internal pure returns (uint256 result) {
		return Rlp.toUint(Rlp.toItem(source));
	}
}


// File @keydonix/uniswap-oracle-contracts/source/[email protected]

pragma solidity 0.6.8;

library MerklePatriciaVerifier {
	/*
	 * @dev Extracts the value from a merkle proof
	 * @param expectedRoot The expected hash of the root node of the trie.
	 * @param path The path in the trie leading to value.
	 * @param proofNodesRlp RLP encoded array of proof nodes.
	 * @return The value proven to exist in the merkle patricia tree whose root is `expectedRoot` at the path `path`
	 *
	 * WARNING: Does not currently support validation of unset/0 values!
	 */
	function getValueFromProof(bytes32 expectedRoot, bytes32 path, bytes memory proofNodesRlp) internal pure returns (bytes memory) {
		Rlp.Item memory rlpParentNodes = Rlp.toItem(proofNodesRlp);
		Rlp.Item[] memory parentNodes = Rlp.toList(rlpParentNodes);

		bytes memory currentNode;
		Rlp.Item[] memory currentNodeList;

		bytes32 nodeKey = expectedRoot;
		uint pathPtr = 0;

		// our input is a 32-byte path, but we have to prepend a single 0 byte to that and pass it along as a 33 byte memory array since that is what getNibbleArray wants
		bytes memory nibblePath = new bytes(33);
		assembly { mstore(add(nibblePath, 33), path) }
		nibblePath = _getNibbleArray(nibblePath);

		require(path.length != 0, "empty path provided");

		currentNode = Rlp.toBytes(parentNodes[0]);

		for (uint i=0; i<parentNodes.length; i++) {
			require(pathPtr <= nibblePath.length, "Path overflow");

			currentNode = Rlp.toBytes(parentNodes[i]);
			require(nodeKey == keccak256(currentNode), "node doesn't match key");
			currentNodeList = Rlp.toList(parentNodes[i]);

			if(currentNodeList.length == 17) {
				if(pathPtr == nibblePath.length) {
					return Rlp.toData(currentNodeList[16]);
				}

				uint8 nextPathNibble = uint8(nibblePath[pathPtr]);
				require(nextPathNibble <= 16, "nibble too long");
				nodeKey = Rlp.toBytes32(currentNodeList[nextPathNibble]);
				pathPtr += 1;
			} else if(currentNodeList.length == 2) {
				pathPtr += _nibblesToTraverse(Rlp.toData(currentNodeList[0]), nibblePath, pathPtr);
				// leaf node
				if(pathPtr == nibblePath.length) {
					return Rlp.toData(currentNodeList[1]);
				}
				//extension node
				require(_nibblesToTraverse(Rlp.toData(currentNodeList[0]), nibblePath, pathPtr) != 0, "invalid extension node");

				nodeKey = Rlp.toBytes32(currentNodeList[1]);
			} else {
				require(false, "unexpected length array");
			}
		}
		require(false, "not enough proof nodes");
	}

	function _nibblesToTraverse(bytes memory encodedPartialPath, bytes memory path, uint pathPtr) private pure returns (uint) {
		uint len;
		// encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
		// and slicedPath have elements that are each one hex character (1 nibble)
		bytes memory partialPath = _getNibbleArray(encodedPartialPath);
		bytes memory slicedPath = new bytes(partialPath.length);

		// pathPtr counts nibbles in path
		// partialPath.length is a number of nibbles
		for(uint i=pathPtr; i<pathPtr+partialPath.length; i++) {
			byte pathNibble = path[i];
			slicedPath[i-pathPtr] = pathNibble;
		}

		if(keccak256(partialPath) == keccak256(slicedPath)) {
			len = partialPath.length;
		} else {
			len = 0;
		}
		return len;
	}

	// bytes byteArray must be hp encoded
	function _getNibbleArray(bytes memory byteArray) private pure returns (bytes memory) {
		bytes memory nibbleArray;
		if (byteArray.length == 0) return nibbleArray;

		uint8 offset;
		uint8 hpNibble = uint8(_getNthNibbleOfBytes(0,byteArray));
		if(hpNibble == 1 || hpNibble == 3) {
			nibbleArray = new bytes(byteArray.length*2-1);
			byte oddNibble = _getNthNibbleOfBytes(1,byteArray);
			nibbleArray[0] = oddNibble;
			offset = 1;
		} else {
			nibbleArray = new bytes(byteArray.length*2-2);
			offset = 0;
		}

		for(uint i=offset; i<nibbleArray.length; i++) {
			nibbleArray[i] = _getNthNibbleOfBytes(i-offset+2,byteArray);
		}
		return nibbleArray;
	}

	function _getNthNibbleOfBytes(uint n, bytes memory str) private pure returns (byte) {
		return byte(n%2==0 ? uint8(str[n/2])/0x10 : uint8(str[n/2])%0x10);
	}
}


// File @keydonix/uniswap-oracle-contracts/source/[email protected]

pragma solidity 0.6.8;

// https://raw.githubusercontent.com/Uniswap/uniswap-v2-core/master/contracts/libraries/UQ112x112.sol
// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
	uint224 constant Q112 = 2**112;

	// encode a uint112 as a UQ112x112
	function encode(uint112 y) internal pure returns (uint224 z) {
		z = uint224(y) * Q112; // never overflows
	}

	// divide a UQ112x112 by a uint112, returning a UQ112x112
	function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
		z = x / uint224(y);
	}
}


// File @keydonix/uniswap-oracle-contracts/source/[email protected]

pragma solidity 0.6.8;






contract UniswapOracle {
	using UQ112x112 for uint224;

	bytes32 public constant reserveTimestampSlotHash = keccak256(abi.encodePacked(uint256(8)));
	bytes32 public constant token0Slot = keccak256(abi.encodePacked(uint256(9)));
	bytes32 public constant token1Slot = keccak256(abi.encodePacked(uint256(10)));

	struct ProofData {
		bytes block;
		bytes accountProofNodesRlp;
		bytes reserveAndTimestampProofNodesRlp;
		bytes priceAccumulatorProofNodesRlp;
	}

	function getAccountStorageRoot(address uniswapV2Pair, ProofData memory proofData) public view returns (bytes32 storageRootHash, uint256 blockNumber, uint256 blockTimestamp) {
		bytes32 stateRoot;
		(stateRoot, blockTimestamp, blockNumber) = BlockVerifier.extractStateRootAndTimestamp(proofData.block);
		bytes memory accountDetailsBytes = MerklePatriciaVerifier.getValueFromProof(stateRoot, keccak256(abi.encodePacked(uniswapV2Pair)), proofData.accountProofNodesRlp);
		Rlp.Item[] memory accountDetails = Rlp.toList(Rlp.toItem(accountDetailsBytes));
		return (Rlp.toBytes32(accountDetails[2]), blockNumber, blockTimestamp);
	}

	// This function verifies the full block is old enough (MIN_BLOCK_COUNT), not too old (or blockhash will return 0x0) and return the proof values for the two storage slots we care about
	function verifyBlockAndExtractReserveData(IUniswapV2Pair uniswapV2Pair, uint8 minBlocksBack, uint8 maxBlocksBack, bytes32 slotHash, ProofData memory proofData) public view returns
	(uint256 blockTimestamp, uint256 blockNumber, uint256 priceCumulativeLast, uint112 reserve0, uint112 reserve1, uint256 reserveTimestamp) {
		bytes32 storageRootHash;
		(storageRootHash, blockNumber, blockTimestamp) = getAccountStorageRoot(address(uniswapV2Pair), proofData);
		require (blockNumber <= block.number - minBlocksBack, "Proof does not span enough blocks");
		require (blockNumber >= block.number - maxBlocksBack, "Proof spans too many blocks");

		priceCumulativeLast = Rlp.rlpBytesToUint256(MerklePatriciaVerifier.getValueFromProof(storageRootHash, slotHash, proofData.priceAccumulatorProofNodesRlp));
		uint256 reserve0Reserve1TimestampPacked = Rlp.rlpBytesToUint256(MerklePatriciaVerifier.getValueFromProof(storageRootHash, reserveTimestampSlotHash, proofData.reserveAndTimestampProofNodesRlp));
		reserveTimestamp = reserve0Reserve1TimestampPacked >> (112 + 112);
		reserve1 = uint112((reserve0Reserve1TimestampPacked >> 112) & (2**112 - 1));
		reserve0 = uint112(reserve0Reserve1TimestampPacked & (2**112 - 1));
	}

	function getPrice(IUniswapV2Pair uniswapV2Pair, address denominationToken, uint8 minBlocksBack, uint8 maxBlocksBack, ProofData memory proofData) public view returns (uint256 price, uint256 blockNumber) {
		// exchange = the ExchangeV2Pair. check denomination token (USE create2 check?!) check gas cost
		bool denominationTokenIs0;
		if (uniswapV2Pair.token0() == denominationToken) {
			denominationTokenIs0 = true;
		} else if (uniswapV2Pair.token1() == denominationToken) {
			denominationTokenIs0 = false;
		} else {
			revert("denominationToken invalid");
		}
		return getPriceRaw(uniswapV2Pair, denominationTokenIs0, minBlocksBack, maxBlocksBack, proofData);
	}

	function getPriceRaw(IUniswapV2Pair uniswapV2Pair, bool denominationTokenIs0, uint8 minBlocksBack, uint8 maxBlocksBack, ProofData memory proofData) public view returns (uint256 price, uint256 blockNumber) {
		uint256 historicBlockTimestamp;
		uint256 historicPriceCumulativeLast;
		{
			// Stack-too-deep workaround, manual scope
			// Side-note: wtf Solidity?
			uint112 reserve0;
			uint112 reserve1;
			uint256 reserveTimestamp;
			(historicBlockTimestamp, blockNumber, historicPriceCumulativeLast, reserve0, reserve1, reserveTimestamp) = verifyBlockAndExtractReserveData(uniswapV2Pair, minBlocksBack, maxBlocksBack, denominationTokenIs0 ? token1Slot : token0Slot, proofData);
			uint256 secondsBetweenReserveUpdateAndHistoricBlock = historicBlockTimestamp - reserveTimestamp;
			// bring old record up-to-date, in case there was no cumulative update in provided historic block itself
			if (secondsBetweenReserveUpdateAndHistoricBlock > 0) {
				historicPriceCumulativeLast += secondsBetweenReserveUpdateAndHistoricBlock * uint(UQ112x112
					.encode(denominationTokenIs0 ? reserve0 : reserve1)
					.uqdiv(denominationTokenIs0 ? reserve1 : reserve0)
				);
			}
		}
		uint256 secondsBetweenProvidedBlockAndNow = block.timestamp - historicBlockTimestamp;
		price = (getCurrentPriceCumulativeLast(uniswapV2Pair, denominationTokenIs0) - historicPriceCumulativeLast) / secondsBetweenProvidedBlockAndNow;
		return (price, blockNumber);
	}

	function getCurrentPriceCumulativeLast(IUniswapV2Pair uniswapV2Pair, bool denominationTokenIs0) public view returns (uint256 priceCumulativeLast) {
		(uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = uniswapV2Pair.getReserves();
		priceCumulativeLast = denominationTokenIs0 ? uniswapV2Pair.price1CumulativeLast() : uniswapV2Pair.price0CumulativeLast();
		uint256 timeElapsed = block.timestamp - blockTimestampLast;
		priceCumulativeLast += timeElapsed * uint(UQ112x112
			.encode(denominationTokenIs0 ? reserve0 : reserve1)
			.uqdiv(denominationTokenIs0 ? reserve1 : reserve0)
		);
	}
}


// File contracts/interfaces/IEnv.sol



pragma solidity =0.6.8;

interface IEnv {
  function oracleConfig(address ctr) external view returns (uint8, uint8);

  function rcv() external view returns (address);

  function dsc() external view returns (address);

  function max() external view returns (uint256);

  function fee() external view returns (uint256);

  function spt(address wad, address factory) external view returns (address);

  function end(address usr) external view returns (uint256);

  function active(address ctr) external view returns (bool);

  function month(uint8 idx) external view returns (uint256);

  function price(address wad, uint256 period) external view returns (uint256);

  function set_rcv(address rcv_) external;

  function set_max(uint256 max_) external;

  function set_end(uint256 end_, address guy) external;

  function set_fee(uint256 fee_) external;

  function stop(address ctr) external;

  function start(address ctr) external;

  function set_config(
    address ctr,
    uint8 min_,
    uint8 max_
  ) external;

  function orc(
    IUniswapV2Pair pair,
    address denominationToken,
    uint8 minBlocksBack,
    uint8 maxBlocksBack,
    UniswapOracle.ProofData calldata proofData
  ) external returns (uint256 val, uint256 blockNumber);
}


// File contracts/interfaces/ISPT.sol



pragma solidity =0.6.8;

interface ISPT {
  event Subscribed(
    address indexed subscriber,
    address indexed token,
    uint256 indexed months,
    uint256 price,
    uint256 tokensPaid,
    uint256 expiryDate
  );

  function init(
    address wad_,
    address[] calldata path_,
    address factory_
  ) external;

  function wad() external view returns (address);

  function factory() external view returns (address);

  function path() external view returns (address[] memory);

  function pairs() external view returns (address[] memory res);

  function deployer() external view returns (address);

  function price(
    uint256 multiplier,
    UniswapOracle.ProofData[] calldata proofData
  )
    external
    returns (
      uint256 val,
      address dst,
      uint256 blockNumber
    );

  function subscribe(uint8 idx, UniswapOracle.ProofData[] calldata proofData)
    external
    returns (uint256);
}


// File contracts/libraries/TransferHelper.sol


pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}


// File contracts/libraries/SafeMath.sol



pragma solidity =0.6.8;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }
}


// File contracts/libraries/FullMath.sol

pragma solidity >=0.4.0;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
    }
}


// File contracts/libraries/Babylonian.sol


pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}


// File contracts/libraries/BitMath.sol

pragma solidity >=0.5.0;

library BitMath {
    // returns the 0 indexed position of the most significant bit of the input x
    // s.t. x >= 2**msb and x < 2**(msb+1)
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, "BitMath::mostSignificantBit: zero");

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    // returns the 0 indexed position of the least significant bit of the input x
    // s.t. (x & 2**lsb) != 0 and (x & (2**(lsb) - 1)) == 0)
    // i.e. the bit at the index is set and the mask of all lower bits is 0
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, "BitMath::leastSignificantBit: zero");

        r = 255;
        if (x & uint128(-1) > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & uint64(-1) > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & uint32(-1) > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & uint16(-1) > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & uint8(-1) > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}


// File contracts/libraries/FixedPoint.sol

pragma solidity >=0.4.0;
// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint::mul: overflow');
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(uq112x112 memory self, int256 y) internal pure returns (int256) {
        uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
        require(z < 2**255, 'FixedPoint::muli: overflow');
        return y < 0 ? -int256(z) : int256(z);
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(upper <= uint112(-1), 'FixedPoint::muluq: upper overflow');

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) + uppers_lowero + uppero_lowers + (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= uint224(-1), 'FixedPoint::muluq: sum overflow');

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        require(other._x > 0, 'FixedPoint::divuq: division by zero');
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= uint144(-1)) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= uint224(-1), 'FixedPoint::divuq: overflow');
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= uint224(-1), 'FixedPoint::divuq: overflow');
        return uq112x112(uint224(result));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // can be lossy
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint::reciprocal: reciprocal of zero');
        require(self._x != 1, 'FixedPoint::reciprocal: overflow');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= uint144(-1)) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}


// File contracts/interfaces/IUniswapV2Pair.sol


pragma solidity >=0.5.0;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}


// File contracts/libraries/UniswapV2Library.sol



pragma solidity >=0.5.0;
library UniswapV2Library {
  using SafeMath for uint256;

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex"ff",
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
          )
        )
      )
    );
  }

  // fetches and sorts the reserves for a pair
  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
      pairFor(factory, tokenA, tokenB)
    ).getReserves();
    (reserveA, reserveB) = tokenA == token0
      ? (reserve0, reserve1)
      : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) internal pure returns (uint256 amountB) {
    require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
    require(
      reserveA > 0 && reserveB > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    amountB = amountA.mul(reserveB) / reserveA;
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountIn) {
    require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 numerator = reserveIn.mul(amountOut).mul(1000);
    uint256 denominator = reserveOut.sub(amountOut).mul(997);
    amountIn = (numerator / denominator).add(1);
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(
    address factory,
    uint256 amountIn,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[0] = amountIn;
    for (uint256 i; i < path.length - 1; i++) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(
        factory,
        path[i],
        path[i + 1]
      );
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(
    address factory,
    uint256 amountOut,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = path.length - 1; i > 0; i--) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(
        factory,
        path[i - 1],
        path[i]
      );
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}


// File contracts/spt.sol



pragma solidity =0.6.8;






contract SPT is ISPT {
  using SafeMath for uint256;
  uint256 private immutable MONTH = 30 days;

  address[] private PATH;
  bytes4 private constant SELECTOR =
    bytes4(keccak256(bytes("transfer(address,uint256)")));
  IEnv private immutable env;

  address public override wad;
  address public override factory;

  function _safeTransfer(
    address token,
    address to,
    uint256 value
  ) private {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(SELECTOR, to, value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TF");
  }

  constructor() public {
    env = IEnv(msg.sender);
  }

  function init(
    address wad_,
    address[] calldata path_,
    address factory_
  ) external override {
    require(msg.sender == address(env), "SPT/not-authorized");
    wad = wad_;
    factory = factory_;
    PATH = path_;
  }

  function path() external view override returns (address[] memory) {
    return PATH;
  }

  function pairs() external view override returns (address[] memory res) {
    for (uint256 i; i < PATH.length - 1; i++) {
      res[i] = UniswapV2Library.pairFor(factory, PATH[i], PATH[i + 1]);
    }
  }

  function deployer() external view override returns (address) {
    return address(env);
  }

  // unupdated, run getPriceUpdated before using this.
  function price(
    uint256 multiplier,
    UniswapOracle.ProofData[] calldata proofData
  )
    external
    override
    returns (
      uint256 val,
      address dst,
      uint256 blockNumber
    )
  {
    (uint8 minBlocksBack, uint8 maxBlocksBack) = env.oracleConfig(
      address(this)
    );
    for (uint256 i; i < PATH.length - 1; i++) {
      address src = PATH[i];
      dst = PATH[i + 1];
      address pair = UniswapV2Library.pairFor(factory, src, dst);
      (val, blockNumber) = env.orc(
        IUniswapV2Pair(pair),
        src,
        minBlocksBack,
        maxBlocksBack,
        proofData[i]
      );
      val = val.mul(multiplier);
      multiplier = val;
    }
  }

  function subscribe(uint8 idx, UniswapOracle.ProofData[] calldata proofData)
    external
    override
    returns (uint256)
  {
    uint256 end_old = env.end(msg.sender);
    uint256 period = env.month(idx);
    address rcv = env.rcv();
    uint256 end = end_old == 0
      ? block.timestamp.add(period.mul(MONTH))
      : end_old.add(period.mul(MONTH));
    uint256 MAX_MONTHS = env.max().mul(MONTH);
    // new expiry date can not be more than 12 months from now;
    require((end.sub(block.timestamp)) <= MAX_MONTHS, "SPT/max-reached");
    uint256 multiplier = env.price(wad, period);
    (uint256 val, address src, ) = this.price(multiplier, proofData);
    val = val.mul(period);

    TransferHelper.safeTransferFrom(src, msg.sender, rcv, val);
    env.set_end(end, msg.sender);
    emit Subscribed(msg.sender, src, period, multiplier, val, end);
    return end;
  }
}