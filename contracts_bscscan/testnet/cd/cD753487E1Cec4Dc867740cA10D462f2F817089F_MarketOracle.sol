/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;



// Part: Babylonian

// computes square roots using the babylonian mBnbod
// https://en.wikipedia.org/wiki/MBnbods_of_computing_square_roots#Babylonian_mBnbod
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


interface IPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Part: FixedPoint

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

// Part: UniswapV2OracleLibrary

// library with helper mBnbods for oracles that are concerned with computing average prices
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
        price0Cumulative = IPair(pair).price0CumulativeLast();
        price1Cumulative = IPair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IPair(pair).getReserves();
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


/**
 * @title SHIBIN price Oracle
 *      This Oracle calculates the average USD price of SHIBIN based on the BNB-SHIBIN and BUSD-BNB pools.
 *      NOTE: This might need to be modified based on the actual BSC mainnet listings and available pools
 */
contract MarketOracle is Ownable {
    using FixedPoint for *;

    uint private SHIBINBnbPrice0CumulativeLast;
    uint private SHIBINBnbPrice1CumulativeLast;
    uint32 private SHIBINBnbBlockTimestampLast;

    uint private wbnbBusdPrice0CumulativeLast;
    uint private wbnbBusdPrice1CumulativeLast;
    uint32 private wbnbBusdBlockTimestampLast;

    address private constant _wbnb = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address private constant _busd = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;

    IPair private _SHIBIN_bnb;
    IPair private _wbnb_busd;

    address public system;

    modifier onlySystemOrOwner {
        require(msg.sender == system || msg.sender == owner());
        _;
    }

    constructor(
        address __SHIBIN_bnb,   // Address of the SHIBIN-BNB pair on Pancakeswap
        address __wbnb_busd   // Address of the WBNB-BUSD on Pancakeswapx
        )  {

        system = msg.sender;

        _SHIBIN_bnb = IPair(__SHIBIN_bnb);
        _wbnb_busd = IPair(__wbnb_busd);

        uint112 _dummy1;
        uint112 _dummy2;

        SHIBINBnbPrice0CumulativeLast = _SHIBIN_bnb.price0CumulativeLast();
        SHIBINBnbPrice1CumulativeLast = _SHIBIN_bnb.price1CumulativeLast();

        (_dummy1, _dummy2, SHIBINBnbBlockTimestampLast) = _SHIBIN_bnb.getReserves();

        wbnbBusdPrice0CumulativeLast = _wbnb_busd.price0CumulativeLast();
        wbnbBusdPrice1CumulativeLast = _wbnb_busd.price1CumulativeLast();

        (_dummy1, _dummy2, wbnbBusdBlockTimestampLast) = _wbnb_busd.getReserves();
    }

    // Get the average price of 1 SHIBIN in the smallest BNB unit (18 decimals)
    function getSHIBIN_BNB_Rate() public view returns (uint256, uint256, uint32, uint256) {
        (uint price0Cumulative, uint price1Cumulative, uint32 _blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(_SHIBIN_bnb));

        require(_blockTimestamp != SHIBINBnbBlockTimestampLast, "SHIBIN Last and current are equal");

        FixedPoint.uq112x112 memory SHIBINBnbAverage = FixedPoint.uq112x112(uint224(1e9 * (price0Cumulative - SHIBINBnbPrice0CumulativeLast) / (_blockTimestamp - SHIBINBnbBlockTimestampLast)));

        return (price0Cumulative, price1Cumulative, _blockTimestamp, SHIBINBnbAverage.mul(1).decode144());
    }

    // Get the average price of 1 USD in the smallest BNB unit (18 decimals)
    function getBusdBnbRate() public view returns (uint256, uint256, uint32, uint256) {
        (uint price0Cumulative, uint price1Cumulative, uint32 _blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(_wbnb_busd));

        require(_blockTimestamp != wbnbBusdBlockTimestampLast, "BUSD Last and current are equal");

        FixedPoint.uq112x112 memory busdBnbAverage = FixedPoint.uq112x112(uint224(1e6 * (price1Cumulative - wbnbBusdPrice1CumulativeLast) / (_blockTimestamp - wbnbBusdBlockTimestampLast)));

        return (price0Cumulative, price1Cumulative, _blockTimestamp, busdBnbAverage.mul(1).decode144());
    }

    // Update "last" state variables to current values
   function update() external onlySystemOrOwner {

        uint SHIBINBnbAverage;
        uint busdBnbAverage;

        (SHIBINBnbPrice0CumulativeLast, SHIBINBnbPrice1CumulativeLast, SHIBINBnbBlockTimestampLast, SHIBINBnbAverage) = getSHIBIN_BNB_Rate();
        (wbnbBusdPrice0CumulativeLast, wbnbBusdPrice1CumulativeLast, wbnbBusdBlockTimestampLast, busdBnbAverage) = getBusdBnbRate();
    }

    // Return the average price since last update
    function getData() external view returns (uint256) {

        uint _price0CumulativeLast;
        uint _price1CumulativeLast;
        uint32 _blockTimestampLast;

        uint SHIBINBnbAverage;

        (_price0CumulativeLast, _price1CumulativeLast, _blockTimestampLast, SHIBINBnbAverage) = getSHIBIN_BNB_Rate();

        uint busdBnbAverage;

         (_price0CumulativeLast, _price1CumulativeLast, _blockTimestampLast, busdBnbAverage) = getBusdBnbRate();

        uint answer = SHIBINBnbAverage*(1e6) / busdBnbAverage;

        return (answer);
    }
    
    function setSHIBIN_BNB_Pair(address __SHIBIN_bnb) external onlyOwner{
        _SHIBIN_bnb = IPair(__SHIBIN_bnb);
    }

    function setSystem(address system_) external onlyOwner{
        system = system_;
    }

}