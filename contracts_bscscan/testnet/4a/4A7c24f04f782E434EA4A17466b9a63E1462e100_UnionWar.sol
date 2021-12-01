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


interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function existsUnion(uint256 unionId) external view returns (bool);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}


interface IUnionMember{
    function getMemberIdentity(uint256 unionId,uint256 accountId) external view returns(uint256);
}


interface IDistribute {
    function unionWarRewards(uint256 unionId, uint256 rewardsAmount) external;
}


contract UnionWar is Ownable {
    using SafeMath for uint256;

    address private accountContract;
    address private unionMemberContract;
    address private unionContract;
    address private distributeContract;

    uint256 private maxDifficultySize = 10000;
    uint256 private dailySeconds = 86400;

    uint256[] private difficulties;
    mapping(uint256 => uint256[]) private mapDifficultyMineIds;
    mapping(uint256 => MineInfo) private mapMines;

    mapping(uint256 => uint256[]) private mapUnionsOccupys;

    event RewardsAdded(uint256 indexed difficulty, uint256 indexed mineId, uint256 rewards);
    event Occupied(uint256 indexed unionId, uint256 difficulty, uint256 mineId);
    event Withdrawn(uint256 indexed unionId, uint256 difficulty, uint256 mineId);
    event Quitted(uint256 indexed unionId, uint256 operatorId, uint256 difficulty, uint256 mineId);
    event RewardsPaid(uint256 indexed unionId, uint256 operatorId, uint256 rewards);
    
    constructor(
        address _accountContract,
        address _unionMemberContract,
        address _unionContract,
        address _distributeContract
    ) {
        accountContract = _accountContract;
        unionMemberContract = _unionMemberContract;
        unionContract = _unionContract;
        distributeContract = _distributeContract;
    }

    function getAccountContract() public view returns(address) {
        return accountContract;
    }

    function getAccountId(
        address ownerAccount
    ) public view returns(uint256) {
        return IERC721(accountContract).tokenOfOwnerByIndex(ownerAccount, 0);
    }

    function getUnionMemberContract() public view returns(address) {
        return unionMemberContract;
    }

    function getUnionContract() public view returns(address) {
        return unionContract;
    }

    function getDistributeContract() public view returns(address) {
        return distributeContract;
    }

    function getDifficultiesLength() public view returns(uint256) {
        return difficulties.length;
    }

    function getDifficulties() public view returns(uint256[] memory) {
        return difficulties;
    }

    function getDifficultyByIndex(
        uint256 index
    ) public view returns(uint256) {
        return difficulties[index];
    }

    function isSupportedDifficulty(
        uint256 difficulty
    ) public view returns (bool) {
        bool isSupported = false;
        for(uint256 idx = 0; idx < difficulties.length; idx++){
            if(difficulties[idx] == difficulty){
                isSupported = true;
                break;
            }
        }
        return isSupported;
    }

    function getDifficultyMinesLength(
        uint256 difficulty
    ) public view returns(uint256) {
        return mapDifficultyMineIds[difficulty].length;
    }

    function getDifficultyMines(
        uint256 difficulty
    ) public view returns (MineInfo[] memory) {
        uint256[] storage mineIds = mapDifficultyMineIds[difficulty];
        MineInfo[] memory mines = new MineInfo[](mineIds.length);
        uint256 nowTime = block.timestamp;
        for(uint256 idx = 0; idx < mineIds.length; idx++) {
            uint256 mineKey = _genMineKey(difficulty, mineIds[idx]);
            mines[idx] = mapMines[mineKey];
            uint256 totalRewards = _earned(mines[idx], nowTime);
            mines[idx].totalRewards = totalRewards;
        }
        return mines;
    }

    function getDifficultyMinesByIndex(
        uint256 difficulty,
        uint256 index
    ) public view returns (MineInfo memory) {
        uint256 mineId = mapDifficultyMineIds[difficulty][index];
        uint256 nowTime = block.timestamp;
        uint256 mineKey = _genMineKey(difficulty, mineId);
        MineInfo memory mine = mapMines[mineKey];
        uint256 totalRewards = _earned(mine, nowTime);
        mine.totalRewards = totalRewards;
        return mine;
    }

    function getMineInfo(
        uint256 difficulty,
        uint256 mineId
    ) public view returns (MineInfo memory) {
        uint256 nowTime = block.timestamp;
        uint256 mineKey = _genMineKey(difficulty, mineId);
        MineInfo memory mine = mapMines[mineKey];
        uint256 totalRewards = _earned(mine, nowTime);
        mine.totalRewards = totalRewards;
        return mine;
    }

    function isSupportedMine(
        uint256 difficulty,
        uint256 mineId
    ) public view returns (bool) {
        bool isSupported = false;
        if(isSupportedDifficulty(difficulty)){
            uint256[] storage mineIds = mapDifficultyMineIds[difficulty];
            for(uint256 idx = 0; idx < mineIds.length; idx++) {
                if(mineIds[idx] == mineId){
                    isSupported = true;
                    break;
                }
            }
        }
        return isSupported;
    }

    function getUnionOccupyMinesLength(
        uint256 unionId
    ) public view returns(uint256) {
        return mapUnionsOccupys[unionId].length;
    }

    function getUnionOccupyMines(
        uint256 unionId
    ) public view returns (MineInfo[] memory) {
        uint256[] storage mineKeys = mapUnionsOccupys[unionId];
        MineInfo[] memory mines = new MineInfo[](mineKeys.length);
        uint256 nowTime = block.timestamp;
        for(uint256 idx = 0; idx < mineKeys.length; idx++) {
            mines[idx] = mapMines[mineKeys[idx]];
            uint256 totalRewards = _earned(mines[idx], nowTime);
            mines[idx].totalRewards = totalRewards;
        }
        return mines;
    }

    function getUnionOccupyMineByIndex(
        uint256 unionId,
        uint256 index
    ) public view returns (MineInfo memory) {
        uint256 nowTime = block.timestamp;
        MineInfo memory mine = mapMines[mapUnionsOccupys[unionId][index]];
        uint256 totalRewards = _earned(mine, nowTime);
        mine.totalRewards = totalRewards;
        return mine;
    }

    function isUnionOccupyMine(
        uint256 unionId,
        uint256 difficulty,
        uint256 mineId
    ) public view returns (bool) {
        bool isOccupy = false;
        uint256 mineKey = _genMineKey(difficulty, mineId);
        uint256[] storage unionOccupys = mapUnionsOccupys[unionId];
        for(uint256 idx = 0; idx < unionOccupys.length; idx++) {
            if(unionOccupys[idx] == mineKey) {
                isOccupy = true;
                break;
            }
        }
        return isOccupy;
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

    function setDistributeContract(
        address _distributeContract
    ) public onlyController {
        distributeContract = _distributeContract;
    }

    function addDifficulty(
        uint256 difficulty
    ) public onlyController {
        require(difficulty < maxDifficultySize, "Add failed, difficulty exceed limit");
        difficulties.push(difficulty);
    }

    function removeDifficulty(
        uint256 difficulty
    ) public onlyController {
        bool isAllowRemove = true;
        uint256[] storage mineIds = mapDifficultyMineIds[difficulty];
        for(uint256 idx = 0; idx < mineIds.length; idx++) {
            if (mapMines[_genMineKey(difficulty, mineIds[idx])].mineStatus == 2) {
                isAllowRemove = false;
                break;
            }
        }
        require(isAllowRemove, "Remove failed, unsupported remove");
        uint256 removeIndex = 0;
        uint256 difficultiesLength = difficulties.length;
        for(uint256 idx = 0; idx < difficultiesLength; idx++) {
            if(difficulties[idx] == difficulty) {
                removeIndex = idx;
                break;
            }
        }
        for(uint256 idx = removeIndex; idx < difficultiesLength-1; idx++){
            difficulties[idx] = difficulties[idx+1];
        }
        difficulties.pop();
    }

    function addMineInfo(
        uint256 _mineId,
        uint256 _difficulty,
        string calldata _monsterIcon,
        uint256 _dailyRewards
    ) public onlyController {
        require(isSupportedDifficulty(_difficulty), "Add failed, unsupported difficulty");
        require(!isSupportedMine(_difficulty, _mineId), "Add failed, mine already exists");
        MineInfo memory mine = MineInfo ({
            mineId : _mineId,
            difficulty : _difficulty,
            mineStatus : 1,
            monsterIcon : _monsterIcon,
            dailyRewards : _dailyRewards,
            lastUpdateTime : block.timestamp,
            paidRewards : 0,
            totalRewards : 0,
            unionId : 0,
            occupyTime : 0
        });
        uint256 mineKey = _genMineKey(_difficulty, _mineId);
        mapMines[mineKey] = mine;
        mapDifficultyMineIds[_difficulty].push(_mineId);
        emit RewardsAdded(_difficulty, _mineId, _dailyRewards);
    }

    function removeMineInfo(
        uint256 difficulty,
        uint256 mineId
    ) public onlyController {
        uint256 mineKey = _genMineKey(difficulty, mineId);
        MineInfo memory mine = mapMines[mineKey];
        require(mine.mineStatus == 0 || mine.mineStatus == 1, "Remove failed, unsupported remove");
        uint256 removeIndex = 0;
        uint256 mineIdsLength = mapDifficultyMineIds[difficulty].length;
        for(uint256 idx = 0; idx < mineIdsLength; idx++) {
            if(mapDifficultyMineIds[difficulty][idx] == mineId) {
                removeIndex = idx;
                break;
            }
        }

        for(uint256 idx = removeIndex; idx < mineIdsLength-1; idx++){
            mapDifficultyMineIds[difficulty][idx] = mapDifficultyMineIds[difficulty][idx+1];
        }
        mapDifficultyMineIds[difficulty].pop();
    }

    function openMine(
        uint256 difficulty,
        uint256 mineId
    ) public onlyController {
        uint256 mineKey = _genMineKey(difficulty, mineId);
        require(mapMines[mineKey].mineStatus == 0, "Open failed, mine already opened");
        mapMines[mineKey].mineStatus = 1;
    }

    function closeMine(
        uint256 difficulty,
        uint256 mineId
    ) public onlyController {
        uint256 mineKey = _genMineKey(difficulty, mineId);
        MineInfo storage mine = mapMines[mineKey];
        require(mine.mineStatus != 0, "Close failed, mine already closed");
        uint256 nowTime = block.timestamp;
        if (mine.mineStatus == 2) {
            _withdrawAndClaim(mine, nowTime);
        }
        mapMines[mineKey].mineStatus = 0;
    }

    function changeMonsterIcon(
        uint256 difficulty,
        uint256 mineId,
        string calldata monsterIcon
    ) public onlyController {
        uint256 mineKey = _genMineKey(difficulty, mineId);
        mapMines[mineKey].monsterIcon = monsterIcon;
    }

    function changeDailyRewards(
        uint256 difficulty,
        uint256 mineId,
        uint256 dailyRewards
    ) public onlyController {
        uint256 mineKey = _genMineKey(difficulty, mineId);
        uint256 nowTime = block.timestamp;
        _updateRewards(mapMines[mineKey], nowTime);
        mapMines[mineKey].dailyRewards = dailyRewards;
        emit RewardsAdded(difficulty, mineId, dailyRewards);
    }

    function occupy(
        uint256 unionId,
        uint256 difficulty,
        uint256 mineId
    ) public onlyController {
        require(IERC721(unionContract).existsUnion(unionId),"Occupy failed, the union not exists");
        require(isSupportedMine(difficulty, mineId), "Occupy failed, unsupported mine");
        require(!isUnionOccupyMine(unionId, difficulty, mineId), "Occupy failed, union already occupied mine");
        uint256 mineKey = _genMineKey(difficulty, mineId);
        MineInfo storage mine = mapMines[mineKey];
        require(mine.mineStatus != 0, "Occupy failed, mine not yet open");
        uint256 nowTime = block.timestamp;
        if (mine.mineStatus == 2) {
            _withdrawAndClaim(mine, nowTime);
        }

        mine.mineStatus = 2;
        mine.unionId = unionId;
        mine.occupyTime = nowTime;
        mapUnionsOccupys[unionId].push(mineKey);
        emit Occupied(unionId, difficulty, mineId);
    }

    function earned(
        uint256 difficulty,
        uint256 mineId
    ) public view returns (uint256) {
        uint256 earnedRewards = 0;
        if (isSupportedMine(difficulty, mineId)) {
            uint256 mineKey = _genMineKey(difficulty, mineId);
            uint256 nowTime = block.timestamp;
            earnedRewards = _earned(mapMines[mineKey], nowTime);
        }
        return earnedRewards;
    }

    function claimReward(
        uint256 unionId,
        uint256 difficulty,
        uint256 mineId
    ) public {
        require(isUnionOccupyMine(unionId, difficulty, mineId), "Claim failed, union is not occupy mine");
        uint256 identity =  IUnionMember(unionMemberContract).getMemberIdentity(unionId, getAccountId(msg.sender));
        require(identity == 1 || identity == 2, "Claim failed, account is not permission");
        uint256 mineKey = _genMineKey(difficulty, mineId);
        uint256 nowTime = block.timestamp;
        _updateRewards(mapMines[mineKey], nowTime);
        uint256 operatorId = IERC721(accountContract).tokenOfOwnerByIndex(msg.sender, 0);
        _claimReward(mapMines[mineKey], operatorId, nowTime);
    }

    function quitOccupy(
        uint256 unionId,
        uint256 difficulty,
        uint256 mineId
    ) public {
        require(isUnionOccupyMine(unionId, difficulty, mineId), "Quit failed, union is not occupy mine");
        uint256 identity =  IUnionMember(unionMemberContract).getMemberIdentity(unionId, getAccountId(msg.sender));
        require(identity == 1 || identity == 2, "Quit failed, account is not permission");
        uint256 mineKey = _genMineKey(difficulty, mineId);
        uint256 nowTime = block.timestamp;
        uint256 operatorId = IERC721(accountContract).tokenOfOwnerByIndex(msg.sender, 0);
        _quitOccupy(mapMines[mineKey], operatorId, nowTime);
    }

    function _updateRewards(
        MineInfo storage mine,
        uint256 nowTime
    ) private {
        if (mine.mineStatus == 2) {
            mine.paidRewards = _earned(mine, nowTime);
        }
        mine.lastUpdateTime = nowTime;
    }

    function _earned(
        MineInfo memory mine,
        uint256 nowTime
    ) private view returns (uint256) {
        uint256 currentRewards = 0;
        if (mine.mineStatus == 2) {
            currentRewards = mine.dailyRewards
                .mul(nowTime.sub(mine.lastUpdateTime))
                .div(dailySeconds)
                .add(mine.paidRewards);
        }

        return currentRewards;
    }

    function _withdrawAndClaim(
        MineInfo storage mine,
        uint256 nowTime
    ) private {
        _updateRewards(mine, nowTime);
        _claimReward(mine, 0, nowTime);

        emit Withdrawn(mine.unionId, mine.difficulty, mine.mineId);
        _removeOccupy(mine.unionId, mine.difficulty, mine.mineId);
        mine.mineStatus = 1;
        mine.unionId = 0;
        mine.occupyTime = 0;
    }

    function _quitOccupy(
        MineInfo storage mine,
        uint256 operatorId,
        uint256 nowTime
    ) private {
        _updateRewards(mine, nowTime);
        _claimReward(mine, operatorId, nowTime);

        emit Quitted(mine.unionId, operatorId, mine.difficulty, mine.mineId);
        _removeOccupy(mine.unionId, mine.difficulty, mine.mineId);
        mine.mineStatus = 1;
        mine.unionId = 0;
        mine.occupyTime = 0;
    }

    function _claimReward(
        MineInfo storage mine,
        uint256 operatorId,
        uint256 nowTime
    ) private {
        uint256 trueRewards = _earned(mine, nowTime);
        if (trueRewards > 0) {
            mine.paidRewards = 0;
            IDistribute(distributeContract).unionWarRewards(mine.unionId, trueRewards);
            emit RewardsPaid(mine.unionId, operatorId, trueRewards);
        }
    }

    function _removeOccupy(
        uint256 unionId,
        uint256 difficulty,
        uint256 mineId
    ) private {
        uint256 mineKey = _genMineKey(difficulty, mineId);
        uint256 removeIndex = 0;
        uint256 minesLength = mapUnionsOccupys[unionId].length;
        for(uint256 idx = 0; idx < minesLength; idx++) {
            if(mapUnionsOccupys[unionId][idx] == mineKey) {
                removeIndex = idx;
                break;
            }
        }
        for(uint256 idx = removeIndex; idx < minesLength-1; idx++){
            mapUnionsOccupys[unionId][idx] = mapUnionsOccupys[unionId][idx+1];
        }
        mapUnionsOccupys[unionId].pop();
    }

    function _genMineKey(
        uint256 difficulty,
        uint256 mineId
    ) private view returns (uint256) {
        return mineId.mul(maxDifficultySize).add(difficulty);
    }

    struct MineInfo {
        uint256 mineId;
        uint256 difficulty;
        uint256 mineStatus;
        string  monsterIcon;
        uint256 dailyRewards;
        uint256 lastUpdateTime;
        uint256 paidRewards;
        uint256 totalRewards;
        uint256 unionId;
        uint256 occupyTime;
    }
}