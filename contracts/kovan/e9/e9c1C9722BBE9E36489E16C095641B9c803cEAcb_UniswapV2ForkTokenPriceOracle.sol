pragma solidity ^0.8.4;

import "../libraries/FixedPoint.sol";
import "../libraries/UniswapV2ForkOracleLibrary.sol";
import "../interfaces/IUniswapV2ForkPair.sol";
import "../interfaces/IUniswapV2ForkFactory.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/IKPIToken.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

/**
 * @title UniswapV2ForkTokenPriceOracle
 * @dev UniswapV2ForkTokenPriceOracle contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
contract UniswapV2ForkTokenPriceOracle is
    IOracle,
    Initializable,
    KeeperCompatibleInterface
{
    using FixedPoint for *;

    struct Oracle {
        address pair;
        address token;
        bool token0; // whether the priced token is in position 0 or 1 in the given pair
        uint256 initializationTimestamp;
        uint256 finalizationTimestamp;
        uint256 refreshInterval;
        uint256 lastUpdateTimestamp;
        uint256 lastCumulativePrice;
        FixedPoint.uq112x112 price;
        uint256 readingsAmount;
    }

    Oracle public oracle;
    address public linkedKpiToken;

    function validateInitialization(bytes calldata _validationData)
        external
        override
        initializationValidator
        returns (bytes memory)
    {
        (
            address _pair,
            address _token,
            uint256 _initializationTimestamp,
            uint256 _refreshInterval,
            uint256 _duration
        ) =
            abi.decode(
                _validationData,
                (address, address, uint256, uint256, uint256)
            );

        if (_pair == address(0)) revert(); // TODO: add custom error
        if (_token == address(0)) revert(); // TODO: add custom error
        if (_initializationTimestamp < block.timestamp) revert(); // TODO: add custom error
        if (_duration < 4 hours) revert(); // TODO: add custom error
        if (_refreshInterval > _duration / 2) revert(); // TODO: add custom error

        // check that the passed in pair actually contains the token that needs to be priced
        address _token0 = IUniswapV2ForkPair(_pair).token0();
        address _token1 = IUniswapV2ForkPair(_pair).token1();
        if (_token0 != _token && _token1 != _token) revert(); // TODO: add custom error

        return
            abi.encode(
                _pair,
                _token,
                _token0 == _token,
                _initializationTimestamp,
                _refreshInterval,
                _duration
            );
    }

    function initialize(
        bytes calldata _initializationData,
        address _linkedKpiToken
    ) external override initializer onlyAllowedInitialization {
        (
            address _pair,
            address _token,
            bool _token0,
            uint256 _initializationTimestamp,
            uint256 _refreshInterval,
            uint256 _duration
        ) =
            abi.decode(
                _initializationData,
                (address, address, bool, uint256, uint256, uint256)
            );

        oracle = Oracle({
            pair: _pair,
            token: _token,
            token0: _token0,
            initializationTimestamp: _initializationTimestamp,
            finalizationTimestamp: _initializationTimestamp + _duration,
            refreshInterval: _refreshInterval,
            lastUpdateTimestamp: 0,
            lastCumulativePrice: 0,
            price: FixedPoint.uq112x112(0),
            readingsAmount: 0
        });
        linkedKpiToken = _linkedKpiToken;
    }

    function initializeUpkeeping(
        address _link,
        address _chainlinkKeeperRegistrar,
        uint256 _linkFunding
    ) external override {
        LinkTokenInterface(_link).transferAndCall(
            _chainlinkKeeperRegistrar,
            _linkFunding,
            abi.encodeWithSignature(
                "register(string,bytes,address,uint32,address,bytes,uint96,uint8)",
                "Carrot keeper",
                abi.encodePacked(keccak256("Carrot")),
                address(this),
                1000000,
                address(this),
                bytes(""),
                _linkFunding,
                0
            )
        );
    }

    function _isFinalizable(Oracle memory _oracle)
        internal
        view
        returns (bool)
    {
        return
            block.timestamp >= _oracle.finalizationTimestamp &&
            !IKPIToken(linkedKpiToken).isFinalized();
    }

    function _isUpkeepRequired(Oracle memory _oracle)
        internal
        view
        returns (bool)
    {
        if (block.timestamp < _oracle.initializationTimestamp) return false;
        if (_isFinalizable(_oracle)) return true;
        (, , uint32 _pairPricesTimestamp) =
            UniswapV2ForkOracleLibrary.currentCumulativePrices(_oracle.pair);
        return
            _oracle.lastUpdateTimestamp == 0 ||
            _pairPricesTimestamp - _oracle.lastUpdateTimestamp >=
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

        if (_isFinalizable(oracle)) {
            IKPIToken(linkedKpiToken).finalize(oracle.price.decode());
            return;
        }

        (
            uint256 _pairPrice0Cumulative,
            uint256 _pairPrice1Cumulative,
            uint32 _pairPricesTimestamp
        ) = UniswapV2ForkOracleLibrary.currentCumulativePrices(oracle.pair);
        uint256 _timeElapsed =
            _pairPricesTimestamp - oracle.lastUpdateTimestamp;
        uint256 _priceCumulative =
            oracle.token0 ? _pairPrice0Cumulative : _pairPrice1Cumulative;
        FixedPoint.uq112x112 memory _averagePrice;
        unchecked {
            _averagePrice = FixedPoint.uq112x112(
                uint224(
                    (_priceCumulative - oracle.lastCumulativePrice) /
                        _timeElapsed
                )
            );
        }

        oracle.lastCumulativePrice = _priceCumulative;
        oracle.lastUpdateTimestamp = _pairPricesTimestamp;
        // approximation: price * reserve is here multiplied by 2 to get full
        // reserve liquidity expressed in quote tokens. Keep in mind reserve
        // only represents half of the total reserves
        // FIXME: decode might be removing some important amount of precision, verify
        oracle.price = _averagePrice;
        oracle.readingsAmount++;
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

    function initialize(
        bytes calldata _initializationData,
        address _linkedKpiToken
    ) external virtual;

    function initializeUpkeeping(
        address _chainlinkKeeperRegistrar,
        address _link,
        uint256 _amount
    ) external virtual;

    modifier initializationValidator() {
        _;
        initializationAllowed = true;
    }

    modifier onlyAllowedInitialization() {
        if (!initializationAllowed) revert(); // TODO: add custom error
        _;
    }
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title IKPIToken
 * @dev IKPIToken contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IKPIToken is IERC20Upgradeable {
    struct Collateral {
        address token;
        uint256 amount;
    }

    struct TokenData {
        string name;
        string symbol;
        uint256 totalSupply;
    }

    struct ScalarData {
        uint256 lowerBound;
        uint256 higherBound;
    }

    function initialize(
        address _oracle,
        address _creator,
        Collateral calldata _collateral,
        TokenData calldata _tokenData,
        ScalarData calldata _scalarData
    ) external;

    function finalize(uint256 _result) external;

    function redeem() external;

    function isFinalized() external view returns (bool);
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

// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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