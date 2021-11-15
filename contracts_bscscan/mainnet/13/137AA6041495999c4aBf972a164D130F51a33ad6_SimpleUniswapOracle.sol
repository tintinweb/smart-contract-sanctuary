pragma solidity =0.5.16;

import "./libraries/UQ112x112.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/ISimpleUniswapOracle.sol";

contract SimpleUniswapOracle is ISimpleUniswapOracle {
	using UQ112x112 for uint224;
	
	uint32 public constant MIN_T = 1800;
	
	struct Pair {
		uint256 priceCumulativeA;
		uint256 priceCumulativeB;
		uint32 updateA;
		uint32 updateB;
		bool lastIsA;
		bool initialized;
	}
	mapping(address => Pair) public getPair;

	event PriceUpdate(address indexed pair, uint256 priceCumulative, uint32 blockTimestamp, bool lastIsA);
	
	function toUint224(uint256 input) internal pure returns (uint224) {
		require(input <= uint224(-1), "UniswapOracle: UINT224_OVERFLOW");
		return uint224(input);
	}
	
	function getPriceCumulativeCurrent(address uniswapV2Pair) internal view returns (uint256 priceCumulative) {
		priceCumulative = IUniswapV2Pair(uniswapV2Pair).price0CumulativeLast();
		(uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(uniswapV2Pair).getReserves();
		uint224 priceLast = UQ112x112.encode(reserve1).uqdiv(reserve0);
		uint32 timeElapsed = getBlockTimestamp() - blockTimestampLast; // overflow is desired
		// * never overflows, and + overflow is desired
		priceCumulative += uint256(priceLast) * timeElapsed;
	}
	
	function initialize(address uniswapV2Pair) external {
		Pair storage pairStorage = getPair[uniswapV2Pair];
		require(!pairStorage.initialized, "UniswapOracle: ALREADY_INITIALIZED");
		
		uint256 priceCumulativeCurrent = getPriceCumulativeCurrent(uniswapV2Pair);
		uint32 blockTimestamp = getBlockTimestamp();
		pairStorage.priceCumulativeA = priceCumulativeCurrent;
		pairStorage.priceCumulativeB = priceCumulativeCurrent;
		pairStorage.updateA = blockTimestamp;
		pairStorage.updateB = blockTimestamp;
		pairStorage.lastIsA = true;
		pairStorage.initialized = true;
		emit PriceUpdate(uniswapV2Pair, priceCumulativeCurrent, blockTimestamp, true);
	}
	
	function getResult(address uniswapV2Pair) external returns (uint224 price, uint32 T) {
		Pair memory pair = getPair[uniswapV2Pair];
		require(pair.initialized, "UniswapOracle: NOT_INITIALIZED");
		Pair storage pairStorage = getPair[uniswapV2Pair];
				
		uint32 blockTimestamp = getBlockTimestamp();
		uint32 updateLast = pair.lastIsA ? pair.updateA : pair.updateB;
		uint256 priceCumulativeCurrent = getPriceCumulativeCurrent(uniswapV2Pair);
		uint256 priceCumulativeLast;
		
		if (blockTimestamp - updateLast >= MIN_T) {
			// update
			priceCumulativeLast = pair.lastIsA ? pair.priceCumulativeA : pair.priceCumulativeB;
			if (pair.lastIsA) {
				pairStorage.priceCumulativeB = priceCumulativeCurrent;
				pairStorage.updateB = blockTimestamp;
			} else {
				pairStorage.priceCumulativeA = priceCumulativeCurrent;
				pairStorage.updateA = blockTimestamp;
			}
			pairStorage.lastIsA = !pair.lastIsA;
			emit PriceUpdate(uniswapV2Pair, priceCumulativeCurrent, blockTimestamp, !pair.lastIsA);
		}
		else {
			// don't update and return price using previous priceCumulative
			updateLast = pair.lastIsA ? pair.updateB : pair.updateA;
			priceCumulativeLast = pair.lastIsA ? pair.priceCumulativeB : pair.priceCumulativeA;
		}
		
		T = blockTimestamp - updateLast; // overflow is desired
		require(T >= MIN_T, "UniswapOracle: NOT_READY"); //reverts only if the pair has just been initialized
		// / is safe, and - overflow is desired
		price = toUint224((priceCumulativeCurrent - priceCumulativeLast) / T);
	}
	
	/*** Utilities ***/
	
	function getBlockTimestamp() public view returns (uint32) {
		return uint32(block.timestamp % 2**32);
	}
}

pragma solidity =0.5.16;

interface ISimpleUniswapOracle {
	event PriceUpdate(address indexed pair, uint256 priceCumulative, uint32 blockTimestamp, bool lastIsA);
	function MIN_T() external pure returns (uint32);
	function getBlockTimestamp() external view returns (uint32);
	function getPair(address uniswapV2Pair) external view returns (
		uint256 priceCumulativeA,
		uint256 priceCumulativeB,
		uint32 updateA,
		uint32 updateB,
		bool lastIsA,
		bool initialized
	);
	function initialize(address uniswapV2Pair) external;
	function getResult(address uniswapV2Pair) external returns (uint224 price, uint32 T);
}

pragma solidity =0.5.16;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
}

pragma solidity =0.5.16;

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

