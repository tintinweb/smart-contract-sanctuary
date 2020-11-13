// File: contracts/src/common/lifecycle/Killable.sol

pragma solidity ^0.5.0;

/**
 * A module that allows contracts to self-destruct.
 */
contract Killable {
	address payable public _owner;

	/**
	 * Initialized with the deployer as the owner.
	 */
	constructor() internal {
		_owner = msg.sender;
	}

	/**
	 * Self-destruct the contract.
	 * This function can only be executed by the owner.
	 */
	function kill() public {
		require(msg.sender == _owner, "only owner method");
		selfdestruct(_owner);
	}
}

// File: @openzeppelin/contracts/GSN/Context.sol

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
	constructor() internal {}

	// solhint-disable-previous-line no-empty-blocks

	function _msgSender() internal view returns (address payable) {
		return msg.sender;
	}

	function _msgData() internal view returns (bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

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

	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);

	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	constructor() internal {
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
		require(
			newOwner != address(0),
			"Ownable: new owner is the zero address"
		);
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

// File: contracts/src/common/interface/IGroup.sol

pragma solidity ^0.5.0;

contract IGroup {
	function isGroup(address _addr) public view returns (bool);

	function addGroup(address _addr) external;

	function getGroupKey(address _addr) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked("_group", _addr));
	}
}

// File: contracts/src/common/validate/AddressValidator.sol

pragma solidity ^0.5.0;

/**
 * A module that provides common validations patterns.
 */
contract AddressValidator {
	string constant errorMessage = "this is illegal address";

	/**
	 * Validates passed address is not a zero address.
	 */
	function validateIllegalAddress(address _addr) external pure {
		require(_addr != address(0), errorMessage);
	}

	/**
	 * Validates passed address is included in an address set.
	 */
	function validateGroup(address _addr, address _groupAddr) external view {
		require(IGroup(_groupAddr).isGroup(_addr), errorMessage);
	}

	/**
	 * Validates passed address is included in two address sets.
	 */
	function validateGroups(
		address _addr,
		address _groupAddr1,
		address _groupAddr2
	) external view {
		if (IGroup(_groupAddr1).isGroup(_addr)) {
			return;
		}
		require(IGroup(_groupAddr2).isGroup(_addr), errorMessage);
	}

	/**
	 * Validates that the address of the first argument is equal to the address of the second argument.
	 */
	function validateAddress(address _addr, address _target) external pure {
		require(_addr == _target, errorMessage);
	}

	/**
	 * Validates passed address equals to the two addresses.
	 */
	function validateAddresses(
		address _addr,
		address _target1,
		address _target2
	) external pure {
		if (_addr == _target1) {
			return;
		}
		require(_addr == _target2, errorMessage);
	}

	/**
	 * Validates passed address equals to the three addresses.
	 */
	function validate3Addresses(
		address _addr,
		address _target1,
		address _target2,
		address _target3
	) external pure {
		if (_addr == _target1) {
			return;
		}
		if (_addr == _target2) {
			return;
		}
		require(_addr == _target3, errorMessage);
	}
}

// File: contracts/src/common/validate/UsingValidator.sol

pragma solidity ^0.5.0;

// prettier-ignore

/**
 * Module for contrast handling AddressValidator.
 */
contract UsingValidator {
	AddressValidator private _validator;

	/**
	 * Create a new AddressValidator contract when initialize.
	 */
	constructor() public {
		_validator = new AddressValidator();
	}

	/**
	 * Returns the set AddressValidator address.
	 */
	function addressValidator() internal view returns (AddressValidator) {
		return _validator;
	}
}

// File: contracts/src/common/config/AddressConfig.sol

pragma solidity ^0.5.0;

/**
 * A registry contract to hold the latest contract addresses.
 * Dev Protocol will be upgradeable by this contract.
 */
contract AddressConfig is Ownable, UsingValidator, Killable {
	address public token = 0x98626E2C9231f03504273d55f397409deFD4a093;
	address public allocator;
	address public allocatorStorage;
	address public withdraw;
	address public withdrawStorage;
	address public marketFactory;
	address public marketGroup;
	address public propertyFactory;
	address public propertyGroup;
	address public metricsGroup;
	address public metricsFactory;
	address public policy;
	address public policyFactory;
	address public policySet;
	address public policyGroup;
	address public lockup;
	address public lockupStorage;
	address public voteTimes;
	address public voteTimesStorage;
	address public voteCounter;
	address public voteCounterStorage;

	/**
	 * Set the latest Allocator contract address.
	 * Only the owner can execute this function.
	 */
	function setAllocator(address _addr) external onlyOwner {
		allocator = _addr;
	}

	/**
	 * Set the latest AllocatorStorage contract address.
	 * Only the owner can execute this function.
	 * NOTE: But currently, the AllocatorStorage contract is not used.
	 */
	function setAllocatorStorage(address _addr) external onlyOwner {
		allocatorStorage = _addr;
	}

	/**
	 * Set the latest Withdraw contract address.
	 * Only the owner can execute this function.
	 */
	function setWithdraw(address _addr) external onlyOwner {
		withdraw = _addr;
	}

	/**
	 * Set the latest WithdrawStorage contract address.
	 * Only the owner can execute this function.
	 */
	function setWithdrawStorage(address _addr) external onlyOwner {
		withdrawStorage = _addr;
	}

	/**
	 * Set the latest MarketFactory contract address.
	 * Only the owner can execute this function.
	 */
	function setMarketFactory(address _addr) external onlyOwner {
		marketFactory = _addr;
	}

	/**
	 * Set the latest MarketGroup contract address.
	 * Only the owner can execute this function.
	 */
	function setMarketGroup(address _addr) external onlyOwner {
		marketGroup = _addr;
	}

	/**
	 * Set the latest PropertyFactory contract address.
	 * Only the owner can execute this function.
	 */
	function setPropertyFactory(address _addr) external onlyOwner {
		propertyFactory = _addr;
	}

	/**
	 * Set the latest PropertyGroup contract address.
	 * Only the owner can execute this function.
	 */
	function setPropertyGroup(address _addr) external onlyOwner {
		propertyGroup = _addr;
	}

	/**
	 * Set the latest MetricsFactory contract address.
	 * Only the owner can execute this function.
	 */
	function setMetricsFactory(address _addr) external onlyOwner {
		metricsFactory = _addr;
	}

	/**
	 * Set the latest MetricsGroup contract address.
	 * Only the owner can execute this function.
	 */
	function setMetricsGroup(address _addr) external onlyOwner {
		metricsGroup = _addr;
	}

	/**
	 * Set the latest PolicyFactory contract address.
	 * Only the owner can execute this function.
	 */
	function setPolicyFactory(address _addr) external onlyOwner {
		policyFactory = _addr;
	}

	/**
	 * Set the latest PolicyGroup contract address.
	 * Only the owner can execute this function.
	 */
	function setPolicyGroup(address _addr) external onlyOwner {
		policyGroup = _addr;
	}

	/**
	 * Set the latest PolicySet contract address.
	 * Only the owner can execute this function.
	 */
	function setPolicySet(address _addr) external onlyOwner {
		policySet = _addr;
	}

	/**
	 * Set the latest Policy contract address.
	 * Only the latest PolicyFactory contract can execute this function.
	 */
	function setPolicy(address _addr) external {
		addressValidator().validateAddress(msg.sender, policyFactory);
		policy = _addr;
	}

	/**
	 * Set the latest Dev contract address.
	 * Only the owner can execute this function.
	 */
	function setToken(address _addr) external onlyOwner {
		token = _addr;
	}

	/**
	 * Set the latest Lockup contract address.
	 * Only the owner can execute this function.
	 */
	function setLockup(address _addr) external onlyOwner {
		lockup = _addr;
	}

	/**
	 * Set the latest LockupStorage contract address.
	 * Only the owner can execute this function.
	 * NOTE: But currently, the LockupStorage contract is not used as a stand-alone because it is inherited from the Lockup contract.
	 */
	function setLockupStorage(address _addr) external onlyOwner {
		lockupStorage = _addr;
	}

	/**
	 * Set the latest VoteTimes contract address.
	 * Only the owner can execute this function.
	 * NOTE: But currently, the VoteTimes contract is not used.
	 */
	function setVoteTimes(address _addr) external onlyOwner {
		voteTimes = _addr;
	}

	/**
	 * Set the latest VoteTimesStorage contract address.
	 * Only the owner can execute this function.
	 * NOTE: But currently, the VoteTimesStorage contract is not used.
	 */
	function setVoteTimesStorage(address _addr) external onlyOwner {
		voteTimesStorage = _addr;
	}

	/**
	 * Set the latest VoteCounter contract address.
	 * Only the owner can execute this function.
	 */
	function setVoteCounter(address _addr) external onlyOwner {
		voteCounter = _addr;
	}

	/**
	 * Set the latest VoteCounterStorage contract address.
	 * Only the owner can execute this function.
	 * NOTE: But currently, the VoteCounterStorage contract is not used as a stand-alone because it is inherited from the VoteCounter contract.
	 */
	function setVoteCounterStorage(address _addr) external onlyOwner {
		voteCounterStorage = _addr;
	}
}

// File: contracts/src/common/config/UsingConfig.sol

pragma solidity ^0.5.0;

/**
 * Module for using AddressConfig contracts.
 */
contract UsingConfig {
	AddressConfig private _config;

	/**
	 * Initialize the argument as AddressConfig address.
	 */
	constructor(address _addressConfig) public {
		_config = AddressConfig(_addressConfig);
	}

	/**
	 * Returns the latest AddressConfig instance.
	 */
	function config() internal view returns (AddressConfig) {
		return _config;
	}

	/**
	 * Returns the latest AddressConfig address.
	 */
	function configAddress() external view returns (address) {
		return address(_config);
	}
}

