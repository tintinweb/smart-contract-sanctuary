/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

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

// File: contracts/src/common/libs/Decimals.sol

pragma solidity 0.5.17;


/**
 * Library for emulating calculations involving decimals.
 */
library Decimals {
	using SafeMath for uint256;
	uint120 private constant BASIS_VAKUE = 1000000000000000000;

	/**
	 * @dev Returns the ratio of the first argument to the second argument.
	 * @param _a Numerator.
	 * @param _b Fraction.
	 * @return Calculated ratio.
	 */
	function outOf(uint256 _a, uint256 _b)
		internal
		pure
		returns (uint256 result)
	{
		if (_a == 0) {
			return 0;
		}
		uint256 a = _a.mul(BASIS_VAKUE);
		if (a < _b) {
			return 0;
		}
		return (a.div(_b));
	}

	/**
	 * @dev Returns multiplied the number by 10^18.
	 * @param _a Numerical value to be multiplied.
	 * @return Multiplied value.
	 */
	function mulBasis(uint256 _a) internal pure returns (uint256) {
		return _a.mul(BASIS_VAKUE);
	}

	/**
	 * @dev Returns divisioned the number by 10^18.
	 * This function can use it to restore the number of digits in the result of `outOf`.
	 * @param _a Numerical value to be divisioned.
	 * @return Divisioned value.
	 */
	function divBasis(uint256 _a) internal pure returns (uint256) {
		return _a.div(BASIS_VAKUE);
	}
}

// File: contracts/interface/IAddressConfig.sol

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

// File: contracts/src/common/config/UsingConfig.sol

pragma solidity 0.5.17;


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

// File: contracts/interface/IUsingStorage.sol

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IUsingStorage {
	function getStorageAddress() external view returns (address);

	function createStorage() external;

	function setStorage(address _storageAddress) external;

	function changeOwner(address newOwner) external;
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
contract UsingStorage is Ownable, IUsingStorage {
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

// File: contracts/src/withdraw/WithdrawStorage.sol

pragma solidity 0.5.17;


contract WithdrawStorage is UsingStorage {
	// RewardsAmount
	function setRewardsAmount(address _property, uint256 _value) internal {
		eternalStorage().setUint(getRewardsAmountKey(_property), _value);
	}

	function getRewardsAmount(address _property) public view returns (uint256) {
		return eternalStorage().getUint(getRewardsAmountKey(_property));
	}

	function getRewardsAmountKey(address _property)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("_rewardsAmount", _property));
	}

	// CumulativePrice
	function setCumulativePrice(address _property, uint256 _value) internal {
		// The previously used function
		// This function is only used in testing
		eternalStorage().setUint(getCumulativePriceKey(_property), _value);
	}

	function getCumulativePrice(address _property)
		public
		view
		returns (uint256)
	{
		return eternalStorage().getUint(getCumulativePriceKey(_property));
	}

	function getCumulativePriceKey(address _property)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("_cumulativePrice", _property));
	}

	//LastWithdrawalPrice
	function setLastWithdrawalPrice(
		address _property,
		address _user,
		uint256 _value
	) internal {
		eternalStorage().setUint(
			getLastWithdrawalPriceKey(_property, _user),
			_value
		);
	}

	function getLastWithdrawalPrice(address _property, address _user)
		public
		view
		returns (uint256)
	{
		return
			eternalStorage().getUint(
				getLastWithdrawalPriceKey(_property, _user)
			);
	}

	function getLastWithdrawalPriceKey(address _property, address _user)
		private
		pure
		returns (bytes32)
	{
		return
			keccak256(
				abi.encodePacked("_lastWithdrawalPrice", _property, _user)
			);
	}

	//PendingWithdrawal
	function setPendingWithdrawal(
		address _property,
		address _user,
		uint256 _value
	) internal {
		eternalStorage().setUint(
			getPendingWithdrawalKey(_property, _user),
			_value
		);
	}

	function getPendingWithdrawal(address _property, address _user)
		public
		view
		returns (uint256)
	{
		return
			eternalStorage().getUint(getPendingWithdrawalKey(_property, _user));
	}

	function getPendingWithdrawalKey(address _property, address _user)
		private
		pure
		returns (bytes32)
	{
		return
			keccak256(abi.encodePacked("_pendingWithdrawal", _property, _user));
	}

	//lastWithdrawnReward
	function setStorageLastWithdrawnReward(
		address _property,
		address _user,
		uint256 _value
	) internal {
		eternalStorage().setUint(
			getStorageLastWithdrawnRewardKey(_property, _user),
			_value
		);
	}

	function getStorageLastWithdrawnReward(address _property, address _user)
		public
		view
		returns (uint256)
	{
		return
			eternalStorage().getUint(
				getStorageLastWithdrawnRewardKey(_property, _user)
			);
	}

	function getStorageLastWithdrawnRewardKey(address _property, address _user)
		private
		pure
		returns (bytes32)
	{
		return
			keccak256(
				abi.encodePacked("_lastWithdrawnReward", _property, _user)
			);
	}
}

