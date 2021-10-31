/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {// Equivalent to contains(set, value)
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
            set._indexes[lastvalue] = valueIndex;
            // Replace lastvalue's index to valueIndex

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


abstract contract Ownable is Context {
    address private _owner;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private governments;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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

    function addGovernment(address government) public onlyOwner {
        governments.add(government);
    }

    function deletedGovernment(address government) public onlyOwner {
        governments.remove(government);
    }

    function getGovernment(uint256 index) public view returns (address) {
        return governments.at(index);
    }

    function isGovernment(address account) public view returns (bool){
        return governments.contains(account);
    }

    function getGovernmentLength() public view returns (uint256) {
        return governments.length();
    }

    modifier onlyGovernment() {
        require(isGovernment(_msgSender()), "Ownable: caller is not the Government");
        _;
    }

    modifier onlyController(){
        require(_msgSender() == owner() || isGovernment(_msgSender()), "Ownable: caller is not the controller");
        _;
    }

}


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


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


library Math {
    function max(uint256 left, uint256 right) internal pure returns (uint256) {
        return left >= right ? left : right;
    }

    function min(uint256 left, uint256 right) internal pure returns (uint256) {
        return left< right ? left : right;
    }

    function avg(uint256 left, uint256 right) internal pure returns (uint256) {
        return (left/ 2) + (right / 2) + ((left % 2 + right % 2) / 2);
    }
}


interface ICalcFormula {
    function calcCapacity(uint256 tokenLevel, bool isProfessional) external view returns (uint256);
}


struct Parmas{
    string name;
    uint256 level;
    uint256 rarity;
    uint256 series;
    uint256 race;
    uint256 mineralLevel;
}

interface INFTToken {
    function getNFTParams(uint256 tokenId) external view returns (Parmas memory);

    function updateStatus(uint256 tokenId, uint256 status) external;
    
    function getStatus(uint256 tokenId) external returns (uint256);
}


interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}


struct AccountInfo {
    uint256 id;
    string nickName;
    string avatar;
    uint256 level;
    uint256 birthHeight;
    uint256 birthPlace;
    uint256 gender;
    uint256 influence;
}

interface IAccount {
    function getAccountInfo(uint256 tokenId) external view returns (AccountInfo memory);
}


interface IToken {
    function additional(address to, uint256 amount) external returns (bool);
}


struct TokenList{
    uint256[] tokens;
}


