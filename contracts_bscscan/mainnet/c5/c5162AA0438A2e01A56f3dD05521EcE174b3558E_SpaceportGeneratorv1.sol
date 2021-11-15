// SPDX-License-Identifier: MIT

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/GSN/Context.sol
// Subject to the MIT license.

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

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/EnumerableSet.sol
// Subject to the MIT license.

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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
// Subject to the MIT license.

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
// Subject to the MIT license.

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
// Subject to the MIT license.

pragma solidity >=0.6.0 <0.8.0;

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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// Generates SpacePort contracts and registers them in the SpaceFactory 

pragma solidity 0.6.12;

import "./Spaceportv1.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";
import "./SpaceportHelper.sol";

interface ISpaceportFactory {
    function registerSpaceport (address _spaceportAddress) external;
    function spaceportIsRegistered(address _spaceportAddress) external view returns (bool);
}

interface IPlasmaswapLocker {
    function lockLPToken (address _lpToken, uint256 _amount, uint256 _unlock_date, address payable _withdrawer) external payable;
}

contract SpaceportGeneratorv1 is Ownable {
    using SafeMath for uint256;
    
    ISpaceportFactory public SPACEPORT_FACTORY;
    ISpaceportSettings public SPACEPORT_SETTINGS;
    
    struct SpaceportParams {
        uint256 amount; // the amount of spaceport tokens up for presale
        uint256 tokenPrice; // 1 base token = ? s_tokens, fixed price
        uint256 maxSpendPerBuyer; // maximum base token BUY amount per account
        uint256 hardcap;
        uint256 softcap;
        uint256 liquidityPercent; // divided by 1000
        uint256 listingRate; // sale token listing price on plasmaswap
        uint256 startblock;
        uint256 endblock;
        uint256 lockPeriod; // unix timestamp -> e.g. 2 weeks
    }
    
    constructor() public {
        SPACEPORT_FACTORY = ISpaceportFactory(0x3585e70766b2732B2F474EfeFCe29d53531bF02c);
        SPACEPORT_SETTINGS = ISpaceportSettings(0x807B11A0561889bCFfF8df28CeAEb5898F590313);
    }
    
    /**
     * @notice Creates a new Spaceport contract and verify it in the SpaceportFactory.sol.
     */
    function createSpaceport (
      address payable _spaceportOwner,
      IERC20 _spaceportToken,
      IERC20 _baseToken,
      uint256[10] memory uint_params,
      uint256[2] memory vesting_params
      ) public payable {
        
        SpaceportParams memory params;
        params.amount = uint_params[0];
        params.tokenPrice = uint_params[1];
        params.maxSpendPerBuyer = uint_params[2];
        params.hardcap = uint_params[3];
        params.softcap = uint_params[4];
        params.liquidityPercent = uint_params[5];
        params.listingRate = uint_params[6];
        params.startblock = uint_params[7];
        params.endblock = uint_params[8];
        params.lockPeriod = uint_params[9];
        
        if (params.lockPeriod < 4 weeks) {
            params.lockPeriod = 4 weeks;
        }
        
        // Charge ETH fee for contract creation
        require(msg.value == SPACEPORT_SETTINGS.getEthCreationFee(), 'FEE NOT MET');
        SPACEPORT_SETTINGS.getEthAddress().transfer(SPACEPORT_SETTINGS.getEthCreationFee());
        
        
        require(params.amount >= 10000, 'MIN DIVIS'); // minimum divisibility
        require(params.endblock.sub(params.startblock) <= SPACEPORT_SETTINGS.getMaxSpaceportLength());
        require(params.tokenPrice.mul(params.hardcap) > 0, 'INVALID PARAMS'); // ensure no overflow for future calculations
        require(params.liquidityPercent >= 300 && params.liquidityPercent <= 1000, 'MIN LIQUIDITY'); // 30% minimum liquidity lock
        
        uint256 tokensRequiredForSpaceport = SpaceportHelper.calculateAmountRequired(params.amount, params.tokenPrice, params.listingRate, params.liquidityPercent, SPACEPORT_SETTINGS.getTokenFee());
      
        Spaceportv1 newSpaceport = new Spaceportv1(address(this));
        TransferHelper.safeTransferFrom(address(_spaceportToken), address(msg.sender), address(newSpaceport), tokensRequiredForSpaceport);
        newSpaceport.init1(_spaceportOwner, params.amount, params.tokenPrice, params.maxSpendPerBuyer, params.hardcap, params.softcap, 
        params.liquidityPercent, params.listingRate, params.startblock, params.endblock, params.lockPeriod);
        newSpaceport.init2(_baseToken, _spaceportToken, SPACEPORT_SETTINGS.getBaseFee(), SPACEPORT_SETTINGS.getTokenFee(), SPACEPORT_SETTINGS.getEthAddress(), SPACEPORT_SETTINGS.getTokenAddress(), vesting_params[0], vesting_params[1]);
        SPACEPORT_FACTORY.registerSpaceport(address(newSpaceport));
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


import "./SafeMath.sol";

library SpaceportHelper {
    using SafeMath for uint256;
    
    function calculateAmountRequired (uint256 _amount, uint256 _tokenPrice, uint256 _listingRate, uint256 _liquidityPercent, uint256 _tokenFee) public pure returns (uint256) {
        uint256 listingRatePercent = _listingRate.mul(1000).div(_tokenPrice);
        uint256 plfiTokenFee = _amount.mul(_tokenFee).div(1000);
        uint256 amountMinusFee = _amount.sub(plfiTokenFee);
        uint256 liquidityRequired = amountMinusFee.mul(_liquidityPercent).mul(listingRatePercent).div(1000000);
        uint256 tokensRequiredForSpaceport = _amount.add(liquidityRequired).add(plfiTokenFee);
        return tokensRequiredForSpaceport;
    }
}

// SPDX-License-Identifier: MIT

// SpacePort v.1

pragma solidity 0.6.12;

import "./TransferHelper.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

interface IPlasmaswapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface ISpaceportLockForwarder {
    function lockLiquidity (IERC20 _baseToken, IERC20 _saleToken, uint256 _baseAmount, uint256 _saleAmount, uint256 _unlock_date, address payable _withdrawer) external;
    function plasmaswapPairIsInitialised (address _token0, address _token1) external view returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface ISpaceportSettings {
    function getMaxSpaceportLength () external view returns (uint256);
    function getRound1Length () external view returns (uint256);
    function userHoldsSufficientRound1Token (address _user) external view returns (bool);
    function getBaseFee () external view returns (uint256);
    function getTokenFee () external view returns (uint256);
    function getEthAddress () external view returns (address payable);
    function getTokenAddress () external view returns (address payable);
    function getEthCreationFee () external view returns (uint256);
}

contract Spaceportv1 is ReentrancyGuard {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;
  
  event spaceportUserDeposit(uint256 value);
  event spaceportUserWithdrawTokens(uint256 value);
  event spaceportUserWithdrawBaseTokens(uint256 value);
  event spaceportOwnerWithdrawTokens();
  event spaceportAddLiquidity();
  event spaceportForceFailIfPairExists();
  event spaceportForceFailByPlfi();
  event spaceportUpdateBlocks(uint256 start, uint256 end);

  /// @notice Spaceport Contract Version, used to choose the correct ABI to decode the contract
  uint256 public CONTRACT_VERSION = 1;
  
  struct SpaceportInfo {
    address payable SPACEPORT_OWNER;
    IERC20 S_TOKEN; // sale token
    IERC20 B_TOKEN; // base token // usually WETH (ETH)
    uint256 TOKEN_PRICE; // 1 base token = ? s_tokens, fixed price
    uint256 MAX_SPEND_PER_BUYER; // maximum base token BUY amount per account
    uint256 AMOUNT; // the amount of spaceport tokens up for presale
    uint256 HARDCAP;
    uint256 SOFTCAP;
    uint256 LIQUIDITY_PERCENT; // divided by 1000 - to be locked !
    uint256 LISTING_RATE; // fixed rate at which the token will list on plasmaswap - start rate
    uint256 START_BLOCK;
    uint256 END_BLOCK;
    uint256 LOCK_PERIOD; // unix timestamp -> e.g. 2 weeks
    bool SPACEPORT_IN_ETH; // if this flag is true the Spaceport is raising ETH, otherwise an ERC20 token such as DAI
  }

  struct SpaceportVesting {
    uint256 vestingCliff;
    uint256 vestingEnd;
  }

  struct SpaceportFeeInfo {
    uint256 PLFI_BASE_FEE; // divided by 1000
    uint256 PLFI_TOKEN_FEE; // divided by 1000
    address payable BASE_FEE_ADDRESS;
    address payable TOKEN_FEE_ADDRESS;
  }
  
  struct SpaceportStatus {
    bool WHITELIST_ONLY; // if set to true only whitelisted members may participate
    bool LP_GENERATION_COMPLETE; // final flag required to end a Spaceport and enable withdrawls
    bool FORCE_FAILED; // set this flag to force fail the Spaceport
    uint256 TOTAL_BASE_COLLECTED; // total base currency raised (usually ETH)
    uint256 TOTAL_TOKENS_SOLD; // total Spaceport tokens sold
    uint256 TOTAL_TOKENS_WITHDRAWN; // total tokens withdrawn post successful Spaceport
    uint256 TOTAL_BASE_WITHDRAWN; // total base tokens withdrawn on Spaceport failure
    uint256 ROUND1_LENGTH; // in blocks
    uint256 NUM_BUYERS; // number of unique participants
    uint256 LP_GENERATION_COMPLETE_TIME;  //  the date when LP is done
  }

  struct BuyerInfo {
    uint256 baseDeposited; // total base token (usually ETH) deposited by user, can be withdrawn on presale failure
    uint256 tokensOwed; // num Spaceport tokens a user is owed, can be withdrawn on presale success
    uint256 tokensClaimed;
    uint256 lastUpdate;
  }
  
  SpaceportVesting public SPACEPORT_VESTING;
  SpaceportInfo public SPACEPORT_INFO;
  SpaceportFeeInfo public SPACEPORT_FEE_INFO;
  SpaceportStatus public STATUS;
  address public SPACEPORT_GENERATOR;
  ISpaceportLockForwarder public SPACEPORT_LOCK_FORWARDER;
  ISpaceportSettings public SPACEPORT_SETTINGS;
  address PLFI_DEV_ADDRESS;
  IPlasmaswapFactory public PLASMASWAP_FACTORY;
  IWETH public WETH;
  mapping(address => BuyerInfo) public BUYERS;
  EnumerableSet.AddressSet private WHITELIST;

  constructor(address _spaceportGenerator) public {
    SPACEPORT_GENERATOR = _spaceportGenerator;
    PLASMASWAP_FACTORY = IPlasmaswapFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    WETH = IWETH(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    SPACEPORT_SETTINGS = ISpaceportSettings(0x807B11A0561889bCFfF8df28CeAEb5898F590313);
    SPACEPORT_LOCK_FORWARDER = ISpaceportLockForwarder(0xe8AB90CCD7C907C6E72a649f3268318691A4503C);
    PLFI_DEV_ADDRESS = 0x803982e6E7F0543cd193a4Fe7b49ab453B1bA3B7;
  }
  
  function init1 (
    address payable _spaceportOwner, 
    uint256 _amount,
    uint256 _tokenPrice, 
    uint256 _maxEthPerBuyer, 
    uint256 _hardcap, 
    uint256 _softcap,
    uint256 _liquidityPercent,
    uint256 _listingRate,
    uint256 _startblock,
    uint256 _endblock,
    uint256 _lockPeriod
    ) external {
          
      require(msg.sender == SPACEPORT_GENERATOR, 'FORBIDDEN');
      SPACEPORT_INFO.SPACEPORT_OWNER = _spaceportOwner;
      SPACEPORT_INFO.AMOUNT = _amount;
      SPACEPORT_INFO.TOKEN_PRICE = _tokenPrice;
      SPACEPORT_INFO.MAX_SPEND_PER_BUYER = _maxEthPerBuyer;
      SPACEPORT_INFO.HARDCAP = _hardcap;
      SPACEPORT_INFO.SOFTCAP = _softcap;
      SPACEPORT_INFO.LIQUIDITY_PERCENT = _liquidityPercent;
      SPACEPORT_INFO.LISTING_RATE = _listingRate;
      SPACEPORT_INFO.START_BLOCK = _startblock;
      SPACEPORT_INFO.END_BLOCK = _endblock;
      SPACEPORT_INFO.LOCK_PERIOD = _lockPeriod;
  }
  
  function init2 (
    IERC20 _baseToken,
    IERC20 _spaceportToken,
    uint256 _plfiBaseFee,
    uint256 _plfiTokenFee,
    address payable _baseFeeAddress,
    address payable _tokenFeeAddress,
    uint256 _vestingCliff,
    uint256 _vestingEnd
    ) external {
          
      require(msg.sender == SPACEPORT_GENERATOR, 'FORBIDDEN');
      // require(!SPACEPORT_LOCK_FORWARDER.plasmaswapPairIsInitialised(address(_spaceportToken), address(_baseToken)), 'PAIR INITIALISED');
      
      SPACEPORT_INFO.SPACEPORT_IN_ETH = address(_baseToken) == address(WETH);
      SPACEPORT_INFO.S_TOKEN = _spaceportToken;
      SPACEPORT_INFO.B_TOKEN = _baseToken;
      SPACEPORT_FEE_INFO.PLFI_BASE_FEE = _plfiBaseFee;
      SPACEPORT_FEE_INFO.PLFI_TOKEN_FEE = _plfiTokenFee;
      
      SPACEPORT_FEE_INFO.BASE_FEE_ADDRESS = _baseFeeAddress;
      SPACEPORT_FEE_INFO.TOKEN_FEE_ADDRESS = _tokenFeeAddress;
      STATUS.ROUND1_LENGTH = SPACEPORT_SETTINGS.getRound1Length();

      SPACEPORT_VESTING.vestingCliff = _vestingCliff;
      SPACEPORT_VESTING.vestingEnd = _vestingEnd;
  }
  
  modifier onlySpaceportOwner() {
    require(SPACEPORT_INFO.SPACEPORT_OWNER == msg.sender, "NOT SPACEPORT OWNER");
    _;
  }
  
  function spaceportStatus () public view returns (uint256) {
    if (STATUS.FORCE_FAILED) {
      return 3; // FAILED - force fail
    }
    if ((block.number > SPACEPORT_INFO.END_BLOCK) && (STATUS.TOTAL_BASE_COLLECTED < SPACEPORT_INFO.SOFTCAP)) {
      return 3; // FAILED - softcap not met by end block
    }
    if (STATUS.TOTAL_BASE_COLLECTED >= SPACEPORT_INFO.HARDCAP) {
      return 2; // SUCCESS - hardcap met
    }
    if ((block.number > SPACEPORT_INFO.END_BLOCK) && (STATUS.TOTAL_BASE_COLLECTED >= SPACEPORT_INFO.SOFTCAP)) {
      return 2; // SUCCESS - endblock and soft cap reached
    }
    if ((block.number >= SPACEPORT_INFO.START_BLOCK) && (block.number <= SPACEPORT_INFO.END_BLOCK)) {
      return 1; // ACTIVE - deposits enabled
    }
    return 0; // QUED - awaiting start block
  }
  
  // accepts msg.value for eth or _amount for ERC20 tokens
  function userDeposit (uint256 _amount) external payable nonReentrant {
    require(spaceportStatus() == 1, 'NOT ACTIVE'); // ACTIVE
    if (STATUS.WHITELIST_ONLY) {
      require(WHITELIST.contains(msg.sender), 'NOT WHITELISTED');
    }
    // Spaceport Round 1 - require participant to hold a certain token and balance
    if (block.number < SPACEPORT_INFO.START_BLOCK + STATUS.ROUND1_LENGTH) { // 276 blocks = 1 hour
        require(SPACEPORT_SETTINGS.userHoldsSufficientRound1Token(msg.sender), 'INSUFFICENT ROUND 1 TOKEN BALANCE');
    }
    BuyerInfo storage buyer = BUYERS[msg.sender];
    uint256 amount_in = SPACEPORT_INFO.SPACEPORT_IN_ETH ? msg.value : _amount;
    uint256 allowance = SPACEPORT_INFO.MAX_SPEND_PER_BUYER.sub(buyer.baseDeposited);
    uint256 remaining = SPACEPORT_INFO.HARDCAP - STATUS.TOTAL_BASE_COLLECTED;
    allowance = allowance > remaining ? remaining : allowance;
    if (amount_in > allowance) {
      amount_in = allowance;
    }
    uint256 tokensSold = amount_in.mul(SPACEPORT_INFO.TOKEN_PRICE).div(10 ** uint256(SPACEPORT_INFO.B_TOKEN.decimals()));
    require(tokensSold > 0, 'ZERO TOKENS');
    if (buyer.baseDeposited == 0) {
        STATUS.NUM_BUYERS++;
    }

    buyer.baseDeposited = buyer.baseDeposited.add(amount_in);
    buyer.tokensOwed = buyer.tokensOwed.add(tokensSold);
    buyer.lastUpdate = block.timestamp;

    STATUS.TOTAL_BASE_COLLECTED = STATUS.TOTAL_BASE_COLLECTED.add(amount_in);
    STATUS.TOTAL_TOKENS_SOLD = STATUS.TOTAL_TOKENS_SOLD.add(tokensSold);
    
    // return unused ETH
    if (SPACEPORT_INFO.SPACEPORT_IN_ETH && amount_in < msg.value) {
      msg.sender.transfer(msg.value.sub(amount_in));
    }
    // deduct non ETH token from user
    if (!SPACEPORT_INFO.SPACEPORT_IN_ETH) {
      TransferHelper.safeTransferFrom(address(SPACEPORT_INFO.B_TOKEN), msg.sender, address(this), amount_in);
    }
    emit spaceportUserDeposit(amount_in);
  }
  
  // withdraw spaceport tokens
  // percentile withdrawls allows fee on transfer or rebasing tokens to still work
  function userWithdrawTokens () external nonReentrant {
    require(STATUS.LP_GENERATION_COMPLETE, 'AWAITING LP GENERATION');
    BuyerInfo storage buyer = BUYERS[msg.sender];
    require(STATUS.LP_GENERATION_COMPLETE_TIME + SPACEPORT_VESTING.vestingCliff < block.timestamp, "vesting cliff : not time yet");

    if (buyer.lastUpdate < STATUS.LP_GENERATION_COMPLETE_TIME ) {
        buyer.lastUpdate = STATUS.LP_GENERATION_COMPLETE_TIME;
    }
    
    uint256 tokensOwed = 0;
    if(STATUS.LP_GENERATION_COMPLETE_TIME + SPACEPORT_VESTING.vestingEnd < block.timestamp) {
      tokensOwed = buyer.tokensOwed.sub(buyer.tokensClaimed);
    }
    else {
      tokensOwed = buyer.tokensOwed.mul(block.timestamp - buyer.lastUpdate).div(SPACEPORT_VESTING.vestingEnd);
    }

    buyer.lastUpdate = block.timestamp;
    buyer.tokensClaimed = buyer.tokensClaimed.add(tokensOwed);
    
    require(tokensOwed > 0, 'NOTHING TO CLAIM');
    require(buyer.tokensClaimed <= buyer.tokensOwed, 'CLAIM TOKENS ERROR');

    STATUS.TOTAL_TOKENS_WITHDRAWN = STATUS.TOTAL_TOKENS_WITHDRAWN.add(tokensOwed);
    TransferHelper.safeTransfer(address(SPACEPORT_INFO.S_TOKEN), msg.sender, tokensOwed);

    emit spaceportUserWithdrawTokens(tokensOwed);
  }
  
  // on spaceport failure
  // percentile withdrawls allows fee on transfer or rebasing tokens to still work
  function userWithdrawBaseTokens () external nonReentrant {
    require(spaceportStatus() == 3, 'NOT FAILED'); // FAILED
    BuyerInfo storage buyer = BUYERS[msg.sender];
    uint256 baseRemainingDenominator = STATUS.TOTAL_BASE_COLLECTED.sub(STATUS.TOTAL_BASE_WITHDRAWN);
    uint256 remainingBaseBalance = SPACEPORT_INFO.SPACEPORT_IN_ETH ? address(this).balance : SPACEPORT_INFO.B_TOKEN.balanceOf(address(this));
    uint256 tokensOwed = remainingBaseBalance.mul(buyer.baseDeposited).div(baseRemainingDenominator);
    require(tokensOwed > 0, 'NOTHING TO WITHDRAW');
    STATUS.TOTAL_BASE_WITHDRAWN = STATUS.TOTAL_BASE_WITHDRAWN.add(buyer.baseDeposited);
    buyer.baseDeposited = 0;
    TransferHelper.safeTransferBaseToken(address(SPACEPORT_INFO.B_TOKEN), msg.sender, tokensOwed, !SPACEPORT_INFO.SPACEPORT_IN_ETH);
    emit spaceportUserWithdrawBaseTokens(tokensOwed);
  }
  
  // failure
  // allows the owner to withdraw the tokens they sent for presale & initial liquidity
  function ownerWithdrawTokens () external onlySpaceportOwner {
    require(spaceportStatus() == 3); // FAILED
    TransferHelper.safeTransfer(address(SPACEPORT_INFO.S_TOKEN), SPACEPORT_INFO.SPACEPORT_OWNER, SPACEPORT_INFO.S_TOKEN.balanceOf(address(this)));
    emit spaceportOwnerWithdrawTokens();
  }
  

  // Can be called at any stage before or during the presale to cancel it before it ends.
  // If the pair already exists on plasmaswap and it contains the presale token as liquidity 
  // the final stage of the presale 'addLiquidity()' will fail. This function 
  // allows anyone to end the presale prematurely to release funds in such a case.
  function forceFailIfPairExists () external {
    require(!STATUS.LP_GENERATION_COMPLETE && !STATUS.FORCE_FAILED);
    if (SPACEPORT_LOCK_FORWARDER.plasmaswapPairIsInitialised(address(SPACEPORT_INFO.S_TOKEN), address(SPACEPORT_INFO.B_TOKEN))) {
        STATUS.FORCE_FAILED = true;
        emit spaceportForceFailIfPairExists();
    }
  }
  
  // if something goes wrong in LP generation
  function forceFailByPlfi () external {
      require(msg.sender == PLFI_DEV_ADDRESS);
      STATUS.FORCE_FAILED = true;
      emit spaceportForceFailByPlfi();
  }
  
  // on spaceport success, this is the final step to end the spaceport, lock liquidity and enable withdrawls of the sale token.
  // This function does not use percentile distribution. Rebasing mechanisms, fee on transfers, or any deflationary logic
  // are not taken into account at this stage to ensure stated liquidity is locked and the pool is initialised according to 
  // the spaceport parameters and fixed prices.
  function addLiquidity() external nonReentrant {
    require(!STATUS.LP_GENERATION_COMPLETE, 'GENERATION COMPLETE');
    require(spaceportStatus() == 2, 'NOT SUCCESS'); // SUCCESS
    // Fail the spaceport if the pair exists and contains spaceport token liquidity
    if (SPACEPORT_LOCK_FORWARDER.plasmaswapPairIsInitialised(address(SPACEPORT_INFO.S_TOKEN), address(SPACEPORT_INFO.B_TOKEN))) {
        STATUS.FORCE_FAILED = true;
        return;
    }
    
    uint256 plfiBaseFee = STATUS.TOTAL_BASE_COLLECTED.mul(SPACEPORT_FEE_INFO.PLFI_BASE_FEE).div(1000);
    
    // base token liquidity
    uint256 baseLiquidity = STATUS.TOTAL_BASE_COLLECTED.sub(plfiBaseFee).mul(SPACEPORT_INFO.LIQUIDITY_PERCENT).div(1000);
    if (SPACEPORT_INFO.SPACEPORT_IN_ETH) {
        WETH.deposit{value : baseLiquidity}();
    }
    TransferHelper.safeApprove(address(SPACEPORT_INFO.B_TOKEN), address(SPACEPORT_LOCK_FORWARDER), baseLiquidity);
    
    // sale token liquidity
    uint256 tokenLiquidity = baseLiquidity.mul(SPACEPORT_INFO.LISTING_RATE).div(10 ** uint256(SPACEPORT_INFO.B_TOKEN.decimals()));
    TransferHelper.safeApprove(address(SPACEPORT_INFO.S_TOKEN), address(SPACEPORT_LOCK_FORWARDER), tokenLiquidity);
    
    SPACEPORT_LOCK_FORWARDER.lockLiquidity(SPACEPORT_INFO.B_TOKEN, SPACEPORT_INFO.S_TOKEN, baseLiquidity, tokenLiquidity, block.timestamp + SPACEPORT_INFO.LOCK_PERIOD, SPACEPORT_INFO.SPACEPORT_OWNER);
    
    // transfer fees
    uint256 plfiTokenFee = STATUS.TOTAL_TOKENS_SOLD.mul(SPACEPORT_FEE_INFO.PLFI_TOKEN_FEE).div(1000);
    TransferHelper.safeTransferBaseToken(address(SPACEPORT_INFO.B_TOKEN), SPACEPORT_FEE_INFO.BASE_FEE_ADDRESS, plfiBaseFee, !SPACEPORT_INFO.SPACEPORT_IN_ETH);
    TransferHelper.safeTransfer(address(SPACEPORT_INFO.S_TOKEN), SPACEPORT_FEE_INFO.TOKEN_FEE_ADDRESS, plfiTokenFee);
    
    // burn unsold tokens
    uint256 remainingSBalance = SPACEPORT_INFO.S_TOKEN.balanceOf(address(this));
    if (remainingSBalance > STATUS.TOTAL_TOKENS_SOLD) {
        uint256 burnAmount = remainingSBalance.sub(STATUS.TOTAL_TOKENS_SOLD);
        TransferHelper.safeTransfer(address(SPACEPORT_INFO.S_TOKEN), 0x111ed2C8077E2CBBEb2723070005cD35b5F12A43, burnAmount);
    }
    
    // send remaining base tokens to spaceport owner
    uint256 remainingBaseBalance = SPACEPORT_INFO.SPACEPORT_IN_ETH ? address(this).balance : SPACEPORT_INFO.B_TOKEN.balanceOf(address(this));
    TransferHelper.safeTransferBaseToken(address(SPACEPORT_INFO.B_TOKEN), SPACEPORT_INFO.SPACEPORT_OWNER, remainingBaseBalance, !SPACEPORT_INFO.SPACEPORT_IN_ETH);
    
    STATUS.LP_GENERATION_COMPLETE = true;
    STATUS.LP_GENERATION_COMPLETE_TIME = block.timestamp;
    
    emit spaceportAddLiquidity();
  }
  
  function updateMaxSpendLimit(uint256 _maxSpend) external onlySpaceportOwner {
    SPACEPORT_INFO.MAX_SPEND_PER_BUYER = _maxSpend;
  }
  
  // postpone or bring a spaceport forward, this will only work when a presale is inactive.
  function updateBlocks(uint256 _startBlock, uint256 _endBlock) external onlySpaceportOwner {
    require(SPACEPORT_INFO.START_BLOCK > block.number);
    require(_endBlock.sub(_startBlock) <= SPACEPORT_SETTINGS.getMaxSpaceportLength());
    SPACEPORT_INFO.START_BLOCK = _startBlock;
    SPACEPORT_INFO.END_BLOCK = _endBlock;
    emit spaceportUpdateBlocks(_startBlock, _endBlock);
  }

  // editable at any stage of the presale
  function setWhitelistFlag(bool _flag) external onlySpaceportOwner {
    STATUS.WHITELIST_ONLY = _flag;
  }

  // editable at any stage of the presale
  function editWhitelist(address[] memory _users, bool _add) external onlySpaceportOwner {
    if (_add) {
        for (uint i = 0; i < _users.length; i++) {
          WHITELIST.add(_users[i]);
        }
    } else {
        for (uint i = 0; i < _users.length; i++) {
          WHITELIST.remove(_users[i]);
        }
    }
  }

  // whitelist getters
  function getWhitelistedUsersLength () external view returns (uint256) {
    return WHITELIST.length();
  }
  
  function getWhitelistedUserAtIndex (uint256 _index) external view returns (address) {
    return WHITELIST.at(_index);
  }
  
  function getUserWhitelistStatus (address _user) external view returns (bool) {
    return WHITELIST.contains(_user);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
    helper methods for interacting with ERC20 tokens that do not consistently return true/false
    with the addition of a transfer function to send eth or an erc20 token
*/
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
    // sends ETH or an erc20 token
    function safeTransferBaseToken(address token, address payable to, uint value, bool isERC20) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
        }
    }
}

