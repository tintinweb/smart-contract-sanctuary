pragma solidity =0.5.16;

import "./libraries/UQ112x112.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IPriceOracle.sol";

contract PriceOracle is IPriceOracle {
    using UQ112x112 for uint224;

    uint32 public constant MIN_T = 1500;

    struct Pair {
        uint256 priceCumulativeSlotA;
        uint256 priceCumulativeSlotB;
        uint32 lastUpdateSlotA;
        uint32 lastUpdateSlotB;
        bool latestIsSlotA;
        bool initialized;
    }
    mapping(address => Pair) public getPair;

    event PriceUpdate(
        address indexed pair,
        uint256 priceCumulative,
        uint32 blockTimestamp,
        bool latestIsSlotA
    );

    function toUint224(uint256 input) internal pure returns (uint224) {
        require(input <= uint224(-1), "PriceOracle: UINT224_OVERFLOW");
        return uint224(input);
    }

    function getPriceCumulativeCurrent(address uniswapV2Pair)
        internal
        view
        returns (uint256 priceCumulative)
    {
        priceCumulative = IUniswapV2Pair(uniswapV2Pair).price0CumulativeLast();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) =
            IUniswapV2Pair(uniswapV2Pair).getReserves();
        uint224 priceLatest = UQ112x112.encode(reserve1).uqdiv(reserve0);
        uint32 timeElapsed = getBlockTimestamp() - blockTimestampLast; // overflow is desired
        // * never overflows, and + overflow is desired
        priceCumulative += uint256(priceLatest) * timeElapsed;
    }

    function initialize(address uniswapV2Pair) external {
        Pair storage pairStorage = getPair[uniswapV2Pair];
        require(!pairStorage.initialized, "PriceOracle: ALREADY_INITIALIZED");

        uint256 priceCumulativeCurrent =
            getPriceCumulativeCurrent(uniswapV2Pair);
        uint32 blockTimestamp = getBlockTimestamp();
        pairStorage.priceCumulativeSlotA = priceCumulativeCurrent;
        pairStorage.priceCumulativeSlotB = priceCumulativeCurrent;
        pairStorage.lastUpdateSlotA = blockTimestamp;
        pairStorage.lastUpdateSlotB = blockTimestamp;
        pairStorage.latestIsSlotA = true;
        pairStorage.initialized = true;
        emit PriceUpdate(
            uniswapV2Pair,
            priceCumulativeCurrent,
            blockTimestamp,
            true
        );
    }

    function getResult(address uniswapV2Pair)
        external
        returns (uint224 price, uint32 T)
    {
        Pair memory pair = getPair[uniswapV2Pair];
        require(pair.initialized, "PriceOracle: NOT_INITIALIZED");
        Pair storage pairStorage = getPair[uniswapV2Pair];

        uint32 blockTimestamp = getBlockTimestamp();
        uint32 lastUpdateTimestamp =
            pair.latestIsSlotA ? pair.lastUpdateSlotA : pair.lastUpdateSlotB;
        uint256 priceCumulativeCurrent =
            getPriceCumulativeCurrent(uniswapV2Pair);
        uint256 priceCumulativeLast;

        if (blockTimestamp - lastUpdateTimestamp >= MIN_T) {
            // update price
            priceCumulativeLast = pair.latestIsSlotA
                ? pair.priceCumulativeSlotA
                : pair.priceCumulativeSlotB;
            if (pair.latestIsSlotA) {
                pairStorage.priceCumulativeSlotB = priceCumulativeCurrent;
                pairStorage.lastUpdateSlotB = blockTimestamp;
            } else {
                pairStorage.priceCumulativeSlotA = priceCumulativeCurrent;
                pairStorage.lastUpdateSlotA = blockTimestamp;
            }
            pairStorage.latestIsSlotA = !pair.latestIsSlotA;
            emit PriceUpdate(
                uniswapV2Pair,
                priceCumulativeCurrent,
                blockTimestamp,
                !pair.latestIsSlotA
            );
        } else {
            // don't update and return price using previous priceCumulative
            lastUpdateTimestamp = pair.latestIsSlotA
                ? pair.lastUpdateSlotB
                : pair.lastUpdateSlotA;
            priceCumulativeLast = pair.latestIsSlotA
                ? pair.priceCumulativeSlotB
                : pair.priceCumulativeSlotA;
        }

        T = blockTimestamp - lastUpdateTimestamp; // overflow is desired
        require(T >= MIN_T, "PriceOracle: NOT_READY"); //reverts only if the pair has just been initialized
        // / is safe, and - overflow is desired
        price = toUint224((priceCumulativeCurrent - priceCumulativeLast) / T);
    }

    /*** Utilities ***/

    function getBlockTimestamp() public view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }
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

pragma solidity =0.5.16;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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
}

pragma solidity =0.5.16;

interface IPriceOracle {
    event PriceUpdate(
        address indexed pair,
        uint256 priceCumulative,
        uint32 blockTimestamp,
        bool lastIsA
    );

    function MIN_T() external pure returns (uint32);

    function getPair(address uniswapV2Pair)
        external
        view
        returns (
            uint256 priceCumulativeSlotA,
            uint256 priceCumulativeSlotB,
            uint32 lastUpdateSlotA,
            uint32 lastUpdateSlotB,
            bool latestIsSlotA,
            bool initialized
        );

    function initialize(address uniswapV2Pair) external;

    function getResult(address uniswapV2Pair)
        external
        returns (uint224 price, uint32 T);

    function getBlockTimestamp() external view returns (uint32);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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