pragma solidity 0.5.17;

import {Ownable} from "@openzeppelin/contracts/ownership/Ownable.sol";
import "../common/config/UsingConfig.sol";
import "../market/Market.sol";
import "../../interface/IMarket.sol";
import "../../interface/IMarketFactory.sol";
import "../../interface/IMarketGroup.sol";

/**
 * A factory contract that creates a new Market contract.
 */
contract MarketFactory is Ownable, IMarketFactory, UsingConfig {
	event Create(address indexed _from, address _market);

	/**
	 * Initialize the passed address as AddressConfig address.
	 */
	constructor(address _config) public UsingConfig(_config) {}

	/**
	 * Creates a new Market contract.
	 */
	function create(address _addr) external returns (address) {
		/**
		 * Validates the passed address is not 0 address.
		 */
		require(_addr != address(0), "this is illegal address");

		/**
		 * Creates a new Market contract with the passed address as the IMarketBehavior.
		 */
		Market market = new Market(address(config()), _addr);

		/**
		 * Adds the created Market contract to the Market address set.
		 */
		address marketAddr = address(market);
		IMarketGroup marketGroup = IMarketGroup(config().marketGroup());
		marketGroup.addGroup(marketAddr);

		/**
		 * For the first Market contract, it will be activated immediately.
		 * If not, the Market contract will be activated after a vote by the voters.
		 */
		if (marketGroup.getCount() == 1) {
			market.toEnable();
		}

		emit Create(msg.sender, marketAddr);
		return marketAddr;
	}

	/**
	 * Creates a new Market contract.
	 */
	function enable(address _addr) external onlyOwner {
		/**
		 * Validates the passed address is not 0 address.
		 */
		IMarketGroup marketGroup = IMarketGroup(config().marketGroup());
		require(marketGroup.isGroup(_addr), "illegal address");

		/**
		 * Market will be enable.
		 */
		IMarket market = IMarket(_addr);
		require(market.enabled() == false, "already enabled");

		market.toEnable();
	}

	/**
	 * Creates a new Market contract.
	 */
	function disable(address _addr) external onlyOwner {
		/**
		 * Validates the passed address is not 0 address.
		 */
		IMarketGroup marketGroup = IMarketGroup(config().marketGroup());
		require(marketGroup.isGroup(_addr), "illegal address");

		/**
		 * Market will be enable.
		 */
		IMarket market = IMarket(_addr);
		require(market.enabled() == true, "already disabled");

		market.toDisable();
		marketGroup.deleteGroup(_addr);
	}
}

pragma solidity 0.5.17;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import "../common/config/UsingConfig.sol";
import "../../interface/IProperty.sol";
import "../../interface/IMarket.sol";
import "../../interface/IMarketBehavior.sol";
import "../../interface/IPolicy.sol";
import "../../interface/IMetrics.sol";
import "../../interface/IMetricsFactory.sol";
import "../../interface/IMetricsGroup.sol";
import "../../interface/ILockup.sol";
import "../../interface/IDev.sol";

/**
 * A user-proposable contract for authenticating and associating assets with Property.
 * A user deploys a contract that inherits IMarketBehavior and creates this Market contract with the MarketFactory contract.
 */
