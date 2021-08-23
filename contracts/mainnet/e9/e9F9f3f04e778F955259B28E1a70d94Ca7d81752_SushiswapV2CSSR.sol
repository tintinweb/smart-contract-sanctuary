// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import {SushiswapV2Library} from "@mochifi/library/contracts/SushiswapV2Library.sol";
import {UQ112x112} from "@mochifi/library/contracts/UQ112x112.sol";
import {BlockVerifier} from "@mochifi/library/contracts/BlockVerifier.sol";
import {MerklePatriciaVerifier} from "@mochifi/library/contracts/MerklePatriciaVerifier.sol";
import {Rlp} from "@mochifi/library/contracts/Rlp.sol";
import {AccountVerifier} from "@mochifi/library/contracts/AccountVerifier.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2CSSR.sol";

contract SushiswapV2CSSR is IUniswapV2CSSR {
    address public immutable override uniswapFactory;
    using UQ112x112 for uint224;

    bytes32 public constant reserveTimestampSlotHash =
        keccak256(abi.encodePacked(uint256(8)));
    bytes32 public constant token0Slot =
        keccak256(abi.encodePacked(uint256(9)));
    bytes32 public constant token1Slot =
        keccak256(abi.encodePacked(uint256(10)));

    uint256 public constant WINDOW_SIZE = 10 minutes;

    mapping(uint256 => Window) public window;
    // blockNumber => stateRoot
    mapping(uint256 => BlockData) public blockState;
    // blockNumber => pair => observedData
    mapping(uint256 => mapping(address => ObservedData)) public observedData;

    constructor(address _uniswapFactory) {
        uniswapFactory = _uniswapFactory;
    }

    // stores block data
    function saveState(bytes memory blockData)
        external
        override
        returns (
            bytes32 stateRoot,
            uint256 blockNumber,
            uint256 blockTimestamp
        )
    {
        (stateRoot, blockTimestamp, blockNumber) = BlockVerifier
            .extractStateRootAndTimestamp(blockData);
        if (blockState[blockNumber].blockTimestamp != 0) {
            return (stateRoot, blockNumber, blockTimestamp);
        }
        blockState[blockNumber] = BlockData({
            blockTimestamp: blockTimestamp,
            stateRoot: stateRoot
        });
        updateWindow(uint128(blockNumber), blockTimestamp);
    }

    function updateWindow(uint128 blockNumber, uint256 timestamp) internal {
        uint256 idx = windowIndex(timestamp);
        Window memory _window = window[idx];
        if (_window.from == 0 && _window.to == 0) {
            _window = Window({from: blockNumber, to: blockNumber});
        } else if (_window.from > blockNumber) {
            _window = Window({from: blockNumber, to: _window.to});
        } else if (_window.to < blockNumber) {
            _window = Window({from: _window.from, to: blockNumber});
        }
        window[idx] = _window;
    }

    function windowIndex(uint256 timestamp) internal pure returns (uint256) {
        return (timestamp / WINDOW_SIZE) * WINDOW_SIZE;
    }

    // does not cair about pair address since all it does is save the data
    function saveReserve(
        uint256 blockNumber,
        address pair,
        bytes memory accountProof,
        bytes memory reserveProof,
        bytes memory price0Proof,
        bytes memory price1Proof
    ) external override returns (ObservedData memory data) {
        bytes32 stateRoot = blockState[blockNumber].stateRoot;
        if (observedData[blockNumber][pair].reserveTimestamp != 0) {
            return observedData[blockNumber][pair];
        }
        bytes32 storageRoot = AccountVerifier.getAccountStorageRoot(
            pair,
            stateRoot,
            accountProof
        );
        (
            data.reserve0,
            data.reserve1,
            data.reserveTimestamp
        ) = unpackReserveData(
            Rlp.rlpBytesToUint256(
                MerklePatriciaVerifier.getValueFromProof(
                    storageRoot,
                    reserveTimestampSlotHash,
                    reserveProof
                )
            )
        );
        data.price0Data = Rlp.rlpBytesToUint256(
            MerklePatriciaVerifier.getValueFromProof(
                storageRoot,
                token0Slot,
                price0Proof
            )
        );
        data.price1Data = Rlp.rlpBytesToUint256(
            MerklePatriciaVerifier.getValueFromProof(
                storageRoot,
                token1Slot,
                price1Proof
            )
        );
        observedData[blockNumber][pair] = data;
    }

    function unpackReserveData(uint256 packedReserveData)
        internal
        pure
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 reserveTimestamp
        )
    {
        reserve0 = uint112(packedReserveData & (2**112 - 1));
        reserve1 = uint112((packedReserveData >> 112) & (2**112 - 1));
        reserveTimestamp = uint32(packedReserveData >> (112 + 112));
    }

    // locked **denominator** amount paired with token
    function getLiquidity(address token, address denominator)
        external
        view
        override
        returns (uint256)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(
            SushiswapV2Library.pairFor(uniswapFactory, token, denominator)
        );
        Window memory currentWindow = window[windowIndex(block.timestamp)];
        uint128 lastObserved = currentWindow.to;
        if (lastObserved == 0) {
            lastObserved = window[windowIndex(block.timestamp) - WINDOW_SIZE]
                .to;
            require(lastObserved != 0, "!observed");
        }
        BlockData memory state = blockState[lastObserved];
        require(block.timestamp - state.blockTimestamp < WINDOW_SIZE, "stale");
        bool denominationTokenIs0;
        if (pair.token0() == denominator) {
            denominationTokenIs0 = true;
        } else if (pair.token1() == denominator) {
            denominationTokenIs0 = false;
        } else {
            revert("denominationToken invalid");
        }
        ObservedData memory historicData = observedData[lastObserved][
            address(pair)
        ];
        return
            denominationTokenIs0
                ? historicData.reserve0
                : historicData.reserve1;
    }

    function getExchangeRatio(address token, address denominator)
        external
        view
        override
        returns (uint256)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(
            SushiswapV2Library.pairFor(uniswapFactory, token, denominator)
        );
        Window memory currentWindow = window[windowIndex(block.timestamp)];
        uint128 lastObserved = currentWindow.to;
        if (lastObserved == 0) {
            lastObserved = window[windowIndex(block.timestamp) - WINDOW_SIZE]
                .to;
            require(lastObserved != 0, "!observed");
        }
        BlockData memory state = blockState[lastObserved];
        require(block.timestamp - state.blockTimestamp < WINDOW_SIZE, "stale");
        bool denominationTokenIs0;
        if (pair.token0() == denominator) {
            denominationTokenIs0 = true;
        } else if (pair.token1() == denominator) {
            denominationTokenIs0 = false;
        } else {
            revert("denominationToken invalid");
        }
        //now calculate
        //get historic data
        ObservedData memory historicData = observedData[lastObserved][
            address(pair)
        ];
        uint256 historicePriceCumulative = calculatedPriceCumulative(
            denominationTokenIs0
                ? historicData.reserve0
                : historicData.reserve1,
            denominationTokenIs0
                ? historicData.reserve1
                : historicData.reserve0,
            denominationTokenIs0
                ? historicData.price1Data
                : historicData.price0Data,
            state.blockTimestamp - uint256(historicData.reserveTimestamp)
        );
        //get current data
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair
            .getReserves();
        uint256 currentPriceCumulative = calculatedPriceCumulative(
            denominationTokenIs0 ? reserve0 : reserve1,
            denominationTokenIs0 ? reserve1 : reserve0,
            denominationTokenIs0
                ? pair.price1CumulativeLast()
                : pair.price0CumulativeLast(),
            block.timestamp - blockTimestampLast
        );
        return
            (currentPriceCumulative - historicePriceCumulative) /
            (block.timestamp - state.blockTimestamp);
    }

    function calculatedPriceCumulative(
        uint112 reserve,
        uint112 pairedReserve,
        uint256 priceCumulativeLast,
        uint256 timeElapsed
    ) internal pure returns (uint256) {
        if (timeElapsed == 0) {
            return priceCumulativeLast;
        }
        return
            priceCumulativeLast +
            timeElapsed *
            uint256(UQ112x112.encode(reserve).uqdiv(pairedReserve));
    }
}

