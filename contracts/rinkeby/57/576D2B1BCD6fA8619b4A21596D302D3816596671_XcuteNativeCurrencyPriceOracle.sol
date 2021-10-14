pragma solidity ^0.8.4;

import "./libraries/FixedPoint.sol";
import "./libraries/UniswapV2ForkOracleLibrary.sol";
import "./interfaces/IUniswapV2ForkPair.sol";
import "./interfaces/IXcuteNativeCurrencyPriceOracle.sol";
import "./Job.sol";

error ZeroAddressPair();
error InvalidRefreshRate();
error NoWorkRequired();
error NoXcuteInPair();

/**
 * @title XcuteNativeCurrencyPriceOracle
 * @dev XcuteNativeCurrencyPriceOracle contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
contract XcuteNativeCurrencyPriceOracle is
    Job,
    IXcuteNativeCurrencyPriceOracle
{
    using FixedPoint for *;

    struct Observation {
        uint32 timestamp;
        FixedPoint.uq112x112 price;
        uint256 lastCumulative;
    }

    uint256 refreshRate;
    Observation public observation;
    bool private token0;
    address public pair;

    constructor(
        address _xcuteMaster,
        address _pair,
        address _xcute,
        uint256 _refreshRate
    ) Job(_xcuteMaster) {
        if (_pair == address(0)) revert ZeroAddressPair();
        if (_refreshRate <= 30) revert InvalidRefreshRate();

        if (IUniswapV2ForkPair(_pair).token0() == _xcute) token0 = true;
        else if (IUniswapV2ForkPair(_pair).token1() == _xcute) token0 = false;
        else revert NoXcuteInPair();

        (
            uint256 _price0Cumulative,
            uint256 _price1Cumulative,
            uint32 _timestamp
        ) = UniswapV2ForkOracleLibrary.currentCumulativePrices(_pair);

        refreshRate = _refreshRate;
        pair = _pair;
        observation = Observation({
            timestamp: _timestamp,
            price: FixedPoint.uq112x112(0),
            lastCumulative: token0 ? _price1Cumulative : _price0Cumulative
        });
    }

    function _workable() internal view returns (bool) {
        (, , uint32 _timestamp) = UniswapV2ForkOracleLibrary
            .currentCumulativePrices(pair);
        uint32 _timeElapsed;
        unchecked {
            _timeElapsed = _timestamp - observation.timestamp;
        }
        return _timestamp - observation.timestamp >= refreshRate;
    }

    function workable() external view override returns (bool) {
        return _workable();
    }

    function work() external override needsExecution {
        if (!_workable()) revert NoWorkRequired();

        (
            uint256 _price0Cumulative,
            uint256 _price1Cumulative,
            uint32 _timestamp
        ) = UniswapV2ForkOracleLibrary.currentCumulativePrices(pair);

        uint256 _priceCumulative = (
            token0 ? _price1Cumulative : _price0Cumulative
        );
        FixedPoint.uq112x112 memory _averagePriceCumulative;
        // over/underflow is desired
        unchecked {
            uint32 _timeElapsed = _timestamp - observation.timestamp;
            _averagePriceCumulative = FixedPoint.uq112x112(
                uint224(
                    (_priceCumulative - observation.lastCumulative) /
                        _timeElapsed
                )
            );
        }

        observation.price = _averagePriceCumulative;
        observation.lastCumulative = _priceCumulative;
        observation.timestamp = _timestamp;
    }

    function quote(uint256 _nativeCurrencyAmount)
        external
        view
        returns (uint256)
    {
        return observation.price.mul(_nativeCurrencyAmount).decode144();
    }
}

pragma solidity ^0.8.4;

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

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(x != 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y)
        internal
        pure
        returns (uq144x112 memory)
    {
        uint256 z;
        require(
            y == 0 || (z = uint256(self._x) * y) / y == uint256(self._x),
            "FixedPoint: MULTIPLICATION_OVERFLOW"
        );
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator)
        internal
        pure
        returns (uq112x112 memory)
    {
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
}

/// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "../interfaces/IUniswapV2ForkPair.sol";
import "./FixedPoint.sol";

library UniswapV2ForkOracleLibrary {
    using FixedPoint for *;

    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }

    function currentCumulativePrices(address pair)
        internal
        view
        returns (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        )
    {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2ForkPair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2ForkPair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = IUniswapV2ForkPair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            unchecked {
                // subtraction overflow is desired
                uint32 timeElapsed = blockTimestamp - blockTimestampLast;
                // addition overflow is desired
                // counterfactual
                price0Cumulative +=
                    uint256(FixedPoint.fraction(reserve1, reserve0)._x) *
                    timeElapsed;
                // counterfactual
                price1Cumulative +=
                    uint256(FixedPoint.fraction(reserve0, reserve1)._x) *
                    timeElapsed;
            }
        }
    }
}

pragma solidity >=0.8.9;

/**
 * @title IUniswapV2ForkPair
 * @dev IUniswapV2ForkPair contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IUniswapV2ForkPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

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

pragma solidity >=0.8.9;

/**
 * @title IXcuteNativeCurrencyPriceOracle
 * @dev IXcuteNativeCurrencyPriceOracle contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IXcuteNativeCurrencyPriceOracle {
    function quote(uint256 _nativeCurrencyAmount)
        external
        view
        returns (uint256);
}

pragma solidity ^0.8.4;

import "./interfaces/IXcuteMaster.sol";
import "@openzeppelin/contracts/utils/Context.sol";

error ZeroAddressMaster();
error NotAWorker();
error InvalidWorker();

/**
 * @title IJob
 * @dev IJob contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
abstract contract Job is Context {
    address public immutable XCUTE_MASTER;

    constructor(address _xcuteMaster) {
        if (_xcuteMaster == address(0)) revert ZeroAddressMaster();
        XCUTE_MASTER = _xcuteMaster;
    }

    function workable() external view virtual returns (bool);

    function work() external virtual;

    modifier needsExecution() {
        if (!IXcuteMaster(XCUTE_MASTER).isWorker(_msgSender()))
            revert NotAWorker();
        _;
        IXcuteMaster(XCUTE_MASTER).worked(_msgSender());
    }

    modifier needsExecutionWithRequirements(
        uint256 _minimumStaked,
        uint256 _minimumEarned,
        uint256 _minimumAge
    ) {
        if (
            !IXcuteMaster(XCUTE_MASTER).isWorkerWithRequirements(
                _msgSender(),
                _minimumStaked,
                _minimumEarned,
                _minimumAge
            )
        ) revert InvalidWorker();
        _;
        IXcuteMaster(XCUTE_MASTER).worked(_msgSender());
    }
}

pragma solidity >=0.8.9;

/**
 * @title IXcuteMaster
 * @dev IXcuteMaster contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IXcuteMaster {
    struct Job {
        bool exists;
        uint256 credit;
    }

    function addJob(address _job) external;

    function removeJob(address _job) external;

    function addFreeCredit(address _job, uint256 _amount) external;

    function addCredit(address _job, uint256 _amount) external;

    function addCreditWithPermit(
        address _job,
        uint256 _amount,
        uint256 _permittedAmount, // can be used for infinite approvals
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function isWorker(address _address) external returns (bool);

    function isWorkerWithRequirements(
        address _address,
        uint256 _minimumStaked,
        uint256 _minimumEarned,
        uint256 _minimumAge
    ) external returns (bool);

    function worked(address _worker) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}