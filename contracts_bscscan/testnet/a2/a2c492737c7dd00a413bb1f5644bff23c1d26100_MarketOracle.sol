/**
 *Submitted for verification at BscScan.com on 2021-10-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;



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

// Part: IUniswapV2Pair

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

// Part: Ownable

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;
  address private _previousOwner;
  uint256 private _lockTime;

  event OwnershipRenounced(address indexed previousOwner);

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  function getUnlockTime() public view returns (uint256) {
    return _lockTime;
  }


  //Locks the contract for owner
  function lock() public onlyOwner {
    _previousOwner = _owner;
    _owner = address(0);
    emit OwnershipRenounced(_owner);

  }

  function unlock() public {
    require(_previousOwner == msg.sender, "You don’t have permission to unlock");
    require(now > _lockTime , "Contract is locked until 7 days");
    emit OwnershipTransferred(_owner, _previousOwner);
    _owner = _previousOwner;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
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

// File: MarketOracle.sol

/**
 * @title MNY price Oracle
 *      This Oracle calculates the average USD price of MNY based on the BNB-MNY and USDC-BNB pools.
 *      NOTE: This might need to be modified based on the actual BSC mainnet listings and available pools
 */
contract MarketOracle is Ownable {
    using FixedPoint for *;

    uint private mnyBnbPrice0CumulativeLast;
    uint private mnyBnbPrice1CumulativeLast;
    uint32 private mnyBnbBlockTimestampLast;

    uint private wbnbBusdPrice0CumulativeLast;
    uint private wbnbBusdPrice1CumulativeLast;
    uint32 private wbnbBusdBlockTimestampLast;


    IUniswapV2Pair private _mny_bnb;
    IUniswapV2Pair private _wbnb_busd;

    address public controller;

    modifier onlyControllerOrOwner {
        require(msg.sender == controller || msg.sender == owner());
        _;
    }

    constructor(
        address __mny_bnb,   // Address of the mny-BNB pair on Pancakeswap
        address __wbnb_busd   // Address of the WBNB-BUSD on Pancakeswapx
        ) public {

        controller = msg.sender;

        _mny_bnb = IUniswapV2Pair(__mny_bnb);
        _wbnb_busd = IUniswapV2Pair(__wbnb_busd);

        uint112 _dummy1;
        uint112 _dummy2;

        mnyBnbPrice0CumulativeLast = _mny_bnb.price0CumulativeLast();
        mnyBnbPrice1CumulativeLast = _mny_bnb.price1CumulativeLast();

        (_dummy1, _dummy2, mnyBnbBlockTimestampLast) = _mny_bnb.getReserves();

        wbnbBusdPrice0CumulativeLast = _wbnb_busd.price0CumulativeLast();
        wbnbBusdPrice1CumulativeLast = _wbnb_busd.price1CumulativeLast();

        (_dummy1, _dummy2, wbnbBusdBlockTimestampLast) = _wbnb_busd.getReserves();
    }

    // Get the average price of 1 mny in the smallest BNB unit (18 decimals)
    function getmnyBnbRate() public view returns (uint256, uint256, uint32, uint256) {
        (uint price0Cumulative, uint price1Cumulative, uint32 _blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(_mny_bnb));

        require(_blockTimestamp != mnyBnbBlockTimestampLast, "MNY Last and current are equal");

        FixedPoint.uq112x112 memory mnyBnbAverage = FixedPoint.uq112x112(uint224(1e9 * (price0Cumulative - mnyBnbPrice0CumulativeLast) / (_blockTimestamp - mnyBnbBlockTimestampLast)));

        return (price0Cumulative, price1Cumulative, _blockTimestamp, mnyBnbAverage.mul(1).decode144());
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
   function update() external onlyControllerOrOwner {

        uint mnyBnbAverage;
        uint busdBnbAverage;

        (mnyBnbPrice0CumulativeLast, mnyBnbPrice1CumulativeLast, mnyBnbBlockTimestampLast, mnyBnbAverage) = getmnyBnbRate();
        (wbnbBusdPrice0CumulativeLast, wbnbBusdPrice1CumulativeLast, wbnbBusdBlockTimestampLast, busdBnbAverage) = getBusdBnbRate();
    }

    // Return the average price since last update
    function getData() external view returns (uint256) {

        uint _price0CumulativeLast;
        uint _price1CumulativeLast;
        uint32 _blockTimestampLast;

        uint mnyBnbAverage;

        (_price0CumulativeLast, _price1CumulativeLast, _blockTimestampLast, mnyBnbAverage) = getmnyBnbRate();

        uint busdBnbAverage;

         (_price0CumulativeLast, _price1CumulativeLast, _blockTimestampLast, busdBnbAverage) = getBusdBnbRate();

        uint answer = mnyBnbAverage*(1e6) / busdBnbAverage;

        return (answer);
    }

    function setController(address controller_)
        external
        onlyOwner
    {
        controller = controller_;
    }

}