// File: contracts/src/market/IMarketFactory.sol

pragma solidity ^0.5.0;

contract IMarketFactory {
	function create(address _addr) external returns (address);
}

// File: @openzeppelin/contracts/math/SafeMath.sol

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
	function div(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
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
	function mod(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}

// File: contracts/src/property/IProperty.sol

pragma solidity ^0.5.0;

contract IProperty {
	function author() external view returns (address);

	function withdraw(address _sender, uint256 _value) external;
}

// File: contracts/src/market/IMarket.sol

pragma solidity ^0.5.0;

interface IMarket {
	function authenticate(
		address _prop,
		string calldata _args1,
		string calldata _args2,
		string calldata _args3,
		string calldata _args4,
		string calldata _args5
	)
		external
		returns (
			// solium-disable-next-line indentation
			bool
		);

	function authenticatedCallback(address _property, bytes32 _idHash)
		external
		returns (address);

	function deauthenticate(address _metrics) external;

	function schema() external view returns (string memory);

	function behavior() external view returns (address);

	function enabled() external view returns (bool);

	function votingEndBlockNumber() external view returns (uint256);

	function toEnable() external;
}

// File: contracts/src/market/IMarketBehavior.sol

pragma solidity ^0.5.0;

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
	)
		external
		returns (
			// solium-disable-next-line indentation
			bool
		);

	function schema() external view returns (string memory);

	function getId(address _metrics) external view returns (string memory);

	function getMetrics(string calldata _id) external view returns (address);
}

// File: contracts/src/policy/IPolicy.sol

pragma solidity ^0.5.0;

contract IPolicy {
	function rewards(uint256 _lockups, uint256 _assets)
		external
		view
		returns (uint256);

	function holdersShare(uint256 _amount, uint256 _lockups)
		external
		view
		returns (uint256);

	function assetValue(uint256 _value, uint256 _lockups)
		external
		view
		returns (uint256);

	function authenticationFee(uint256 _assets, uint256 _propertyAssets)
		external
		view
		returns (uint256);

	function marketApproval(uint256 _agree, uint256 _opposite)
		external
		view
		returns (bool);

	function policyApproval(uint256 _agree, uint256 _opposite)
		external
		view
		returns (bool);

	function marketVotingBlocks() external view returns (uint256);

	function policyVotingBlocks() external view returns (uint256);

	function abstentionPenalty(uint256 _count) external view returns (uint256);

	function lockUpBlocks() external view returns (uint256);
}

// File: contracts/src/metrics/IMetrics.sol

pragma solidity ^0.5.0;

contract IMetrics {
	address public market;
	address public property;
}

// File: contracts/src/metrics/Metrics.sol

pragma solidity ^0.5.0;

/**
 * A contract for associating a Property and an asset authenticated by a Market.
 */
contract Metrics is IMetrics {
	address public market;
	address public property;

	constructor(address _market, address _property) public {
		//Do not validate because there is no AddressConfig
		market = _market;
		property = _property;
	}
}

// File: contracts/src/metrics/IMetricsFactory.sol

pragma solidity ^0.5.0;

contract IMetricsFactory {
	function create(address _property) external returns (address);

	function destroy(address _metrics) external;
}

// File: contracts/src/metrics/IMetricsGroup.sol

pragma solidity ^0.5.0;

contract IMetricsGroup is IGroup {
	function removeGroup(address _addr) external;

	function totalIssuedMetrics() external view returns (uint256);

	function getMetricsCountPerProperty(address _property)
		public
		view
		returns (uint256);

	function hasAssets(address _property) public view returns (bool);
}

// File: contracts/src/lockup/ILockup.sol

pragma solidity ^0.5.0;

contract ILockup {
	function lockup(
		address _from,
		address _property,
		uint256 _value
		// solium-disable-next-line indentation
	) external;

	function update() public;

	function cancel(address _property) external;

	function withdraw(address _property) external;

	function difference(address _property, uint256 _lastReward)
		public
		view
		returns (
			uint256 _reward,
			uint256 _holdersAmount,
			uint256 _holdersPrice,
			uint256 _interestAmount,
			uint256 _interestPrice
		);

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
	)
		public
		view
		returns (
			// solium-disable-next-line indentation
			uint256
		);

	function withdrawInterest(address _property) external;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
	function transfer(address recipient, uint256 amount)
		external
		returns (bool);

	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 *
	 * This value changes when {approve} or {transferFrom} are called.
	 */
	function allowance(address owner, address spender)
		external
		view
		returns (uint256);

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
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
	string private _name;
	string private _symbol;
	uint8 private _decimals;

	/**
	 * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
	 * these values are immutable: they can only be set once during
	 * construction.
	 */
	constructor(
		string memory name,
		string memory symbol,
		uint8 decimals
	) public {
		_name = name;
		_symbol = symbol;
		_decimals = decimals;
	}

	/**
	 * @dev Returns the name of the token.
	 */
	function name() public view returns (string memory) {
		return _name;
	}

	/**
	 * @dev Returns the symbol of the token, usually a shorter version of the
	 * name.
	 */
	function symbol() public view returns (string memory) {
		return _symbol;
	}

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 * For example, if `decimals` equals `2`, a balance of `505` tokens should
	 * be displayed to a user as `5,05` (`505 / 10 ** 2`).
	 *
	 * Tokens usually opt for a value of 18, imitating the relationship between
	 * Ether and Wei.
	 *
	 * NOTE: This information is only used for _display_ purposes: it in
	 * no way affects any of the arithmetic of the contract, including
	 * {IERC20-balanceOf} and {IERC20-transfer}.
	 */
	function decimals() public view returns (uint8) {
		return _decimals;
	}
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
	using SafeMath for uint256;

	mapping(address => uint256) private _balances;

	mapping(address => mapping(address => uint256)) private _allowances;

	uint256 private _totalSupply;

	/**
	 * @dev See {IERC20-totalSupply}.
	 */
	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	/**
	 * @dev See {IERC20-balanceOf}.
	 */
	function balanceOf(address account) public view returns (uint256) {
		return _balances[account];
	}

	/**
	 * @dev See {IERC20-transfer}.
	 *
	 * Requirements:
	 *
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) public returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	/**
	 * @dev See {IERC20-allowance}.
	 */
	function allowance(address owner, address spender)
		public
		view
		returns (uint256)
	{
		return _allowances[owner][spender];
	}

	/**
	 * @dev See {IERC20-approve}.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 */
	function approve(address spender, uint256 amount) public returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	/**
	 * @dev See {IERC20-transferFrom}.
	 *
	 * Emits an {Approval} event indicating the updated allowance. This is not
	 * required by the EIP. See the note at the beginning of {ERC20};
	 *
	 * Requirements:
	 * - `sender` and `recipient` cannot be the zero address.
	 * - `sender` must have a balance of at least `amount`.
	 * - the caller must have allowance for `sender`'s tokens of at least
	 * `amount`.
	 */
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(
			sender,
			_msgSender(),
			_allowances[sender][_msgSender()].sub(
				amount,
				"ERC20: transfer amount exceeds allowance"
			)
		);
		return true;
	}

	/**
	 * @dev Atomically increases the allowance granted to `spender` by the caller.
	 *
	 * This is an alternative to {approve} that can be used as a mitigation for
	 * problems described in {IERC20-approve}.
	 *
	 * Emits an {Approval} event indicating the updated allowance.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 */
	function increaseAllowance(address spender, uint256 addedValue)
		public
		returns (bool)
	{
		_approve(
			_msgSender(),
			spender,
			_allowances[_msgSender()][spender].add(addedValue)
		);
		return true;
	}

	/**
	 * @dev Atomically decreases the allowance granted to `spender` by the caller.
	 *
	 * This is an alternative to {approve} that can be used as a mitigation for
	 * problems described in {IERC20-approve}.
	 *
	 * Emits an {Approval} event indicating the updated allowance.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 * - `spender` must have allowance for the caller of at least
	 * `subtractedValue`.
	 */
	function decreaseAllowance(address spender, uint256 subtractedValue)
		public
		returns (bool)
	{
		_approve(
			_msgSender(),
			spender,
			_allowances[_msgSender()][spender].sub(
				subtractedValue,
				"ERC20: decreased allowance below zero"
			)
		);
		return true;
	}

	/**
	 * @dev Moves tokens `amount` from `sender` to `recipient`.
	 *
	 * This is internal function is equivalent to {transfer}, and can be used to
	 * e.g. implement automatic token fees, slashing mechanisms, etc.
	 *
	 * Emits a {Transfer} event.
	 *
	 * Requirements:
	 *
	 * - `sender` cannot be the zero address.
	 * - `recipient` cannot be the zero address.
	 * - `sender` must have a balance of at least `amount`.
	 */
	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");

		_balances[sender] = _balances[sender].sub(
			amount,
			"ERC20: transfer amount exceeds balance"
		);
		_balances[recipient] = _balances[recipient].add(amount);
		emit Transfer(sender, recipient, amount);
	}

	/** @dev Creates `amount` tokens and assigns them to `account`, increasing
	 * the total supply.
	 *
	 * Emits a {Transfer} event with `from` set to the zero address.
	 *
	 * Requirements
	 *
	 * - `to` cannot be the zero address.
	 */
	function _mint(address account, uint256 amount) internal {
		require(account != address(0), "ERC20: mint to the zero address");

		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}

	/**
	 * @dev Destroys `amount` tokens from `account`, reducing the
	 * total supply.
	 *
	 * Emits a {Transfer} event with `to` set to the zero address.
	 *
	 * Requirements
	 *
	 * - `account` cannot be the zero address.
	 * - `account` must have at least `amount` tokens.
	 */
	function _burn(address account, uint256 amount) internal {
		require(account != address(0), "ERC20: burn from the zero address");

		_balances[account] = _balances[account].sub(
			amount,
			"ERC20: burn amount exceeds balance"
		);
		_totalSupply = _totalSupply.sub(amount);
		emit Transfer(account, address(0), amount);
	}

	/**
	 * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
	 *
	 * This is internal function is equivalent to `approve`, and can be used to
	 * e.g. set automatic allowances for certain subsystems, etc.
	 *
	 * Emits an {Approval} event.
	 *
	 * Requirements:
	 *
	 * - `owner` cannot be the zero address.
	 * - `spender` cannot be the zero address.
	 */
	function _approve(
		address owner,
		address spender,
		uint256 amount
	) internal {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	/**
	 * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
	 * from the caller's allowance.
	 *
	 * See {_burn} and {_approve}.
	 */
	function _burnFrom(address account, uint256 amount) internal {
		_burn(account, amount);
		_approve(
			account,
			_msgSender(),
			_allowances[account][_msgSender()].sub(
				amount,
				"ERC20: burn amount exceeds allowance"
			)
		);
	}
}