contract Market is UsingConfig, IMarket {
	using SafeMath for uint256;
	bool public enabled;
	address public behavior;
	uint256 public votingEndBlockNumber;
	uint256 public issuedMetrics;
	mapping(bytes32 => bool) private idMap;
	mapping(address => bytes32) private idHashMetricsMap;

	/**
	 * Initialize the passed address as AddressConfig address and user-proposed contract.
	 */
	constructor(address _config, address _behavior)
		public
		UsingConfig(_config)
	{
		/**
		 * Validates the sender is MarketFactory contract.
		 */
		require(
			msg.sender == config().marketFactory(),
			"this is illegal address"
		);

		/**
		 * Stores the contract address proposed by a user as an internal variable.
		 */
		behavior = _behavior;

		/**
		 * By default this contract is disabled.
		 */
		enabled = false;

		/**
		 * Sets the period during which voting by voters can be accepted.
		 * This period is determined by `Policy.marketVotingBlocks`.
		 */
		uint256 marketVotingBlocks = IPolicy(config().policy())
			.marketVotingBlocks();
		votingEndBlockNumber = block.number.add(marketVotingBlocks);
	}

	/**
	 * Validates the sender is the passed Property's author.
	 */
	function propertyValidation(address _prop) private view {
		require(
			msg.sender == IProperty(_prop).author(),
			"this is illegal address"
		);
		require(enabled, "market is not enabled");
	}

	/**
	 * Modifier for validates the sender is the passed Property's author.
	 */
	modifier onlyPropertyAuthor(address _prop) {
		propertyValidation(_prop);
		_;
	}

	/**
	 * Modifier for validates the sender is the author of the Property associated with the passed Metrics contract.
	 */
	modifier onlyLinkedPropertyAuthor(address _metrics) {
		address _prop = IMetrics(_metrics).property();
		propertyValidation(_prop);
		_;
	}

	/**
	 * Activates this Market.
	 * Called from MarketFactory contract.
	 */
	function toEnable() external {
		require(msg.sender == config().marketFactory(), "illegal accesss");
		require(isDuringVotingPeriod(), "deadline is over");
		enabled = true;
	}

	/**
	 * deactivates this Market.
	 * Called from MarketFactory contract.
	 */
	function toDisable() external {
		require(msg.sender == config().marketFactory(), "illegal accesss");
		enabled = false;
	}

	/**
	 * Authenticates the new asset and proves that the Property author is the owner of the asset.
	 */
	function authenticate(
		address _prop,
		string memory _args1,
		string memory _args2,
		string memory _args3,
		string memory _args4,
		string memory _args5
	) public onlyPropertyAuthor(_prop) returns (bool) {
		return
			_authenticate(
				_prop,
				msg.sender,
				_args1,
				_args2,
				_args3,
				_args4,
				_args5
			);
	}

	/**
	 * Authenticates the new asset and proves that the Property author is the owner of the asset.
	 */
	function authenticateFromPropertyFactory(
		address _prop,
		address _author,
		string calldata _args1,
		string calldata _args2,
		string calldata _args3,
		string calldata _args4,
		string calldata _args5
	) external returns (bool) {
		/**
		 * Validates the sender is PropertyFactory.
		 */
		require(
			msg.sender == config().propertyFactory(),
			"this is illegal address"
		);

		/**
		 * Validates this Market is already enabled..
		 */
		require(enabled, "market is not enabled");

		return
			_authenticate(
				_prop,
				_author,
				_args1,
				_args2,
				_args3,
				_args4,
				_args5
			);
	}

	/**
	 * Bypass to IMarketBehavior.authenticate.
	 * Authenticates the new asset and proves that the Property author is the owner of the asset.
	 */
	function _authenticate(
		address _prop,
		address _author,
		string memory _args1,
		string memory _args2,
		string memory _args3,
		string memory _args4,
		string memory _args5
	) private returns (bool) {
		require(bytes(_args1).length > 0, "id is required");

		return
			IMarketBehavior(behavior).authenticate(
				_prop,
				_args1,
				_args2,
				_args3,
				_args4,
				_args5,
				address(this),
				_author
			);
	}

	/**
	 * Returns the authentication fee.
	 * Calculates by gets the staking amount of the Property to be authenticated
	 * and the total number of authenticated assets on the protocol, and calling `Policy.authenticationFee`.
	 */
	function getAuthenticationFee(address _property)
		private
		view
		returns (uint256)
	{
		uint256 tokenValue = ILockup(config().lockup()).getPropertyValue(
			_property
		);
		IPolicy policy = IPolicy(config().policy());
		IMetricsGroup metricsGroup = IMetricsGroup(config().metricsGroup());
		return
			policy.authenticationFee(
				metricsGroup.totalIssuedMetrics(),
				tokenValue
			);
	}

	/**
	 * A function that will be called back when the asset is successfully authenticated.
	 * There are cases where oracle is required for the authentication process, so the function is used callback style.
	 */
	function authenticatedCallback(address _property, bytes32 _idHash)
		external
		returns (address)
	{
		/**
		 * Validates the sender is the saved IMarketBehavior address.
		 */
		require(msg.sender == behavior, "this is illegal address");
		require(enabled, "market is not enabled");

		/**
		 * Validates the assets are not double authenticated.
		 */
		require(idMap[_idHash] == false, "id is duplicated");
		idMap[_idHash] = true;

		/**
		 * Gets the Property author address.
		 */
		address sender = IProperty(_property).author();

		/**
		 * Publishes a new Metrics contract and associate the Property with the asset.
		 */
		IMetricsFactory metricsFactory = IMetricsFactory(
			config().metricsFactory()
		);
		address metrics = metricsFactory.create(_property);
		idHashMetricsMap[metrics] = _idHash;

		/**
		 * Burn as a authentication fee.
		 */
		uint256 authenticationFee = getAuthenticationFee(_property);
		require(
			IDev(config().token()).fee(sender, authenticationFee),
			"dev fee failed"
		);

		/**
		 * Adds the number of authenticated assets in this Market.
		 */
		issuedMetrics = issuedMetrics.add(1);
		return metrics;
	}

	/**
	 * Release the authenticated asset.
	 */
	function deauthenticate(address _metrics)
		external
		onlyLinkedPropertyAuthor(_metrics)
	{
		/**
		 * Validates the passed Metrics address is authenticated in this Market.
		 */
		bytes32 idHash = idHashMetricsMap[_metrics];
		require(idMap[idHash], "not authenticated");

		/**
		 * Removes the authentication status from local variables.
		 */
		idMap[idHash] = false;
		idHashMetricsMap[_metrics] = bytes32(0);

		/**
		 * Removes the passed Metrics contract from the Metrics address set.
		 */
		IMetricsFactory metricsFactory = IMetricsFactory(
			config().metricsFactory()
		);
		metricsFactory.destroy(_metrics);

		/**
		 * Subtracts the number of authenticated assets in this Market.
		 */
		issuedMetrics = issuedMetrics.sub(1);
	}

	/**
	 * Bypass to IMarketBehavior.schema.
	 */
	function schema() external view returns (string memory) {
		return IMarketBehavior(behavior).schema();
	}

	function isDuringVotingPeriod() private view returns (bool) {
		return block.number < votingEndBlockNumber;
	}
}

