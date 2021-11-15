pragma solidity ^0.8.4;

import "../libraries/FixedPoint.sol";
import "../libraries/UniswapV2ForkOracleLibrary.sol";
import "../interfaces/IUniswapV2ForkPair.sol";
import "../interfaces/IUniswapV2ForkFactory.sol";
import "../interfaces/IOracle.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

/**
 * @title UniswapV2ForkPairLiquidityOracle
 * @dev UniswapV2ForkPairLiquidityOracle contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
contract UniswapV2ForkPairLiquidityOracle is
    IOracle,
    Initializable,
    KeeperCompatibleInterface
{
    using FixedPoint for *;

    struct Observation {
        uint256 cumulativeLiquidity;
        uint256 readingsAmount;
    }

    struct ObservedPair {
        address addrezz;
        address token0;
        address token1;
    }

    struct QuotePair {
        address addrezz;
        address token0;
        address token1;
    }

    struct Oracle {
        ObservedPair observedPair;
        QuotePair quotePair;
        address quoteToken;
        uint256 initializationTimestamp;
        uint256 finalizationTimestamp;
        uint256 refreshInterval;
        uint256 lastUpdateTimestamp;
        uint256 lastCumulativePrice;
        Observation observation;
    }

    Oracle public oracle;
    address public link;

    function validateInitialization(bytes calldata _validationData)
        external
        override
        initializationValidator
        returns (bytes memory)
    {
        (
            address _factory,
            address _observedPairTokenA,
            address _observedPairTokenB,
            uint256 _initializationTimestamp,
            uint256 _refreshInterval,
            uint256 _duration,
            address _quotePairFactory,
            address _quotePair,
            address _quoteToken
        ) =
            abi.decode(
                _validationData,
                (
                    address,
                    address,
                    address,
                    uint256,
                    uint256,
                    uint256,
                    address,
                    address,
                    address
                )
            );

        if (_factory == address(0)) revert(); // TODO: add custom error
        if (_initializationTimestamp < block.timestamp) revert(); // TODO: add custom error
        if (_duration < 4 hours) revert(); // TODO: add custom error
        if (_refreshInterval > _duration / 2) revert(); // TODO: add custom error
        if (_quotePairFactory == address(0)) revert(); // TODO: add custom error
        if (_quotePair == address(0)) revert(); // TODO: add custom error
        if (_quoteToken == address(0)) revert(); // TODO: add custom error

        (address _observedPairToken0, address _observedPairToken1) =
            _observedPairTokenA < _observedPairTokenB
                ? (_observedPairTokenA, _observedPairTokenB)
                : (_observedPairTokenB, _observedPairTokenA);
        if (_observedPairToken0 == address(0)) revert(); // TODO: add custom error

        // check that the passed in quote pair contains both the quote token
        // and one out of the two token in the observed pair
        address _quotePairToken0 = IUniswapV2ForkPair(_quotePair).token0();
        address _quotePairToken1 = IUniswapV2ForkPair(_quotePair).token1();
        if (_quotePairToken0 != _quoteToken && _quotePairToken1 != _quoteToken)
            revert(); // TODO: add custom error
        if (
            _quotePairToken0 != _observedPairTokenA &&
            _quotePairToken1 != _observedPairTokenA &&
            _quotePairToken0 != _observedPairTokenB &&
            _quotePairToken1 != _observedPairTokenB
        ) revert(); // TODO: add custom error

        // check that the passed token pair was actually spawned by the passed factory
        if (
            _quotePair !=
            _getPairAddress(
                _quotePairFactory,
                IUniswapV2ForkFactory(_quotePairFactory).INIT_CODE_PAIR_HASH(),
                _quotePairToken0,
                _quotePairToken1
            )
        ) revert();

        return
            abi.encode(
                _getPairAddress(
                    _factory,
                    IUniswapV2ForkFactory(_factory).INIT_CODE_PAIR_HASH(),
                    _observedPairToken0,
                    _observedPairToken1
                ),
                _observedPairToken0,
                _observedPairToken1,
                _quotePair,
                _quotePairToken0,
                _quotePairToken1,
                _initializationTimestamp,
                _refreshInterval,
                _duration,
                _quoteToken
            );
    }

    function initialize(bytes calldata _initializationData)
        external
        override
        initializer
        onlyAllowedInitialization
    {
        (
            address _observedPair,
            address _observedPairToken0,
            address _observedPairToken1,
            address _quotePair,
            address _quotePairToken0,
            address _quotePairToken1,
            uint256 _initializationTimestamp,
            uint256 _refreshInterval,
            uint256 _duration,
            address _quoteToken
        ) =
            abi.decode(
                _initializationData,
                (
                    address,
                    address,
                    address,
                    address,
                    address,
                    address,
                    uint256,
                    uint256,
                    uint256,
                    address
                )
            );
        oracle = Oracle({
            observedPair: ObservedPair({
                addrezz: _observedPair,
                token0: _observedPairToken0,
                token1: _observedPairToken1
            }),
            quotePair: QuotePair({
                addrezz: _quotePair,
                token0: _quotePairToken0,
                token1: _quotePairToken1
            }),
            quoteToken: _quoteToken,
            initializationTimestamp: _initializationTimestamp,
            finalizationTimestamp: _initializationTimestamp + _duration,
            refreshInterval: _refreshInterval,
            lastUpdateTimestamp: 0,
            lastCumulativePrice: 0,
            observation: Observation({
                cumulativeLiquidity: 0,
                readingsAmount: 0
            })
        });
    }

    function initializeUpkeeping(
        address _link,
        address _chainlinkKeeperRegistrar,
        uint256 _linkFunding
    ) external override {
        LinkTokenInterface(_link).transferAndCall(
            _chainlinkKeeperRegistrar,
            _linkFunding,
            abi.encodeWithSelector(
                bytes4(0xc4110e5c),
                "Carrot keeper",
                keccak256("Carrot"),
                address(this),
                1000000,
                address(this),
                bytes(""),
                _linkFunding,
                0
            )
        );
    }

    function _getPairAddress(
        address _factory,
        bytes32 _pairInitCodeHash,
        address _token0,
        address _token1
    ) internal pure returns (address) {
        if (_token0 == address(0) || _token1 == address(0)) revert(); // TODO: add custom error
        return
            address(
                bytes20(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            _factory,
                            keccak256(abi.encodePacked(_token0, _token1)),
                            _pairInitCodeHash
                        )
                    )
                )
            );
    }

    function _isUpkeepRequired(Oracle memory _oracle)
        internal
        view
        returns (bool)
    {
        if (
            block.timestamp < _oracle.initializationTimestamp ||
            block.timestamp > _oracle.finalizationTimestamp
        ) return false;
        (, , uint32 _quotePairPricesTimestamp) =
            UniswapV2ForkOracleLibrary.currentCumulativePrices(
                /* oracle.quotePair.addrezz */
                address(0)
            );
        return
            _oracle.lastUpdateTimestamp == 0 ||
            _quotePairPricesTimestamp - _oracle.lastUpdateTimestamp >=
            _oracle.refreshInterval;
    }

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool, bytes memory)
    {
        Oracle memory _oracle = oracle;
        return (_isUpkeepRequired(_oracle), bytes(""));
    }

    function performUpkeep(bytes calldata) external override {
        if (!_isUpkeepRequired(oracle)) revert(); // TODO: add custom error

        (uint112 _observedPairReserve0, uint112 _observedPairReserve1, ) =
            IUniswapV2ForkPair(oracle.observedPair.addrezz).getReserves();
        (
            uint256 _quotePairPrice0Cumulative,
            uint256 _quotePairPrice1Cumulative,
            uint32 _quotePairPricesTimestamp
        ) =
            UniswapV2ForkOracleLibrary.currentCumulativePrices(
                oracle.quotePair.addrezz
            );

        uint256 _timeElapsed =
            _quotePairPricesTimestamp - oracle.lastUpdateTimestamp;

        // in the quote pair, determine which of the 2 tokens is the quote token,
        // and return both the other token's address and and price
        (address _pricedToken, uint256 _priceCumulative) =
            oracle.quotePair.token0 == oracle.quoteToken
                ? (oracle.quotePair.token1, _quotePairPrice1Cumulative)
                : (oracle.quotePair.token0, _quotePairPrice0Cumulative);

        // based on the previously fetched priced token, determine which of the
        // reserves to pick in the observed pair, to be multiplied by the
        // quote token price
        uint112 _reserve =
            oracle.observedPair.token0 == _pricedToken
                ? _observedPairReserve0
                : _observedPairReserve1;

        FixedPoint.uq112x112 memory _price;
        unchecked {
            _price = FixedPoint.uq112x112(
                uint224(
                    (_priceCumulative - oracle.lastCumulativePrice) /
                        _timeElapsed
                )
            );
        }

        oracle.lastCumulativePrice = _priceCumulative;
        oracle.lastUpdateTimestamp = _quotePairPricesTimestamp;
        // approximation: price * reserve is here multiplied by 2 to get full
        // reserve liquidity expressed in quote tokens. Keep in mind reserve
        // only represents half of the total reserves
        // FIXME: decode might be removing some important amount of precision, verify
        oracle.observation.cumulativeLiquidity += FixedPoint.decode144(
            _price.mul(_reserve * 2)
        );
        oracle.observation.readingsAmount++;
    }

    function isFinalized() external view override returns (bool) {
        return block.timestamp > oracle.finalizationTimestamp;
    }

    function result() external view override returns (uint256) {
        if (block.timestamp < oracle.finalizationTimestamp) revert(); // TODO: add custom error
        // return average
        return
            oracle.observation.cumulativeLiquidity /
            oracle.observation.readingsAmount;
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
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) =
            IUniswapV2ForkPair(pair).getReserves();
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

pragma solidity ^0.8.4;

/**
 * @title IUniswapV2ForkFactory
 * @dev IUniswapV2ForkFactory contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IUniswapV2ForkPair {
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

pragma solidity ^0.8.4;

/**
 * @title IUniswapV2ForkFactory
 * @dev IUniswapV2ForkFactory contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IUniswapV2ForkFactory {
    function INIT_CODE_PAIR_HASH() external pure returns (bytes32);
}

pragma solidity ^0.8.4;

/**
 * @title IOracle
 * @dev IOracle contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
abstract contract IOracle {
    bool initializationAllowed;

    function validateInitialization(bytes calldata _validationData)
        external
        virtual
        returns (bytes memory _initializationData);

    function initialize(bytes calldata _initializationData) external virtual;

    function initializeUpkeeping(
        address _chainlinkKeeperRegistrar,
        address _link,
        uint256 _amount
    ) external virtual;

    function isFinalized() external view virtual returns (bool);

    function result() external view virtual returns (uint256);

    modifier initializationValidator() {
        _;
        initializationAllowed = true;
    }

    modifier onlyAllowedInitialization() {
        if (!initializationAllowed) revert(); // TODO: add custom error
        _;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