// File: @openzeppelin/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
	struct Role {
		mapping(address => bool) bearer;
	}

	/**
	 * @dev Give an account access to this role.
	 */
	function add(Role storage role, address account) internal {
		require(!has(role, account), "Roles: account already has role");
		role.bearer[account] = true;
	}

	/**
	 * @dev Remove an account's access to this role.
	 */
	function remove(Role storage role, address account) internal {
		require(has(role, account), "Roles: account does not have role");
		role.bearer[account] = false;
	}

	/**
	 * @dev Check if an account has this role.
	 * @return bool
	 */
	function has(Role storage role, address account)
		internal
		view
		returns (bool)
	{
		require(account != address(0), "Roles: account is the zero address");
		return role.bearer[account];
	}
}

// File: @openzeppelin/contracts/access/roles/MinterRole.sol

pragma solidity ^0.5.0;

contract MinterRole is Context {
	using Roles for Roles.Role;

	event MinterAdded(address indexed account);
	event MinterRemoved(address indexed account);

	Roles.Role private _minters;

	constructor() internal {
		_addMinter(_msgSender());
	}

	modifier onlyMinter() {
		require(
			isMinter(_msgSender()),
			"MinterRole: caller does not have the Minter role"
		);
		_;
	}

	function isMinter(address account) public view returns (bool) {
		return _minters.has(account);
	}

	function addMinter(address account) public onlyMinter {
		_addMinter(account);
	}

	function renounceMinter() public {
		_removeMinter(_msgSender());
	}

	function _addMinter(address account) internal {
		_minters.add(account);
		emit MinterAdded(account);
	}

	function _removeMinter(address account) internal {
		_minters.remove(account);
		emit MinterRemoved(account);
	}
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Mintable.sol

pragma solidity ^0.5.0;

/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC20Mintable is ERC20, MinterRole {
	/**
	 * @dev See {ERC20-_mint}.
	 *
	 * Requirements:
	 *
	 * - the caller must have the {MinterRole}.
	 */
	function mint(address account, uint256 amount)
		public
		onlyMinter
		returns (bool)
	{
		_mint(account, amount);
		return true;
	}
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Burnable.sol

pragma solidity ^0.5.0;

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Context, ERC20 {
	/**
	 * @dev Destroys `amount` tokens from the caller.
	 *
	 * See {ERC20-_burn}.
	 */
	function burn(uint256 amount) public {
		_burn(_msgSender(), amount);
	}

	/**
	 * @dev See {ERC20-_burnFrom}.
	 */
	function burnFrom(address account, uint256 amount) public {
		_burnFrom(account, amount);
	}
}

// File: contracts/src/common/libs/Decimals.sol

pragma solidity ^0.5.0;

/**
 * Library for emulating calculations involving decimals.
 */
library Decimals {
	using SafeMath for uint256;
	uint120 private constant basisValue = 1000000000000000000;

	/**
	 * Returns the ratio of the first argument to the second argument.
	 */
	function outOf(uint256 _a, uint256 _b)
		internal
		pure
		returns (uint256 result)
	{
		if (_a == 0) {
			return 0;
		}
		uint256 a = _a.mul(basisValue);
		if (a < _b) {
			return 0;
		}
		return (a.div(_b));
	}

	/**
	 * Returns multiplied the number by 10^18.
	 * This is used when there is a very large difference between the two numbers passed to the `outOf` function.
	 */
	function mulBasis(uint256 _a) internal pure returns (uint256) {
		return _a.mul(basisValue);
	}

	/**
	 * Returns by changing the numerical value being emulated to the original number of digits.
	 */
	function divBasis(uint256 _a) internal pure returns (uint256) {
		return _a.div(basisValue);
	}
}

// File: contracts/src/common/storage/EternalStorage.sol

pragma solidity ^0.5.0;

/**
 * Module for persisting states.
 * Stores a map for `uint256`, `string`, `address`, `bytes32`, `bool`, and `int256` type with `bytes32` type as a key.
 */
contract EternalStorage {
	address private currentOwner = msg.sender;

	mapping(bytes32 => uint256) private uIntStorage;
	mapping(bytes32 => string) private stringStorage;
	mapping(bytes32 => address) private addressStorage;
	mapping(bytes32 => bytes32) private bytesStorage;
	mapping(bytes32 => bool) private boolStorage;
	mapping(bytes32 => int256) private intStorage;

	/**
	 * Modifiers to validate that only the owner can execute.
	 */
	modifier onlyCurrentOwner() {
		require(msg.sender == currentOwner, "not current owner");
		_;
	}

	/**
	 * Transfer the owner.
	 * Only the owner can execute this function.
	 */
	function changeOwner(address _newOwner) external {
		require(msg.sender == currentOwner, "not current owner");
		currentOwner = _newOwner;
	}

	// *** Getter Methods ***

	/**
	 * Returns the value of the `uint256` type that mapped to the given key.
	 */
	function getUint(bytes32 _key) external view returns (uint256) {
		return uIntStorage[_key];
	}

	/**
	 * Returns the value of the `string` type that mapped to the given key.
	 */
	function getString(bytes32 _key) external view returns (string memory) {
		return stringStorage[_key];
	}

	/**
	 * Returns the value of the `address` type that mapped to the given key.
	 */
	function getAddress(bytes32 _key) external view returns (address) {
		return addressStorage[_key];
	}

	/**
	 * Returns the value of the `bytes32` type that mapped to the given key.
	 */
	function getBytes(bytes32 _key) external view returns (bytes32) {
		return bytesStorage[_key];
	}

	/**
	 * Returns the value of the `bool` type that mapped to the given key.
	 */
	function getBool(bytes32 _key) external view returns (bool) {
		return boolStorage[_key];
	}

	/**
	 * Returns the value of the `int256` type that mapped to the given key.
	 */
	function getInt(bytes32 _key) external view returns (int256) {
		return intStorage[_key];
	}

	// *** Setter Methods ***

	/**
	 * Maps a value of `uint256` type to a given key.
	 * Only the owner can execute this function.
	 */
	function setUint(bytes32 _key, uint256 _value) external onlyCurrentOwner {
		uIntStorage[_key] = _value;
	}

	/**
	 * Maps a value of `string` type to a given key.
	 * Only the owner can execute this function.
	 */
	function setString(bytes32 _key, string calldata _value)
		external
		onlyCurrentOwner
	{
		stringStorage[_key] = _value;
	}

	/**
	 * Maps a value of `address` type to a given key.
	 * Only the owner can execute this function.
	 */
	function setAddress(bytes32 _key, address _value)
		external
		onlyCurrentOwner
	{
		addressStorage[_key] = _value;
	}

	/**
	 * Maps a value of `bytes32` type to a given key.
	 * Only the owner can execute this function.
	 */
	function setBytes(bytes32 _key, bytes32 _value) external onlyCurrentOwner {
		bytesStorage[_key] = _value;
	}

	/**
	 * Maps a value of `bool` type to a given key.
	 * Only the owner can execute this function.
	 */
	function setBool(bytes32 _key, bool _value) external onlyCurrentOwner {
		boolStorage[_key] = _value;
	}

	/**
	 * Maps a value of `int256` type to a given key.
	 * Only the owner can execute this function.
	 */
	function setInt(bytes32 _key, int256 _value) external onlyCurrentOwner {
		intStorage[_key] = _value;
	}

	// *** Delete Methods ***

	/**
	 * Deletes the value of the `uint256` type that mapped to the given key.
	 * Only the owner can execute this function.
	 */
	function deleteUint(bytes32 _key) external onlyCurrentOwner {
		delete uIntStorage[_key];
	}

	/**
	 * Deletes the value of the `string` type that mapped to the given key.
	 * Only the owner can execute this function.
	 */
	function deleteString(bytes32 _key) external onlyCurrentOwner {
		delete stringStorage[_key];
	}

	/**
	 * Deletes the value of the `address` type that mapped to the given key.
	 * Only the owner can execute this function.
	 */
	function deleteAddress(bytes32 _key) external onlyCurrentOwner {
		delete addressStorage[_key];
	}

	/**
	 * Deletes the value of the `bytes32` type that mapped to the given key.
	 * Only the owner can execute this function.
	 */
	function deleteBytes(bytes32 _key) external onlyCurrentOwner {
		delete bytesStorage[_key];
	}

	/**
	 * Deletes the value of the `bool` type that mapped to the given key.
	 * Only the owner can execute this function.
	 */
	function deleteBool(bytes32 _key) external onlyCurrentOwner {
		delete boolStorage[_key];
	}

	/**
	 * Deletes the value of the `int256` type that mapped to the given key.
	 * Only the owner can execute this function.
	 */
	function deleteInt(bytes32 _key) external onlyCurrentOwner {
		delete intStorage[_key];
	}
}

// File: contracts/src/common/storage/UsingStorage.sol

pragma solidity ^0.5.0;

/**
 * Module for contrast handling EternalStorage.
 */
contract UsingStorage is Ownable {
	address private _storage;

	/**
	 * Modifier to verify that EternalStorage is set.
	 */
	modifier hasStorage() {
		require(_storage != address(0), "storage is not set");
		_;
	}

	/**
	 * Returns the set EternalStorage instance.
	 */
	function eternalStorage()
		internal
		view
		hasStorage
		returns (EternalStorage)
	{
		return EternalStorage(_storage);
	}

	/**
	 * Returns the set EternalStorage address.
	 */
	function getStorageAddress() external view hasStorage returns (address) {
		return _storage;
	}

	/**
	 * Create a new EternalStorage contract.
	 * This function call will fail if the EternalStorage contract is already set.
	 * Also, only the owner can execute it.
	 */
	function createStorage() external onlyOwner {
		require(_storage == address(0), "storage is set");
		EternalStorage tmp = new EternalStorage();
		_storage = address(tmp);
	}

	/**
	 * Assigns the EternalStorage contract that has already been created.
	 * Only the owner can execute this function.
	 */
	function setStorage(address _storageAddress) external onlyOwner {
		_storage = _storageAddress;
	}

	/**
	 * Delegates the owner of the current EternalStorage contract.
	 * Only the owner can execute this function.
	 */
	function changeOwner(address newOwner) external onlyOwner {
		EternalStorage(_storage).changeOwner(newOwner);
	}
}

// File: contracts/src/lockup/LockupStorage.sol

pragma solidity ^0.5.0;

contract LockupStorage is UsingStorage {
	using SafeMath for uint256;

	uint256 public constant basis = 100000000000000000000000000000000;

	//AllValue
	function setStorageAllValue(uint256 _value) internal {
		bytes32 key = getStorageAllValueKey();
		eternalStorage().setUint(key, _value);
	}

	function getStorageAllValue() public view returns (uint256) {
		bytes32 key = getStorageAllValueKey();
		return eternalStorage().getUint(key);
	}

	function getStorageAllValueKey() private pure returns (bytes32) {
		return keccak256(abi.encodePacked("_allValue"));
	}

	//Value
	function setStorageValue(
		address _property,
		address _sender,
		uint256 _value
	) internal {
		bytes32 key = getStorageValueKey(_property, _sender);
		eternalStorage().setUint(key, _value);
	}

	function getStorageValue(address _property, address _sender)
		public
		view
		returns (uint256)
	{
		bytes32 key = getStorageValueKey(_property, _sender);
		return eternalStorage().getUint(key);
	}

	function getStorageValueKey(address _property, address _sender)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("_value", _property, _sender));
	}

	//PropertyValue
	function setStoragePropertyValue(address _property, uint256 _value)
		internal
	{
		bytes32 key = getStoragePropertyValueKey(_property);
		eternalStorage().setUint(key, _value);
	}

	function getStoragePropertyValue(address _property)
		public
		view
		returns (uint256)
	{
		bytes32 key = getStoragePropertyValueKey(_property);
		return eternalStorage().getUint(key);
	}

	function getStoragePropertyValueKey(address _property)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("_propertyValue", _property));
	}

	//WithdrawalStatus
	function setStorageWithdrawalStatus(
		address _property,
		address _from,
		uint256 _value
	) internal {
		bytes32 key = getStorageWithdrawalStatusKey(_property, _from);
		eternalStorage().setUint(key, _value);
	}

	function getStorageWithdrawalStatus(address _property, address _from)
		public
		view
		returns (uint256)
	{
		bytes32 key = getStorageWithdrawalStatusKey(_property, _from);
		return eternalStorage().getUint(key);
	}

	function getStorageWithdrawalStatusKey(address _property, address _sender)
		private
		pure
		returns (bytes32)
	{
		return
			keccak256(
				abi.encodePacked("_withdrawalStatus", _property, _sender)
			);
	}

	//InterestPrice
	function setStorageInterestPrice(address _property, uint256 _value)
		internal
	{
		// The previously used function
		// This function is only used in testing
		eternalStorage().setUint(getStorageInterestPriceKey(_property), _value);
	}

	function getStorageInterestPrice(address _property)
		public
		view
		returns (uint256)
	{
		return eternalStorage().getUint(getStorageInterestPriceKey(_property));
	}

	function getStorageInterestPriceKey(address _property)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("_interestTotals", _property));
	}

	//LastInterestPrice
	function setStorageLastInterestPrice(
		address _property,
		address _user,
		uint256 _value
	) internal {
		eternalStorage().setUint(
			getStorageLastInterestPriceKey(_property, _user),
			_value
		);
	}

	function getStorageLastInterestPrice(address _property, address _user)
		public
		view
		returns (uint256)
	{
		return
			eternalStorage().getUint(
				getStorageLastInterestPriceKey(_property, _user)
			);
	}

	function getStorageLastInterestPriceKey(address _property, address _user)
		private
		pure
		returns (bytes32)
	{
		return
			keccak256(
				abi.encodePacked("_lastLastInterestPrice", _property, _user)
			);
	}

	//LastSameRewardsAmountAndBlock
	function setStorageLastSameRewardsAmountAndBlock(
		uint256 _amount,
		uint256 _block
	) internal {
		uint256 record = _amount.mul(basis).add(_block);
		eternalStorage().setUint(
			getStorageLastSameRewardsAmountAndBlockKey(),
			record
		);
	}

	function getStorageLastSameRewardsAmountAndBlock()
		public
		view
		returns (uint256 _amount, uint256 _block)
	{
		uint256 record = eternalStorage().getUint(
			getStorageLastSameRewardsAmountAndBlockKey()
		);
		uint256 amount = record.div(basis);
		uint256 blockNumber = record.sub(amount.mul(basis));
		return (amount, blockNumber);
	}

	function getStorageLastSameRewardsAmountAndBlockKey()
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("_LastSameRewardsAmountAndBlock"));
	}

	//CumulativeGlobalRewards
	function setStorageCumulativeGlobalRewards(uint256 _value) internal {
		eternalStorage().setUint(
			getStorageCumulativeGlobalRewardsKey(),
			_value
		);
	}

	function getStorageCumulativeGlobalRewards() public view returns (uint256) {
		return eternalStorage().getUint(getStorageCumulativeGlobalRewardsKey());
	}

	function getStorageCumulativeGlobalRewardsKey()
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("_cumulativeGlobalRewards"));
	}

	//LastCumulativeGlobalReward
	function setStorageLastCumulativeGlobalReward(
		address _property,
		address _user,
		uint256 _value
	) internal {
		eternalStorage().setUint(
			getStorageLastCumulativeGlobalRewardKey(_property, _user),
			_value
		);
	}

	function getStorageLastCumulativeGlobalReward(
		address _property,
		address _user
	) public view returns (uint256) {
		return
			eternalStorage().getUint(
				getStorageLastCumulativeGlobalRewardKey(_property, _user)
			);
	}

	function getStorageLastCumulativeGlobalRewardKey(
		address _property,
		address _user
	) private pure returns (bytes32) {
		return
			keccak256(
				abi.encodePacked(
					"_LastCumulativeGlobalReward",
					_property,
					_user
				)
			);
	}

	//LastCumulativePropertyInterest
	function setStorageLastCumulativePropertyInterest(
		address _property,
		address _user,
		uint256 _value
	) internal {
		eternalStorage().setUint(
			getStorageLastCumulativePropertyInterestKey(_property, _user),
			_value
		);
	}

	function getStorageLastCumulativePropertyInterest(
		address _property,
		address _user
	) public view returns (uint256) {
		return
			eternalStorage().getUint(
				getStorageLastCumulativePropertyInterestKey(_property, _user)
			);
	}

	function getStorageLastCumulativePropertyInterestKey(
		address _property,
		address _user
	) private pure returns (bytes32) {
		return
			keccak256(
				abi.encodePacked(
					"_lastCumulativePropertyInterest",
					_property,
					_user
				)
			);
	}

	//CumulativeLockedUpUnitAndBlock
	function setStorageCumulativeLockedUpUnitAndBlock(
		address _addr,
		uint256 _unit,
		uint256 _block
	) internal {
		uint256 record = _unit.mul(basis).add(_block);
		eternalStorage().setUint(
			getStorageCumulativeLockedUpUnitAndBlockKey(_addr),
			record
		);
	}

	function getStorageCumulativeLockedUpUnitAndBlock(address _addr)
		public
		view
		returns (uint256 _unit, uint256 _block)
	{
		uint256 record = eternalStorage().getUint(
			getStorageCumulativeLockedUpUnitAndBlockKey(_addr)
		);
		uint256 unit = record.div(basis);
		uint256 blockNumber = record.sub(unit.mul(basis));
		return (unit, blockNumber);
	}

	function getStorageCumulativeLockedUpUnitAndBlockKey(address _addr)
		private
		pure
		returns (bytes32)
	{
		return
			keccak256(
				abi.encodePacked("_cumulativeLockedUpUnitAndBlock", _addr)
			);
	}

	//CumulativeLockedUpValue
	function setStorageCumulativeLockedUpValue(address _addr, uint256 _value)
		internal
	{
		eternalStorage().setUint(
			getStorageCumulativeLockedUpValueKey(_addr),
			_value
		);
	}

	function getStorageCumulativeLockedUpValue(address _addr)
		public
		view
		returns (uint256)
	{
		return
			eternalStorage().getUint(
				getStorageCumulativeLockedUpValueKey(_addr)
			);
	}

	function getStorageCumulativeLockedUpValueKey(address _addr)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("_cumulativeLockedUpValue", _addr));
	}

	//PendingWithdrawal
	function setStoragePendingInterestWithdrawal(
		address _property,
		address _user,
		uint256 _value
	) internal {
		eternalStorage().setUint(
			getStoragePendingInterestWithdrawalKey(_property, _user),
			_value
		);
	}

	function getStoragePendingInterestWithdrawal(
		address _property,
		address _user
	) public view returns (uint256) {
		return
			eternalStorage().getUint(
				getStoragePendingInterestWithdrawalKey(_property, _user)
			);
	}

	function getStoragePendingInterestWithdrawalKey(
		address _property,
		address _user
	) private pure returns (bytes32) {
		return
			keccak256(
				abi.encodePacked("_pendingInterestWithdrawal", _property, _user)
			);
	}

	//DIP4GenesisBlock
	function setStorageDIP4GenesisBlock(uint256 _block) internal {
		eternalStorage().setUint(getStorageDIP4GenesisBlockKey(), _block);
	}

	function getStorageDIP4GenesisBlock() public view returns (uint256) {
		return eternalStorage().getUint(getStorageDIP4GenesisBlockKey());
	}

	function getStorageDIP4GenesisBlockKey() private pure returns (bytes32) {
		return keccak256(abi.encodePacked("_dip4GenesisBlock"));
	}

	//LastCumulativeLockedUpAndBlock
	function setStorageLastCumulativeLockedUpAndBlock(
		address _property,
		address _user,
		uint256 _cLocked,
		uint256 _block
	) internal {
		uint256 record = _cLocked.mul(basis).add(_block);
		eternalStorage().setUint(
			getStorageLastCumulativeLockedUpAndBlockKey(_property, _user),
			record
		);
	}

	function getStorageLastCumulativeLockedUpAndBlock(
		address _property,
		address _user
	) public view returns (uint256 _cLocked, uint256 _block) {
		uint256 record = eternalStorage().getUint(
			getStorageLastCumulativeLockedUpAndBlockKey(_property, _user)
		);
		uint256 cLocked = record.div(basis);
		uint256 blockNumber = record.sub(cLocked.mul(basis));

		return (cLocked, blockNumber);
	}

	function getStorageLastCumulativeLockedUpAndBlockKey(
		address _property,
		address _user
	) private pure returns (bytes32) {
		return
			keccak256(
				abi.encodePacked(
					"_lastCumulativeLockedUpAndBlock",
					_property,
					_user
				)
			);
	}
}

