/**
 *Submitted for verification at Etherscan.io on 2021-04-18
*/

//SPDX-License-Identifier: MIT 
pragma solidity 0.6.11; 
pragma experimental ABIEncoderV2;

// ====================================================================
//     ________                   _______                           
//    / ____/ /__  ____  ____ _  / ____(_)___  ____ _____  ________ 
//   / __/ / / _ \/ __ \/ __ `/ / /_  / / __ \/ __ `/ __ \/ ___/ _ \
//  / /___/ /  __/ / / / /_/ / / __/ / / / / / /_/ / / / / /__/  __/
// /_____/_/\___/_/ /_/\__,_(_)_/   /_/_/ /_/\__,_/_/ /_/\___/\___/                                                                                                                     
//                                                                        
// ====================================================================
// ====================== Elena Protocol (USE) ========================
// ====================================================================

// Dapp    :  https://elena.finance
// Twitter :  https://twitter.com/ElenaProtocol
// Telegram:  https://t.me/ElenaFinance
// ====================================================================

// File: contracts\Uniswap\Interfaces\IUniswapV2Factory.sol
// License: MIT

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: contracts\Uniswap\Interfaces\IUniswapV2Pair.sol
// License: MIT

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

// File: contracts\Common\Babylonian.sol
// License: MIT

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// File: contracts\Common\FixedPoint.sol
// License: MIT


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
        uint _x;
    }
    uint8 private constant RESOLUTION = 112;
    uint private constant Q112 = uint(1) << RESOLUTION;
    uint private constant Q224 = Q112 << RESOLUTION;
    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }
    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }
    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }
    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }
    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }
    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }
    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint: ZERO_RECIPROCAL');
        return uq112x112(uint224(Q224 / self._x));
    }
    // square root of a UQ112x112
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}

// File: contracts\Uniswap\UniswapV2OracleLibrary.sol
// License: MIT



// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;
    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }
    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();
        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

// File: contracts\Oracle\UniswapPairOracle.sol
// License: MIT

// Fixed window oracle that recomputes the average price for the entire period once every period
// Note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract UniswapPairOracle {
    using FixedPoint for *;
    address owner_address;
    address timelock_address;
    uint public PERIOD = 3600; // 1 hour TWAP (time-weighted average price)
    uint public CONSULT_LENIENCY = 120; // Used for being able to consult past the period end
    bool public ALLOW_STALE_CONSULTS = true; // If false, consult() will fail if the TWAP is stale
    IUniswapV2Pair public  pair;
    address public  token0;
    address public  token1;
    uint    public price0CumulativeLast;
    uint    public price1CumulativeLast;
    uint32  public blockTimestampLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;
    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == owner_address || msg.sender == timelock_address, "You are not an owner or the governance timelock");
        _;
    }
    constructor(address _pair) public { 
        pair = IUniswapV2Pair(_pair);
        token0 = pair.token0();
        token1 = pair.token1();
        price0CumulativeLast = pair.price0CumulativeLast(); // Fetch the current accumulated price value (1 / 0)
        price1CumulativeLast = pair.price1CumulativeLast(); // Fetch the current accumulated price value (0 / 1)
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, 'UniswapPairOracle: NO_RESERVES'); // Ensure that there's liquidity in the pair
        owner_address = msg.sender;
        timelock_address = msg.sender;
    }
    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
    }
    function setTimelock(address _timelock_address) external onlyByOwnerOrGovernance {
        timelock_address = _timelock_address;
    }
    function setPeriod(uint _period) external onlyByOwnerOrGovernance {
        PERIOD = _period;
    }
    function setConsultLeniency(uint _consult_leniency) external onlyByOwnerOrGovernance {
        CONSULT_LENIENCY = _consult_leniency;
    }
    function setAllowStaleConsults(bool _allow_stale_consults) external onlyByOwnerOrGovernance {
        ALLOW_STALE_CONSULTS = _allow_stale_consults;
    }
    // Check if update() can be called instead of wasting gas calling it
    function canUpdate() public view returns (bool) {
        uint32 blockTimestamp = UniswapV2OracleLibrary.currentBlockTimestamp();
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // Overflow is desired
        return (timeElapsed >= PERIOD);
    }
    //get other token
    function getPairToken(address token) external view returns(address){
        return token == token0 ? token1 : token0;
    }
    function containsToken(address token) external view returns(bool){
        return token == token0 || token == token1;
    }
    function getSwapTokenReserve(address token) external view returns(uint256){
         (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
         if(token == token0) return reserve0;
         if(token == token1) return reserve1;
         return 0;
    }
    function getTimeElapsed() public view returns(uint256){
        (, , uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        return blockTimestamp - blockTimestampLast; // Overflow is desired
    }
    function update() external returns(bool){
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
              UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // Overflow is desired
        // Ensure that at least one full period has passed since the last update
        //require(timeElapsed >= PERIOD, 'UniswapPairOracle: PERIOD_NOT_ELAPSED');
        if(timeElapsed >= PERIOD){
            // Overflow is desired, casting never truncates
            // Cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
            price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
            price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));
            price0CumulativeLast = price0Cumulative;
            price1CumulativeLast = price1Cumulative;
            blockTimestampLast = blockTimestamp;
            return true;
        }
        return false;
    }
    // Note this will always return 0 before update has been called successfully for the first time.
    function consult(address tokenIn, uint amountIn) external view returns (uint amountOut) {
        uint32 blockTimestamp = UniswapV2OracleLibrary.currentBlockTimestamp();
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // Overflow is desired
        // Ensure that the price is not stale
        require((timeElapsed < (PERIOD + CONSULT_LENIENCY)) || ALLOW_STALE_CONSULTS, 'UniswapPairOracle: PRICE_IS_STALE_NEED_TO_CALL_UPDATE');
        if (tokenIn == token0) {
            amountOut = price1Average.mul(amountIn).decode144();
        } else {
            require(tokenIn == token1, 'UniswapPairOracle: INVALID_TOKEN');
            amountOut = price0Average.mul(amountIn).decode144();
        }
    }
}