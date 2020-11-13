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

// File: contracts/src/vote/VoteCounterStorage.sol

pragma solidity 0.5.17;


contract VoteCounterStorage is UsingStorage {
	// Already Vote Market
	function setStorageAlreadyVoteMarket(
		address _user,
		address _market,
		address _property
	) internal {
		bytes32 key = getStorageAlreadyVoteMarketKey(_user, _market, _property);
		eternalStorage().setBool(key, true);
	}

	function getStorageAlreadyVoteMarket(
		address _user,
		address _market,
		address _property
	) public view returns (bool) {
		bytes32 key = getStorageAlreadyVoteMarketKey(_user, _market, _property);
		return eternalStorage().getBool(key);
	}

	function getStorageAlreadyVoteMarketKey(
		address _user,
		address _market,
		address _property
	) private pure returns (bytes32) {
		return
			keccak256(
				abi.encodePacked(
					"_alreadyVoteMarket",
					_user,
					_market,
					_property
				)
			);
	}

	// Already Use Property
	function setStorageAlreadyUseProperty(
		address _user,
		address _property,
		uint256 _votingGroupIndex,
		bool _flg
	) internal {
		bytes32 key = getStorageAlreadyUsePropertyKey(
			_user,
			_property,
			_votingGroupIndex
		);
		eternalStorage().setBool(key, _flg);
	}

	function getStorageAlreadyUseProperty(
		address _user,
		address _property,
		uint256 _votingGroupIndex
	) public view returns (bool) {
		bytes32 key = getStorageAlreadyUsePropertyKey(
			_user,
			_property,
			_votingGroupIndex
		);
		return eternalStorage().getBool(key);
	}

	function getStorageAlreadyUsePropertyKey(
		address _user,
		address _property,
		uint256 _votingGroupIndex
	) private pure returns (bytes32) {
		return
			keccak256(
				abi.encodePacked(
					"_alreadyUseProperty",
					_user,
					_property,
					_votingGroupIndex
				)
			);
	}

	// Already Vote Policy
	function setStorageAlreadyVotePolicy(
		address _user,
		address _property,
		uint256 _votingGroupIndex,
		bool _flg
	) internal {
		bytes32 key = getStorageAlreadyVotePolicyKey(
			_user,
			_property,
			_votingGroupIndex
		);
		eternalStorage().setBool(key, _flg);
	}

	function getStorageAlreadyVotePolicy(
		address _user,
		address _property,
		uint256 _votingGroupIndex
	) public view returns (bool) {
		bytes32 key = getStorageAlreadyVotePolicyKey(
			_user,
			_property,
			_votingGroupIndex
		);
		return eternalStorage().getBool(key);
	}

	function getStorageAlreadyVotePolicyKey(
		address _user,
		address _property,
		uint256 _votingGroupIndex
	) private pure returns (bytes32) {
		return
			keccak256(
				abi.encodePacked(
					"_alreadyVotePolicy",
					_user,
					_property,
					_votingGroupIndex
				)
			);
	}

	// Policy Vote Count
	function setStoragePolicyVoteCount(
		address _user,
		address _policy,
		bool _agree,
		uint256 _count
	) internal {
		bytes32 key = getStoragePolicyVoteCountKey(_user, _policy, _agree);
		eternalStorage().setUint(key, _count);
	}

	function getStoragePolicyVoteCount(
		address _user,
		address _policy,
		bool _agree
	) public view returns (uint256) {
		bytes32 key = getStoragePolicyVoteCountKey(_user, _policy, _agree);
		return eternalStorage().getUint(key);
	}

	function getStoragePolicyVoteCountKey(
		address _user,
		address _policy,
		bool _agree
	) private pure returns (bytes32) {
		return
			keccak256(
				abi.encodePacked("_policyVoteCount", _user, _policy, _agree)
			);
	}

	// Agree Count
	function setStorageAgreeCount(address _sender, uint256 count) internal {
		eternalStorage().setUint(getStorageAgreeVoteCountKey(_sender), count);
	}

	function getStorageAgreeCount(address _sender)
		public
		view
		returns (uint256)
	{
		return eternalStorage().getUint(getStorageAgreeVoteCountKey(_sender));
	}

	function getStorageAgreeVoteCountKey(address _sender)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked(_sender, "_agreeVoteCount"));
	}

	// Opposite Count
	function setStorageOppositeCount(address _sender, uint256 count) internal {
		eternalStorage().setUint(
			getStorageOppositeVoteCountKey(_sender),
			count
		);
	}

	function getStorageOppositeCount(address _sender)
		public
		view
		returns (uint256)
	{
		return
			eternalStorage().getUint(getStorageOppositeVoteCountKey(_sender));
	}

	function getStorageOppositeVoteCountKey(address _sender)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked(_sender, "_oppositeVoteCount"));
	}
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