// File: contracts/src/allocator/IAllocator.sol

pragma solidity ^0.5.0;

contract IAllocator {
	function calculateMaxRewardsPerBlock() public view returns (uint256);

	function beforeBalanceChange(
		address _property,
		address _from,
		address _to
		// solium-disable-next-line indentation
	) external;
}

// File: contracts/src/lockup/Lockup.sol

pragma solidity ^0.5.0;

// prettier-ignore

/**
 * A contract that manages the staking of DEV tokens and calculates rewards.
 * Staking and the following mechanism determines that reward calculation.
 *
 * Variables:
 * -`M`: Maximum mint amount per block determined by Allocator contract
 * -`B`: Number of blocks during staking
 * -`P`: Total number of staking locked up in a Property contract
 * -`S`: Total number of staking locked up in all Property contracts
 * -`U`: Number of staking per account locked up in a Property contract
 *
 * Formula:
 * Staking Rewards = M * B * (P / S) * (U / P)
 *
 * Note:
 * -`M`, `P` and `S` vary from block to block, and the variation cannot be predicted.
 * -`B` is added every time the Ethereum block is created.
 * - Only `U` and `B` are predictable variables.
 * - As `M`, `P` and `S` cannot be observed from a staker, the "cumulative sum" is often used to calculate ratio variation with history.
 * - Reward withdrawal always withdraws the total withdrawable amount.
 *
 * Scenario:
 * - Assume `M` is fixed at 500
 * - Alice stakes 100 DEV on Property-A (Alice's staking state on Property-A: `M`=500, `B`=0, `P`=100, `S`=100, `U`=100)
 * - After 10 blocks, Bob stakes 60 DEV on Property-B (Alice's staking state on Property-A: `M`=500, `B`=10, `P`=100, `S`=160, `U`=100)
 * - After 10 blocks, Carol stakes 40 DEV on Property-A (Alice's staking state on Property-A: `M`=500, `B`=20, `P`=140, `S`=200, `U`=100)
 * - After 10 blocks, Alice withdraws Property-A staking reward. The reward at this time is 5000 DEV (10 blocks * 500 DEV) + 3125 DEV (10 blocks * 62.5% * 500 DEV) + 2500 DEV (10 blocks * 50% * 500 DEV).
 */
