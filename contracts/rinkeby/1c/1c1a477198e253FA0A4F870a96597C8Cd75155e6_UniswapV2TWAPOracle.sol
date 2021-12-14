pragma solidity ^0.8.10;

import "@xcute/contracts/JobUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../libraries/FixedPoint.sol";
import "../libraries/UniswapV2OracleLibrary.sol";
import "../interfaces/external/IUniswapV2Pair.sol";
import "../interfaces/oracles/IOracle.sol";
import "../interfaces/IERC20Decimals.sol";
import "../interfaces/kpi-tokens/IKPIToken.sol";

error ZeroAddressKpiToken();
error ZeroAddressPair();
error InvalidRefreshRate();
error NoWorkRequired();
error NoTokenInPair();
error InvalidStartsAt();
error InvalidEndsAt();
error ZeroAddressToken();

/**
 * @title UniswapV2TWAPOracle
 * @dev UniswapV2TWAPOracle contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
contract UniswapV2TWAPOracle is JobUpgradeable, IOracle {
    using FixedPoint for *;

    struct Observation {
        uint32 timestamp;
        FixedPoint.uq112x112 price;
        uint256 lastCumulative;
    }

    bool private finalized;
    bool private token0;
    uint8 public tokenDecimals;
    uint32 public refreshRate;
    uint64 public startsAt;
    uint64 public endsAt;
    address public pair;
    address public kpiToken;
    Observation public observation;

    function initialize(address _kpiToken, bytes calldata _data)
        external
        initializer
    {
        if (_kpiToken == address(0)) revert ZeroAddressKpiToken();

        (
            address _workersMaster,
            address _pair,
            address _token,
            uint64 _startsAt,
            uint64 _endsAt,
            uint32 _refreshRate
        ) = abi.decode(
                _data,
                (address, address, address, uint64, uint64, uint32)
            );

        if (_pair == address(0)) revert ZeroAddressPair();
        if (_token == address(0)) revert ZeroAddressToken();
        if (_startsAt <= block.timestamp) revert InvalidStartsAt();
        if (_refreshRate <= 30) revert InvalidRefreshRate();
        if (_endsAt <= _startsAt + _refreshRate) revert InvalidEndsAt();

        if (IUniswapV2Pair(_pair).token0() == _token) token0 = true;
        else if (IUniswapV2Pair(_pair).token1() == _token) token0 = false;
        else revert NoTokenInPair();

        (
            uint256 _price0Cumulative,
            uint256 _price1Cumulative,
            uint32 _timestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(_pair);

        __Job_init(_workersMaster);
        kpiToken = _kpiToken;
        refreshRate = _refreshRate;
        startsAt = _startsAt;
        endsAt = _endsAt;
        tokenDecimals = IERC20Decimals(_token).decimals();
        pair = _pair;
        observation = Observation({
            timestamp: _timestamp,
            price: FixedPoint.uq112x112(0),
            lastCumulative: token0 ? _price1Cumulative : _price0Cumulative
        });
    }

    function _workable() internal view returns (bool) {
        if (block.timestamp < startsAt) return false;
        if (block.timestamp >= endsAt) return !finalized;
        (, , uint32 _timestamp) = UniswapV2OracleLibrary
            .currentCumulativePrices(pair);
        uint32 _timeElapsed;
        unchecked {
            _timeElapsed = _timestamp - observation.timestamp;
        }
        return _timeElapsed >= refreshRate;
    }

    function workable(bytes memory)
        external
        view
        override
        returns (bool, bytes memory)
    {
        return (_workable(), bytes(""));
    }

    function work(bytes memory) external override needsExecution {
        if (!_workable()) revert NoWorkRequired();

        if (block.timestamp >= endsAt && !finalized) {
            IKPIToken(kpiToken).finalize(
                observation.price.mul(10**tokenDecimals).decode144()
            );
            finalized = true;
            return;
        }

        (
            uint256 _price0Cumulative,
            uint256 _price1Cumulative,
            uint32 _timestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);

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
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IMaster.sol";
import "./interfaces/IJob.sol";

error ZeroAddressMaster();
error NotAWorker();
error InvalidWorker();

/**
 * @title JobUpgradeable
 * @dev JobUpgradeable contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
abstract contract JobUpgradeable is IJob, Initializable, ContextUpgradeable {
    address public master;

    function __Job_init(address _master) internal initializer {
        __Context_init_unchained();
        __Job_init_unchained(_master);
    }

    function __Job_init_unchained(address _master) internal initializer {
        if (_master == address(0)) revert ZeroAddressMaster();
        master = _master;
    }

    function workable(bytes calldata _data)
        external
        view
        virtual
        override
        returns (bool, bytes calldata);

    function work(bytes calldata _data) external virtual override;

    modifier needsExecution() {
        IMaster(master).initializeWork(_msgSender());
        _;
        IMaster(master).finalizeWork(_msgSender());
    }

    modifier needsExecutionWithRequirements(
        uint256 _minimumBonded,
        uint256 _minimumEarned,
        uint256 _minimumAge
    ) {
        IMaster(master).initializeWorkWithRequirements(
            _msgSender(),
            _minimumBonded,
            _minimumEarned,
            _minimumAge
        );
        _;
        IMaster(master).finalizeWork(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.10;

/**
 * @title FixedPoint
 * @dev A library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
 * @author Various
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
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

pragma solidity ^0.8.10;

import "../interfaces/external/IUniswapV2Pair.sol";
import "./FixedPoint.sol";

/**
 * @title UniswapV2OracleLibrary
 * @dev A library to facilitate the use of Uniswap-like pools as price oracles.
 * @author Various
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
library UniswapV2OracleLibrary {
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
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = IUniswapV2Pair(pair).getReserves();
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

pragma solidity ^0.8.10;

/**
 * @title IUniswapV2ForkFactory
 * @dev IUniswapV2ForkFactory contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function token0() external view returns (address);

    function token1() external view returns (address);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);
}

pragma solidity ^0.8.10;

/**
 * @title IOracle
 * @dev IOracle contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IOracle {
    function initialize(address _kpiToken, bytes calldata _data) external;
}

pragma solidity ^0.8.10;

/**
 * @title IERC20Decimals
 * @dev IERC20Decimals contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.10;

import "../../commons/Types.sol";

/**
 * @title IKPIToken
 * @dev IKPIToken contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IKPIToken {
    function initialize(
        address _creator,
        Collateral[] calldata _collaterals,
        Oracle[] calldata _oracles,
        bool _andRelationship,
        bytes calldata _data
    ) external;

    function finalize(uint256 _result) external;

    function redeem() external;

    function finalized() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

pragma solidity >=0.8.9;

/**
 * @title IMaster
 * @dev IMaster contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IMaster {
    function setBonder(address _bonder) external;

    function setJobsRegistry(address _jobsRegistry) external;

    function setWorkEvaluator(address _workEvaluator) external;

    function bonder() external returns (address);

    function jobsRegistry() external returns (address);

    function workEvaluator() external returns (address);

    function initializeWork(address _worker) external;

    function initializeWorkWithRequirements(
        address _worker,
        uint256 _minimumBonded,
        uint256 _minimumEarned,
        uint256 _minimumAge
    ) external;

    function finalizeWork(address _worker) external;

    function finalizeWork(
        address _worker,
        address _rewardToken,
        uint256 _amount
    ) external;
}

pragma solidity >=0.8.9;

/**
 * @title IJob
 * @dev IJob contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IJob {
    function workable(bytes memory _data)
        external
        view
        returns (bool, bytes memory);

    function work(bytes memory _data) external;
}

pragma solidity ^0.8.10;

/**
 * @title Common types
 * @dev Common types
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

struct Collateral {
    address token;
    uint256 amount;
}

struct Oracle {
    address addrezz;
    uint256 lowerBound;
    uint256 higherBound;
    uint256 weight;
}

struct OracleCreationData {
    address template;
    bytes initializationData;
    uint256 jobFunding;
}

struct KpiTokenCreationOracle {
    address template;
    uint256 lowerBound;
    uint256 higherBound;
    uint256 jobFunding;
    uint256 weight;
    bytes initializationData;
}

struct FinalizableOracle {
    uint256 lowerBound;
    uint256 higherBound;
    uint256 finalProgress;
    uint256 weight;
    bool finalized;
}

struct Template {
    string description;
    bool exists;
}