contract MineralPool is Ownable {
    using SafeMath for uint256;
    uint256 private poolPlace;
    
    address private stakeToken;
    address private accountContract;
    address private rewardsContract;
    address private empowerContract;
    
    uint256 private rewardsRate = 0;
    uint256 private dailyRewards;
    uint256 private dailySeconds = 86400;
    
    uint256 private lastUpdateTime;
    uint256 private rewardsPerUnitStored;
    
    mapping(uint256 => uint256) private tokensRewardsPerUnitPaid;
    mapping(uint256 => uint256) private tokensRewards;
    mapping(uint256 => uint256) private tokensCapacities;

    uint256 private _totalSupply = 0;
    uint256 private _totalCapacity = 0;
    
    uint256 private limitTokensNumber = 1;

    uint256 private idleStatus = 0;
    uint256 private miningStatus = 2;
    
    mapping(address => TokenList) private accountsTokens;
    
    event RewardAdded(uint256 rewards);
    event Staked(address indexed account, uint256 tokenId);
    event Withdrawn(address indexed account, uint256 tokenId);
    event RewardPaid(address indexed account, uint256 rewards);
    
    constructor(uint256 _poolPlace, address _stakeToken, address _accountContract, address _rewardsContract, address _empowerContract, uint256 _dailyRewards) {
        poolPlace = _poolPlace;
        stakeToken = _stakeToken;
        accountContract = _accountContract;
        rewardsContract = _rewardsContract;
        empowerContract = _empowerContract;
        _changeDailyRewards(_dailyRewards);
    }

    modifier updateRewards(uint256 tokenId) {
        rewardsPerUnitStored = _rewardsPerUint();
        lastUpdateTime = block.timestamp;
        if (tokenId != 0) {
            tokensRewards[tokenId] = earned(tokenId);
            tokensRewardsPerUnitPaid[tokenId] = rewardsPerUnitStored;
        }
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function totalCapacity() public view returns (uint256) {
        return _totalCapacity;
    }

    function capacityOf(uint256 tokenId) public view returns (uint256) {
        return tokensCapacities[tokenId];
    }

    function getAccountCapacity(address account) public view returns (uint256) {
        uint256 accoutCapacity = 0;
        uint256[] memory ownerTokens = accountsTokens[account].tokens;
        for(uint256 idx = 0; idx < ownerTokens.length; idx++){
            accoutCapacity += tokensCapacities[ownerTokens[idx]];
        }
        return accoutCapacity;
    }


    function getAccountTokensNumber(address account) public view returns (uint256) {
        return accountsTokens[account].tokens.length;
    }

    function getAccountTokens(address account) public view returns (uint256[] memory) {
        return accountsTokens[account].tokens;
    }

    function isAccountStakeToken(address account, uint256 tokenId) public view returns (bool) {
        bool isStake = false;
        uint256[] memory ownerTokens = accountsTokens[account].tokens;
        for(uint256 idx = 0; idx < ownerTokens.length; idx++){
            if(ownerTokens[idx] == tokenId){
                isStake = true;
                break;
            }
        }
        return isStake;
    }

    function getPoolPlace() public view returns (uint256) {
        return poolPlace;
    }

    function getStakeTokenAddress() public view  returns(address) {
        return stakeToken;
    }

    function getAccountContractAddress() public view  returns(address) {
        return accountContract;
    }

    function getRewardsContractAddress() public view  returns(address) {
        return rewardsContract;
    }

    function getEmpowerContractAddress() public view  returns(address) {
        return empowerContract;
    }

    function getRewardsRate() public view returns (uint256) {
        return rewardsRate;
    }

    function getDailyRewards() public view returns (uint256) {
        return dailyRewards;
    }

    function getLastUpdateTime() public view returns (uint256) {
        return lastUpdateTime;
    }

    function getRewardsPerUnitStored() public view returns (uint256) {
        return rewardsPerUnitStored;
    }

    function getLimitTokensNumber() public view returns (uint256) {
        return limitTokensNumber;
    }

    function getTokenIdleStatus() public view returns (uint256) {
        return idleStatus;
    }

    function getTokenMiningStatus() public view returns (uint256) {
        return miningStatus;
    }

    function calcCapacity(uint256 tokenId) public view returns (uint256) {
        AccountInfo memory tokenAccountInfo = IAccount(accountContract).getAccountInfo(tokenId);
        bool isMatchPlace = false;
        if(tokenAccountInfo.birthPlace == poolPlace){
            isMatchPlace = true;
        }

        Parmas memory tokenParmas = INFTToken(stakeToken).getNFTParams(tokenId);
        return ICalcFormula(empowerContract).calcCapacity(tokenParmas.mineralLevel, isMatchPlace);
    }

    function calcPerSecondsRewards(uint256 tokenId) public view returns (uint256) {
        uint256 perSecondsRewards = 0;
        if (totalCapacity() != 0) {
            perSecondsRewards = capacityOf(tokenId).mul(rewardsRate).div(totalCapacity());
        }
        return perSecondsRewards;
    }
    
    function estimatePerSecondsRewards(uint256 tokenId) public view returns (uint256) {
        uint256 tokenCapacity = calcCapacity(tokenId);
        uint256 estimateTotalCapacity = totalCapacity().add(tokenCapacity);
        
        uint256 perSecondsRewards = 0;
        if (estimateTotalCapacity != 0) {
            perSecondsRewards = tokenCapacity.mul(rewardsRate).div(estimateTotalCapacity);
        }
        return perSecondsRewards;
    }

    function setEmpowerContract(address _empowerContract) public onlyController {
        empowerContract = _empowerContract;
    }

    function setLimitTokensNumber(uint256 _limitTokensNumber) public onlyController {
        require(_limitTokensNumber > limitTokensNumber, "Setting failed, limit can only increased");
        limitTokensNumber = _limitTokensNumber;
    }

    function setTokenIdleStatus(uint256 _idleStatus) public onlyController {
        idleStatus = _idleStatus;
    }

    function setTokenMiningStatus(uint256 _miningStatus) public onlyController {
        miningStatus = _miningStatus;
    }

    function changeDailyRewards(uint256 _dailyRewards) public onlyController {
        _changeDailyRewards(_dailyRewards);
    }

    function stake(uint256 tokenId) public updateRewards(tokenId) {
        require(IERC721(accountContract).balanceOf(msg.sender) > 0,"Stake failed, acount is not created");
        require(IERC721(stakeToken).ownerOf(tokenId) == msg.sender,"Stake failed, token is not owner");
        require(getAccountTokensNumber(msg.sender) < limitTokensNumber, "Stake failed, limit tokens number");

        uint256 tokenStatus = INFTToken(stakeToken).getStatus(tokenId);
        require(tokenStatus == idleStatus, "Stake failed, token is not idle");
        
        INFTToken(stakeToken).updateStatus(tokenId, miningStatus);
        
        uint256 capacity = calcCapacity(tokenId);

        _totalSupply = _totalSupply.add(1e18);
        _totalCapacity = _totalCapacity.add(capacity);
        
        tokensCapacities[tokenId] = capacity;
        accountsTokens[msg.sender].tokens.push(tokenId);

        emit Staked(msg.sender, tokenId);
    }

    function earned(uint256 tokenId) public view returns (uint256) {
        return capacityOf(tokenId)
                    .mul(_rewardsPerUint().sub(tokensRewardsPerUnitPaid[tokenId]))
                    .div(1e18).add(tokensRewards[tokenId]);
    }

    function earnedAll(address account) public view returns (uint256) {
        uint256 trueRewards = 0;
        uint256[] memory ownerTokens = accountsTokens[account].tokens;
        for(uint256 idx = 0; idx < ownerTokens.length; idx++){
            trueRewards += earned(ownerTokens[idx]);
        }
        
        return trueRewards;
    }

    function claimReward(uint256 tokenId) public {
        require(isAccountStakeToken(msg.sender, tokenId), "Claim failed, token is not stake");
        _claimReward(tokenId);
    }

    function claimAllReward() public {
        require(getAccountTokensNumber(msg.sender) > 0, "Claim failed, empty stake");
        
        uint256[] memory ownerTokens = accountsTokens[msg.sender].tokens;
        for(uint256 idx = 0; idx < ownerTokens.length; idx++){
            _claimReward(ownerTokens[idx]);
        }
    }

    function withdrawAndClaim(uint256 tokenId) public {
        require(isAccountStakeToken(msg.sender, tokenId), "Withdraw failed, token is not stake");
        _withdrawAndClaim(tokenId);
    }

    function withdrawAllAndClaim() public {
        require(getAccountTokensNumber(msg.sender) > 0, "Withdraw failed, empty stake");

        uint256[] memory ownerTokens = accountsTokens[msg.sender].tokens;
        for(uint256 idx = 0; idx < ownerTokens.length; idx++){
            _withdrawAndClaim(ownerTokens[idx]);
        }
    }

    function _claimReward(uint256 tokenId) private updateRewards(tokenId) {
        _claimTokenReward(tokenId);
    }

    function _withdrawAndClaim(uint256 tokenId) private updateRewards(tokenId) {
        _claimTokenReward(tokenId);

        _totalSupply = _totalSupply.sub(1e18);
        _totalCapacity = _totalCapacity.sub(tokensCapacities[tokenId]);
        
        tokensCapacities[tokenId] = 0;
        _removeToken(msg.sender, tokenId);

        INFTToken(stakeToken).updateStatus(tokenId, idleStatus);
        emit Withdrawn(msg.sender, tokenId);
    }

    function _claimTokenReward(uint256 tokenId) private {
        uint256 trueRewards = earned(tokenId);
        if (trueRewards > 0) {
            tokensRewards[tokenId] = 0;
            IToken(rewardsContract).additional(msg.sender, trueRewards);
            emit RewardPaid(msg.sender, trueRewards);
        }
    }

    function _rewardsPerUint() private view returns (uint256) {
        if (totalCapacity() == 0) {
            return rewardsPerUnitStored;
        }
        uint256 currentTime = block.timestamp;
        return rewardsPerUnitStored.add(
                currentTime
                .sub(lastUpdateTime)
                .mul(rewardsRate)
                .mul(1e18)
                .div(totalCapacity()));
    }

    function _changeDailyRewards(uint256 _dailyRewards) private updateRewards(0){
        dailyRewards = _dailyRewards;
        rewardsRate = _dailyRewards.div(dailySeconds);
        emit RewardAdded(_dailyRewards);
    }

    function _removeToken(address account, uint256 tokenId) private {
        uint256 tokenIndex = 0;
        uint256 length = accountsTokens[account].tokens.length;
        for(uint256 idx = 0; idx < length; idx++){
            if(accountsTokens[account].tokens[idx] == tokenId){
                tokenIndex = idx;
                break;
            }
        }
        
        for(uint256 idx = tokenIndex; idx < length - 1; idx++){
            accountsTokens[account].tokens[idx] = accountsTokens[account].tokens[idx+1];
        }
        
        accountsTokens[account].tokens.pop();
    }
}