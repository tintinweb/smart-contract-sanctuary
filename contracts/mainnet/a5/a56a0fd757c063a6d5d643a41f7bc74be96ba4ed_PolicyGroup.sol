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

// File: contracts/src/common/lifecycle/Killable.sol

pragma solidity 0.5.17;

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

// File: contracts/src/common/interface/IGroup.sol

pragma solidity 0.5.17;

contract IGroup {
	function isGroup(address _addr) public view returns (bool);

	function addGroup(address _addr) external;

	function getGroupKey(address _addr) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked("_group", _addr));
	}
}

// File: contracts/src/common/validate/AddressValidator.sol

pragma solidity 0.5.17;


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

pragma solidity 0.5.17;

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

pragma solidity 0.5.17;




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

pragma solidity 0.5.17;


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

// File: contracts/src/common/storage/EternalStorage.sol

pragma solidity 0.5.17;

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

pragma solidity 0.5.17;



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

// File: contracts/src/policy/IPolicyGroup.sol

pragma solidity 0.5.17;


contract IPolicyGroup is IGroup {
	function getVotingGroupIndex() external view returns (uint256);

	function incrementVotingGroupIndex() external;

	function voting(address _policy) external view returns (bool);

	function addGroupWithoutSetVotingEnd(address _addr) public;
}

// File: contracts/src/policy/IPolicy.sol

pragma solidity 0.5.17;

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

// File: contracts/src/policy/PolicyGroup.sol

pragma solidity 0.5.17;







contract PolicyGroup is
	UsingConfig,
	UsingStorage,
	UsingValidator,
	IPolicyGroup
{
	using SafeMath for uint256;

	// solium-disable-next-line no-empty-blocks
	constructor(address _config) public UsingConfig(_config) {}

	function addGroup(address _addr) external {
		addGroupWithoutSetVotingEnd(_addr);
		/**
		 * Resets the voting period because a new Policy has been added.
		 */
		setVotingEndBlockNumber(_addr);
	}

	function addGroupWithoutSetVotingEnd(address _addr) public {
		addressValidator().validateAddress(
			msg.sender,
			config().policyFactory()
		);

		require(isGroup(_addr) == false, "already group");
		eternalStorage().setBool(getPolicyGroupKey(_addr), true);
	}

	function incrementVotingGroupIndex() external {
		addressValidator().validateAddress(
			msg.sender,
			config().policyFactory()
		);

		bytes32 key = getVotingGroupIndexKey();
		uint256 idx = eternalStorage().getUint(key);
		idx++;
		eternalStorage().setUint(key, idx);
	}

	function addGroupOwner(address _addr) external onlyOwner {
		require(isGroup(_addr) == false, "already group");
		eternalStorage().setBool(getPolicyGroupKey(_addr), true);
	}

	function isGroup(address _addr) public view returns (bool) {
		return eternalStorage().getBool(getPolicyGroupKey(_addr));
	}

	function getVotingGroupIndex() public view returns (uint256) {
		bytes32 key = getVotingGroupIndexKey();
		return eternalStorage().getUint(key);
	}

	function voting(address _policy) external view returns (bool) {
		bytes32 key = getVotingEndBlockNumberKey(_policy);
		uint256 limit = eternalStorage().getUint(key);
		return block.number <= limit;
	}

	function setVotingEndBlockNumber(address _policy) private {
		bytes32 key = getVotingEndBlockNumberKey(_policy);
		uint256 tmp = IPolicy(config().policy()).policyVotingBlocks();
		uint256 votingEndBlockNumber = block.number.add(tmp);
		eternalStorage().setUint(key, votingEndBlockNumber);
	}

	function getVotingGroupIndexKey() private pure returns (bytes32) {
		return keccak256(abi.encodePacked("_votingGroupIndex"));
	}

	function getPolicyGroupKey(address _addr) private view returns (bytes32) {
		uint256 idx = getVotingGroupIndex();
		return keccak256(abi.encodePacked("_group", idx, _addr));
	}

	function getVotingEndBlockNumberKey(address _policy)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("_votingEndBlockNumber", _policy));
	}
}