pragma solidity 0.5.17;

import "../../../interface/IAddressConfig.sol";

/**
 * Module for using AddressConfig contracts.
 */
contract UsingConfig {
	address private _config;

	/**
	 * Initialize the argument as AddressConfig address.
	 */
	constructor(address _addressConfig) public {
		_config = _addressConfig;
	}

	/**
	 * Returns the latest AddressConfig instance.
	 */
	function config() internal view returns (IAddressConfig) {
		return IAddressConfig(_config);
	}

	/**
	 * Returns the latest AddressConfig address.
	 */
	function configAddress() external view returns (address) {
		return _config;
	}
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IProperty {
	function author() external view returns (address);

	function changeAuthor(address _nextAuthor) external;

	function changeName(string calldata _name) external;

	function changeSymbol(string calldata _symbol) external;

	function withdraw(address _sender, uint256 _value) external;
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IPolicy {
	function rewards(uint256 _lockups, uint256 _assets)
		external
		view
		returns (uint256);

	function holdersShare(uint256 _amount, uint256 _lockups)
		external
		view
		returns (uint256);

	function authenticationFee(uint256 _assets, uint256 _propertyAssets)
		external
		view
		returns (uint256);

	function marketVotingBlocks() external view returns (uint256);

	function policyVotingBlocks() external view returns (uint256);

	function shareOfTreasury(uint256 _supply) external view returns (uint256);

	function treasury() external view returns (address);

	function capSetter() external view returns (address);
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IMetricsGroup {
	function addGroup(address _addr) external;

	function removeGroup(address _addr) external;

	function isGroup(address _addr) external view returns (bool);

	function totalIssuedMetrics() external view returns (uint256);

	function hasAssets(address _property) external view returns (bool);

	function getMetricsCountPerProperty(address _property)
		external
		view
		returns (uint256);

	function totalAuthenticatedProperties() external view returns (uint256);
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IMetricsFactory {
	function create(address _property) external returns (address);

	function destroy(address _metrics) external;
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IMetrics {
	function market() external view returns (address);

	function property() external view returns (address);
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IMarketGroup {
	function addGroup(address _addr) external;

	function deleteGroup(address _addr) external;

	function isGroup(address _addr) external view returns (bool);

	function getCount() external view returns (uint256);
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IMarketFactory {
	function create(address _addr) external returns (address);

	function enable(address _addr) external;

	function disable(address _addr) external;
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IMarketBehavior {
	function authenticate(
		address _prop,
		string calldata _args1,
		string calldata _args2,
		string calldata _args3,
		string calldata _args4,
		string calldata _args5,
		address market,
		address account
	) external returns (bool);

	function schema() external view returns (string memory);

	function getId(address _metrics) external view returns (string memory);

	function getMetrics(string calldata _id) external view returns (address);
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IMarket {
	function authenticate(
		address _prop,
		string calldata _args1,
		string calldata _args2,
		string calldata _args3,
		string calldata _args4,
		string calldata _args5
	) external returns (bool);

	function authenticateFromPropertyFactory(
		address _prop,
		address _author,
		string calldata _args1,
		string calldata _args2,
		string calldata _args3,
		string calldata _args4,
		string calldata _args5
	) external returns (bool);

	function authenticatedCallback(address _property, bytes32 _idHash)
		external
		returns (address);

	function deauthenticate(address _metrics) external;

	function schema() external view returns (string memory);

	function behavior() external view returns (address);

	function issuedMetrics() external view returns (uint256);

	function enabled() external view returns (bool);

	function votingEndBlockNumber() external view returns (uint256);

	function toEnable() external;

	function toDisable() external;
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface ILockup {
	function depositToProperty(address _property, uint256 _amount)
		external
		returns (uint256);

	function depositToPosition(uint256 _tokenId, uint256 _amount)
		external
		returns (bool);

	function lockup(
		address _from,
		address _property,
		uint256 _value
	) external;

	function update() external;

	function withdraw(address _property, uint256 _amount) external;

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

	/**
	 * caution!!!this function is deprecated!!!
	 * use calculateRewardAmount
	 */
	function calculateCumulativeHoldersRewardAmount(address _property)
		external
		view
		returns (uint256);

	function getPropertyValue(address _property)
		external
		view
		returns (uint256);

	function getAllValue() external view returns (uint256);

	function getValue(address _property, address _sender)
		external
		view
		returns (uint256);

	function calculateWithdrawableInterestAmount(
		address _property,
		address _user
	) external view returns (uint256);

	function calculateWithdrawableInterestAmountByPosition(uint256 _tokenId)
		external
		view
		returns (uint256);

	function cap() external view returns (uint256);

	function updateCap(uint256 _cap) external;

	function devMinter() external view returns (address);

	function sTokensManager() external view returns (address);

	function migrateToSTokens(address _property) external returns (uint256);
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IDev {
	function deposit(address _to, uint256 _amount) external returns (bool);

	function depositFrom(
		address _from,
		address _to,
		uint256 _amount
	) external returns (bool);

	function fee(address _from, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IAddressConfig {
	function token() external view returns (address);

	function allocator() external view returns (address);

	function allocatorStorage() external view returns (address);

	function withdraw() external view returns (address);

	function withdrawStorage() external view returns (address);

	function marketFactory() external view returns (address);

	function marketGroup() external view returns (address);

	function propertyFactory() external view returns (address);

	function propertyGroup() external view returns (address);

	function metricsGroup() external view returns (address);

	function metricsFactory() external view returns (address);

	function policy() external view returns (address);

	function policyFactory() external view returns (address);

	function policySet() external view returns (address);

	function policyGroup() external view returns (address);

	function lockup() external view returns (address);

	function lockupStorage() external view returns (address);

	function voteTimes() external view returns (address);

	function voteTimesStorage() external view returns (address);

	function voteCounter() external view returns (address);

	function voteCounterStorage() external view returns (address);

	function setAllocator(address _addr) external;

	function setAllocatorStorage(address _addr) external;

	function setWithdraw(address _addr) external;

	function setWithdrawStorage(address _addr) external;

	function setMarketFactory(address _addr) external;

	function setMarketGroup(address _addr) external;

	function setPropertyFactory(address _addr) external;

	function setPropertyGroup(address _addr) external;

	function setMetricsFactory(address _addr) external;

	function setMetricsGroup(address _addr) external;

	function setPolicyFactory(address _addr) external;

	function setPolicyGroup(address _addr) external;

	function setPolicySet(address _addr) external;

	function setPolicy(address _addr) external;

	function setToken(address _addr) external;

	function setLockup(address _addr) external;

	function setLockupStorage(address _addr) external;

	function setVoteTimes(address _addr) external;

	function setVoteTimesStorage(address _addr) external;

	function setVoteCounter(address _addr) external;

	function setVoteCounterStorage(address _addr) external;
}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}