// File: contracts/interface/IDevMinter.sol

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IDevMinter {
	function mint(address account, uint256 amount) external returns (bool);

	function renounceMinter() external;
}

// File: contracts/interface/IWithdraw.sol

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IWithdraw {
	function withdraw(address _property) external;

	function getRewardsAmount(address _property)
		external
		view
		returns (uint256);

	function beforeBalanceChange(
		address _property,
		address _from,
		address _to
	) external;

	function calculateWithdrawableAmount(address _property, address _user)
		external
		view
		returns (uint256);

	function devMinter() external view returns (address);
}

// File: contracts/interface/ILockup.sol

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface ILockup {
	function lockup(
		address _from,
		address _property,
		uint256 _value
	) external;

	function update() external;

	function withdraw(address _property, uint256 _amount) external;

	function calculateCumulativeRewardPrices()
		external
		view
		returns (
			uint256 _reward,
			uint256 _holders,
			uint256 _interest
		);

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

	function devMinter() external view returns (address);
}

// File: contracts/interface/IMetricsGroup.sol

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
}

// File: contracts/interface/IPropertyGroup.sol

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IPropertyGroup {
	function addGroup(address _addr) external;

	function isGroup(address _addr) external view returns (bool);
}

// File: contracts/src/withdraw/Withdraw.sol

pragma solidity 0.5.17;

// prettier-ignore










/**
 * A contract that manages the withdrawal of holder rewards for Property holders.
 */
