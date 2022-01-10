// SPDX-License-Identifier: MPL-2.0
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interface/IDevBridge.sol";
import "../../interface/IWithdraw.sol";
import "../../interface/ILockup.sol";
import "../../interface/IMetricsFactory.sol";
import "../../interface/IPropertyFactory.sol";
import "../common/libs/Decimals.sol";
import "../common/registry/InitializableUsingRegistry.sol";

/**
 * A contract that manages the withdrawal of holder rewards for Property holders.
 */
contract Withdraw is InitializableUsingRegistry, IWithdraw {
	mapping(address => mapping(address => uint256))
		public lastWithdrawnRewardPrice; // {Property: {User: Value}} // From [get/set]StorageLastWithdrawnReward
	mapping(address => mapping(address => uint256))
		public lastWithdrawnRewardCapPrice; // {Property: {User: Value}} // From [get/set]PendingWithdrawal
	mapping(address => mapping(address => uint256)) public pendingWithdrawal; // {Property: {User: Value}}
	mapping(address => uint256) public cumulativeWithdrawnReward; // {Property: Value} // From [get/set]RewardsAmount

	using Decimals for uint256;

	/**
	 * Initialize the passed address as AddressRegistry address.
	 */
	function initialize(address _registry) external initializer {
		__UsingRegistry_init(_registry);
	}

	/**
	 * Withdraws rewards.
	 */
	function withdraw(address _property) external override {
		/**
		 * Validate
		 * the passed Property address is included the Property address set.
		 */
		require(
			IPropertyFactory(registry().registries("PropertyFactory"))
				.isProperty(_property),
			"this is illegal address"
		);

		/**
		 * Gets the withdrawable rewards amount and the latest cumulative sum of the maximum mint amount.
		 */
		(
			uint256 value,
			uint256 lastPrice,
			uint256 lastPriceCap,

		) = _calculateWithdrawableAmount(_property, msg.sender);

		/**
		 * Validates the result is not 0.
		 */
		require(value != 0, "withdraw value is 0");

		/**
		 * Saves the latest cumulative sum of the holder reward price.
		 * By subtracting this value when calculating the next rewards, always withdrawal the difference from the previous time.
		 */
		lastWithdrawnRewardPrice[_property][msg.sender] = lastPrice;
		lastWithdrawnRewardCapPrice[_property][msg.sender] = lastPriceCap;

		/**
		 * Sets the number of unwithdrawn rewards to 0.
		 */
		pendingWithdrawal[_property][msg.sender] = 0;

		/**
		 * Mints the holder reward.
		 */
		require(
			IDevBridge(registry().registries("DevBridge")).mint(
				msg.sender,
				value
			),
			"dev mint failed"
		);

		/**
		 * Since the total supply of tokens has changed, updates the latest maximum mint amount.
		 */
		ILockup lockup = ILockup(registry().registries("Lockup"));
		lockup.update();

		/**
		 * Adds the reward amount already withdrawn in the passed Property.
		 */
		cumulativeWithdrawnReward[_property] =
			cumulativeWithdrawnReward[_property] +
			value;
	}

	/**
	 * Updates the change in compensation amount due to the change in the ownership ratio of the passed Property.
	 * When the ownership ratio of Property changes, the reward that the Property holder can withdraw will change.
	 * It is necessary to update the status before and after the ownership ratio changes.
	 */
	function beforeBalanceChange(address _from, address _to) external override {
		/**
		 * Validates the sender is Allocator contract.
		 */
		require(
			IPropertyFactory(registry().registries("PropertyFactory"))
				.isProperty(msg.sender),
			"this is illegal address"
		);

		/**
		 * Gets the cumulative sum of the transfer source's "before transfer" withdrawable reward amount and the cumulative sum of the maximum mint amount.
		 */
		(
			uint256 amountFrom,
			uint256 priceFrom,
			uint256 priceCapFrom,

		) = _calculateAmount(msg.sender, _from);

		/**
		 * Gets the cumulative sum of the transfer destination's "before receive" withdrawable reward amount and the cumulative sum of the maximum mint amount.
		 */
		(
			uint256 amountTo,
			uint256 priceTo,
			uint256 priceCapTo,

		) = _calculateAmount(msg.sender, _to);

		/**
		 * Updates the last cumulative sum of the maximum mint amount of the transfer source and destination.
		 */
		lastWithdrawnRewardPrice[msg.sender][_from] = priceFrom;
		lastWithdrawnRewardPrice[msg.sender][_to] = priceTo;
		lastWithdrawnRewardCapPrice[msg.sender][_from] = priceCapFrom;
		lastWithdrawnRewardCapPrice[msg.sender][_to] = priceCapTo;

		/**
		 * Gets the unwithdrawn reward amount of the transfer source and destination.
		 */
		uint256 pendFrom = pendingWithdrawal[msg.sender][_from];
		uint256 pendTo = pendingWithdrawal[msg.sender][_to];

		/**
		 * Adds the undrawn reward amount of the transfer source and destination.
		 */
		pendingWithdrawal[msg.sender][_from] = pendFrom + amountFrom;
		pendingWithdrawal[msg.sender][_to] = pendTo + amountTo;
	}

	/**
	 * Returns the holder reward.
	 */
	function _calculateAmount(address _property, address _user)
		private
		view
		returns (
			uint256 _amount,
			uint256 _price,
			uint256 _cap,
			uint256 _allReward
		)
	{
		ILockup lockup = ILockup(registry().registries("Lockup"));
		/**
		 * Gets the latest reward.
		 */
		(uint256 reward, uint256 cap) = lockup.calculateRewardAmount(_property);

		/**
		 * Gets the cumulative sum of the holder reward price recorded the last time you withdrew.
		 */

		uint256 allReward = _calculateAllReward(_property, _user, reward);
		uint256 capped = _calculateCapped(_property, _user, cap);
		uint256 value = capped == 0 ? allReward : allReward <= capped
			? allReward
			: capped;

		/**
		 * Returns the result after adjusted decimals to 10^18, and the latest cumulative sum of the holder reward price.
		 */
		return (value, reward, cap, allReward);
	}

	/**
	 * Return the reward cap
	 */
	function _calculateCapped(
		address _property,
		address _user,
		uint256 _cap
	) private view returns (uint256) {
		/**
		 * Gets the cumulative sum of the holder reward price recorded the last time you withdrew.
		 */
		uint256 _lastRewardCap = lastWithdrawnRewardCapPrice[_property][_user];
		IERC20 property = IERC20(_property);
		uint256 balance = property.balanceOf(_user);
		uint256 totalSupply = property.totalSupply();
		uint256 unitPriceCap = (_cap - _lastRewardCap) / totalSupply;
		return (unitPriceCap * balance).divBasis();
	}

	/**
	 * Return the reward
	 */
	function _calculateAllReward(
		address _property,
		address _user,
		uint256 _reward
	) private view returns (uint256) {
		/**
		 * Gets the cumulative sum of the holder reward price recorded the last time you withdrew.
		 */
		uint256 _lastReward = lastWithdrawnRewardPrice[_property][_user];
		IERC20 property = IERC20(_property);
		uint256 balance = property.balanceOf(_user);
		uint256 totalSupply = property.totalSupply();
		uint256 unitPrice = ((_reward - _lastReward).mulBasis()) / totalSupply;
		return (unitPrice * balance).divBasis().divBasis();
	}

	/**
	 * Returns the total rewards currently available for withdrawal. (For calling from inside the contract)
	 */
	function _calculateWithdrawableAmount(address _property, address _user)
		private
		view
		returns (
			uint256 _amount,
			uint256 _price,
			uint256 _cap,
			uint256 _allReward
		)
	{
		/**
		 * Gets the latest withdrawal reward amount.
		 */
		(
			uint256 _value,
			uint256 price,
			uint256 cap,
			uint256 allReward
		) = _calculateAmount(_property, _user);

		/**
		 * If the passed Property has not authenticated, returns always 0.
		 */
		if (
			IMetricsFactory(registry().registries("MetricsFactory")).hasAssets(
				_property
			) == false
		) {
			return (0, price, cap, 0);
		}

		/**
		 * Gets the reward amount in saved without withdrawal and returns the sum of all values.
		 */
		uint256 value = _value + pendingWithdrawal[_property][_user];
		return (value, price, cap, allReward);
	}

	/**
	 * Returns the rewards amount
	 */
	function calculateRewardAmount(address _property, address _user)
		external
		view
		override
		returns (
			uint256 _amount,
			uint256 _price,
			uint256 _cap,
			uint256 _allReward
		)
	{
		return _calculateWithdrawableAmount(_property, _user);
	}
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity =0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../../interface/IAddressRegistry.sol";

/**
 * Module for using AddressRegistry contracts.
 */
abstract contract InitializableUsingRegistry is Initializable {
	address private _registry;

	/**
	 * Initialize the argument as AddressRegistry address.
	 */
	/* solhint-disable func-name-mixedcase */
	function __UsingRegistry_init(address _addressRegistry)
		internal
		initializer
	{
		_registry = _addressRegistry;
	}

	/**
	 * Returns the latest AddressRegistry instance.
	 */
	function registry() internal view returns (IAddressRegistry) {
		return IAddressRegistry(_registry);
	}

	/**
	 * Returns the AddressRegistry address.
	 */
	function registryAddress() external view returns (address) {
		return _registry;
	}
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity =0.8.9;

/**
 * Library for emulating calculations involving decimals.
 */
library Decimals {
	uint120 private constant BASIS_VALUE = 1000000000000000000;

	/**
	 * @dev Returns the ratio of the first argument to the second argument.
	 * @param _a Numerator.
	 * @param _b Fraction.
	 * @return result Calculated ratio.
	 */
	function outOf(uint256 _a, uint256 _b)
		internal
		pure
		returns (uint256 result)
	{
		if (_a == 0) {
			return 0;
		}
		uint256 a = _a * BASIS_VALUE;
		if (a < _b) {
			return 0;
		}
		return a / _b;
	}

	/**
	 * @dev Returns multiplied the number by 10^18.
	 * @param _a Numerical value to be multiplied.
	 * @return Multiplied value.
	 */
	function mulBasis(uint256 _a) internal pure returns (uint256) {
		return _a * BASIS_VALUE;
	}

	/**
	 * @dev Returns divisioned the number by 10^18.
	 * This function can use it to restore the number of digits in the result of `outOf`.
	 * @param _a Numerical value to be divisioned.
	 * @return Divisioned value.
	 */
	function divBasis(uint256 _a) internal pure returns (uint256) {
		return _a / BASIS_VALUE;
	}
}

// SPDX-License-Identifier: MPL-2.0
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

interface IWithdraw {
	function withdraw(address _property) external;

	function beforeBalanceChange(address _from, address _to) external;

	function calculateRewardAmount(address _property, address _user)
		external
		view
		returns (
			uint256 _amount,
			uint256 _price,
			uint256 _cap,
			uint256 _allReward
		);
}

// SPDX-License-Identifier: MPL-2.0
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

interface IPropertyFactory {
	event Create(address indexed _from, address _property);

	function create(
		string memory _name,
		string memory _symbol,
		address _author
	) external returns (address);

	function createAndAuthenticate(
		string memory _name,
		string memory _symbol,
		address _market,
		string[] memory _args
	) external returns (bool);

	function isProperty(address _addr) external view returns (bool);
}

// SPDX-License-Identifier: MPL-2.0
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

interface IMetricsFactory {
	event Create(
		address indexed _market,
		address indexed _property,
		address _metrics
	);
	event Destroy(
		address indexed _market,
		address indexed _property,
		address _metrics
	);

	function create(address _property) external returns (address);

	function destroy(address _metrics) external;

	function isMetrics(address _addr) external view returns (bool);

	function metricsCount() external view returns (uint256);

	function metricsCountPerProperty(address _addr)
		external
		view
		returns (uint256);

	function metricsOfProperty(address _property)
		external
		view
		returns (address[] memory);

	function hasAssets(address _property) external view returns (bool);

	function authenticatedPropertiesCount() external view returns (uint256);
}

// SPDX-License-Identifier: MPL-2.0
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

interface ILockup {
	struct RewardPrices {
		uint256 reward;
		uint256 holders;
		uint256 interest;
		uint256 holdersCap;
	}

	struct LockedupProperty {
		address property;
		uint256 value;
	}

	event Lockedup(
		address indexed _from,
		address indexed _property,
		uint256 _value,
		uint256 _tokenId
	);
	event Withdrew(
		address indexed _from,
		address indexed _property,
		uint256 _value,
		uint256 _reward,
		uint256 _tokenId
	);

	event UpdateCap(uint256 _cap);

	function depositToProperty(address _property, uint256 _amount)
		external
		returns (uint256);

	function depositToPosition(uint256 _tokenId, uint256 _amount)
		external
		returns (bool);

	function getLockedupProperties()
		external
		view
		returns (LockedupProperty[] memory);

	function update() external;

	function withdrawByPosition(uint256 _tokenId, uint256 _amount)
		external
		returns (bool);

	function calculateCumulativeRewardPrices()
		external
		view
		returns (
			uint256 _reward,
			uint256 _holders,
			uint256 _interest,
			uint256 _holdersCap
		);

	function calculateRewardAmount(address _property)
		external
		view
		returns (uint256, uint256);

	function totalLockedForProperty(address _property)
		external
		view
		returns (uint256);

	function totalLocked() external view returns (uint256);

	function calculateWithdrawableInterestAmountByPosition(uint256 _tokenId)
		external
		view
		returns (uint256);

	function cap() external view returns (uint256);

	function updateCap(uint256 _cap) external;
}

// SPDX-License-Identifier: MPL-2.0
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

interface IDevBridge {
	function mint(address _account, uint256 _amount) external returns (bool);

	function burn(address _account, uint256 _amount) external returns (bool);

	function renounceMinter() external;

	function renounceBurner() external;
}

// SPDX-License-Identifier: MPL-2.0
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

interface IAddressRegistry {
	function setRegistry(string memory _key, address _addr) external;

	function registries(string memory _key) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: MIT

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