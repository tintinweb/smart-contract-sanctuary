/**
 *Submitted for verification at BscScan.com on 2021-12-01
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
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function avg(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


interface IDistribute {
    function unionWarRewards(uint256 unionId, uint256 rewardsAmount) external;
}


interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function existsUnion(uint256 unionId) external view returns (bool);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}


interface IUnionMember{
    function getUnionAccountCount(uint256 unionId) external view returns (uint256);
    function getUnionAccountIdByIndex(uint256 unionId,uint256 index) external view returns (uint256);
    function getMemberIdentity(uint256 unionId,uint256 accountId) external view returns(uint256);
    function getBelongUnion(uint256 accountId) external view returns (uint256);
}


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function getBalanceOfUnion(uint256 unionId)  external view returns (uint256);
}


interface IRewardsWallet {
    function transfer(address recipient, uint256 amount) external;
}


contract Distribute is Ownable, IDistribute {
    using SafeMath for uint256;

    address private accountContract;
    address private unionMemberContract;
    address private unionContract;
    address private contributeContract;
    address private rewardsWalletContract;

    uint256 private maxLeaderRewardsPercent = 50000000000000000;
    mapping (uint256 => mapping(uint256=>uint256)) unoinsManagersBonusPercent;
    mapping(uint256 => mapping(uint256=>uint256)) private unionManagersRewards;
    mapping(uint256 => uint256[]) private unoinsManagers;

    uint256 private initializeTime;
    uint256 private duration;
    mapping(uint256 => PoolInfo[]) private unoinsPools;
    mapping(uint256 => mapping(uint256=>uint256)) private unionAccountsClaimTime;

    event WarRewards(uint256 indexed unionId, uint256 rewards);
    event RewardsPaid(address indexed account, uint256 rewards);
    event SetBonusPercent(uint256 indexed unionId, uint256 accountId, uint256 bonusPercent);
    
    constructor(
        address _accountContract,
        address _unionMemberContract,
        address _unionContract,
        address _contributeContract,
        address _rewardsWalletContract,
        uint256 _initializeTime,
        uint256 _duration
        ) {
        accountContract = _accountContract;
        unionMemberContract = _unionMemberContract;
        unionContract = _unionContract;
        contributeContract = _contributeContract;
        rewardsWalletContract = _rewardsWalletContract;
        initializeTime = _initializeTime;
        duration = _duration;
    }

    function getAccountContract() public view returns(address) {
        return accountContract;
    }

    function getUnionMemberContract() public view returns(address) {
        return unionMemberContract;
    }

    function getUnionContract() public view returns(address) {
        return unionContract;
    }

    function getContributeContract() public view returns(address) {
        return contributeContract;
    }

    function getRewardsWalletContract() public view returns(address) {
        return rewardsWalletContract;
    }

    function getMaxLeaderRewardsPercent() public view returns(uint256) {
        return maxLeaderRewardsPercent;
    }

    function getInitializeTime() public view returns(uint256) {
        return initializeTime;
    }

    function getDuration() public view returns(uint256) {
        return duration;
    }

    function getUnoinManagersLength(
        uint256 unoinId
    ) public view returns(uint256) {
        return unoinsManagers[unoinId].length;
    }

    function getUnionManagerByIndex(
        uint256 unionId,
        uint256 index
    ) public view returns (uint256) {
        return unoinsManagers[unionId][index];
    }

    function getUnionManagers(
        uint256 unionId
    ) public view returns (uint256[] memory) {
        return unoinsManagers[unionId];
    }

    function getUnionManagerBonusPercent(
        uint256 unionId,
        uint256 accountId
    ) public view returns (uint256) {
        return unoinsManagersBonusPercent[unionId][accountId];
    }

    function getUnionManagersBonusInfo (
        uint256 unionId
    ) public view returns (BonusInfo[] memory) {
        uint256[] storage managers = unoinsManagers[unionId];
        uint256 managersLength = managers.length;
        BonusInfo[] memory managersBonus = new BonusInfo[](managersLength);
        for(uint256 idx = 0; idx < managersLength; idx++) {
            managersBonus[idx].accountId = managers[idx];
            managersBonus[idx].bonusPercent = unoinsManagersBonusPercent[unionId][managers[idx]];
        }
        return managersBonus;
    }

    function getUnionBonusPercent(
        uint256 unionId
    ) public view returns (uint256) {
        uint256 totalBonusPercent = 0;
        uint256[] storage managers = unoinsManagers[unionId];
        for(uint256 idx = 0; idx < managers.length; idx++) {
            uint256 identity =  getMemberIdentity(unionId, managers[idx]);
            if(identity == 2) {
                totalBonusPercent = totalBonusPercent.add(unoinsManagersBonusPercent[unionId][managers[idx]]);
            }
        }
        return totalBonusPercent;
    }

    function getMemberIdentity(
        uint256 unionId,
        uint256 accountId
    ) public view returns(uint256){
        return IUnionMember(unionMemberContract).getMemberIdentity(unionId, accountId);
    }

    function getBelongUnion(
        uint256 accountId
    ) public view returns (uint256) {
        return IUnionMember(unionMemberContract).getBelongUnion(accountId);
    }

    function getUnionPools(
        uint256 unionId
    ) public view returns (PoolInfo[] memory) {
        return unoinsPools[unionId];
    }

    function getAccountLastClaimTime(
        uint256 unionId,
        uint256 accountId
    ) public view returns (uint256) {
        return unionAccountsClaimTime[unionId][accountId];
    }

    function setAccountContract(
        address _accountContract
    ) public onlyController {
        accountContract = _accountContract;
    }

    function setUnionMemberContract(
        address _unionMemberContract
    ) public onlyController {
        unionMemberContract = _unionMemberContract;
    }

    function setUnionContract(
        address _unionContract
    ) public onlyController {
        unionContract = _unionContract;
    }

    function setContributeContract(
        address _contributeContract
    ) public onlyController {
        contributeContract = _contributeContract;
    }

    function setRewardsWalletContract(
        address _rewardsWalletContract
    ) public onlyController {
        rewardsWalletContract = _rewardsWalletContract;
    }

    function setMaxLeaderRewardsPercent(
        uint256 _maxLeaderRewardsPercent
    ) public onlyController {
        maxLeaderRewardsPercent = _maxLeaderRewardsPercent;
    }

    function batchClaimReward(
        uint256[] calldata batchAccountIds
    ) public onlyController {
        for (uint256 idx; idx < batchAccountIds.length; idx++) {
            uint256 accountId = batchAccountIds[idx];
            require(accountId > 0, "Claim failed, account id must be > 0");
            address ownerAccount = IERC721(accountContract).ownerOf(accountId);
            uint256 unionId = getBelongUnion(accountId);
            require(unionId != 0, "Claim failed, you has no union");
            uint256 nowTime = block.timestamp;
            uint256 poolStartTime = nowTime-((nowTime-initializeTime)%duration);
            uint256 poolRewards = _earnedPool(unionId, accountId, poolStartTime);
            uint256 trueRewards = poolRewards;
            trueRewards = trueRewards.add(_earnedManager(unionId, accountId));
            if (trueRewards > 0) {
                _claimReward(unionId, accountId, poolRewards, poolStartTime);
                unionAccountsClaimTime[unionId][accountId] = nowTime;
                IRewardsWallet(rewardsWalletContract).transfer(ownerAccount, trueRewards);
                emit RewardsPaid(ownerAccount, trueRewards);
            }
        }
    }

    function setManagerBonusPercent(
        uint256 unionId,
        uint256 accountId,
        uint256 bonusPercent
    ) public {
        require(unionId > 0, "Set failed, union id must be > 0");
        require(accountId > 0, "Set failed, account id must be > 0");
        require(IERC721(unionContract).existsUnion(unionId), "Set failed, the union not exists");
        uint256 leaderAccountId = IERC721(accountContract).tokenOfOwnerByIndex(msg.sender,0);
        uint256 leaderIdentity = getMemberIdentity(unionId, leaderAccountId);
        require(leaderIdentity > 0, "Set failed, you is not in this union");
        require(leaderIdentity == 1, "Set failed, you do not have this permission");
        uint256 accountIdentity = getMemberIdentity(unionId, accountId);
        require(accountIdentity > 0, "Set failed, account is not in this union");
        require(accountIdentity == 2, "Set failed, account do not have this permission");
        uint256 expectBonusPercent = getUnionBonusPercent(unionId).add(bonusPercent).sub(unoinsManagersBonusPercent[unionId][accountId]);
        require(expectBonusPercent <= 1e18,"Set failed, exceed max bonus percent");
        unoinsManagersBonusPercent[unionId][accountId] = bonusPercent;
        unoinsManagers[unionId].push(accountId);
        emit SetBonusPercent(unionId, accountId, bonusPercent);

        uint256 removeCount = 0;
        uint256[] storage managers = unoinsManagers[unionId];
        for(uint256 idx = 0; idx < managers.length-removeCount; idx++) {
            uint256 identity =  getMemberIdentity(unionId, managers[idx]);
            if(identity != 2) {
                for(uint256 rev = managers.length-removeCount-1; rev > idx; rev--) {
                    uint256 revIdentity =  getMemberIdentity(unionId, managers[rev]);
                    if(revIdentity != 2) {
                        removeCount++;
                    } else {
                        unoinsManagers[unionId][idx] = unoinsManagers[unionId][managers.length-removeCount-1];
                        break;
                    }
                }
                removeCount++;
            }
        }

        for(uint256 idx = 0; idx < removeCount; idx++) {
            unoinsManagers[unionId].pop();
        }
    }

    function earned(
        uint256 accountId
    ) public view returns(uint256) {
        require(accountId > 0, "Claim failed, account id must be > 0");
        uint256 unionId = getBelongUnion(accountId);
        require(unionId != 0, "Claim failed, you has no union");
        uint256 nowTime = block.timestamp;
        uint256 poolStartTime = nowTime-((nowTime-initializeTime)%duration);
        uint256 poolRewards = _earnedPool(unionId, accountId, poolStartTime);
        uint256 trueRewards = poolRewards;
        trueRewards = trueRewards.add(_earnedManager(unionId, accountId));
        return trueRewards;
    }

    function earnedOfBonus(
        uint256 accountId
    ) public view returns(uint256) {
        require(accountId > 0, "Claim failed, account id must be > 0");
        uint256 unionId = getBelongUnion(accountId);
        require(unionId != 0, "Claim failed, you has no union");
        return _earnedManager(unionId, accountId);
    }

    function claimReward(
        uint256 accountId
    ) public {
        require(accountId > 0, "Claim failed, account id must be > 0");
        require(IERC721(accountContract).ownerOf(accountId) == msg.sender, "Claim failed, token is not owner");
        uint256 unionId = getBelongUnion(accountId);
        require(unionId != 0, "Claim failed, you has no union");
        uint256 nowTime = block.timestamp;
        uint256 poolStartTime = nowTime-((nowTime-initializeTime)%duration);
        uint256 poolRewards = _earnedPool(unionId, accountId, poolStartTime);
        uint256 trueRewards = poolRewards;
        trueRewards = trueRewards.add(_earnedManager(unionId, accountId));
        require(trueRewards > 0, "Claim failed, no rewards available");
        IRewardsWallet(rewardsWalletContract).transfer(msg.sender, trueRewards);
        _claimReward(unionId, accountId, poolRewards, poolStartTime);
        unionAccountsClaimTime[unionId][accountId] = nowTime;
        emit RewardsPaid(msg.sender, trueRewards);
    }

    function _earnedManager(
        uint256 unionId,
        uint256 accountId
    ) private view returns(uint256) {
        return unionManagersRewards[unionId][accountId];
    }

    function _earnedPool(
        uint256 unionId,
        uint256 accountId,
        uint256 poolStartTime
    ) private view returns(uint256) {
        address ownerAccount = IERC721(accountContract).ownerOf(accountId);
        uint256 amount =  IERC20(contributeContract).balanceOf(ownerAccount);
        uint256 unionAmount =  IERC20(contributeContract).getBalanceOfUnion(unionId);
        require(unionAmount > 0, "Claim failed, contribute must be > 0");
        uint256 trueRewards = 0;
        uint256 lastClaimTime = unionAccountsClaimTime[unionId][accountId];
        if (unoinsPools[unionId].length == 2 && lastClaimTime < poolStartTime) {
            PoolInfo[] storage pools = unoinsPools[unionId];
            if (pools[0].startTime == poolStartTime) {
                trueRewards = amount.mul(pools[1].rewardsAmount).div(unionAmount);
                trueRewards = Math.min(trueRewards, pools[1].rewardsAmount.sub(pools[1].claimedAmount));
            } else if (pools[1].startTime == poolStartTime) {
                trueRewards = amount.mul(pools[0].rewardsAmount).div(unionAmount);
                trueRewards = Math.min(trueRewards, pools[0].rewardsAmount.sub(pools[0].claimedAmount));
            } else {
                trueRewards = amount.mul(pools[0].rewardsAmount.sub(pools[0].claimedAmount)
                    .add(pools[1].rewardsAmount.sub(pools[1].claimedAmount))).div(unionAmount);
                uint256 unclaimedAmount = pools[0].rewardsAmount.sub(pools[0].claimedAmount)
                    .add(pools[1].rewardsAmount.sub(pools[1].claimedAmount));
                trueRewards = Math.min(trueRewards, unclaimedAmount);
            }
        }
        return trueRewards;
    }

    function _claimReward(
        uint256 unionId,
        uint256 accountId,
        uint256 poolRewards,
        uint256 poolStartTime
    ) private {
        unionManagersRewards[unionId][accountId] = 0;
        PoolInfo[] storage pools = unoinsPools[unionId];
        if (pools[0].startTime == poolStartTime) {
            pools[1].claimedAmount = pools[1].claimedAmount.add(poolRewards);
        } else if (pools[1].startTime == poolStartTime) {
            pools[0].claimedAmount = pools[0].claimedAmount.add(poolRewards);
        } else {
            pools[0].startTime = poolStartTime - duration;
            pools[0].rewardsAmount = pools[0].rewardsAmount
                .add(pools[1].rewardsAmount)
                .sub(pools[0].claimedAmount)
                .sub(pools[1].claimedAmount);
            pools[0].claimedAmount = poolRewards;
            pools[1].startTime = poolStartTime;
            pools[1].rewardsAmount = 0;
            pools[1].claimedAmount = 0;
        }
    }

    function unionWarRewards(
        uint256 unionId,
        uint256 rewardsAmount
    )public virtual override onlyController{
        require(IERC721(unionContract).existsUnion(unionId),"Reward failed, the union not exists");
        uint256 nowTime = block.timestamp;
        uint256 poolStartTime = nowTime-((nowTime-initializeTime)%duration);
        if (unoinsPools[unionId].length == 0)
        {
            PoolInfo memory pool = PoolInfo ({
                startTime : poolStartTime,
                rewardsAmount : 0,
                claimedAmount : 0
            });
            unoinsPools[unionId].push(pool);
            pool.startTime -= duration;
            unoinsPools[unionId].push(pool);
        }

        uint256 leaderRewardsAmount = rewardsAmount.mul(maxLeaderRewardsPercent).div(1e18);
        uint256 poolRewardsAmount = rewardsAmount.sub(leaderRewardsAmount);

        _unionWarManagerRewards(unionId, leaderRewardsAmount);
        _unionWarPoolRewards(unionId, poolRewardsAmount, poolStartTime);
        emit WarRewards(unionId, rewardsAmount);
    }

    function _unionWarManagerRewards(
        uint256 unionId,
        uint256 leaderRewardsAmount
    ) private {
        uint256 bonusRewardsAmount = 0;
        uint256[] storage managers = unoinsManagers[unionId];
        for(uint256 idx = 0; idx < managers.length; idx++) {
            uint256 accountId = managers[idx];
            uint256 identity =  getMemberIdentity(unionId, accountId);
            if(identity == 2) {
                uint256 managerBonusAmount = leaderRewardsAmount.mul(unoinsManagersBonusPercent[unionId][accountId]).div(1e18);
                unionManagersRewards[unionId][accountId] = unionManagersRewards[unionId][accountId].add(managerBonusAmount);
                bonusRewardsAmount = bonusRewardsAmount.add(managerBonusAmount);
            }
        }

        address leaderOwner = IERC721(unionContract).ownerOf(unionId);
        uint256 leaderAccountId = IERC721(accountContract).tokenOfOwnerByIndex(leaderOwner,0);
        unionManagersRewards[unionId][leaderAccountId] = unionManagersRewards[unionId][leaderAccountId].add(leaderRewardsAmount.sub(bonusRewardsAmount));
    }

    function _unionWarPoolRewards(
        uint256 unionId,
        uint256 poolRewardsAmount,
        uint256 poolStartTime
    ) private {
        PoolInfo[] storage pools = unoinsPools[unionId];
        if (pools[0].startTime == poolStartTime) {
            pools[0].rewardsAmount = pools[0].rewardsAmount.add(poolRewardsAmount);
        } else if (pools[1].startTime == poolStartTime) {
            pools[1].rewardsAmount = pools[1].rewardsAmount.add(poolRewardsAmount);
        } else {
            pools[0].startTime = poolStartTime - duration;
            pools[0].rewardsAmount = pools[0].rewardsAmount
                .add(pools[1].rewardsAmount)
                .sub(pools[0].claimedAmount)
                .sub(pools[1].claimedAmount);
            pools[0].claimedAmount = 0;
            pools[1].startTime = poolStartTime;
            pools[1].rewardsAmount = poolRewardsAmount;
            pools[1].claimedAmount = 0;
        }
    }

    struct PoolInfo {
        uint256 startTime;
        uint256 rewardsAmount;
        uint256 claimedAmount;
    }

    struct BonusInfo {
        uint256 accountId;
        uint256 bonusPercent;
    }
}