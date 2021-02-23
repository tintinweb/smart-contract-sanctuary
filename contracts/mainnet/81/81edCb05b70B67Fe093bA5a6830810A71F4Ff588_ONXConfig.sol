// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
import "./libraries/SafeMath.sol";
import "./modules/ConfigNames.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

interface IERC20 {
	function balanceOf(address owner) external view returns (uint256);

	function decimals() external view returns (uint8);
}

interface IONXPool {
	function collateralToken() external view returns (address);
}

interface IAETH {
	function ratio() external view returns (uint256);
}

contract ONXConfig is Initializable {
	using SafeMath for uint256;
	using SafeMath for uint8;
	address public owner;
	address public platform;
	address public factory;
	address public token;
	address public WETH;
	uint256 public lastPriceBlock;
	uint256 public DAY = 6400;
	uint256 public HOUR = 267;

	struct ConfigItem {
			uint min;
			uint max;
			uint value;
	}
	
	mapping (address => mapping (bytes32 => ConfigItem)) public poolParams;
	mapping (bytes32 => ConfigItem) public params;
	mapping(bytes32 => address) public wallets;
	mapping(address => uint256) public prices;
	event PriceChange(address token, uint256 value);
	event ParameterChange(bytes32 key, uint256 value);
	event PoolParameterChange(bytes32 key, uint256 value);

	constructor() public {
		owner = msg.sender;
		uint256 id;
		assembly {
			id := chainid()
		}
		if (id != 1) {
			DAY = 28800;
			HOUR = 1200;
		}
	}

	function initialize(
		address _platform,
		address _factory,
		address _token,
		address _WETH
	) external initializer {
		require(msg.sender == owner, "ONX: Config FORBIDDEN");
		platform = _platform;
		factory = _factory;
		token = _token;
		WETH = _WETH;

		initParameter();
	}

	function setWallets(bytes32[] calldata _names, address[] calldata _wallets) external {
		require(msg.sender == owner, "ONX: ONLY ONWER");
		require(_names.length == _wallets.length, "ONX: WALLETS LENGTH MISMATCH");
		for (uint256 i = 0; i < _names.length; i++) {
			wallets[_names[i]] = _wallets[i];
		}
	}

	function initParameter() internal {
			require(msg.sender == owner, "ONX: Config FORBIDDEN");
			_setParams(ConfigNames.STAKE_LOCK_TIME, 0, 7 * DAY, 0);
			_setParams(ConfigNames.CHANGE_PRICE_DURATION, 0, 500, 0);
			_setParams(ConfigNames.CHANGE_PRICE_PERCENT, 1, 100, 20);
			_setParams(ConfigNames.DEPOSIT_ENABLE, 0, 1, 1);
			_setParams(ConfigNames.WITHDRAW_ENABLE, 0, 1, 1);
			_setParams(ConfigNames.BORROW_ENABLE, 0, 1, 1);
			_setParams(ConfigNames.REPAY_ENABLE, 0, 1, 1);
			_setParams(ConfigNames.LIQUIDATION_ENABLE, 0, 1, 1);
			_setParams(ConfigNames.REINVEST_ENABLE, 0, 1, 1);
			_setParams(ConfigNames.POOL_REWARD_RATE, 0, 1e18, 5e16);
			_setParams(ConfigNames.POOL_ARBITRARY_RATE, 0, 1e18, 9e16);
	}

	function initPoolParams(address _pool) external {
			require(msg.sender == factory, "Config FORBIDDEN");
			_setPoolParams(_pool, ConfigNames.POOL_BASE_INTERESTS, 0, 1e18, 2e17);	
			_setPoolParams(_pool, ConfigNames.POOL_MARKET_FRENZY, 0, 1e18, 2e17);	
			_setPoolParams(_pool, ConfigNames.POOL_PLEDGE_RATE, 0, 1e18, 75e16);	
			_setPoolParams(_pool, ConfigNames.POOL_LIQUIDATION_RATE, 0, 1e18, 9e17);	
			_setPoolParams(_pool, ConfigNames.POOL_MINT_POWER, 0, 100000, 10000);	
			_setPoolParams(_pool, ConfigNames.POOL_MINT_BORROW_PERCENT, 0, 10000, 5000);
	}

	function _setPoolValue(address _pool, bytes32 _key, uint256 _value) internal {
		poolParams[_pool][_key].value = _value;
		emit PoolParameterChange(_key, _value);
	}

	function _setParams(bytes32 _key, uint _min, uint _max, uint _value) internal {
		params[_key] = ConfigItem(_min, _max, _value);
		emit ParameterChange(_key, _value);
	}

	function _setPoolParams(address _pool, bytes32 _key, uint _min, uint _max, uint _value) internal {
		poolParams[_pool][_key] = ConfigItem(_min, _max, _value);
		emit PoolParameterChange(_key, _value);
	}

	function _setPrice(address _token, uint256 _value) internal {
		prices[_token] = _value;
		emit PriceChange(_token, _value);
	}

	function setTokenPrice(address[] calldata _tokens, uint256[] calldata _prices) external {
		uint256 duration = params[ConfigNames.CHANGE_PRICE_DURATION].value;
		uint256 maxPercent = params[ConfigNames.CHANGE_PRICE_PERCENT].value;
		require(block.number >= lastPriceBlock.add(duration), "ONX: Price Duration");
		require(msg.sender == wallets[bytes32("price")], "ONX: Config FORBIDDEN");
		require(_tokens.length == _prices.length, "ONX: PRICES LENGTH MISMATCH");
		for (uint256 i = 0; i < _tokens.length; i++) {
			if (prices[_tokens[i]] == 0) {
				_setPrice(_tokens[i], _prices[i]);
			} else {
				uint256 currentPrice = prices[_tokens[i]];
				if (_prices[i] > currentPrice) {
					uint256 maxPrice = currentPrice.add(currentPrice.mul(maxPercent).div(10000));
					_setPrice(_tokens[i], _prices[i] > maxPrice ? maxPrice : _prices[i]);
				} else {
					uint256 minPrice = currentPrice.sub(currentPrice.mul(maxPercent).div(10000));
					_setPrice(_tokens[i], _prices[i] < minPrice ? minPrice : _prices[i]);
				}
			}
		}

		lastPriceBlock = block.number;
	}

	function setValue(bytes32 _key, uint256 _value) external {
		require(
			msg.sender == owner,
			"ONX: ONLY OWNER"
		);
		require(
			_value <= params[_key].max && params[_key].min <= _value,
			"ONX: EXCEEDED RANGE"
		);
		params[_key].value = _value;
		emit ParameterChange(_key, _value);
	}

	function setPoolValue(address _pool, bytes32 _key, uint256 _value) external {
		require(
			msg.sender == owner || msg.sender == platform,
			"ONX: FORBIDDEN"
		);
		require(
			_value <= params[_key].max && params[_key].min <= _value,
			"ONX: EXCEEDED RANGE"
		);
		_setPoolValue(_pool, _key, _value);
	}

	function getValue(bytes32 _key) external view returns (uint256) {
		return params[_key].value;
	}

	function getPoolValue(address _pool, bytes32 _key) external view returns (uint256) {
		return poolParams[_pool][_key].value;
	}

	function setParams(bytes32 _key, uint _min, uint _max, uint _value) external {
			require(msg.sender == owner || msg.sender == platform, "ONX: FORBIDDEN");
			_setParams(_key, _min, _max, _value);
	}

	function setPoolParams(address _pool, bytes32 _key, uint _min, uint _max, uint _value) external {
			require(msg.sender == owner || msg.sender == platform, "ONX: FORBIDDEN");
			_setPoolParams(_pool, _key, _min, _max, _value);
	}

	function getParams(bytes32 _key)
		external
		view
		returns (
			uint256,
			uint256,
			uint256
		)
	{
		ConfigItem memory item = params[_key];
		return (item.min, item.max, item.value);
	}

	function getPoolParams(address _pool, bytes32 _key)
		external
		view
		returns (
			uint256,
			uint256,
			uint256
		)
	{
		ConfigItem memory item = poolParams[_pool][_key];
		return (item.min, item.max, item.value);
	}

	function convertTokenAmount(
		address _fromToken,			////// usually collateral token
		address _toToken,			////// usually lend token
		uint256 _fromAmount
	) external view returns (uint256 toAmount) {
		// use original price calculation on other token
		// use ratio for aETH
		if (address(WETH) == address(_toToken)) {
			toAmount = _fromAmount.mul(1e18).div(IAETH(_fromToken).ratio());
		} else {
			uint256 fromPrice = prices[_fromToken];
			uint256 toPrice = prices[_toToken];
			uint8 fromDecimals = IERC20(_fromToken).decimals();
			uint8 toDecimals = IERC20(_toToken).decimals();
			toAmount = _fromAmount.mul(fromPrice).div(toPrice);
			if (fromDecimals > toDecimals) {
				toAmount = toAmount.div(10**(fromDecimals.sub(toDecimals)));
			} else if (toDecimals > fromDecimals) {
				toAmount = toAmount.mul(10**(toDecimals.sub(fromDecimals)));
			}
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

library SafeMath {
	/**
	 * @dev Returns the addition of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `+` operator.
	 *
	 * Requirements:
	 *
	 * - Addition cannot overflow.
	 */
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting on
	 * overflow (when the result is negative).
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
	 * overflow (when the result is negative).
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;
		return c;
	}

	/**
	 * @dev Returns the multiplication of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `*` operator.
	 *
	 * Requirements:
	 *
	 * - Multiplication cannot overflow.
	 */
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");
		return c;
	}

	/**
	 * @dev Returns the integer division of two unsigned integers. Reverts on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	/**
	 * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function div(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * Reverts when dividing by zero.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * Reverts with custom message when dividing by zero.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function mod(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

library ConfigNames {
	//GOVERNANCE
	bytes32 public constant STAKE_LOCK_TIME = bytes32("STAKE_LOCK_TIME");
	bytes32 public constant CHANGE_PRICE_DURATION = bytes32("CHANGE_PRICE_DURATION");
	bytes32 public constant CHANGE_PRICE_PERCENT = bytes32("CHANGE_PRICE_PERCENT"); // POOL
	bytes32 public constant POOL_BASE_INTERESTS = bytes32("POOL_BASE_INTERESTS");
	bytes32 public constant POOL_MARKET_FRENZY = bytes32("POOL_MARKET_FRENZY");
	bytes32 public constant POOL_PLEDGE_RATE = bytes32("POOL_PLEDGE_RATE");
	bytes32 public constant POOL_LIQUIDATION_RATE = bytes32("POOL_LIQUIDATION_RATE");
	bytes32 public constant POOL_MINT_BORROW_PERCENT = bytes32("POOL_MINT_BORROW_PERCENT");
	bytes32 public constant POOL_MINT_POWER = bytes32("POOL_MINT_POWER");
	bytes32 public constant POOL_REWARD_RATE = bytes32("POOL_REWARD_RATE");
	bytes32 public constant POOL_ARBITRARY_RATE = bytes32("POOL_ARBITRARY_RATE");

	//NOT GOVERNANCE
	bytes32 public constant DEPOSIT_ENABLE = bytes32("DEPOSIT_ENABLE");
	bytes32 public constant WITHDRAW_ENABLE = bytes32("WITHDRAW_ENABLE");
	bytes32 public constant BORROW_ENABLE = bytes32("BORROW_ENABLE");
	bytes32 public constant REPAY_ENABLE = bytes32("REPAY_ENABLE");
	bytes32 public constant LIQUIDATION_ENABLE = bytes32("LIQUIDATION_ENABLE");
	bytes32 public constant REINVEST_ENABLE = bytes32("REINVEST_ENABLE");
	bytes32 public constant POOL_PRICE = bytes32("POOL_PRICE"); //wallet
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}