contract Lockup is ILockup, UsingConfig, UsingValidator, LockupStorage {
	using SafeMath for uint256;
	using Decimals for uint256;
	event Lockedup(address _from, address _property, uint256 _value);

	/**
	 * Initialize the passed address as AddressConfig address.
	 */
	// solium-disable-next-line no-empty-blocks
	constructor(address _config) public UsingConfig(_config) {}

	/**
	 * Adds staking.
	 * Only the Dev contract can execute this function.
	 */
	function lockup(
		address _from,
		address _property,
		uint256 _value
	) external {
		/**
		 * Validates the sender is Dev contract.
		 */
		addressValidator().validateAddress(msg.sender, config().token());

		/**
		 * Validates the target of staking is included Property set.
		 */
		addressValidator().validateGroup(_property, config().propertyGroup());
		require(_value != 0, "illegal lockup value");

		/**
		 * Validates the passed Property has greater than 1 asset.
		 */
		require(
			IMetricsGroup(config().metricsGroup()).hasAssets(_property),
			"unable to stake to unauthenticated property"
		);

		/**
		 * Refuses new staking when after cancel staking and until release it.
		 */
		bool isWaiting = getStorageWithdrawalStatus(_property, _from) != 0;
		require(isWaiting == false, "lockup is already canceled");

		/**
		 * Since the reward per block that can be withdrawn will change with the addition of staking,
		 * saves the undrawn withdrawable reward before addition it.
		 */
		updatePendingInterestWithdrawal(_property, _from);

		/**
		 * Saves the variables at the time of staking to prepare for reward calculation.
		 */
		(, , , uint256 interest, ) = difference(_property, 0);
		updateStatesAtLockup(_property, _from, interest);

		/**
		 * Saves variables that should change due to the addition of staking.
		 */
		updateValues(true, _from, _property, _value);
		emit Lockedup(_from, _property, _value);
	}

	/**
	 * Cancel staking.
	 * The staking amount can be withdrawn after the blocks specified by `Policy.lockUpBlocks` have passed.
	 */
	function cancel(address _property) external {
		/**
		 * Validates the target of staked is included Property set.
		 */
		addressValidator().validateGroup(_property, config().propertyGroup());

		/**
		 * Validates the sender is staking to the target Property.
		 */
		require(hasValue(_property, msg.sender), "dev token is not locked");

		/**
		 * Validates not already been canceled.
		 */
		bool isWaiting = getStorageWithdrawalStatus(_property, msg.sender) != 0;
		require(isWaiting == false, "lockup is already canceled");

		/**
		 * Get `Policy.lockUpBlocks`, add it to the current block number, and saves that block number in `WithdrawalStatus`.
		 * Staking is cannot release until the block number saved in `WithdrawalStatus` is reached.
		 */
		uint256 blockNumber = IPolicy(config().policy()).lockUpBlocks();
		blockNumber = blockNumber.add(block.number);
		setStorageWithdrawalStatus(_property, msg.sender, blockNumber);
	}

	/**
	 * Withdraw staking.
	 * Releases canceled staking and transfer the staked amount to the sender.
	 */
	function withdraw(address _property) external {
		/**
		 * Validates the target of staked is included Property set.
		 */
		addressValidator().validateGroup(_property, config().propertyGroup());

		/**
		 * Validates the block number reaches the block number where staking can be released.
		 */
		require(possible(_property, msg.sender), "waiting for release");

		/**
		 * Validates the sender is staking to the target Property.
		 */
		uint256 lockedUpValue = getStorageValue(_property, msg.sender);
		require(lockedUpValue != 0, "dev token is not locked");

		/**
		 * Since the increase of rewards will stop with the release of the staking,
		 * saves the undrawn withdrawable reward before releasing it.
		 */
		updatePendingInterestWithdrawal(_property, msg.sender);

		/**
		 * Transfer the staked amount to the sender.
		 */
		IProperty(_property).withdraw(msg.sender, lockedUpValue);

		/**
		 * Saves variables that should change due to the canceling staking..
		 */
		updateValues(false, msg.sender, _property, lockedUpValue);

		/**
		 * Sets the staked amount to 0.
		 */
		setStorageValue(_property, msg.sender, 0);

		/**
		 * Sets the cancellation status to not have.
		 */
		setStorageWithdrawalStatus(_property, msg.sender, 0);
	}

	/**
	 * Returns the current staking amount, and the block number in which the recorded last.
	 * These values are used to calculate the cumulative sum of the staking.
	 */
	function getCumulativeLockedUpUnitAndBlock(address _property)
		private
		view
		returns (uint256 _unit, uint256 _block)
	{
		/**
		 * Get the current staking amount and the last recorded block number from the `CumulativeLockedUpUnitAndBlock` storage.
		 * If the last recorded block number is not 0, it is returns as it is.
		 */
		(
			uint256 unit,
			uint256 lastBlock
		) = getStorageCumulativeLockedUpUnitAndBlock(_property);
		if (lastBlock > 0) {
			return (unit, lastBlock);
		}

		/**
		 * If the last recorded block number is 0, this function falls back as already staked before the current specs (before DIP4).
		 * More detail for DIP4: https://github.com/dev-protocol/DIPs/issues/4
		 *
		 * When the passed address is 0, the caller wants to know the total staking amount on the protocol,
		 * so gets the total staking amount from `AllValue` storage.
		 * When the address is other than 0, the caller wants to know the staking amount of a Property,
		 * so gets the staking amount from the `PropertyValue` storage.
		 */
		unit = _property == address(0)
			? getStorageAllValue()
			: getStoragePropertyValue(_property);

		/**
		 * Staking pre-DIP4 will be treated as staked simultaneously with the DIP4 release.
		 * Therefore, the last recorded block number is the same as the DIP4 release block.
		 */
		lastBlock = getStorageDIP4GenesisBlock();
		return (unit, lastBlock);
	}

	/**
	 * Returns the cumulative sum of the staking on passed address, the current staking amount,
	 * and the block number in which the recorded last.
	 * The latest cumulative sum can be calculated using the following formula:
	 * (current staking amount) * (current block number - last recorded block number) + (last cumulative sum)
	 */
	function getCumulativeLockedUp(address _property)
		public
		view
		returns (
			uint256 _value,
			uint256 _unit,
			uint256 _block
		)
	{
		/**
		 * Gets the current staking amount and the last recorded block number from the `getCumulativeLockedUpUnitAndBlock` function.
		 */
		(uint256 unit, uint256 lastBlock) = getCumulativeLockedUpUnitAndBlock(
			_property
		);

		/**
		 * Gets the last cumulative sum of the staking from `CumulativeLockedUpValue` storage.
		 */
		uint256 lastValue = getStorageCumulativeLockedUpValue(_property);

		/**
		 * Returns the latest cumulative sum, current staking amount as a unit, and last recorded block number.
		 */
		return (
			lastValue.add(unit.mul(block.number.sub(lastBlock))),
			unit,
			lastBlock
		);
	}

	/**
	 * Returns the cumulative sum of the staking on the protocol totally, the current staking amount,
	 * and the block number in which the recorded last.
	 */
	function getCumulativeLockedUpAll()
		public
		view
		returns (
			uint256 _value,
			uint256 _unit,
			uint256 _block
		)
	{
		/**
		 * If the 0 address is passed as a key, it indicates the entire protocol.
		 */
		return getCumulativeLockedUp(address(0));
	}

	/**
	 * Updates the `CumulativeLockedUpValue` and `CumulativeLockedUpUnitAndBlock` storage.
	 * This function expected to executes when the amount of staking as a unit changes.
	 */
	function updateCumulativeLockedUp(
		bool _addition,
		address _property,
		uint256 _unit
	) private {
		address zero = address(0);

		/**
		 * Gets the cumulative sum of the staking amount, staking amount, and last recorded block number for the passed Property address.
		 */
		(uint256 lastValue, uint256 lastUnit, ) = getCumulativeLockedUp(
			_property
		);

		/**
		 * Gets the cumulative sum of the staking amount, staking amount, and last recorded block number for the protocol total.
		 */
		(uint256 lastValueAll, uint256 lastUnitAll, ) = getCumulativeLockedUp(
			zero
		);

		/**
		 * Adds or subtracts the staking amount as a new unit to the cumulative sum of the staking for the passed Property address.
		 */
		setStorageCumulativeLockedUpValue(
			_property,
			_addition ? lastValue.add(_unit) : lastValue.sub(_unit)
		);

		/**
		 * Adds or subtracts the staking amount as a new unit to the cumulative sum of the staking for the protocol total.
		 */
		setStorageCumulativeLockedUpValue(
			zero,
			_addition ? lastValueAll.add(_unit) : lastValueAll.sub(_unit)
		);

		/**
		 * Adds or subtracts the staking amount to the staking unit for the passed Property address.
		 * Also, record the latest block number.
		 */
		setStorageCumulativeLockedUpUnitAndBlock(
			_property,
			_addition ? lastUnit.add(_unit) : lastUnit.sub(_unit),
			block.number
		);

		/**
		 * Adds or subtracts the staking amount to the staking unit for the protocol total.
		 * Also, record the latest block number.
		 */
		setStorageCumulativeLockedUpUnitAndBlock(
			zero,
			_addition ? lastUnitAll.add(_unit) : lastUnitAll.sub(_unit),
			block.number
		);
	}

	/**
	 * Updates cumulative sum of the maximum mint amount calculated by Allocator contract, the latest maximum mint amount per block,
	 * and the last recorded block number.
	 * The cumulative sum of the maximum mint amount is always added.
	 * By recording that value when the staker last stakes, the difference from the when the staker stakes can be calculated.
	 */
	function update() public {
		/**
		 * Gets the cumulative sum of the maximum mint amount and the maximum mint number per block.
		 */
		(uint256 _nextRewards, uint256 _amount) = dry();

		/**
		 * Records each value and the latest block number.
		 */
		setStorageCumulativeGlobalRewards(_nextRewards);
		setStorageLastSameRewardsAmountAndBlock(_amount, block.number);
	}

	/**
	 * Updates the cumulative sum of the maximum mint amount when staking, the cumulative sum of staker reward as an interest of the target Property
	 * and the cumulative staking amount, and the latest block number.
	 */
	function updateStatesAtLockup(
		address _property,
		address _user,
		uint256 _interest
	) private {
		/**
		 * Gets the cumulative sum of the maximum mint amount.
		 */
		(uint256 _reward, ) = dry();

		/**
		 * Records each value and the latest block number.
		 */
		if (isSingle(_property, _user)) {
			setStorageLastCumulativeGlobalReward(_property, _user, _reward);
		}
		setStorageLastCumulativePropertyInterest(_property, _user, _interest);
		(uint256 cLocked, , ) = getCumulativeLockedUp(_property);
		setStorageLastCumulativeLockedUpAndBlock(
			_property,
			_user,
			cLocked,
			block.number
		);
	}

	/**
	 * Returns the last cumulative staking amount of the passed Property address and the last recorded block number.
	 */
	function getLastCumulativeLockedUpAndBlock(address _property, address _user)
		private
		view
		returns (uint256 _cLocked, uint256 _block)
	{
		/**
		 * Gets the values from `LastCumulativeLockedUpAndBlock` storage.
		 */
		(
			uint256 cLocked,
			uint256 blockNumber
		) = getStorageLastCumulativeLockedUpAndBlock(_property, _user);

		/**
		 * When the last recorded block number is 0, the block number at the time of the DIP4 release is returned as being staked at the same time as the DIP4 release.
		 * More detail for DIP4: https://github.com/dev-protocol/DIPs/issues/4
		 */
		if (blockNumber == 0) {
			blockNumber = getStorageDIP4GenesisBlock();
		}
		return (cLocked, blockNumber);
	}

	/**
	 * Referring to the values recorded in each storage to returns the latest cumulative sum of the maximum mint amount and the latest maximum mint amount per block.
	 */
	function dry()
		private
		view
		returns (uint256 _nextRewards, uint256 _amount)
	{
		/**
		 * Gets the latest mint amount per block from Allocator contract.
		 */
		uint256 rewardsAmount = IAllocator(config().allocator())
			.calculateMaxRewardsPerBlock();

		/**
		 * Gets the maximum mint amount per block, and the last recorded block number from `LastSameRewardsAmountAndBlock` storage.
		 */
		(
			uint256 lastAmount,
			uint256 lastBlock
		) = getStorageLastSameRewardsAmountAndBlock();

		/**
		 * If the recorded maximum mint amount per block and the result of the Allocator contract are different,
		 * the result of the Allocator contract takes precedence as a maximum mint amount per block.
		 */
		uint256 lastMaxRewards = lastAmount == rewardsAmount
			? rewardsAmount
			: lastAmount;

		/**
		 * Calculates the difference between the latest block number and the last recorded block number.
		 */
		uint256 blocks = lastBlock > 0 ? block.number.sub(lastBlock) : 0;

		/**
		 * Adds the calculated new cumulative maximum mint amount to the recorded cumulative maximum mint amount.
		 */
		uint256 additionalRewards = lastMaxRewards.mul(blocks);
		uint256 nextRewards = getStorageCumulativeGlobalRewards().add(
			additionalRewards
		);

		/**
		 * Returns the latest theoretical cumulative sum of maximum mint amount and maximum mint amount per block.
		 */
		return (nextRewards, rewardsAmount);
	}

	/**
	 * Returns the latest theoretical cumulative sum of maximum mint amount, the holder's reward of the passed Property address and its unit price,
	 * and the staker's reward as interest and its unit price.
	 * The latest theoretical cumulative sum of maximum mint amount is got from `dry` function.
	 * The Holder's reward is a staking(delegation) reward received by the holder of the Property contract(token) according to the share.
	 * The unit price of the holder's reward is the reward obtained per 1 piece of Property contract(token).
	 * The staker rewards are rewards for staking users.
	 * The unit price of the staker reward is the reward per DEV token 1 piece that is staking.
	 */
	function difference(address _property, uint256 _lastReward)
		public
		view
		returns (
			uint256 _reward,
			uint256 _holdersAmount,
			uint256 _holdersPrice,
			uint256 _interestAmount,
			uint256 _interestPrice
		)
	{
		/**
		 * Gets the cumulative sum of the maximum mint amount.
		 */
		(uint256 rewards, ) = dry();

		/**
		 * Gets the cumulative sum of the staking amount of the passed Property address and
		 * the cumulative sum of the staking amount of the protocol total.
		 */
		(uint256 valuePerProperty, , ) = getCumulativeLockedUp(_property);
		(uint256 valueAll, , ) = getCumulativeLockedUpAll();

		/**
		 * Calculates the amount of reward that can be received by the Property from the ratio of the cumulative sum of the staking amount of the Property address
		 * and the cumulative sum of the staking amount of the protocol total.
		 * If the past cumulative sum of the maximum mint amount passed as the second argument is 1 or more,
		 * this result is the difference from that cumulative sum.
		 */
		uint256 propertyRewards = rewards.sub(_lastReward).mul(
			valuePerProperty.mulBasis().outOf(valueAll)
		);

		/**
		 * Gets the staking amount and total supply of the Property and calls `Policy.holdersShare` function to calculates
		 * the holder's reward amount out of the total reward amount.
		 */
		uint256 lockedUpPerProperty = getStoragePropertyValue(_property);
		uint256 totalSupply = ERC20Mintable(_property).totalSupply();
		uint256 holders = IPolicy(config().policy()).holdersShare(
			propertyRewards,
			lockedUpPerProperty
		);

		/**
		 * The total rewards amount minus the holder reward amount is the staker rewards as an interest.
		 */
		uint256 interest = propertyRewards.sub(holders);

		/**
		 * Returns each value and a unit price of each reward.
		 */
		return (
			rewards,
			holders,
			holders.div(totalSupply),
			interest,
			lockedUpPerProperty > 0 ? interest.div(lockedUpPerProperty) : 0
		);
	}

	/**
	 * Returns the staker reward as interest.
	 */
	function _calculateInterestAmount(address _property, address _user)
		private
		view
		returns (uint256)
	{
		/**
		 * Gets the cumulative sum of the staking amount, current staking amount, and last recorded block number of the Property.
		 */
		(
			uint256 cLockProperty,
			uint256 unit,
			uint256 lastBlock
		) = getCumulativeLockedUp(_property);

		/**
		 * Gets the cumulative sum of staking amount and block number of Property when the user staked.
		 */
		(
			uint256 lastCLocked,
			uint256 lastBlockUser
		) = getLastCumulativeLockedUpAndBlock(_property, _user);

		/**
		 * Get the amount the user is staking for the Property.
		 */
		uint256 lockedUpPerAccount = getStorageValue(_property, _user);

		/**
		 * Gets the cumulative sum of the Property's staker reward when the user staked.
		 */
		uint256 lastInterest = getStorageLastCumulativePropertyInterest(
			_property,
			_user
		);

		/**
		 * Calculates the cumulative sum of the staking amount from the time the user staked to the present.
		 * It can be calculated by multiplying the staking amount by the number of elapsed blocks.
		 */
		uint256 cLockUser = lockedUpPerAccount.mul(
			block.number.sub(lastBlockUser)
		);

		/**
		 * Determines if the user is the only staker to the Property.
		 */
		bool isOnly = unit == lockedUpPerAccount && lastBlock <= lastBlockUser;

		/**
		 * If the user is the Property's only staker and the first staker, and the only staker on the protocol:
		 */
		if (isSingle(_property, _user)) {
			/**
			 * Passing the cumulative sum of the maximum mint amount when staked, to the `difference` function,
			 * gets the staker reward amount that the user can receive from the time of staking to the present.
			 * In the case of the staking is single, the ratio of the Property and the user account for 100% of the cumulative sum of the maximum mint amount,
			 * so the difference cannot be calculated with the value of `LastCumulativePropertyInterest`.
			 * Therefore, it is necessary to calculate the difference using the cumulative sum of the maximum mint amounts at the time of staked.
			 */
			(, , , , uint256 interestPrice) = difference(
				_property,
				getStorageLastCumulativeGlobalReward(_property, _user)
			);

			/**
			 * Returns the result after adjusted decimals to 10^18.
			 */
			uint256 result = interestPrice
				.mul(lockedUpPerAccount)
				.divBasis()
				.divBasis();
			return result;

			/**
			 * If not the single but the only staker:
			 */
		} else if (isOnly) {
			/**
			 * Pass 0 to the `difference` function to gets the Property's cumulative sum of the staker reward.
			 */
			(, , , uint256 interest, ) = difference(_property, 0);

			/**
			 * Calculates the difference in rewards that can be received by subtracting the Property's cumulative sum of staker rewards at the time of staking.
			 */
			uint256 result = interest >= lastInterest
				? interest.sub(lastInterest).divBasis().divBasis()
				: 0;
			return result;
		}

		/**
		 * If the user is the Property's not the first staker and not the only staker:
		 */

		/**
		 * Pass 0 to the `difference` function to gets the Property's cumulative sum of the staker reward.
		 */
		(, , , uint256 interest, ) = difference(_property, 0);

		/**
		 * Calculates the share of rewards that can be received by the user among Property's staker rewards.
		 * "Cumulative sum of the staking amount of the Property at the time of staking" is subtracted from "cumulative sum of the staking amount of the Property",
		 * and calculates the cumulative sum of staking amounts from the time of staking to the present.
		 * The ratio of the "cumulative sum of staking amount from the time the user staked to the present" to that value is the share.
		 */
		uint256 share = cLockUser.outOf(cLockProperty.sub(lastCLocked));

		/**
		 * If the Property's staker reward is greater than the value of the `CumulativePropertyInterest` storage,
		 * calculates the difference and multiply by the share.
		 * Otherwise, it returns 0.
		 */
		uint256 result = interest >= lastInterest
			? interest
				.sub(lastInterest)
				.mul(share)
				.divBasis()
				.divBasis()
				.divBasis()
			: 0;
		return result;
	}

	/**
	 * Returns the total rewards currently available for withdrawal. (For calling from inside the contract)
	 */
	function _calculateWithdrawableInterestAmount(
		address _property,
		address _user
	) private view returns (uint256) {
		/**
		 * If the passed Property has not authenticated, returns always 0.
		 */
		if (
			IMetricsGroup(config().metricsGroup()).hasAssets(_property) == false
		) {
			return 0;
		}

		/**
		 * Gets the reward amount in saved without withdrawal.
		 */
		uint256 pending = getStoragePendingInterestWithdrawal(_property, _user);

		/**
		 * Gets the reward amount of before DIP4.
		 */
		uint256 legacy = __legacyWithdrawableInterestAmount(_property, _user);

		/**
		 * Gets the latest withdrawal reward amount.
		 */
		uint256 amount = _calculateInterestAmount(_property, _user);

		/**
		 * Returns the sum of all values.
		 */
		uint256 withdrawableAmount = amount
			.add(pending) // solium-disable-next-line indentation
			.add(legacy);
		return withdrawableAmount;
	}

	/**
	 * Returns the total rewards currently available for withdrawal. (For calling from external of the contract)
	 */
	function calculateWithdrawableInterestAmount(
		address _property,
		address _user
	) public view returns (uint256) {
		uint256 amount = _calculateWithdrawableInterestAmount(_property, _user);
		return amount;
	}

	/**
	 * Withdraws staking reward as an interest.
	 */
	function withdrawInterest(address _property) external {
		/**
		 * Validates the target of staking is included Property set.
		 */
		addressValidator().validateGroup(_property, config().propertyGroup());

		/**
		 * Gets the withdrawable amount.
		 */
		uint256 value = _calculateWithdrawableInterestAmount(
			_property,
			msg.sender
		);

		/**
		 * Gets the cumulative sum of staker rewards of the passed Property address.
		 */
		(, , , uint256 interest, ) = difference(_property, 0);

		/**
		 * Validates rewards amount there are 1 or more.
		 */
		require(value > 0, "your interest amount is 0");

		/**
		 * Sets the unwithdrawn reward amount to 0.
		 */
		setStoragePendingInterestWithdrawal(_property, msg.sender, 0);

		/**
		 * Creates a Dev token instance.
		 */
		ERC20Mintable erc20 = ERC20Mintable(config().token());

		/**
		 * Updates the staking status to avoid double rewards.
		 */
		updateStatesAtLockup(_property, msg.sender, interest);
		__updateLegacyWithdrawableInterestAmount(_property, msg.sender);

		/**
		 * Mints the reward.
		 */
		require(erc20.mint(msg.sender, value), "dev mint failed");

		/**
		 * Since the total supply of tokens has changed, updates the latest maximum mint amount.
		 */
		update();
	}

	/**
	 * Status updates with the addition or release of staking.
	 */
	function updateValues(
		bool _addition,
		address _account,
		address _property,
		uint256 _value
	) private {
		/**
		 * If added staking:
		 */
		if (_addition) {
			/**
			 * Updates the cumulative sum of the staking amount of the passed Property and the cumulative amount of the staking amount of the protocol total.
			 */
			updateCumulativeLockedUp(true, _property, _value);

			/**
			 * Updates the current staking amount of the protocol total.
			 */
			addAllValue(_value);

			/**
			 * Updates the current staking amount of the Property.
			 */
			addPropertyValue(_property, _value);

			/**
			 * Updates the user's current staking amount in the Property.
			 */
			addValue(_property, _account, _value);

			/**
			 * If released staking:
			 */
		} else {
			/**
			 * Updates the cumulative sum of the staking amount of the passed Property and the cumulative amount of the staking amount of the protocol total.
			 */
			updateCumulativeLockedUp(false, _property, _value);

			/**
			 * Updates the current staking amount of the protocol total.
			 */
			subAllValue(_value);

			/**
			 * Updates the current staking amount of the Property.
			 */
			subPropertyValue(_property, _value);
		}

		/**
		 * Since each staking amount has changed, updates the latest maximum mint amount.
		 */
		update();
	}

	/**
	 * Returns the staking amount of the protocol total.
	 */
	function getAllValue() external view returns (uint256) {
		return getStorageAllValue();
	}

	/**
	 * Adds the staking amount of the protocol total.
	 */
	function addAllValue(uint256 _value) private {
		uint256 value = getStorageAllValue();
		value = value.add(_value);
		setStorageAllValue(value);
	}

	/**
	 * Subtracts the staking amount of the protocol total.
	 */
	function subAllValue(uint256 _value) private {
		uint256 value = getStorageAllValue();
		value = value.sub(_value);
		setStorageAllValue(value);
	}

	/**
	 * Returns the user's staking amount in the Property.
	 */
	function getValue(address _property, address _sender)
		external
		view
		returns (uint256)
	{
		return getStorageValue(_property, _sender);
	}

	/**
	 * Adds the user's staking amount in the Property.
	 */
	function addValue(
		address _property,
		address _sender,
		uint256 _value
	) private {
		uint256 value = getStorageValue(_property, _sender);
		value = value.add(_value);
		setStorageValue(_property, _sender, value);
	}

	/**
	 * Returns whether the user is staking in the Property.
	 */
	function hasValue(address _property, address _sender)
		private
		view
		returns (bool)
	{
		uint256 value = getStorageValue(_property, _sender);
		return value != 0;
	}

	/**
	 * Returns whether a single user has all staking share.
	 * This value is true when only one Property and one user is historically the only staker.
	 */
	function isSingle(address _property, address _user)
		private
		view
		returns (bool)
	{
		uint256 perAccount = getStorageValue(_property, _user);
		(uint256 cLockProperty, uint256 unitProperty, ) = getCumulativeLockedUp(
			_property
		);
		(uint256 cLockTotal, , ) = getCumulativeLockedUpAll();
		return perAccount == unitProperty && cLockProperty == cLockTotal;
	}

	/**
	 * Returns the staking amount of the Property.
	 */
	function getPropertyValue(address _property)
		external
		view
		returns (uint256)
	{
		return getStoragePropertyValue(_property);
	}

	/**
	 * Adds the staking amount of the Property.
	 */
	function addPropertyValue(address _property, uint256 _value) private {
		uint256 value = getStoragePropertyValue(_property);
		value = value.add(_value);
		setStoragePropertyValue(_property, value);
	}

	/**
	 * Subtracts the staking amount of the Property.
	 */
	function subPropertyValue(address _property, uint256 _value) private {
		uint256 value = getStoragePropertyValue(_property);
		uint256 nextValue = value.sub(_value);
		setStoragePropertyValue(_property, nextValue);
	}

	/**
	 * Saves the latest reward amount as an undrawn amount.
	 */
	function updatePendingInterestWithdrawal(address _property, address _user)
		private
	{
		/**
		 * Gets the latest reward amount.
		 */
		uint256 withdrawableAmount = _calculateWithdrawableInterestAmount(
			_property,
			_user
		);

		/**
		 * Saves the amount to `PendingInterestWithdrawal` storage.
		 */
		setStoragePendingInterestWithdrawal(
			_property,
			_user,
			withdrawableAmount
		);

		/**
		 * Updates the reward amount of before DIP4 to prevent further addition it.
		 */
		__updateLegacyWithdrawableInterestAmount(_property, _user);
	}

	/**
	 * Returns whether the staking can be released.
	 */
	function possible(address _property, address _from)
		private
		view
		returns (bool)
	{
		uint256 blockNumber = getStorageWithdrawalStatus(_property, _from);
		if (blockNumber == 0) {
			return false;
		}
		if (blockNumber <= block.number) {
			return true;
		} else {
			if (IPolicy(config().policy()).lockUpBlocks() == 1) {
				return true;
			}
		}
		return false;
	}

	/**
	 * Returns the reward amount of the calculation model before DIP4.
	 * It can be calculated by subtracting "the last cumulative sum of reward unit price" from
	 * "the current cumulative sum of reward unit price," and multiplying by the staking amount.
	 */
	function __legacyWithdrawableInterestAmount(
		address _property,
		address _user
	) private view returns (uint256) {
		uint256 _last = getStorageLastInterestPrice(_property, _user);
		uint256 price = getStorageInterestPrice(_property);
		uint256 priceGap = price.sub(_last);
		uint256 lockedUpValue = getStorageValue(_property, _user);
		uint256 value = priceGap.mul(lockedUpValue);
		return value.divBasis();
	}

	/**
	 * Updates and treats the reward of before DIP4 as already received.
	 */
	function __updateLegacyWithdrawableInterestAmount(
		address _property,
		address _user
	) private {
		uint256 interestPrice = getStorageInterestPrice(_property);
		if (getStorageLastInterestPrice(_property, _user) != interestPrice) {
			setStorageLastInterestPrice(_property, _user, interestPrice);
		}
	}

	/**
	 * Updates the block number of the time of DIP4 release.
	 */
	function setDIP4GenesisBlock(uint256 _block) external onlyOwner {
		/**
		 * Validates the value is not set.
		 */
		require(getStorageDIP4GenesisBlock() == 0, "already set the value");

		/**
		 * Sets the value.
		 */
		setStorageDIP4GenesisBlock(_block);
	}
}