contract Withdraw is IWithdraw, UsingConfig, WithdrawStorage {
	using SafeMath for uint256;
	using Decimals for uint256;
	address public devMinter;
	event PropertyTransfer(address _property, address _from, address _to);

	/**
	 * Initialize the passed address as AddressConfig address.
	 */
	constructor(address _config, address _devMinter)
		public
		UsingConfig(_config)
	{
		devMinter = _devMinter;
	}

	/**
	 * Withdraws rewards.
	 */
	function withdraw(address _property) external {
		/**
		 * Validate
		 * the passed Property address is included the Property address set.
		 */
		require(
			IPropertyGroup(config().propertyGroup()).isGroup(_property),
			"this is illegal address"
		);

		/**
		 * Gets the withdrawable rewards amount and the latest cumulative sum of the maximum mint amount.
		 */
		(uint256 value, uint256 lastPrice) =
			_calculateWithdrawableAmount(_property, msg.sender);

		/**
		 * Validates the result is not 0.
		 */
		require(value != 0, "withdraw value is 0");

		/**
		 * Saves the latest cumulative sum of the holder reward price.
		 * By subtracting this value when calculating the next rewards, always withdrawal the difference from the previous time.
		 */
		setStorageLastWithdrawnReward(_property, msg.sender, lastPrice);

		/**
		 * Sets the number of unwithdrawn rewards to 0.
		 */
		setPendingWithdrawal(_property, msg.sender, 0);

		/**
		 * Updates the withdrawal status to avoid double withdrawal for before DIP4.
		 */
		__updateLegacyWithdrawableAmount(_property, msg.sender);

		/**
		 * Mints the holder reward.
		 */
		require(
			IDevMinter(devMinter).mint(msg.sender, value),
			"dev mint failed"
		);

		/**
		 * Since the total supply of tokens has changed, updates the latest maximum mint amount.
		 */
		ILockup lockup = ILockup(config().lockup());
		lockup.update();

		/**
		 * Adds the reward amount already withdrawn in the passed Property.
		 */
		setRewardsAmount(_property, getRewardsAmount(_property).add(value));
	}

	/**
	 * Updates the change in compensation amount due to the change in the ownership ratio of the passed Property.
	 * When the ownership ratio of Property changes, the reward that the Property holder can withdraw will change.
	 * It is necessary to update the status before and after the ownership ratio changes.
	 */
	function beforeBalanceChange(
		address _property,
		address _from,
		address _to
	) external {
		/**
		 * Validates the sender is Allocator contract.
		 */
		require(msg.sender == config().allocator(), "this is illegal address");

		/**
		 * Gets the cumulative sum of the transfer source's "before transfer" withdrawable reward amount and the cumulative sum of the maximum mint amount.
		 */
		(uint256 amountFrom, uint256 priceFrom) =
			_calculateAmount(_property, _from);

		/**
		 * Gets the cumulative sum of the transfer destination's "before receive" withdrawable reward amount and the cumulative sum of the maximum mint amount.
		 */
		(uint256 amountTo, uint256 priceTo) = _calculateAmount(_property, _to);

		/**
		 * Updates the last cumulative sum of the maximum mint amount of the transfer source and destination.
		 */
		setStorageLastWithdrawnReward(_property, _from, priceFrom);
		setStorageLastWithdrawnReward(_property, _to, priceTo);

		/**
		 * Gets the unwithdrawn reward amount of the transfer source and destination.
		 */
		uint256 pendFrom = getPendingWithdrawal(_property, _from);
		uint256 pendTo = getPendingWithdrawal(_property, _to);

		/**
		 * Adds the undrawn reward amount of the transfer source and destination.
		 */
		setPendingWithdrawal(_property, _from, pendFrom.add(amountFrom));
		setPendingWithdrawal(_property, _to, pendTo.add(amountTo));

		emit PropertyTransfer(_property, _from, _to);
	}

	/**
	 * Returns the holder reward.
	 */
	function _calculateAmount(address _property, address _user)
		private
		view
		returns (uint256 _amount, uint256 _price)
	{
		ILockup lockup = ILockup(config().lockup());
		IERC20 property = IERC20(_property);

		/**
		 * Gets the latest cumulative sum of the holder reward.
		 */
		uint256 reward =
			lockup.calculateCumulativeHoldersRewardAmount(_property);

		/**
		 * Gets the cumulative sum of the holder reward price recorded the last time you withdrew.
		 */
		uint256 _lastReward = getStorageLastWithdrawnReward(_property, _user);

		uint256 balance = property.balanceOf(_user);
		uint256 totalSupply = property.totalSupply();
		uint256 unitPrice = reward.sub(_lastReward).mulBasis().div(totalSupply);

		uint256 value = unitPrice.mul(balance).divBasis().divBasis();

		/**
		 * Returns the result after adjusted decimals to 10^18, and the latest cumulative sum of the holder reward price.
		 */
		return (value, reward);
	}

	/**
	 * Returns the total rewards currently available for withdrawal. (For calling from inside the contract)
	 */
	function _calculateWithdrawableAmount(address _property, address _user)
		private
		view
		returns (uint256 _amount, uint256 _price)
	{
		/**
		 * Gets the latest withdrawal reward amount.
		 */
		(uint256 _value, uint256 price) = _calculateAmount(_property, _user);

		/**
		 * If the passed Property has not authenticated, returns always 0.
		 */
		if (
			IMetricsGroup(config().metricsGroup()).hasAssets(_property) == false
		) {
			return (0, price);
		}

		/**
		 * Gets the reward amount of before DIP4.
		 */
		uint256 legacy = __legacyWithdrawableAmount(_property, _user);

		/**
		 * Gets the reward amount in saved without withdrawal and returns the sum of all values.
		 */
		uint256 value =
			_value.add(getPendingWithdrawal(_property, _user)).add(legacy);
		return (value, price);
	}

	/**
	 * Returns the total rewards currently available for withdrawal. (For calling from external of the contract)
	 */
	function calculateWithdrawableAmount(address _property, address _user)
		external
		view
		returns (uint256)
	{
		(uint256 value, ) = _calculateWithdrawableAmount(_property, _user);
		return value;
	}

	/**
	 * Returns the reward amount of the calculation model before DIP4.
	 * It can be calculated by subtracting "the last cumulative sum of reward unit price" from
	 * "the current cumulative sum of reward unit price," and multiplying by the balance of the user.
	 */
	function __legacyWithdrawableAmount(address _property, address _user)
		private
		view
		returns (uint256)
	{
		uint256 _last = getLastWithdrawalPrice(_property, _user);
		uint256 price = getCumulativePrice(_property);
		uint256 priceGap = price.sub(_last);
		uint256 balance = IERC20(_property).balanceOf(_user);
		uint256 value = priceGap.mul(balance);
		return value.divBasis();
	}

	/**
	 * Updates and treats the reward of before DIP4 as already received.
	 */
	function __updateLegacyWithdrawableAmount(address _property, address _user)
		private
	{
		uint256 price = getCumulativePrice(_property);
		setLastWithdrawalPrice(_property, _user, price);
	}
}