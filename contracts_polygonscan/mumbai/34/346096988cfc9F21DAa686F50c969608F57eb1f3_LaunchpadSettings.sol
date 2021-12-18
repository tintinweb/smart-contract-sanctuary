// SPDX-License-Identifier: MIT

/**
 * @title Settings of EnergyFi launchpad enviroment
 * @dev This contract holds variables with getter and setter to manage general settings of the launchpads.
 * The core is to manage fees, fee receiver, launchpad length limitations, allowed referrers and early
 * access token to participate on round 1. The values can only be changed by the contract owner.
 */

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ILaunchpadSettings.sol";

contract LaunchpadSettings is ILaunchpadSettings, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // holding all launchpad settings parameter
    struct Settings {
        uint256 tokenFee; // fee charged on base and sale token to dev address in parts per 1000
        uint256 referralFee; // fee charged on base and sale token fees to referral address in parts per 1000
        address payable baseFeeReceiver; // address to send the base token fee to
        address payable tokenFeeReceiver; // address to send the sale token fee to
        uint256 creationFee; // absolute fee in BNB used by generator on launchpad creation
        uint256 round1Length; // the duration of round 1 in seconds
        uint256 maxLaunchpadLength; // maximum duration of launchpad in seconds
    }

    // holds addresses allowed to receive referral fee
    EnumerableSet.AddressSet private ALLOWED_REFERRERS;

    // set of tokens allowing early access (round1 purchase)
    EnumerableSet.AddressSet private EARLY_ACCESS_TOKENS;
    // specifing the amount of early acces token to be held by a user
    // EARLY_ACCESS_TOKEN => REQUIRED HOLDING AMOUNT
    mapping(address => uint256) public EARLY_ACCESS_AMOUNTS;

    // holding all launchpad settings parameter
    Settings public settings;

    /**
     * @dev Sets initial settings for launchpads
     */
    constructor() public {
        settings.tokenFee = 100; // 1.8%
        settings.referralFee = 200; // 20%
        settings.creationFee = 5e17; // 0.5 BNB
        settings.baseFeeReceiver = msg.sender;
        settings.tokenFeeReceiver = msg.sender;
        settings.round1Length = 7200; // 7,200 seconds = 2 hours
        settings.maxLaunchpadLength = 1209600; // 1,209,600 seconds = 2 weeks
    }

    /*---------------------------------------------------------------------------------------------
     * --------------------------------------Setter functions--------------------------------------
     */

    /**
     * @notice edits the list of allowed referrers by owner. Referrers can be added to or removed from
     * the allowed referrers list.
     * @dev referrers are checked in create function of generator
     * @param _referrer address of the referrer to be changed
     * @param _allow bool if the referrer should be added to (=true) or removed from (=false) the list
     */
    function editAllowedReferrers(address payable _referrer, bool _allow)
        external
        onlyOwner
    {
        if (_allow) {
            ALLOWED_REFERRERS.add(_referrer);
        } else {
            ALLOWED_REFERRERS.remove(_referrer);
        }
    }

    /**
     * @notice edits the list of early access tokens by owner.
     * @param _token address of the token to be changed for early access
     * @param _holdAmount the minimum amount of early acces token hold by user for early access
     * @param _allow bool if the token should be added to (=true) or removed from (=false) the list
     */
    function editEarlyAccessTokens(
        address _token,
        uint256 _holdAmount,
        bool _allow
    ) external onlyOwner {
        if (_allow) {
            EARLY_ACCESS_TOKENS.add(_token);
        } else {
            EARLY_ACCESS_TOKENS.remove(_token);
        }
        EARLY_ACCESS_AMOUNTS[_token] = _holdAmount;
    }

    /**
     * @notice sets the fee receiver addresses for base token and sale token fees
     * @param _baseFeeReceiver address of the base token fee receiver
     * @param _tokenFeeReceiver address of the sale token fee receiver
     */
    function setFeeAddresses(
        address payable _baseFeeReceiver,
        address payable _tokenFeeReceiver
    ) external onlyOwner {
        settings.baseFeeReceiver = _baseFeeReceiver;
        settings.tokenFeeReceiver = _tokenFeeReceiver;
    }

    /**
     * @notice sets the fees for the launchpad by owner
     * @param _tokenFee relative fee charged on base and sale tokens in parts per 1000
     * @param _creationFee absolute fee in BNB charged on launchpad creation
     * @param _referralFee relative fee charged on base and sale tokens fee in parts per 1000
     */
    function setFees(
        uint256 _tokenFee,
        uint256 _creationFee,
        uint256 _referralFee
    ) external onlyOwner {
        settings.tokenFee = _tokenFee;
        settings.referralFee = _referralFee;
        settings.creationFee = _creationFee;
    }

    /**
     * @notice sets the maximum duration of a launchpad by owner
     * @param _maxLength duration in seconds (difference between start and end time)
     */
    function setMaxLaunchpadLength(uint256 _maxLength) external onlyOwner {
        settings.maxLaunchpadLength = _maxLength;
    }

    /**
     * @notice set the duration of round 1 by owner
     * @param _round1Length the duration of round 1 in seconds
     */
    function setRound1Length(uint256 _round1Length) external onlyOwner {
        settings.round1Length = _round1Length;
    }

    /*---------------------------------------------------------------------------------------------
     * --------------------------------------Getter functions--------------------------------------
     */

    /**
     * @notice returns total amount of allowed referrers
     */
    function allowedReferrersLength() external view returns (uint256) {
        return ALLOWED_REFERRERS.length();
    }

    /**
     * @notice returns total amount registered early access tokens
     */
    function earlyAccessTokensLength() public view returns (uint256) {
        return EARLY_ACCESS_TOKENS.length();
    }

    /**
     * @notice returns the address of the base fee receiver
     */
    function getBaseFeeReceiver()
        external
        view
        override
        returns (address payable)
    {
        return settings.baseFeeReceiver;
    }

    /**
     * @notice returns the absolute fee in BNB for launchpad creation
     */
    function getBnbCreationFee() external view override returns (uint256) {
        return settings.creationFee;
    }

    /**
     * @notice returns the address and holding amount of the early access token at given index
     * @param _index  position of the early access token in the EARLY_ACCESS_TOKENS set
     */
    function getEarlyAccessTokenAtIndex(uint256 _index)
        public
        view
        returns (address, uint256)
    {
        address tokenAddress = EARLY_ACCESS_TOKENS.at(_index);
        return (tokenAddress, EARLY_ACCESS_AMOUNTS[tokenAddress]);
    }

    /**
     * @notice returns the maximum duration of a launchpad in seconds
     */
    function getMaxLaunchpadLength() external view override returns (uint256) {
        return settings.maxLaunchpadLength;
    }

    /**
     * @notice returns the relative referral fee charged on base and sale token fee in parts per 1000
     */
    function getReferralFee() external view override returns (uint256) {
        return settings.referralFee;
    }

    /**
     * @notice returns the address of the referrer at a given index
     * @param _index position of the referrer in the ALLOWED_REFERRERS set
     */
    function getReferrerAtIndex(uint256 _index)
        external
        view
        returns (address)
    {
        return ALLOWED_REFERRERS.at(_index);
    }

    /**
     * @notice returns the duration of round 1 in seconds
     */
    function getRound1Length() external view override returns (uint256) {
        return settings.round1Length;
    }

    /**
     * @notice returns the sale token fee receiver address
     */
    function getSaleFeeReceiver()
        external
        view
        override
        returns (address payable)
    {
        return settings.tokenFeeReceiver;
    }

    /**
     * @notice returns the relative sale token fee in parts per 1000
     */
    function getTokenFee() external view override returns (uint256) {
        return settings.tokenFee;
    }

    /**
     * @notice returns if a given referrer is valid
     * @param _referrer address of the checked referrer
     */
    function referrerIsValid(address _referrer)
        external
        view
        override
        returns (bool)
    {
        return ALLOWED_REFERRERS.contains(_referrer);
    }

    /**
     * @notice returns if a given user has sufficient balance of early access tokens
     * registered in the EARLY_ACCESS_TOKENS set to participate in round 1
     * @dev we are aware of out of gas scenarios in for loop. It is intended to keep
     * the early access tokens list very small (max. 5)
     * @param _user address of the user to be checked
     */
    function userHoldsSufficientRound1Token(address _user)
        external
        view
        override
        returns (bool)
    {
        if (earlyAccessTokensLength() == 0) {
            return true;
        }
        for (uint256 i = 0; i < earlyAccessTokensLength(); i++) {
            (address token, uint256 amountHold) = getEarlyAccessTokenAtIndex(i);
            if (IERC20(token).balanceOf(_user) >= amountHold) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT

/**
 * @title Settings Interface of EnergyFi launchpad enviroment
 * @dev This Interface holds getter functions for getting the current general settings
 * of the launchpad. General settings are fees, fee receiver, launchpad length limitations,
 * allowed referrers and early access token to participate on round 1.
 */

pragma solidity 0.6.12;

interface ILaunchpadSettings {
    /**
     * @notice returns the address of the base fee receiver
     */
    function getBaseFeeReceiver() external view returns (address payable);

    /**
     * @notice returns the absolute fee in BNB for launchpad creation
     */
    function getBnbCreationFee() external view returns (uint256);

    /**
     * @notice returns the maximum duration of a launchpad in blocks
     */
    function getMaxLaunchpadLength() external view returns (uint256);

    /**
     * @notice returns the relative referral fee charged on base and sale token fee in parts per 1000
     */
    function getReferralFee() external view returns (uint256);

    /**
     * @notice returns the duration of round 1 in blocks
     */
    function getRound1Length() external view returns (uint256);

    /**
     * @notice returns the sale token fee receiver address
     */
    function getSaleFeeReceiver() external view returns (address payable);

    /**
     * @notice returns the relative sale token fee in parts per 1000
     */
    function getTokenFee() external view returns (uint256);

    /**
     * @notice returns if a given referrer is valid
     * @param _referrer address of the checked referrer
     */
    function referrerIsValid(address _referrer) external view returns (bool);

    /**
     * @notice returns if a given user has sufficient balance of early access tokens
     * registered in the EARLY_ACCESS_TOKENS set to participate in round 1
     * @param _user address of the user to be checked
     */
    function userHoldsSufficientRound1Token(address _user)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}