// File: contracts/src/dev/Dev.sol

pragma solidity ^0.5.0;

// prettier-ignore

// prettier-ignore

// prettier-ignore

/**
 * The contract used as the DEV token.
 * The DEV token is an ERC20 token used as the native token of the Dev Protocol.
 * The DEV token is created by migration from its predecessor, the MVP, legacy DEV token. For that reason, the initial supply is 0.
 * Also, mint will be performed based on the Allocator contract.
 * When authenticated a new asset by the Market contracts, DEV token is burned as fees.
 */
contract Dev is
	ERC20Detailed,
	ERC20Mintable,
	ERC20Burnable,
	UsingConfig,
	UsingValidator
{
	/**
	 * Initialize the passed address as AddressConfig address.
	 * The token name is `Dev`, the token symbol is `DEV`, and the decimals is 18.
	 */
	constructor(address _config)
		public
		ERC20Detailed("Dev", "DEV", 18)
		UsingConfig(_config)
	{}

	/**
	 * Staking DEV tokens.
	 * The transfer destination must always be included in the address set for Property tokens.
	 * This is because if the transfer destination is not a Property token, it is possible that the staked DEV token cannot be withdrawn.
	 */
	function deposit(address _to, uint256 _amount) external returns (bool) {
		require(transfer(_to, _amount), "dev transfer failed");
		lock(msg.sender, _to, _amount);
		return true;
	}

	/**
	 * Staking DEV tokens by an allowanced address.
	 * The transfer destination must always be included in the address set for Property tokens.
	 * This is because if the transfer destination is not a Property token, it is possible that the staked DEV token cannot be withdrawn.
	 */
	function depositFrom(
		address _from,
		address _to,
		uint256 _amount
	) external returns (bool) {
		require(transferFrom(_from, _to, _amount), "dev transferFrom failed");
		lock(_from, _to, _amount);
		return true;
	}

	/**
	 * Burn the DEV tokens as an authentication fee.
	 * Only Market contracts can execute this function.
	 */
	function fee(address _from, uint256 _amount) external returns (bool) {
		addressValidator().validateGroup(msg.sender, config().marketGroup());
		_burn(_from, _amount);
		return true;
	}

	/**
	 * Call `Lockup.lockup` to execute staking.
	 */
	function lock(
		address _from,
		address _to,
		uint256 _amount
	) private {
		Lockup(config().lockup()).lockup(_from, _to, _amount);
	}
}