// File: contracts/src/lockup/ILockup.sol

pragma solidity 0.5.17;

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

	function calculateCumulativeRewardPrices()
		public
		view
		returns (
			uint256 _reward,
			uint256 _holders,
			uint256 _interest
		);

	function calculateCumulativeHoldersRewardAmount(address _property)
		public
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
	)
		public
		view
		returns (
			// solium-disable-next-line indentation
			uint256
		);

	function withdrawInterest(address _property) external;
}

// File: contracts/src/market/IMarket.sol

pragma solidity 0.5.17;

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

	function authenticateFromPropertyFactory(
		address _prop,
		address _author,
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

// File: contracts/src/vote/IVoteCounter.sol

pragma solidity 0.5.17;

contract IVoteCounter {
	function voteMarket(
		address _market,
		address _property,
		bool _agree
		// solium-disable-next-line indentation
	) external;

	function isAlreadyVoteMarket(address _target, address _property)
		external
		view
		returns (bool);

	function votePolicy(
		address _policy,
		address _property,
		bool _agree
		// solium-disable-next-line indentation
	) external;

	function cancelVotePolicy(address _policy, address _property) external;
}

// File: contracts/src/policy/IPolicyGroup.sol

pragma solidity 0.5.17;


contract IPolicyGroup is IGroup {
	function getVotingGroupIndex() external view returns (uint256);

	function incrementVotingGroupIndex() external;

	function voting(address _policy) external view returns (bool);

	function addGroupWithoutSetVotingEnd(address _addr) public;
}

// File: contracts/src/policy/IPolicyFactory.sol

pragma solidity 0.5.17;

contract IPolicyFactory {
	function create(address _newPolicyAddress) external;

	function convergePolicy(address _currentPolicyAddress) external;
}

// File: contracts/src/vote/VoteCounter.sol

pragma solidity 0.5.17;











/**
 * A contract that manages the activation votes for new markets and new policies.
 * Voting rights of voters are determined by the staking amount to a Property.
 * That is, at the voting, expecting to pass a Property address for specification the voting right.
 * Market voting is an election that selects out all that voters think is good.
 * Policy voting is an election to select one that seems to be the best with Quadratic Voting.
 * Quadratic Voting is realized by exercising multiple voting rights in Policy voting.
 */
contract VoteCounter is
	IVoteCounter,
	UsingConfig,
	UsingValidator,
	VoteCounterStorage
{
	using SafeMath for uint256;

	/**
	 * Initialize the passed address as AddressConfig address.
	 */
	// solium-disable-next-line no-empty-blocks
	constructor(address _config) public UsingConfig(_config) {}

	/**
	 * Votes for or against new Market
	 */
	function voteMarket(
		address _market,
		address _property,
		bool _agree
	) external {
		/**
		 * Validates the passed Market address is included the Market address set
		 */
		addressValidator().validateGroup(_market, config().marketGroup());

		/**
		 * Validates the passed Market is still not enabled
		 */
		IMarket market = IMarket(_market);
		require(market.enabled() == false, "market is already enabled");

		/**
		 * Validates the voting deadline has not passed.
		 */
		require(
			block.number <= market.votingEndBlockNumber(),
			"voting deadline is over"
		);

		/**
		 * Gets the staking amount for the passed Property as a voting right.
		 * If the voting right is 0, it cannot vote.
		 */
		uint256 count = ILockup(config().lockup()).getValue(
			_property,
			msg.sender
		);
		require(count != 0, "vote count is 0");

		/**
		 * Validates it does not become a double vote.
		 */
		bool alreadyVote = getStorageAlreadyVoteMarket(
			msg.sender,
			_market,
			_property
		);
		require(alreadyVote == false, "already vote");

		/**
		 * Votes
		 */
		vote(_market, count, _agree);

		/**
		 * Records voting status to avoid double voting.
		 */
		setStorageAlreadyVoteMarket(msg.sender, _market, _property);

		/**
		 * Gets the votes for and against and gets whether or not the threshold
		 * for enabling the Market is exceeded.
		 */
		bool result = IPolicy(config().policy()).marketApproval(
			getStorageAgreeCount(_market),
			getStorageOppositeCount(_market)
		);

		/**
		 * If the result is false, the process ends.
		 */
		if (result == false) {
			return;
		}

		/**
		 * If the result is true, to enable the passed Market.
		 */
		market.toEnable();
	}

	function isAlreadyVoteMarket(address _target, address _property)
		external
		view
		returns (bool)
	{
		return getStorageAlreadyVoteMarket(msg.sender, _target, _property);
	}

	/**
	 * Votes for or against new Policy
	 */
	function votePolicy(
		address _policy,
		address _property,
		bool _agree
	) external {
		/**
		 * Validates the passed Policy address is included the Policy address set
		 */
		addressValidator().validateGroup(_policy, config().policyGroup());

		/**
		 * Validates the passed Policy is not the current Policy.
		 */
		require(config().policy() != _policy, "this policy is current");

		/**
		 * Validates the voting deadline has not passed.
		 */
		IPolicyGroup policyGroup = IPolicyGroup(config().policyGroup());
		require(policyGroup.voting(_policy), "voting deadline is over");

		/**
		 * Validates it does not become a double vote.
		 * In a Policy vote, the Property used to vote for one of the Policies with the same voting period cannot be reused.
		 */
		uint256 votingGroupIndex = policyGroup.getVotingGroupIndex();
		bool alreadyVote = getStorageAlreadyUseProperty(
			msg.sender,
			_property,
			votingGroupIndex
		);
		require(alreadyVote == false, "already use property");

		/**
		 * Validates it does not become a double vote.
		 */
		alreadyVote = getStorageAlreadyVotePolicy(
			msg.sender,
			_policy,
			votingGroupIndex
		);
		require(alreadyVote == false, "already vote policy");

		/**
		 * Gets the staking amount for the passed Property as a voting right.
		 * If the voting right is 0, it cannot vote.
		 */
		uint256 count = ILockup(config().lockup()).getValue(
			_property,
			msg.sender
		);
		require(count != 0, "vote count is 0");

		/**
		 * Votes
		 */
		vote(_policy, count, _agree);

		/**
		 * Records voting status to avoid double voting.
		 */
		setStorageAlreadyUseProperty(
			msg.sender,
			_property,
			votingGroupIndex,
			true
		);
		setStorageAlreadyVotePolicy(
			msg.sender,
			_policy,
			votingGroupIndex,
			true
		);

		/**
		 * Records the used number of voting rights.
		 * The Policy vote is an election to select one, so voters can cancel an existing vote if voters think a later Policy is better.
		 */
		setStoragePolicyVoteCount(msg.sender, _policy, _agree, count);

		/**
		 * Gets the votes for and against and gets whether or not the threshold
		 * for enabling the Policy is exceeded.
		 */
		bool result = IPolicy(config().policy()).policyApproval(
			getStorageAgreeCount(_policy),
			getStorageOppositeCount(_policy)
		);

		/**
		 * If the result is false, the process ends.
		 */
		if (result == false) {
			return;
		}

		/**
		 * If the result is true, to enable the passed Policy.
		 */
		IPolicyFactory policyFactory = IPolicyFactory(config().policyFactory());
		policyFactory.convergePolicy(_policy);
	}

	/**
	 * Cancel voting for Policy
	 */
	function cancelVotePolicy(address _policy, address _property) external {
		/**
		 * Validates the passed Policy has already been voted using the passed Property.
		 */
		IPolicyGroup policyGroup = IPolicyGroup(config().policyGroup());
		uint256 votingGroupIndex = policyGroup.getVotingGroupIndex();
		bool alreadyVote = getStorageAlreadyUseProperty(
			msg.sender,
			_property,
			votingGroupIndex
		);
		require(alreadyVote, "not use property");

		/**
		 * Validates the passed Policy has already been voted.
		 */
		alreadyVote = getStorageAlreadyVotePolicy(
			msg.sender,
			_policy,
			votingGroupIndex
		);
		require(alreadyVote, "not vote policy");

		/**
		 * Gets the number of for or against votes the sender has voted.
		 */
		bool agree = true;
		uint256 count = getStoragePolicyVoteCount(msg.sender, _policy, agree);
		if (count == 0) {
			agree = false;
			count = getStoragePolicyVoteCount(msg.sender, _policy, agree);

			/**
			 * Validates the voting rights are not 0.
			 */
			require(count != 0, "not vote policy");
		}

		/**
		 * Subtracts the exercised voting rights to cancel the vote.
		 */
		cancelVote(_policy, count, agree);

		/**
		 * Sets the exercised voting rights to 0.
		 */
		setStoragePolicyVoteCount(msg.sender, _policy, agree, 0);

		/**
		 * Deletes a Property as voting rights and the exercise record.
		 */
		setStorageAlreadyUseProperty(
			msg.sender,
			_property,
			votingGroupIndex,
			false
		);
		setStorageAlreadyVotePolicy(
			msg.sender,
			_policy,
			votingGroupIndex,
			false
		);
	}

	/**
	 * Exercises voting rights.
	 */
	function vote(
		address _target,
		uint256 count,
		bool _agree
	) private {
		if (_agree) {
			/**
			 * For:
			 */
			addAgreeCount(_target, count);
		} else {
			/**
			 * Against:
			 */
			addOppositeCount(_target, count);
		}
	}

	/**
	 * Subtracts the exercised voting rights to cancel the vote.
	 */
	function cancelVote(
		address _target,
		uint256 count,
		bool _agree
	) private {
		if (_agree) {
			/**
			 * Cancel the yes:
			 */
			subAgreeCount(_target, count);
		} else {
			/**
			 * Cancel the against:
			 */
			subOppositeCount(_target, count);
		}
	}

	/**
	 * Adds voting rights exercised as for.
	 */
	function addAgreeCount(address _target, uint256 _voteCount) private {
		uint256 agreeCount = getStorageAgreeCount(_target);
		agreeCount = agreeCount.add(_voteCount);
		setStorageAgreeCount(_target, agreeCount);
	}

	/**
	 * Adds voting rights exercised as against.
	 */
	function addOppositeCount(address _target, uint256 _voteCount) private {
		uint256 oppositeCount = getStorageOppositeCount(_target);
		oppositeCount = oppositeCount.add(_voteCount);
		setStorageOppositeCount(_target, oppositeCount);
	}

	/**
	 * Subtracts voting rights exercised as for.
	 */
	function subAgreeCount(address _target, uint256 _voteCount) private {
		uint256 agreeCount = getStorageAgreeCount(_target);
		agreeCount = agreeCount.sub(_voteCount);
		setStorageAgreeCount(_target, agreeCount);
	}

	/**
	 * Subtracts voting rights exercised as against.
	 */
	function subOppositeCount(address _target, uint256 _voteCount) private {
		uint256 oppositeCount = getStorageOppositeCount(_target);
		oppositeCount = oppositeCount.sub(_voteCount);
		setStorageOppositeCount(_target, oppositeCount);
	}
}