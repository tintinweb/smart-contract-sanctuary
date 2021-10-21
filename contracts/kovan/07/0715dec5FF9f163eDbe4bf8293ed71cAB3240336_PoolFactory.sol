/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]



pragma solidity ^0.8.0;

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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


// File @openzeppelin/contracts/utils/structs/[email protected]



pragma solidity ^0.8.0;

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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}


// File contracts/PoolFactory.sol


pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;



    ///@title Pool Factory
    /**
    @author @viken33 and @famole
    This contract is used to create and join Tournament Pools on the BlockBets Dapp
    It allows Blockbets to create and finish time-based tournament pools
    It allows players to join tournaments pools for their favourite games
    @dev We use Open Zeppelin SafeMath, EnumerableSet and Ownable libraries
    */
contract PoolFactory is Ownable {
    
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;    
    
    struct Pool {
        uint256 game;               // game {1: MW, 2: WZ}
        uint256 gameMode;           // gameMode { 1: MP challenge, 2: WZ challenge, 3: WZ kill race }
        uint256 currentPrize;
        uint256 entryFee;
        bool finished;
        address winner;
        uint256 startOn;
        uint256 finishOn;
        address payable[] players;
        mapping(address => bool) joined;
        uint256 firstFee;
        uint256 secondFee;
        uint256 thirdFee;
    }
    
    
    
    uint256 public poolCount;                       // historic counter, poolId comes from the counter
    uint256 public bbFee;                            // generate PoolIds by counting
    mapping(uint256 => Pool) public pools;                   // PoolId => Pool Struct
    mapping(address => uint256[]) public userPools;          // maps player => joined Pools 
    EnumerableSet.UintSet private activePools;    // set of current active Pools
   
    
    /** 
    * @dev Event emitted on new pool created
    * @param poolId pool Id
    * @param _game game Id
    * @param _gameMode game Mode Id
    * @param _currentPrize initial pool prize
    * @param _entryFee entry fee to join the pool
    * @param _startOn unix start epoch in ms
    * @param _finishOn unix finish epoch in ms
    * @param _firstFee percentage fee of 1st place
    * @param _secondFee percentage fee of 2nd place
    * @param _thirdFee percentage fee of 3d place
    */
    event NewPool(
        uint256 indexed poolId,
        uint256 _game,
        uint256 _gameMode,
        uint256 _currentPrize,
        uint256 _entryFee,
        uint256 _startOn,
        uint256 _finishOn,
        uint256 _firstFee,
        uint256 _secondFee,
        uint256 _thirdFee
        );
        
    /** 
    * @dev Event emitted on cancelled pool
    * @param _poolId pool Id of cancelled pool
    */    
    event CancelPool(uint256 indexed _poolId);
    /** 
    * @dev Event emitted when a player leaves a pool
    * @param _player player who leaves the pool
    * @param _poolId pool Id
    */ 
    event PoolLeftBy(uint256 indexed _poolId, address _player);
    /** 
    * @dev Event emitted when a player joins a pool
    * @param _player player who joins the pool
    * @param _poolId pool Id
    */ 
    event PoolJoinedBy(uint256 indexed _poolId, address _player);
    /** 
    * @dev Event emitted on a finished pool
    * @param _poolId pool Id
    * @param _winner winner of the pool tournament
    */ 
    event PoolFinished(uint256 indexed _poolId, address _winner);
    
    /** 
    * @dev Initializes pool count and bbFee
    */
    constructor() {
        poolCount = 0;
        bbFee = 2; // 2% fee
    }

    /** 
    * @dev Creates a new Pool providing entryFee, CurrentPrize, start and finish times. <br>
    * @dev The transaction value must be equal to initial pool prize. <br>
    * @dev Prizes and fees are in uint256, start and finish times are Unix Epochs in miliseconds. <br>
    * @dev Fees are uint expressed in percentages i.e. a value of 10 means 10% fee, the sum of the 3 fees must equal a 100
    * @param _game game Id
    * @param _gameMode game Mode Id
    * @param _currentPrize initial pool prize
    * @param _entryFee entry fee to join the pool
    * @param _startOn unix start epoch in ms
    * @param _finishOn unix finish epoch in ms
    * @param _firstFee percentage fee of 1st place
    * @param _secondFee percentage fee of 2nd place
    * @param _thirdFee percentage fee of 3d place
    * @return PoolId (uint256)
    */
    
    function createPool(
        uint256 _game,
        uint256 _gameMode,
        uint256 _currentPrize,
        uint256 _entryFee,
        uint256 _startOn,
        uint256 _finishOn,
        uint256 _firstFee,
        uint256 _secondFee,
        uint256 _thirdFee) public payable onlyOwner returns(uint256){
       
        require(_startOn >= 0, "wrong startOn");
        require(_finishOn >= 0, "wrong finishOn");
        require(_firstFee + _secondFee + _thirdFee == 100, "wrong prize fee structure");
        require(msg.value == _currentPrize, "value must be equal to _currentPrize");
        
        Pool storage pool = pools[poolCount++];
            pool.game = _game;
            pool.gameMode = _gameMode;
            pool.currentPrize = _currentPrize;
            pool.entryFee = _entryFee;
            pool.finished = false;
            pool.winner = address(0);
            pool.startOn = _startOn;
            pool.finishOn = _finishOn;
            pool.firstFee = _firstFee;
            pool.secondFee = _secondFee;
            pool.thirdFee = _thirdFee;
            
            EnumerableSet.add(activePools, poolCount);
            
            emit NewPool(poolCount, pool.game, pool.gameMode, pool.currentPrize, pool.entryFee, pool.startOn, pool.finishOn, pool.firstFee, pool.secondFee, pool.thirdFee);
            return poolCount;
    }
    
    /** 
    * @dev Allows players to join a pool
    * @dev if the pool has an entry fee it should be equal to msg.value
    */

    function joinPool(uint256 _poolId) public payable {
        require(msg.value == pools[_poolId].entryFee, "wrong entryFee sent");
        require(pools[_poolId].finished == false, "pool is finished");
        require(pools[_poolId].joined[msg.sender] == false , "address already in pool");
        Pool storage p = pools[_poolId];
        p.currentPrize = p.currentPrize.add(msg.value);
        p.players.push(payable(msg.sender));
        p.joined[msg.sender] = true;
        userPools[msg.sender].push(_poolId);
                
        emit PoolJoinedBy(_poolId, msg.sender);
        
    }
    
    /** 
    * @dev Allows players to leave the pool if they change their mind before it starts
    * @dev Already started pools can't be left
    */

    function leavePool(uint256 _poolId) public {
        require(pools[_poolId].joined[msg.sender] == true, "address not in pool");
        require(pools[_poolId].startOn > block.timestamp, "pool already started");
        pools[_poolId].joined[msg.sender] = false;
        pools[_poolId].currentPrize = pools[_poolId].currentPrize.sub(pools[_poolId].entryFee);
        payable(msg.sender).transfer(pools[_poolId].entryFee);
        // remove from UserPools and players
        for (uint i = 0; i < pools[_poolId].players.length; i++) {
            if (pools[_poolId].players[i] == msg.sender) {
            delete pools[_poolId].players[i];
            }
        }
        for (uint i = 0; i < userPools[msg.sender].length; i++) {
            if (userPools[msg.sender][i] == _poolId) {
            delete userPools[msg.sender][i];
            }
        }
        emit PoolLeftBy(_poolId, msg.sender);
    }

    /** 
    * @dev View function to retrieve joined pools for a given player(address)
    * @param _addr address of player
    */

    function viewPools(address _addr) public view returns(uint256[] memory _userPools) {
        return userPools[_addr];
    }

    /** 
    * @dev View function to retrieve players of a given pool
    * @param _poolId pool id number
    * @return _users an array of players addresses
    */

    function viewPoolPlayers(uint256 _poolId) public view returns(address payable[] memory _users) {
        return pools[_poolId].players;
    }

    /** 
    * @dev View function to retrieve current active Pools
    * @return _activePools an array of pool Ids
    */

    function viewActivePools() public view returns(uint256[] memory _activePools) {
        return activePools.values();
    }
     
    /** 
    * @dev Admin function to finish a pool
    * @param _poolId id of the pool to finish
    * @param _winner1 address of the first place
    * @param _winner2 address of the second place
    * @param _winner3 address of the third place
    * 
    */

    function finishPool(uint256 _poolId, address payable _winner1, address payable _winner2, address payable _winner3) public onlyOwner {
        // call with Pool Id and address of winner, in case of draw should be called address owner as winner
        
        Pool storage poo = pools[_poolId];
        require(poo.finishOn < block.timestamp, "pool period not ended");
        require(poo.joined[_winner1] && poo.joined[_winner2] && poo.joined[_winner3], "winner not in pool !");
      
        address payable _owner = payable(address(uint160(owner())));
        // uint256 ownersCut = poo.currentPrize.mul(bbFee).div(100);
        _owner.transfer(poo.currentPrize.mul(bbFee).div(100));
        poo.currentPrize = (poo.currentPrize).sub(poo.currentPrize.mul(bbFee).div(100));

        _winner1.transfer((poo.currentPrize).mul(poo.firstFee).div(100));
        _winner2.transfer((poo.currentPrize).mul(poo.secondFee).div(100));
        _winner3.transfer((poo.currentPrize).mul(poo.thirdFee).div(100));
        poo.currentPrize = 0;
        poo.finished = true;
        poo.winner = _winner1;
        EnumerableSet.remove(activePools, _poolId);
        
        emit PoolFinished(_poolId, _winner1);
    }
    
    /** 
    * @dev Admin function to cancel a pool
    * it returns the entry fee to all the players who joined, and the prize pool to owner
    * @param _poolId id of the pool to finish
    * 
    */

    function cancelPool(uint256 _poolId) public onlyOwner {
        
        if (pools[_poolId].entryFee > 0) {
        for (uint i = 0; i < pools[_poolId].players.length; i++) {
            if (pools[_poolId].joined[pools[_poolId].players[i]]) {
            pools[_poolId].players[i].transfer(pools[_poolId].entryFee);
            }
          }
        }

        if (pools[_poolId].currentPrize > 0) {
            address payable _owner = payable(address(uint160(owner())));
            _owner.transfer(pools[_poolId].currentPrize);
        }
                       
        delete pools[_poolId];
        EnumerableSet.remove(activePools, _poolId);
        emit CancelPool(_poolId);
    }
    
    /** 
    * @dev Admin function to update protocol fee
    * @param _newFee new fee to set
    * 
    */

    function updateFee(uint256 _newFee) public onlyOwner {
          bbFee = _newFee;
      }
   
}