// SPDX-License-Identifier: MIT
// fetched from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
// slightly modified to remove SafeMath and 0.8 compatible
pragma solidity ^0.8.0;

import { IUniswapV2Pair } from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

library SushiswapV2Library {

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(bytes20(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303'
            ))))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Rlp } from "./Rlp.sol";

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
	function getValueFromProof(bytes32 expectedRoot, bytes32 path, bytes memory proofNodesRlp) internal pure returns (bytes memory value) {
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
			bytes1 pathNibble = path[i];
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
			bytes1 oddNibble = _getNthNibbleOfBytes(1,byteArray);
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

	function _getNthNibbleOfBytes(uint n, bytes memory str) private pure returns (bytes1) {
		return bytes1(n%2==0 ? uint8(str[n/2])/0x10 : uint8(str[n/2])%0x10);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function toByte(Item memory self) internal pure returns (bytes1) {
        require(isData(self), "Rlp.sol:Rlp:toByte:1");
        (uint256 rStartPos, uint256 len) = _decode(self);
        require(len == 1, "Rlp.sol:Rlp:toByte:3");
        bytes1 temp;
        assembly {
            temp := byte(0, mload(rStartPos))
        }
        return bytes1(temp);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import { BlockVerifier } from "./BlockVerifier.sol";
import { MerklePatriciaVerifier } from "./MerklePatriciaVerifier.sol";
import { Rlp } from "./Rlp.sol";


library AccountVerifier {
    function getAccountStorageRoot(
        address account,
        bytes32 stateRoot,
        bytes memory accountProof
    ) internal pure returns(
        bytes32 storageRootHash
    ) {
        bytes memory accountDetailsBytes = MerklePatriciaVerifier.getValueFromProof(stateRoot, keccak256(abi.encodePacked(account)), accountProof);
        Rlp.Item[] memory accountDetails = Rlp.toList(Rlp.toItem(accountDetailsBytes));
        return Rlp.toBytes32(accountDetails[2]);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct Window {
    uint128 from;
    uint128 to;
}

struct BlockData {
    uint256 blockTimestamp;
    bytes32 stateRoot;
}

struct ObservedData {
    uint32 reserveTimestamp;
    uint112 reserve0;
    uint112 reserve1;
    uint256 price0Data;
    uint256 price1Data;
}

interface IUniswapV2CSSR {
    function uniswapFactory() external view returns (address);

    function getExchangeRatio(address token, address denominator)
        external
        view
        returns (uint256);

    function getLiquidity(address token, address denominator)
        external
        view
        returns (uint256);

    function saveState(bytes memory blockData)
        external
        returns (
            bytes32 stateRoot,
            uint256 blockNumber,
            uint256 blockTimestamp
        );

    function saveReserve(
        uint256 blockNumber,
        address pair,
        bytes memory accountProof,
        bytes memory reserveProof,
        bytes memory price0Proof,
        bytes memory price1Proof
    ) external returns (ObservedData memory data);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "metadata": {
    "bytecodeHash": "none"
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}