// File: contracts/src/market/Market.sol

pragma solidity ^0.5.0;

/**
 * A user-proposable contract for authenticating and associating assets with Property.
 * A user deploys a contract that inherits IMarketBehavior and creates this Market contract with the MarketFactory contract.
 */
contract Market is UsingConfig, IMarket, UsingValidator {
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
		addressValidator().validateAddress(
			msg.sender,
			config().marketFactory()
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
		addressValidator().validateAddress(
			msg.sender,
			IProperty(_prop).author()
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
		address _prop = Metrics(_metrics).property();
		propertyValidation(_prop);
		_;
	}

	/**
	 * Activates this Market.
	 * Called from VoteCounter contract when passed the voting or from MarketFactory contract when the first Market is created.
	 */
	function toEnable() external {
		addressValidator().validateAddresses(
			msg.sender,
			config().marketFactory(),
			config().voteCounter()
		);
		enabled = true;
	}

	/**
	 * Bypass to IMarketBehavior.authenticate.
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
		uint256 len = bytes(_args1).length;
		require(len > 0, "id is required");

		return
			IMarketBehavior(behavior).authenticate(
				_prop,
				_args1,
				_args2,
				_args3,
				_args4,
				_args5,
				address(this),
				msg.sender
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
		addressValidator().validateAddress(msg.sender, behavior);
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
			Dev(config().token()).fee(sender, authenticationFee),
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
}

// File: contracts/src/market/IMarketGroup.sol

pragma solidity ^0.5.0;

contract IMarketGroup is IGroup {
	function getCount() external view returns (uint256);
}

// File: contracts/src/market/MarketFactory.sol

pragma solidity ^0.5.0;

/**
 * A factory contract that creates a new Market contract.
 */
contract MarketFactory is IMarketFactory, UsingConfig, UsingValidator {
	event Create(address indexed _from, address _market);

	/**
	 * Initialize the passed address as AddressConfig address.
	 */
	// solium-disable-next-line no-empty-blocks
	constructor(address _config) public UsingConfig(_config) {}

	/**
	 * Creates a new Market contract.
	 */
	function create(address _addr) external returns (address) {
		/**
		 * Validates the passed address is not 0 address.
		 */
		addressValidator().validateIllegalAddress(_addr);

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
}