// File: contracts/IManager.sol

pragma solidity ^0.5.11;


contract IManager {
    event SetController(address controller);
    event ParameterUpdate(string param);

    function setController(address _controller) external;
}

// File: contracts/zeppelin/Ownable.sol

pragma solidity ^0.5.11;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

  /**
   * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// File: contracts/zeppelin/Pausable.sol

pragma solidity ^0.5.11;



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

// File: contracts/IController.sol

pragma solidity ^0.5.11;



contract IController is Pausable {
    event SetContractInfo(bytes32 id, address contractAddress, bytes20 gitCommitHash);

    function setContractInfo(bytes32 _id, address _contractAddress, bytes20 _gitCommitHash) external;
    function updateController(bytes32 _id, address _controller) external;
    function getContract(bytes32 _id) public view returns (address);
}

// File: contracts/Manager.sol

pragma solidity ^0.5.11;




contract Manager is IManager {
    // Controller that contract is registered with
    IController public controller;

    // Check if sender is controller
    modifier onlyController() {
        require(msg.sender == address(controller), "caller must be Controller");
        _;
    }

    // Check if sender is controller owner
    modifier onlyControllerOwner() {
        require(msg.sender == controller.owner(), "caller must be Controller owner");
        _;
    }

    // Check if controller is not paused
    modifier whenSystemNotPaused() {
        require(!controller.paused(), "system is paused");
        _;
    }

    // Check if controller is paused
    modifier whenSystemPaused() {
        require(controller.paused(), "system is not paused");
        _;
    }

    constructor(address _controller) public {
        controller = IController(_controller);
    }

    /**
     * @notice Set controller. Only callable by current controller
     * @param _controller Controller contract address
     */
    function setController(address _controller) external onlyController {
        controller = IController(_controller);

        emit SetController(_controller);
    }
}

// File: contracts/ManagerProxyTarget.sol

pragma solidity ^0.5.11;



/**
 * @title ManagerProxyTarget
 * @notice The base contract that target contracts used by a proxy contract should inherit from
 * @dev Both the target contract and the proxy contract (implemented as ManagerProxy) MUST inherit from ManagerProxyTarget in order to guarantee
 that both contracts have the same storage layout. Differing storage layouts in a proxy contract and target contract can
 potentially break the delegate proxy upgradeability mechanism
 */
contract ManagerProxyTarget is Manager {
    // Used to look up target contract address in controller's registry
    bytes32 public targetContractId;
}

// File: contracts/bonding/IBondingManager.sol

pragma solidity ^0.5.11;


/**
 * @title Interface for BondingManager
 * TODO: switch to interface type
 */
contract IBondingManager {
    event TranscoderUpdate(address indexed transcoder, uint256 rewardCut, uint256 feeShare);
    event TranscoderActivated(address indexed transcoder, uint256 activationRound);
    event TranscoderDeactivated(address indexed transcoder, uint256 deactivationRound);
    event TranscoderSlashed(address indexed transcoder, address finder, uint256 penalty, uint256 finderReward);
    event Reward(address indexed transcoder, uint256 amount);
    event Bond(address indexed newDelegate, address indexed oldDelegate, address indexed delegator, uint256 additionalAmount, uint256 bondedAmount);
    event Unbond(address indexed delegate, address indexed delegator, uint256 unbondingLockId, uint256 amount, uint256 withdrawRound);
    event Rebond(address indexed delegate, address indexed delegator, uint256 unbondingLockId, uint256 amount);
    event WithdrawStake(address indexed delegator, uint256 unbondingLockId, uint256 amount, uint256 withdrawRound);
    event WithdrawFees(address indexed delegator);
    event EarningsClaimed(address indexed delegate, address indexed delegator, uint256 rewards, uint256 fees, uint256 startRound, uint256 endRound);

    // Deprecated events
    // These event signatures can be used to construct the appropriate topic hashes to filter for past logs corresponding
    // to these deprecated events.
    // event Bond(address indexed delegate, address indexed delegator);
    // event Unbond(address indexed delegate, address indexed delegator);
    // event WithdrawStake(address indexed delegator);
    // event TranscoderUpdate(address indexed transcoder, uint256 pendingRewardCut, uint256 pendingFeeShare, uint256 pendingPricePerSegment, bool registered);
    // event TranscoderEvicted(address indexed transcoder);
    // event TranscoderResigned(address indexed transcoder);

    // External functions
    function updateTranscoderWithFees(address _transcoder, uint256 _fees, uint256 _round) external;
    function slashTranscoder(address _transcoder, address _finder, uint256 _slashAmount, uint256 _finderFee) external;
    function setCurrentRoundTotalActiveStake() external;

    // Public functions
    function getTranscoderPoolSize() public view returns (uint256);
    function transcoderTotalStake(address _transcoder) public view returns (uint256);
    function isActiveTranscoder(address _transcoder) public view returns (bool);
    function getTotalBonded() public view returns (uint256);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts/libraries/SortedDoublyLL.sol

pragma solidity ^0.5.11;



/**
 * @title A sorted doubly linked list with nodes sorted in descending order. Optionally accepts insert position hints
 *
 * Given a new node with a `key`, a hint is of the form `(prevId, nextId)` s.t. `prevId` and `nextId` are adjacent in the list.
 * `prevId` is a node with a key >= `key` and `nextId` is a node with a key <= `key`. If the sender provides a hint that is a valid insert position
 * the insert operation is a constant time storage write. However, the provided hint in a given transaction might be a valid insert position, but if other transactions are included first, when
 * the given transaction is executed the provided hint may no longer be a valid insert position. For example, one of the nodes referenced might be removed or their keys may
 * be updated such that the the pair of nodes in the hint no longer represent a valid insert position. If one of the nodes in the hint becomes invalid, we still try to use the other
 * valid node as a starting point for finding the appropriate insert position. If both nodes in the hint become invalid, we use the head of the list as a starting point
 * to find the appropriate insert position.
 */
library SortedDoublyLL {
    using SafeMath for uint256;

    // Information for a node in the list
    struct Node {
        uint256 key;                     // Node's key used for sorting
        address nextId;                  // Id of next node (smaller key) in the list
        address prevId;                  // Id of previous node (larger key) in the list
    }

    // Information for the list
    struct Data {
        address head;                        // Head of the list. Also the node in the list with the largest key
        address tail;                        // Tail of the list. Also the node in the list with the smallest key
        uint256 maxSize;                     // Maximum size of the list
        uint256 size;                        // Current size of the list
        mapping (address => Node) nodes;     // Track the corresponding ids for each node in the list
    }

    /**
     * @dev Set the maximum size of the list
     * @param _size Maximum size
     */
    function setMaxSize(Data storage self, uint256 _size) public {
        require(_size > self.maxSize, "new max size must be greater than old max size");

        self.maxSize = _size;
    }

    /**
     * @dev Add a node to the list
     * @param _id Node's id
     * @param _key Node's key
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */
    function insert(Data storage self, address _id, uint256 _key, address _prevId, address _nextId) public {
        // List must not be full
        require(!isFull(self), "list is full");
        // List must not already contain node
        require(!contains(self, _id), "node already in list");
        // Node id must not be null
        require(_id != address(0), "node id is null");
        // Key must be non-zero
        require(_key > 0, "key is zero");

        address prevId = _prevId;
        address nextId = _nextId;

        if (!validInsertPosition(self, _key, prevId, nextId)) {
            // Sender's hint was not a valid insert position
            // Use sender's hint to find a valid insert position
            (prevId, nextId) = findInsertPosition(self, _key, prevId, nextId);
        }

        self.nodes[_id].key = _key;

        if (prevId == address(0) && nextId == address(0)) {
            // Insert as head and tail
            self.head = _id;
            self.tail = _id;
        } else if (prevId == address(0)) {
            // Insert before `prevId` as the head
            self.nodes[_id].nextId = self.head;
            self.nodes[self.head].prevId = _id;
            self.head = _id;
        } else if (nextId == address(0)) {
            // Insert after `nextId` as the tail
            self.nodes[_id].prevId = self.tail;
            self.nodes[self.tail].nextId = _id;
            self.tail = _id;
        } else {
            // Insert at insert position between `prevId` and `nextId`
            self.nodes[_id].nextId = nextId;
            self.nodes[_id].prevId = prevId;
            self.nodes[prevId].nextId = _id;
            self.nodes[nextId].prevId = _id;
        }

        self.size = self.size.add(1);
    }

    /**
     * @dev Remove a node from the list
     * @param _id Node's id
     */
    function remove(Data storage self, address _id) public {
        // List must contain the node
        require(contains(self, _id), "node not in list");

        if (self.size > 1) {
            // List contains more than a single node
            if (_id == self.head) {
                // The removed node is the head
                // Set head to next node
                self.head = self.nodes[_id].nextId;
                // Set prev pointer of new head to null
                self.nodes[self.head].prevId = address(0);
            } else if (_id == self.tail) {
                // The removed node is the tail
                // Set tail to previous node
                self.tail = self.nodes[_id].prevId;
                // Set next pointer of new tail to null
                self.nodes[self.tail].nextId = address(0);
            } else {
                // The removed node is neither the head nor the tail
                // Set next pointer of previous node to the next node
                self.nodes[self.nodes[_id].prevId].nextId = self.nodes[_id].nextId;
                // Set prev pointer of next node to the previous node
                self.nodes[self.nodes[_id].nextId].prevId = self.nodes[_id].prevId;
            }
        } else {
            // List contains a single node
            // Set the head and tail to null
            self.head = address(0);
            self.tail = address(0);
        }

        delete self.nodes[_id];
        self.size = self.size.sub(1);
    }

    /**
     * @dev Update the key of a node in the list
     * @param _id Node's id
     * @param _newKey Node's new key
     * @param _prevId Id of previous node for the new insert position
     * @param _nextId Id of next node for the new insert position
     */
    function updateKey(Data storage self, address _id, uint256 _newKey, address _prevId, address _nextId) public {
        // List must contain the node
        require(contains(self, _id), "node not in list");

        // Remove node from the list
        remove(self, _id);

        if (_newKey > 0) {
            // Insert node if it has a non-zero key
            insert(self, _id, _newKey, _prevId, _nextId);
        }
    }

    /**
     * @dev Checks if the list contains a node
     * @param _id Address of transcoder
     * @return true if '_id' is in list
     */
    function contains(Data storage self, address _id) public view returns (bool) {
        // List only contains non-zero keys, so if key is non-zero the node exists
        return self.nodes[_id].key > 0;
    }

    /**
     * @dev Checks if the list is full
     * @return true if list is full
     */
    function isFull(Data storage self) public view returns (bool) {
        return self.size == self.maxSize;
    }

    /**
     * @dev Checks if the list is empty
     * @return true if list is empty
     */
    function isEmpty(Data storage self) public view returns (bool) {
        return self.size == 0;
    }

    /**
     * @dev Returns the current size of the list
     * @return current size of the list
     */
    function getSize(Data storage self) public view returns (uint256) {
        return self.size;
    }

    /**
     * @dev Returns the maximum size of the list
     */
    function getMaxSize(Data storage self) public view returns (uint256) {
        return self.maxSize;
    }

    /**
     * @dev Returns the key of a node in the list
     * @param _id Node's id
     * @return key for node with '_id'
     */
    function getKey(Data storage self, address _id) public view returns (uint256) {
        return self.nodes[_id].key;
    }

    /**
     * @dev Returns the first node in the list (node with the largest key)
     * @return address for the head of the list
     */
    function getFirst(Data storage self) public view returns (address) {
        return self.head;
    }

    /**
     * @dev Returns the last node in the list (node with the smallest key)
     * @return address for the tail of the list
     */
    function getLast(Data storage self) public view returns (address) {
        return self.tail;
    }

    /**
     * @dev Returns the next node (with a smaller key) in the list for a given node
     * @param _id Node's id
     * @return address for the node following node in list with '_id'
     */
    function getNext(Data storage self, address _id) public view returns (address) {
        return self.nodes[_id].nextId;
    }

    /**
     * @dev Returns the previous node (with a larger key) in the list for a given node
     * @param _id Node's id
     * address for the node before node in list with '_id'
     */
    function getPrev(Data storage self, address _id) public view returns (address) {
        return self.nodes[_id].prevId;
    }

    /**
     * @dev Check if a pair of nodes is a valid insertion point for a new node with the given key
     * @param _key Node's key
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     * @return if the insert position is valid
     */
    function validInsertPosition(Data storage self, uint256 _key, address _prevId, address _nextId) public view returns (bool) {
        if (_prevId == address(0) && _nextId == address(0)) {
            // `(null, null)` is a valid insert position if the list is empty
            return isEmpty(self);
        } else if (_prevId == address(0)) {
            // `(null, _nextId)` is a valid insert position if `_nextId` is the head of the list
            return self.head == _nextId && _key >= self.nodes[_nextId].key;
        } else if (_nextId == address(0)) {
            // `(_prevId, null)` is a valid insert position if `_prevId` is the tail of the list
            return self.tail == _prevId && _key <= self.nodes[_prevId].key;
        } else {
            // `(_prevId, _nextId)` is a valid insert position if they are adjacent nodes and `_key` falls between the two nodes' keys
            return self.nodes[_prevId].nextId == _nextId && self.nodes[_prevId].key >= _key && _key >= self.nodes[_nextId].key;
        }
    }

    /**
     * @dev Descend the list (larger keys to smaller keys) to find a valid insert position
     * @param _key Node's key
     * @param _startId Id of node to start ascending the list from
     */
    function descendList(Data storage self, uint256 _key, address _startId) private view returns (address, address) {
        // If `_startId` is the head, check if the insert position is before the head
        if (self.head == _startId && _key >= self.nodes[_startId].key) {
            return (address(0), _startId);
        }

        address prevId = _startId;
        address nextId = self.nodes[prevId].nextId;

        // Descend the list until we reach the end or until we find a valid insert position
        while (prevId != address(0) && !validInsertPosition(self, _key, prevId, nextId)) {
            prevId = self.nodes[prevId].nextId;
            nextId = self.nodes[prevId].nextId;
        }

        return (prevId, nextId);
    }

    /**
     * @dev Ascend the list (smaller keys to larger keys) to find a valid insert position
     * @param _key Node's key
     * @param _startId Id of node to start descending the list from
     */
    function ascendList(Data storage self, uint256 _key, address _startId) private view returns (address, address) {
        // If `_startId` is the tail, check if the insert position is after the tail
        if (self.tail == _startId && _key <= self.nodes[_startId].key) {
            return (_startId, address(0));
        }

        address nextId = _startId;
        address prevId = self.nodes[nextId].prevId;

        // Ascend the list until we reach the end or until we find a valid insertion point
        while (nextId != address(0) && !validInsertPosition(self, _key, prevId, nextId)) {
            nextId = self.nodes[nextId].prevId;
            prevId = self.nodes[nextId].prevId;
        }

        return (prevId, nextId);
    }

    /**
     * @dev Find the insert position for a new node with the given key
     * @param _key Node's key
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */
    function findInsertPosition(Data storage self, uint256 _key, address _prevId, address _nextId) private view returns (address, address) {
        address prevId = _prevId;
        address nextId = _nextId;

        if (prevId != address(0)) {
            if (!contains(self, prevId) || _key > self.nodes[prevId].key) {
                // `prevId` does not exist anymore or now has a smaller key than the given key
                prevId = address(0);
            }
        }

        if (nextId != address(0)) {
            if (!contains(self, nextId) || _key < self.nodes[nextId].key) {
                // `nextId` does not exist anymore or now has a larger key than the given key
                nextId = address(0);
            }
        }

        if (prevId == address(0) && nextId == address(0)) {
            // No hint - descend list starting from head
            return descendList(self, _key, self.head);
        } else if (prevId == address(0)) {
            // No `prevId` for hint - ascend list starting from `nextId`
            return ascendList(self, _key, nextId);
        } else if (nextId == address(0)) {
            // No `nextId` for hint - descend list starting from `prevId`
            return descendList(self, _key, prevId);
        } else {
            // Descend list starting from `prevId`
            return descendList(self, _key, prevId);
        }
    }
}

// File: contracts/libraries/MathUtils.sol

pragma solidity ^0.5.11;



library MathUtils {
    using SafeMath for uint256;

    // Divisor used for representing percentages
    uint256 public constant PERC_DIVISOR = 1000000;

    /**
     * @dev Returns whether an amount is a valid percentage out of PERC_DIVISOR
     * @param _amount Amount that is supposed to be a percentage
     */
    function validPerc(uint256 _amount) internal pure returns (bool) {
        return _amount <= PERC_DIVISOR;
    }

    /**
     * @dev Compute percentage of a value with the percentage represented by a fraction
     * @param _amount Amount to take the percentage of
     * @param _fracNum Numerator of fraction representing the percentage
     * @param _fracDenom Denominator of fraction representing the percentage
     */
    function percOf(uint256 _amount, uint256 _fracNum, uint256 _fracDenom) internal pure returns (uint256) {
        return _amount.mul(percPoints(_fracNum, _fracDenom)).div(PERC_DIVISOR);
    }

    /**
     * @dev Compute percentage of a value with the percentage represented by a fraction over PERC_DIVISOR
     * @param _amount Amount to take the percentage of
     * @param _fracNum Numerator of fraction representing the percentage with PERC_DIVISOR as the denominator
     */
    function percOf(uint256 _amount, uint256 _fracNum) internal pure returns (uint256) {
        return _amount.mul(_fracNum).div(PERC_DIVISOR);
    }

    /**
     * @dev Compute percentage representation of a fraction
     * @param _fracNum Numerator of fraction represeting the percentage
     * @param _fracDenom Denominator of fraction represeting the percentage
     */
    function percPoints(uint256 _fracNum, uint256 _fracDenom) internal pure returns (uint256) {
        return _fracNum.mul(PERC_DIVISOR).div(_fracDenom);
    }
}

// File: contracts/bonding/libraries/EarningsPool.sol

pragma solidity ^0.5.11;




/**
 * @title EarningsPool
 * @dev Manages reward and fee pools for delegators and transcoders
 */
library EarningsPool {
    using SafeMath for uint256;

    // Represents rewards and fees to be distributed to delegators
    // The `hasTranscoderRewardFeePool` flag was introduced so that EarningsPool.Data structs used by the BondingManager
    // created with older versions of this library can be differentiated from EarningsPool.Data structs used by the BondingManager
    // created with a newer version of this library. If the flag is true, then the struct was initialized using the `init` function
    // using a newer version of this library meaning that it is using separate transcoder reward and fee pools
    struct Data {
        uint256 rewardPool;                // Delegator rewards. If `hasTranscoderRewardFeePool` is false, this will contain transcoder rewards as well
        uint256 feePool;                   // Delegator fees. If `hasTranscoderRewardFeePool` is false, this will contain transcoder fees as well
        uint256 totalStake;                // Transcoder's total stake during the earnings pool's round
        uint256 claimableStake;            // Stake that can be used to claim portions of the fee and reward pools
        uint256 transcoderRewardCut;       // Transcoder's reward cut during the earnings pool's round
        uint256 transcoderFeeShare;        // Transcoder's fee share during the earnings pool's round
        uint256 transcoderRewardPool;      // Transcoder rewards. If `hasTranscoderRewardFeePool` is false, this should always be 0
        uint256 transcoderFeePool;         // Transcoder fees. If `hasTranscoderRewardFeePool` is false, this should always be 0
        bool hasTranscoderRewardFeePool;   // Flag to indicate if the earnings pool has separate transcoder reward and fee pools

        // LIP-36 (https://github.com/livepeer/LIPs/blob/master/LIPs/LIP-36.md) fields
        // See EarningsPoolLIP36.sol
        uint256 cumulativeRewardFactor;
        uint256 cumulativeFeeFactor;
    }

    /**
     * @dev Sets transcoderRewardCut and transcoderFeeshare for an EarningsPool
     * @param earningsPool Storage pointer to EarningsPool struct
     * @param _rewardCut Reward cut of transcoder during the earnings pool's round
     * @param _feeShare Fee share of transcoder during the earnings pool's round
     */
    function setCommission(EarningsPool.Data storage earningsPool, uint256 _rewardCut, uint256 _feeShare) internal {
        earningsPool.transcoderRewardCut = _rewardCut;
        earningsPool.transcoderFeeShare = _feeShare;
        // Prior to LIP-36, we set this flag to true here to differentiate between EarningsPool structs created using older versions of this library.
        // When using a version of this library after the introduction of this flag to read an EarningsPool struct created using an older version
        // of this library, this flag should be false in the returned struct because the default value for EVM storage is 0
        // earningsPool.hasTranscoderRewardFeePool = true;
    }

    /**
     * @dev Sets totalStake for an EarningsPool
     * @param earningsPool Storage pointer to EarningsPool struct
     * @param _stake Total stake of the transcoder during the earnings pool's round
     */
    function setStake(EarningsPool.Data storage earningsPool, uint256 _stake) internal {
        earningsPool.totalStake = _stake;
        // Prior to LIP-36, we also set the claimableStake
        // earningsPool.claimableStake = _stake;
    }

    /**
     * @dev Return whether this earnings pool has claimable shares i.e. is there unclaimed stake
     * @param earningsPool Storage pointer to EarningsPool struct
     */
    function hasClaimableShares(EarningsPool.Data storage earningsPool) internal view returns (bool) {
        return earningsPool.claimableStake > 0;
    }

    /**
     * @dev Returns the fee pool share for a claimant. If the claimant is a transcoder, include transcoder fees as well.
     * @param earningsPool Storage pointer to EarningsPool struct
     * @param _stake Stake of claimant
     * @param _isTranscoder Flag indicating whether the claimant is a transcoder
     */
    function feePoolShare(EarningsPool.Data storage earningsPool, uint256 _stake, bool _isTranscoder) internal view returns (uint256) {
        uint256 delegatorFees = 0;
        uint256 transcoderFees = 0;

        if (earningsPool.hasTranscoderRewardFeePool) {
            (delegatorFees, transcoderFees) = feePoolShareWithTranscoderRewardFeePool(earningsPool, _stake, _isTranscoder);
        } else {
            (delegatorFees, transcoderFees) = feePoolShareNoTranscoderRewardFeePool(earningsPool, _stake, _isTranscoder);
        }

        return delegatorFees.add(transcoderFees);
    }

    /**
     * @dev Returns the reward pool share for a claimant. If the claimant is a transcoder, include transcoder rewards as well.
     * @param earningsPool Storage pointer to EarningsPool struct
     * @param _stake Stake of claimant
     * @param _isTranscoder Flag indicating whether the claimant is a transcoder
     */
    function rewardPoolShare(EarningsPool.Data storage earningsPool, uint256 _stake, bool _isTranscoder) internal view returns (uint256) {
        uint256 delegatorRewards = 0;
        uint256 transcoderRewards = 0;

        if (earningsPool.hasTranscoderRewardFeePool) {
            (delegatorRewards, transcoderRewards) = rewardPoolShareWithTranscoderRewardFeePool(earningsPool, _stake, _isTranscoder);
        } else {
            (delegatorRewards, transcoderRewards) = rewardPoolShareNoTranscoderRewardFeePool(earningsPool, _stake, _isTranscoder);
        }

        return delegatorRewards.add(transcoderRewards);
    }

    /**
     * @dev Helper function to calculate fee pool share if the earnings pool has a separate transcoder fee pool
     * @param earningsPool Storage pointer to EarningsPool struct
     * @param _stake Stake of claimant
     * @param _isTranscoder Flag indicating whether the claimant is a transcoder
     */
    function feePoolShareWithTranscoderRewardFeePool(
        EarningsPool.Data storage earningsPool,
        uint256 _stake,
        bool _isTranscoder
    )
        internal
        view
        returns (uint256, uint256)
    {
        // If there is no claimable stake, the fee pool share is 0
        // If there is claimable stake, calculate fee pool share based on remaining amount in fee pool, remaining claimable stake and claimant's stake
        uint256 delegatorFees = earningsPool.claimableStake > 0 ? MathUtils.percOf(earningsPool.feePool, _stake, earningsPool.claimableStake) : 0;

        // If claimant is a transcoder, include transcoder fee pool as well
        return _isTranscoder ? (delegatorFees, earningsPool.transcoderFeePool) : (delegatorFees, 0);
    }

    /**
     * @dev Helper function to calculate reward pool share if the earnings pool has a separate transcoder reward pool
     * @param earningsPool Storage pointer to EarningsPool struct
     * @param _stake Stake of claimant
     * @param _isTranscoder Flag indicating whether the claimant is a transcoder
     */
    function rewardPoolShareWithTranscoderRewardFeePool(
        EarningsPool.Data storage earningsPool,
        uint256 _stake,
        bool _isTranscoder
    )
        internal
        view
        returns (uint256, uint256)
    {
        // If there is no claimable stake, the reward pool share is 0
        // If there is claimable stake, calculate reward pool share based on remaining amount in reward pool, remaining claimable stake and claimant's stake
        uint256 delegatorRewards = earningsPool.claimableStake > 0 ? MathUtils.percOf(earningsPool.rewardPool, _stake, earningsPool.claimableStake) : 0;

        // If claimant is a transcoder, include transcoder reward pool as well
        return _isTranscoder ? (delegatorRewards, earningsPool.transcoderRewardPool) : (delegatorRewards, 0);
    }

    /**
     * @dev Helper function to calculate the fee pool share if the earnings pool does not have a separate transcoder fee pool
     * This implements calculation logic from a previous version of this library
     * @param earningsPool Storage pointer to EarningsPool struct
     * @param _stake Stake of claimant
     * @param _isTranscoder Flag indicating whether the claimant is a transcoder
     */
    function feePoolShareNoTranscoderRewardFeePool(
        EarningsPool.Data storage earningsPool,
        uint256 _stake,
        bool _isTranscoder
    )
        internal
        view
        returns (uint256, uint256)
    {
        uint256 transcoderFees = 0;
        uint256 delegatorFees = 0;

        if (earningsPool.claimableStake > 0) {
            uint256 delegatorsFees = MathUtils.percOf(earningsPool.feePool, earningsPool.transcoderFeeShare);
            transcoderFees = earningsPool.feePool.sub(delegatorsFees);
            delegatorFees = MathUtils.percOf(delegatorsFees, _stake, earningsPool.claimableStake);
        }

        if (_isTranscoder) {
            return (delegatorFees, transcoderFees);
        } else {
            return (delegatorFees, 0);
        }
    }

    /**
     * @dev Helper function to calculate the reward pool share if the earnings pool does not have a separate transcoder reward pool
     * This implements calculation logic from a previous version of this library
     * @param earningsPool Storage pointer to EarningsPool struct
     * @param _stake Stake of claimant
     * @param _isTranscoder Flag indicating whether the claimant is a transcoder
     */
    function rewardPoolShareNoTranscoderRewardFeePool(
        EarningsPool.Data storage earningsPool,
        uint256 _stake,
        bool _isTranscoder
    )
        internal
        view
        returns (uint256, uint256)
    {
        uint256 transcoderRewards = 0;
        uint256 delegatorRewards = 0;

        if (earningsPool.claimableStake > 0) {
            transcoderRewards = MathUtils.percOf(earningsPool.rewardPool, earningsPool.transcoderRewardCut);
            delegatorRewards = MathUtils.percOf(earningsPool.rewardPool.sub(transcoderRewards), _stake, earningsPool.claimableStake);
        }

        if (_isTranscoder) {
            return (delegatorRewards, transcoderRewards);
        } else {
            return (delegatorRewards, 0);
        }
    }
}

// File: contracts/bonding/libraries/EarningsPoolLIP36.sol

pragma solidity ^0.5.11;




library EarningsPoolLIP36 {
    using SafeMath for uint256;

    /**
     * @notice Update the cumulative fee factor stored in an earnings pool with new fees
     * @param earningsPool Storage pointer to EarningsPools.Data struct
     * @param _prevEarningsPool In-memory EarningsPool.Data struct that stores the previous cumulative reward and fee factors
     * @param _fees Amount of new fees
     */
    function updateCumulativeFeeFactor(EarningsPool.Data storage earningsPool, EarningsPool.Data memory _prevEarningsPool, uint256 _fees) internal {
        uint256 prevCumulativeFeeFactor = _prevEarningsPool.cumulativeFeeFactor;
        uint256 prevCumulativeRewardFactor = _prevEarningsPool.cumulativeRewardFactor != 0 ? _prevEarningsPool.cumulativeRewardFactor : MathUtils.percPoints(1,1);

        // Initialize the cumulativeFeeFactor when adding fees for the first time
        if (earningsPool.cumulativeFeeFactor == 0) {
            earningsPool.cumulativeFeeFactor = prevCumulativeFeeFactor.add(
                MathUtils.percOf(prevCumulativeRewardFactor, _fees, earningsPool.totalStake)
            );
            return;
        }

        earningsPool.cumulativeFeeFactor = earningsPool.cumulativeFeeFactor.add(
            MathUtils.percOf(prevCumulativeRewardFactor, _fees, earningsPool.totalStake)
        );
    }

    /**
     * @notice Update the cumulative reward factor stored in an earnings pool with new rewards
     * @param earningsPool Storage pointer to EarningsPool.Data struct
     * @param _prevEarningsPool Storage pointer to EarningsPool.Data struct that stores the previous cumulative reward factor
     * @param _rewards Amount of new rewards
     */
    function updateCumulativeRewardFactor(EarningsPool.Data storage earningsPool, EarningsPool.Data storage _prevEarningsPool, uint256 _rewards) internal {
        uint256 prevCumulativeRewardFactor = _prevEarningsPool.cumulativeRewardFactor != 0 ? _prevEarningsPool.cumulativeRewardFactor : MathUtils.percPoints(1,1);

        earningsPool.cumulativeRewardFactor = prevCumulativeRewardFactor.add(
            MathUtils.percOf(prevCumulativeRewardFactor, _rewards, earningsPool.totalStake)
        );
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;



/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
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
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

// File: contracts/token/ILivepeerToken.sol

pragma solidity ^0.5.11;




contract ILivepeerToken is ERC20, Ownable {
    function mint(address _to, uint256 _amount) public returns (bool);
    function burn(uint256 _amount) public;
}

// File: contracts/token/IMinter.sol

pragma solidity ^0.5.11;



/**
 * @title Minter interface
 */
contract IMinter {
    // Events
    event SetCurrentRewardTokens(uint256 currentMintableTokens, uint256 currentInflation);

    // External functions
    function createReward(uint256 _fracNum, uint256 _fracDenom) external returns (uint256);
    function trustedTransferTokens(address _to, uint256 _amount) external;
    function trustedBurnTokens(uint256 _amount) external;
    function trustedWithdrawETH(address payable _to, uint256 _amount) external;
    function depositETH() external payable returns (bool);
    function setCurrentRewardTokens() external;
    function currentMintableTokens() external view returns (uint256);
    function currentMintedTokens() external view returns (uint256);
    // Public functions
    function getController() public view returns (IController);
}

// File: contracts/rounds/IRoundsManager.sol

pragma solidity ^0.5.11;


/**
 * @title RoundsManager interface
 */
contract IRoundsManager {
    // Events
    event NewRound(uint256 indexed round, bytes32 blockHash);

    // Deprecated events
    // These event signatures can be used to construct the appropriate topic hashes to filter for past logs corresponding
    // to these deprecated events.
    // event NewRound(uint256 round)

    // External functions
    function initializeRound() external;
    function lipUpgradeRound(uint256 _lip) external view returns (uint256);

    // Public functions
    function blockNum() public view returns (uint256);
    function blockHash(uint256 _block) public view returns (bytes32);
    function blockHashForRound(uint256 _round) public view returns (bytes32);
    function currentRound() public view returns (uint256);
    function currentRoundStartBlock() public view returns (uint256);
    function currentRoundInitialized() public view returns (bool);
    function currentRoundLocked() public view returns (bool);
}

// File: contracts/snapshots/IMerkleSnapshot.sol

pragma solidity ^0.5.11;


contract IMerkleSnapshot {
    function verify(bytes32 _id, bytes32[] calldata _proof, bytes32 _leaf) external view returns (bool);
}

// File: contracts/bonding/BondingManager.sol

pragma solidity 0.5.11;













/**
 * @title BondingManager
 * @notice Manages bonding, transcoder and rewards/fee accounting related operations of the Livepeer protocol
 */
contract BondingManager is ManagerProxyTarget, IBondingManager {
    using SafeMath for uint256;
    using SortedDoublyLL for SortedDoublyLL.Data;
    using EarningsPool for EarningsPool.Data;
    using EarningsPoolLIP36 for EarningsPool.Data;

    // Constants
    // Occurances are replaced at compile time
    // and computed to a single value if possible by the optimizer
    uint256 constant MAX_FUTURE_ROUND = 2**256 - 1;

    // Time between unbonding and possible withdrawl in rounds
    uint64 public unbondingPeriod;
    // DEPRECATED - DO NOT USE
    uint256 public numActiveTranscodersDEPRECATED;
    // Max number of rounds that a caller can claim earnings for at once
    uint256 public maxEarningsClaimsRounds;

    // Represents a transcoder's current state
    struct Transcoder {
        uint256 lastRewardRound;                                        // Last round that the transcoder called reward
        uint256 rewardCut;                                              // % of reward paid to transcoder by a delegator
        uint256 feeShare;                                               // % of fees paid to delegators by transcoder
        uint256 pricePerSegmentDEPRECATED;                              // DEPRECATED - DO NOT USE
        uint256 pendingRewardCutDEPRECATED;                             // DEPRECATED - DO NOT USE
        uint256 pendingFeeShareDEPRECATED;                              // DEPRECATED - DO NOT USE
        uint256 pendingPricePerSegmentDEPRECATED;                       // DEPRECATED - DO NOT USE
        mapping (uint256 => EarningsPool.Data) earningsPoolPerRound;    // Mapping of round => earnings pool for the round
        uint256 lastActiveStakeUpdateRound;                             // Round for which the stake was last updated while the transcoder is active
        uint256 activationRound;                                        // Round in which the transcoder became active - 0 if inactive
        uint256 deactivationRound;                                      // Round in which the transcoder will become inactive
        uint256 activeCumulativeRewards;                                // The transcoder's cumulative rewards that are active in the current round
        uint256 cumulativeRewards;                                      // The transcoder's cumulative rewards (earned via the its active staked rewards and its reward cut).
        uint256 cumulativeFees;                                         // The transcoder's cumulative fees (earned via the its active staked rewards and its fee share)
        uint256 lastFeeRound;                                           // Latest round in which the transcoder received fees
    }

    // The various states a transcoder can be in
    enum TranscoderStatus { NotRegistered, Registered }

    // Represents a delegator's current state
    struct Delegator {
        uint256 bondedAmount;                    // The amount of bonded tokens
        uint256 fees;                            // The amount of fees collected
        address delegateAddress;                 // The address delegated to
        uint256 delegatedAmount;                 // The amount of tokens delegated to the delegator
        uint256 startRound;                      // The round the delegator transitions to bonded phase and is delegated to someone
        uint256 withdrawRoundDEPRECATED;         // DEPRECATED - DO NOT USE
        uint256 lastClaimRound;                  // The last round during which the delegator claimed its earnings
        uint256 nextUnbondingLockId;             // ID for the next unbonding lock created
        mapping (uint256 => UnbondingLock) unbondingLocks; // Mapping of unbonding lock ID => unbonding lock
    }

    // The various states a delegator can be in
    enum DelegatorStatus { Pending, Bonded, Unbonded }

    // Represents an amount of tokens that are being unbonded
    struct UnbondingLock {
        uint256 amount;              // Amount of tokens being unbonded
        uint256 withdrawRound;       // Round at which unbonding period is over and tokens can be withdrawn
    }

    // Keep track of the known transcoders and delegators
    mapping (address => Delegator) private delegators;
    mapping (address => Transcoder) private transcoders;

    // DEPRECATED - DO NOT USE
    // The function getTotalBonded() no longer uses this variable
    // and instead calculates the total bonded value separately
    uint256 private totalBondedDEPRECATED;

    // DEPRECATED - DO NOT USE
    SortedDoublyLL.Data private transcoderPoolDEPRECATED;

    // DEPRECATED - DO NOT USE
    struct ActiveTranscoderSetDEPRECATED {
        address[] transcoders;
        mapping (address => bool) isActive;
        uint256 totalStake;
    }

    // DEPRECATED - DO NOT USE
    mapping (uint256 => ActiveTranscoderSetDEPRECATED) public activeTranscoderSetDEPRECATED;

    // The total active stake (sum of the stake of active set members) for the current round
    uint256 public currentRoundTotalActiveStake;
    // The total active stake (sum of the stake of active set members) for the next round
    uint256 public nextRoundTotalActiveStake;

    // The transcoder pool is used to keep track of the transcoders that are eligible for activation.
    // The pool keeps track of the pending active set in round N and the start of round N + 1 transcoders
    // in the pool are locked into the active set for round N + 1
    SortedDoublyLL.Data private transcoderPoolV2;

    // Check if sender is TicketBroker
    modifier onlyTicketBroker() {
        _onlyTicketBroker();
        _;
    }

    // Check if sender is RoundsManager
    modifier onlyRoundsManager() {
        _onlyRoundsManager();
        _;
    }

    // Check if sender is Verifier
    modifier onlyVerifier() {
        _onlyVerifier();
        _;
    }

    // Check if current round is initialized
    modifier currentRoundInitialized() {
        _currentRoundInitialized();
        _;
    }

    // Automatically claim earnings from lastClaimRound through the current round
    modifier autoClaimEarnings() {
        _autoClaimEarnings();
        _;
    }

    /**
     * @notice BondingManager constructor. Only invokes constructor of base Manager contract with provided Controller address
     * @dev This constructor will not initialize any state variables besides `controller`. The following setter functions
     * should be used to initialize state variables post-deployment:
     * - setUnbondingPeriod()
     * - setNumActiveTranscoders()
     * - setMaxEarningsClaimsRounds()
     * @param _controller Address of Controller that this contract will be registered with
     */
    constructor(address _controller) public Manager(_controller) {}

    /**
     * @notice Set unbonding period. Only callable by Controller owner
     * @param _unbondingPeriod Rounds between unbonding and possible withdrawal
     */
    function setUnbondingPeriod(uint64 _unbondingPeriod) external onlyControllerOwner {
        unbondingPeriod = _unbondingPeriod;

        emit ParameterUpdate("unbondingPeriod");
    }

    /**
     * @notice Set maximum number of active transcoders. Only callable by Controller owner
     * @param _numActiveTranscoders Number of active transcoders
     */
    function setNumActiveTranscoders(uint256 _numActiveTranscoders) external onlyControllerOwner {
        transcoderPoolV2.setMaxSize(_numActiveTranscoders);

        emit ParameterUpdate("numActiveTranscoders");
    }

    /**
     * @notice Set max number of rounds a caller can claim earnings for at once. Only callable by Controller owner
     * @param _maxEarningsClaimsRounds Max number of rounds a caller can claim earnings for at once
     */
    function setMaxEarningsClaimsRounds(uint256 _maxEarningsClaimsRounds) external onlyControllerOwner {
        maxEarningsClaimsRounds = _maxEarningsClaimsRounds;

        emit ParameterUpdate("maxEarningsClaimsRounds");
    }

    /**
     * @notice Sets commission rates as a transcoder and if the caller is not in the transcoder pool tries to add it
     * @dev Percentages are represented as numerators of fractions over MathUtils.PERC_DIVISOR
     * @param _rewardCut % of reward paid to transcoder by a delegator
     * @param _feeShare % of fees paid to delegators by a transcoder
     */
    function transcoder(uint256 _rewardCut, uint256 _feeShare) external {
        transcoderWithHint(_rewardCut, _feeShare, address(0), address(0));
    }

    /**
     * @notice Delegate stake towards a specific address
     * @param _amount The amount of tokens to stake
     * @param _to The address of the transcoder to stake towards
     */
    function bond(uint256 _amount, address _to) external {
        bondWithHint(
            _amount,
            _to,
            address(0),
            address(0),
            address(0),
            address(0)
        );
    }

    /**
     * @notice Unbond an amount of the delegator's bonded stake
     * @param _amount Amount of tokens to unbond
     */
    function unbond(uint256 _amount) external {
        unbondWithHint(_amount, address(0), address(0));
    }

    /**
     * @notice Rebond tokens for an unbonding lock to a delegator's current delegate while a delegator is in the Bonded or Pending status
     * @param _unbondingLockId ID of unbonding lock to rebond with
     */
    function rebond(uint256 _unbondingLockId) external {
        rebondWithHint(_unbondingLockId, address(0), address(0));
    }

    /**
     * @notice Rebond tokens for an unbonding lock to a delegate while a delegator is in the Unbonded status
     * @param _to Address of delegate
     * @param _unbondingLockId ID of unbonding lock to rebond with
     */
    function rebondFromUnbonded(address _to, uint256 _unbondingLockId) external {
        rebondFromUnbondedWithHint(_to, _unbondingLockId, address(0), address(0));
    }

    /**
     * @notice Withdraws tokens for an unbonding lock that has existed through an unbonding period
     * @param _unbondingLockId ID of unbonding lock to withdraw with
     */
    function withdrawStake(uint256 _unbondingLockId)
        external
        whenSystemNotPaused
        currentRoundInitialized
    {
        Delegator storage del = delegators[msg.sender];
        UnbondingLock storage lock = del.unbondingLocks[_unbondingLockId];

        require(isValidUnbondingLock(msg.sender, _unbondingLockId), "invalid unbonding lock ID");
        require(lock.withdrawRound <= roundsManager().currentRound(), "withdraw round must be before or equal to the current round");

        uint256 amount = lock.amount;
        uint256 withdrawRound = lock.withdrawRound;
        // Delete unbonding lock
        delete del.unbondingLocks[_unbondingLockId];

        // Tell Minter to transfer stake (LPT) to the delegator
        minter().trustedTransferTokens(msg.sender, amount);

        emit WithdrawStake(msg.sender, _unbondingLockId, amount, withdrawRound);
    }

    /**
     * @notice Withdraws fees to the caller
     */
    function withdrawFees()
        external
        whenSystemNotPaused
        currentRoundInitialized
        autoClaimEarnings
    {
        uint256 fees = delegators[msg.sender].fees;
        require(fees > 0, "no fees to withdraw");
        delegators[msg.sender].fees = 0;

        // Tell Minter to transfer fees (ETH) to the delegator
        minter().trustedWithdrawETH(msg.sender, fees);

        emit WithdrawFees(msg.sender);
    }

    /**
     * @notice Mint token rewards for an active transcoder and its delegators
     */
    function reward() external {
        rewardWithHint(address(0), address(0));
    }

    /**
     * @notice Update transcoder's fee pool. Only callable by the TicketBroker
     * @param _transcoder Transcoder address
     * @param _fees Fees to be added to the fee pool
     */
    function updateTranscoderWithFees(
        address _transcoder,
        uint256 _fees,
        uint256 _round
    )
        external
        whenSystemNotPaused
        onlyTicketBroker
    {
        // Silence unused param compiler warning
        _round;

        require(isRegisteredTranscoder(_transcoder), "transcoder must be registered");

        uint256 currentRound = roundsManager().currentRound();

        Transcoder storage t = transcoders[_transcoder];

        uint256 lastRewardRound = t.lastRewardRound;
        uint256 activeCumulativeRewards = t.activeCumulativeRewards;

        // LIP-36: Add fees for the current round instead of '_round'
        // https://github.com/livepeer/LIPs/issues/35#issuecomment-673659199
        EarningsPool.Data storage earningsPool = t.earningsPoolPerRound[currentRound];
        EarningsPool.Data memory prevEarningsPool = latestCumulativeFactorsPool(t, currentRound.sub(1));

        // if transcoder hasn't called 'reward()' for '_round' its 'transcoderFeeShare', 'transcoderRewardCut' and 'totalStake'
        // on the 'EarningsPool' for '_round' would not be initialized and the fee distribution wouldn't happen as expected
        // for cumulative fee calculation this would result in division by zero.
        if (currentRound > lastRewardRound) {
            earningsPool.setCommission(
                t.rewardCut,
                t.feeShare
            );

            uint256 lastUpdateRound = t.lastActiveStakeUpdateRound;
            if (lastUpdateRound < currentRound) {
                earningsPool.setStake(t.earningsPoolPerRound[lastUpdateRound].totalStake);
            }

            // If reward() has not been called yet in the current round, then the transcoder's activeCumulativeRewards has not
            // yet been set in for the round. When the transcoder calls reward() its activeCumulativeRewards will be set to its
            // current cumulativeRewards. So, we can just use the transcoder's cumulativeRewards here because this will become
            // the transcoder's activeCumulativeRewards if it calls reward() later on in the current round
            activeCumulativeRewards = t.cumulativeRewards;
        }

        uint256 totalStake = earningsPool.totalStake;
        if (prevEarningsPool.cumulativeRewardFactor == 0 && lastRewardRound == currentRound) {
            // if transcoder called reward for 'currentRound' but not for 'currentRound - 1' (missed reward call)
            // retroactively calculate what its cumulativeRewardFactor would have been for 'currentRound - 1' (cfr. previous lastRewardRound for transcoder)
            // based on rewards for currentRound
            IMinter mtr = minter();
            uint256 rewards = MathUtils.percOf(mtr.currentMintableTokens().add(mtr.currentMintedTokens()), totalStake, currentRoundTotalActiveStake);
            uint256 transcoderCommissionRewards = MathUtils.percOf(rewards, earningsPool.transcoderRewardCut);
            uint256 delegatorsRewards = rewards.sub(transcoderCommissionRewards);

            prevEarningsPool.cumulativeRewardFactor = MathUtils.percOf(
                earningsPool.cumulativeRewardFactor,
                totalStake,
                delegatorsRewards.add(totalStake)
            );
        }

        uint256 delegatorsFees = MathUtils.percOf(_fees, earningsPool.transcoderFeeShare);
        uint256 transcoderCommissionFees = _fees.sub(delegatorsFees);
        // Calculate the fees earned by the transcoder's earned rewards
        uint256 transcoderRewardStakeFees = MathUtils.percOf(delegatorsFees, activeCumulativeRewards, totalStake);
        // Track fees earned by the transcoder based on its earned rewards and feeShare
        t.cumulativeFees = t.cumulativeFees.add(transcoderRewardStakeFees).add(transcoderCommissionFees);
        // Update cumulative fee factor with new fees
        // The cumulativeFeeFactor is used to calculate fees for all delegators including the transcoder (self-delegated)
        // Note that delegatorsFees includes transcoderRewardStakeFees, but no delegator will claim that amount using
        // the earnings claiming algorithm and instead that amount is accounted for in the transcoder's cumulativeFees field
        earningsPool.updateCumulativeFeeFactor(prevEarningsPool, delegatorsFees);

        t.lastFeeRound = currentRound;
    }

    /**
     * @notice Slash a transcoder. Only callable by the Verifier
     * @param _transcoder Transcoder address
     * @param _finder Finder that proved a transcoder violated a slashing condition. Null address if there is no finder
     * @param _slashAmount Percentage of transcoder bond to be slashed
     * @param _finderFee Percentage of penalty awarded to finder. Zero if there is no finder
     */
    function slashTranscoder(
        address _transcoder,
        address _finder,
        uint256 _slashAmount,
        uint256 _finderFee
    )
        external
        whenSystemNotPaused
        onlyVerifier
    {
        Delegator storage del = delegators[_transcoder];

        if (del.bondedAmount > 0) {
            uint256 penalty = MathUtils.percOf(delegators[_transcoder].bondedAmount, _slashAmount);

            // If active transcoder, resign it
            if (transcoderPoolV2.contains(_transcoder)) {
                resignTranscoder(_transcoder);
            }

            // Decrease bonded stake
            del.bondedAmount = del.bondedAmount.sub(penalty);

            // If still bonded decrease delegate's delegated amount
            if (delegatorStatus(_transcoder) == DelegatorStatus.Bonded) {
                delegators[del.delegateAddress].delegatedAmount = delegators[del.delegateAddress].delegatedAmount.sub(penalty);
            }

            // Account for penalty
            uint256 burnAmount = penalty;

            // Award finder fee if there is a finder address
            if (_finder != address(0)) {
                uint256 finderAmount = MathUtils.percOf(penalty, _finderFee);
                minter().trustedTransferTokens(_finder, finderAmount);

                // Minter burns the slashed funds - finder reward
                minter().trustedBurnTokens(burnAmount.sub(finderAmount));

                emit TranscoderSlashed(_transcoder, _finder, penalty, finderAmount);
            } else {
                // Minter burns the slashed funds
                minter().trustedBurnTokens(burnAmount);

                emit TranscoderSlashed(_transcoder, address(0), penalty, 0);
            }
        } else {
            emit TranscoderSlashed(_transcoder, _finder, 0, 0);
        }
    }

    /**
     * @notice Claim token pools shares for a delegator from its lastClaimRound through the end round
     * @param _endRound The last round for which to claim token pools shares for a delegator
     */
    function claimEarnings(uint256 _endRound) external whenSystemNotPaused currentRoundInitialized {
        uint256 lastClaimRound = delegators[msg.sender].lastClaimRound;
        require(lastClaimRound < _endRound, "end round must be after last claim round");
        require(_endRound <= roundsManager().currentRound(), "end round must be before or equal to current round");

        updateDelegatorWithEarnings(msg.sender, _endRound, lastClaimRound);
    }

    /**
     * @notice Claim earnings for a delegator based on the snapshot taken in LIP-52
     * @dev https://github.com/livepeer/LIPs/blob/master/LIPs/LIP-52.md
     * @param _pendingStake the amount of pending stake for the delegator (current stake + pending rewards)
     * @param _pendingFees the amount of pending fees for the delegator (current fees + pending fees)
     * @param _earningsProof array of keccak256 sibling hashes on the branch of the leaf for the delegator up to the root
     * @param _data (optional) raw transaction data to be executed on behalf of msg.sender after claiming snapshot earnings
     */
    function claimSnapshotEarnings(
        uint256 _pendingStake,
        uint256 _pendingFees,
        bytes32[] calldata _earningsProof,
        bytes calldata _data
    )
        external
        whenSystemNotPaused
        currentRoundInitialized
    {
        Delegator storage del = delegators[msg.sender];

        uint256 lip52Round = roundsManager().lipUpgradeRound(52);

        uint256 lastClaimRound = del.lastClaimRound;

        require(lastClaimRound < lip52Round, "Already claimed for LIP-52");

        bytes32 leaf = keccak256(abi.encode(msg.sender, _pendingStake, _pendingFees));

        require(
            IMerkleSnapshot(controller.getContract(keccak256("MerkleSnapshot"))).verify(keccak256("LIP-52"), _earningsProof, leaf),
            "Merkle proof is invalid"
        );

        emit EarningsClaimed(
            del.delegateAddress,
            msg.sender,
            _pendingStake.sub(del.bondedAmount),
            _pendingFees.sub(del.fees),
            lastClaimRound.add(1),
            lip52Round
        );

        del.lastClaimRound = lip52Round;
        del.bondedAmount = _pendingStake;
        del.fees = _pendingFees;

        // allow for execution of subsequent claiming or staking operations
        if (_data.length > 0) {
            (bool success, bytes memory returnData) = address(this).delegatecall(_data);
            require(success, string(returnData));
        }
    }

    /**
     * @notice Called during round initialization to set the total active stake for the round. Only callable by the RoundsManager
     */
    function setCurrentRoundTotalActiveStake() external onlyRoundsManager {
        currentRoundTotalActiveStake = nextRoundTotalActiveStake;
    }

    /**
     * @notice Sets commission rates as a transcoder and if the caller is not in the transcoder pool tries to add it using an optional list hint
     * @dev Percentages are represented as numerators of fractions over MathUtils.PERC_DIVISOR. If the caller is going to be added to the pool, the
     * caller can provide an optional hint for the insertion position in the pool via the `_newPosPrev` and `_newPosNext` params. A linear search will
     * be executed starting at the hint to find the correct position - in the best case, the hint is the correct position so no search is executed.
     * See SortedDoublyLL.sol for details on list hints
     * @param _rewardCut % of reward paid to transcoder by a delegator
     * @param _feeShare % of fees paid to delegators by a transcoder
     * @param _newPosPrev Address of previous transcoder in pool if the caller joins the pool
     * @param _newPosNext Address of next transcoder in pool if the caller joins the pool
     */
    function transcoderWithHint(uint256 _rewardCut, uint256 _feeShare, address _newPosPrev, address _newPosNext)
        public
        whenSystemNotPaused
        currentRoundInitialized
    {
        require(
            !roundsManager().currentRoundLocked(),
            "can't update transcoder params, current round is locked"
        );
        require(MathUtils.validPerc(_rewardCut), "invalid rewardCut percentage");
        require(MathUtils.validPerc(_feeShare), "invalid feeShare percentage");
        require(isRegisteredTranscoder(msg.sender), "transcoder must be registered");

        Transcoder storage t = transcoders[msg.sender];
        uint256 currentRound = roundsManager().currentRound();

        require(
            !isActiveTranscoder(msg.sender) || t.lastRewardRound == currentRound,
            "caller can't be active or must have already called reward for the current round"
        );

        t.rewardCut = _rewardCut;
        t.feeShare = _feeShare;

        if (!transcoderPoolV2.contains(msg.sender)) {
            tryToJoinActiveSet(msg.sender, delegators[msg.sender].delegatedAmount, currentRound.add(1), _newPosPrev, _newPosNext);
        }

        emit TranscoderUpdate(msg.sender, _rewardCut, _feeShare);
    }

    /**
     * @notice Delegate stake towards a specific address and updates the transcoder pool using optional list hints if needed
     * @dev If the caller is decreasing the stake of its old delegate in the transcoder pool, the caller can provide an optional hint
     * for the insertion position of the old delegate via the `_oldDelegateNewPosPrev` and `_oldDelegateNewPosNext` params.
     * If the caller is delegating to a delegate that is in the transcoder pool, the caller can provide an optional hint for the
     * insertion position of the delegate via the `_currDelegateNewPosPrev` and `_currDelegateNewPosNext` params.
     * In both cases, a linear search will be executed starting at the hint to find the correct position. In the best case, the hint
     * is the correct position so no search is executed. See SortedDoublyLL.sol for details on list hints
     * @param _amount The amount of tokens to stake.
     * @param _to The address of the transcoder to stake towards
     * @param _oldDelegateNewPosPrev The address of the previous transcoder in the pool for the old delegate
     * @param _oldDelegateNewPosNext The address of the next transcoder in the pool for the old delegate
     * @param _currDelegateNewPosPrev The address of the previous transcoder in the pool for the current delegate
     * @param _currDelegateNewPosNext The address of the next transcoder in the pool for the current delegate
     */
    function bondWithHint(
        uint256 _amount,
        address _to,
        address _oldDelegateNewPosPrev,
        address _oldDelegateNewPosNext,
        address _currDelegateNewPosPrev,
        address _currDelegateNewPosNext
    )
        public
        whenSystemNotPaused
        currentRoundInitialized
        autoClaimEarnings
    {
        Delegator storage del = delegators[msg.sender];

        uint256 currentRound = roundsManager().currentRound();
        // Amount to delegate
        uint256 delegationAmount = _amount;
        // Current delegate
        address currentDelegate = del.delegateAddress;

        if (delegatorStatus(msg.sender) == DelegatorStatus.Unbonded) {
            // New delegate
            // Set start round
            // Don't set start round if delegator is in pending state because the start round would not change
            del.startRound = currentRound.add(1);
            // Unbonded state = no existing delegate and no bonded stake
            // Thus, delegation amount = provided amount
        } else if (currentDelegate != address(0) && currentDelegate != _to) {
            // A registered transcoder cannot delegate its bonded stake toward another address
            // because it can only be delegated toward itself
            // In the future, if delegation towards another registered transcoder as an already
            // registered transcoder becomes useful (i.e. for transitive delegation), this restriction
            // could be removed
            require(!isRegisteredTranscoder(msg.sender), "registered transcoders can't delegate towards other addresses");
            // Changing delegate
            // Set start round
            del.startRound = currentRound.add(1);
            // Update amount to delegate with previous delegation amount
            delegationAmount = delegationAmount.add(del.bondedAmount);

            decreaseTotalStake(currentDelegate, del.bondedAmount, _oldDelegateNewPosPrev, _oldDelegateNewPosNext);
        }

        // cannot delegate to someone without having bonded stake
        require(delegationAmount > 0, "delegation amount must be greater than 0");
        // Update delegate
        del.delegateAddress = _to;
        // Update bonded amount
        del.bondedAmount = del.bondedAmount.add(_amount);

        increaseTotalStake(_to, delegationAmount, _currDelegateNewPosPrev, _currDelegateNewPosNext);

        if (_amount > 0) {
            // Transfer the LPT to the Minter
            livepeerToken().transferFrom(msg.sender, address(minter()), _amount);
        }

        emit Bond(_to, currentDelegate, msg.sender, _amount, del.bondedAmount);
    }

    /**
     * @notice Unbond an amount of the delegator's bonded stake and updates the transcoder pool using an optional list hint if needed
     * @dev If the caller remains in the transcoder pool, the caller can provide an optional hint for its insertion position in the
     * pool via the `_newPosPrev` and `_newPosNext` params. A linear search will be executed starting at the hint to find the correct position.
     * In the best case, the hint is the correct position so no search is executed. See SortedDoublyLL.sol details on list hints
     * @param _amount Amount of tokens to unbond
     * @param _newPosPrev Address of previous transcoder in pool if the caller remains in the pool
     * @param _newPosNext Address of next transcoder in pool if the caller remains in the pool
     */
    function unbondWithHint(uint256 _amount, address _newPosPrev, address _newPosNext)
        public
        whenSystemNotPaused
        currentRoundInitialized
        autoClaimEarnings
    {
        require(delegatorStatus(msg.sender) == DelegatorStatus.Bonded, "caller must be bonded");

        Delegator storage del = delegators[msg.sender];

        require(_amount > 0, "unbond amount must be greater than 0");
        require(_amount <= del.bondedAmount, "amount is greater than bonded amount");

        address currentDelegate = del.delegateAddress;
        uint256 currentRound = roundsManager().currentRound();
        uint256 withdrawRound = currentRound.add(unbondingPeriod);
        uint256 unbondingLockId = del.nextUnbondingLockId;

        // Create new unbonding lock
        del.unbondingLocks[unbondingLockId] = UnbondingLock({
            amount: _amount,
            withdrawRound: withdrawRound
        });
        // Increment ID for next unbonding lock
        del.nextUnbondingLockId = unbondingLockId.add(1);
        // Decrease delegator's bonded amount
        del.bondedAmount = del.bondedAmount.sub(_amount);

        if (del.bondedAmount == 0) {
            // Delegator no longer delegated to anyone if it does not have a bonded amount
            del.delegateAddress = address(0);
            // Delegator does not have a start round if it is no longer delegated to anyone
            del.startRound = 0;

            if (transcoderPoolV2.contains(msg.sender)) {
                resignTranscoder(msg.sender);
            }
        }

        // If msg.sender was resigned this statement will only decrease delegators[currentDelegate].delegatedAmount
        decreaseTotalStake(currentDelegate, _amount, _newPosPrev, _newPosNext);

        emit Unbond(currentDelegate, msg.sender, unbondingLockId, _amount, withdrawRound);
    }

    /**
     * @notice Rebond tokens for an unbonding lock to a delegator's current delegate while a delegator is in the Bonded or Pending status and updates
     * the transcoder pool using an optional list hint if needed
     * @dev If the delegate is in the transcoder pool, the caller can provide an optional hint for the delegate's insertion position in the
     * pool via the `_newPosPrev` and `_newPosNext` params. A linear search will be executed starting at the hint to find the correct position.
     * In the best case, the hint is the correct position so no search is executed. See SortedDoublyLL.sol details on list hints
     * @param _unbondingLockId ID of unbonding lock to rebond with
     * @param _newPosPrev Address of previous transcoder in pool if the delegate is in the pool
     * @param _newPosNext Address of next transcoder in pool if the delegate is in the pool
     */
    function rebondWithHint(
        uint256 _unbondingLockId,
        address _newPosPrev,
        address _newPosNext
    )
        public
        whenSystemNotPaused
        currentRoundInitialized
        autoClaimEarnings
    {
        require(delegatorStatus(msg.sender) != DelegatorStatus.Unbonded, "caller must be bonded");

        // Process rebond using unbonding lock
        processRebond(msg.sender, _unbondingLockId, _newPosPrev, _newPosNext);
    }

    /**
     * @notice Rebond tokens for an unbonding lock to a delegate while a delegator is in the Unbonded status and updates the transcoder pool using
     * an optional list hint if needed
     * @dev If the delegate joins the transcoder pool, the caller can provide an optional hint for the delegate's insertion position in the
     * pool via the `_newPosPrev` and `_newPosNext` params. A linear search will be executed starting at the hint to find the correct position.
     * In the best case, the hint is the correct position so no search is executed. See SortedDoublyLL.sol for details on list hints
     * @param _to Address of delegate
     * @param _unbondingLockId ID of unbonding lock to rebond with
     * @param _newPosPrev Address of previous transcoder in pool if the delegate joins the pool
     * @param _newPosNext Address of next transcoder in pool if the delegate joins the pool
     */
    function rebondFromUnbondedWithHint(
        address _to,
        uint256 _unbondingLockId,
        address _newPosPrev,
        address _newPosNext
    )
        public
        whenSystemNotPaused
        currentRoundInitialized
        autoClaimEarnings
    {
        require(delegatorStatus(msg.sender) == DelegatorStatus.Unbonded, "caller must be unbonded");

        // Set delegator's start round and transition into Pending state
        delegators[msg.sender].startRound = roundsManager().currentRound().add(1);
        // Set delegator's delegate
        delegators[msg.sender].delegateAddress = _to;
        // Process rebond using unbonding lock
        processRebond(msg.sender, _unbondingLockId, _newPosPrev, _newPosNext);
    }

    /**
     * @notice Mint token rewards for an active transcoder and its delegators and update the transcoder pool using an optional list hint if needed
     * @dev If the caller is in the transcoder pool, the caller can provide an optional hint for its insertion position in the
     * pool via the `_newPosPrev` and `_newPosNext` params. A linear search will be executed starting at the hint to find the correct position.
     * In the best case, the hint is the correct position so no search is executed. See SortedDoublyLL.sol for details on list hints
     * @param _newPosPrev Address of previous transcoder in pool if the caller is in the pool
     * @param _newPosNext Address of next transcoder in pool if the caller is in the pool
     */
    function rewardWithHint(address _newPosPrev, address _newPosNext) public whenSystemNotPaused currentRoundInitialized {
        uint256 currentRound = roundsManager().currentRound();

        require(isActiveTranscoder(msg.sender), "caller must be an active transcoder");
        require(transcoders[msg.sender].lastRewardRound != currentRound, "caller has already called reward for the current round");

        Transcoder storage t = transcoders[msg.sender];
        EarningsPool.Data storage earningsPool = t.earningsPoolPerRound[currentRound];

        // Set last round that transcoder called reward
        earningsPool.setCommission(t.rewardCut, t.feeShare);

        // If transcoder didn't receive stake updates during the previous round and hasn't called reward for > 1 round
        // the 'totalStake' on its 'EarningsPool' for the current round wouldn't be initialized
        // Thus we sync the the transcoder's stake to when it was last updated
        // 'updateTrancoderWithRewards()' will set the update round to 'currentRound +1' so this synchronization shouldn't occur frequently
        uint256 lastUpdateRound = t.lastActiveStakeUpdateRound;
        if (lastUpdateRound < currentRound) {
            earningsPool.setStake(t.earningsPoolPerRound[lastUpdateRound].totalStake);
        }

        // Create reward based on active transcoder's stake relative to the total active stake
        // rewardTokens = (current mintable tokens for the round * active transcoder stake) / total active stake
        uint256 rewardTokens = minter().createReward(earningsPool.totalStake, currentRoundTotalActiveStake);

        updateTranscoderWithRewards(msg.sender, rewardTokens, currentRound, _newPosPrev, _newPosNext);

        // Set last round that transcoder called reward
        t.lastRewardRound = currentRound;

        emit Reward(msg.sender, rewardTokens);
    }

    /**
     * @notice Returns pending bonded stake for a delegator from its lastClaimRound through an end round
     * @param _delegator Address of delegator
     * @param _endRound The last round to compute pending stake from
     * @return Pending bonded stake for '_delegator' since last claiming rewards
     */
    function pendingStake(address _delegator, uint256 _endRound) public view returns (uint256) {
        (
            uint256 stake,
        ) = pendingStakeAndFees(_delegator, _endRound);
        return stake;
    }

    /**
     * @notice Returns pending fees for a delegator from its lastClaimRound through an end round
     * @param _delegator Address of delegator
     * @param _endRound The last round to compute pending fees from
     * @return Pending fees for '_delegator' since last claiming fees
     */
    function pendingFees(address _delegator, uint256 _endRound) public view returns (uint256) {
        (
            ,
            uint256 fees
        ) = pendingStakeAndFees(_delegator, _endRound);
        return fees;
    }

    /**
     * @notice Returns total bonded stake for a transcoder
     * @param _transcoder Address of transcoder
     * @return total bonded stake for a delegator
     */
    function transcoderTotalStake(address _transcoder) public view returns (uint256) {
        return delegators[_transcoder].delegatedAmount;
    }

    /**
     * @notice Computes transcoder status
     * @param _transcoder Address of transcoder
     * @return registered or not registered transcoder status
     */
    function transcoderStatus(address _transcoder) public view returns (TranscoderStatus) {
        if (isRegisteredTranscoder(_transcoder)) return TranscoderStatus.Registered;
        return TranscoderStatus.NotRegistered;
    }

    /**
     * @notice Computes delegator status
     * @param _delegator Address of delegator
     * @return bonded, unbonded or pending delegator status
     */
    function delegatorStatus(address _delegator) public view returns (DelegatorStatus) {
        Delegator storage del = delegators[_delegator];

        if (del.bondedAmount == 0) {
            // Delegator unbonded all its tokens
            return DelegatorStatus.Unbonded;
        } else if (del.startRound > roundsManager().currentRound()) {
            // Delegator round start is in the future
            return DelegatorStatus.Pending;
        } else {
            // Delegator round start is now or in the past
            // del.startRound != 0 here because if del.startRound = 0 then del.bondedAmount = 0 which
            // would trigger the first if clause
            return DelegatorStatus.Bonded;
        }
    }

    /**
     * @notice Return transcoder information
     * @param _transcoder Address of transcoder
     * @return lastRewardRound Trancoder's last reward round
     * @return rewardCut Transcoder's reward cut
     * @return feeShare Transcoder's fee share
     * @return lastActiveStakeUpdateRound Round in which transcoder's stake was last updated while active
     * @return activationRound Round in which transcoder became active
     * @return deactivationRound Round in which transcoder will no longer be active
     * @return activeCumulativeRewards Transcoder's cumulative rewards that are currently active
     * @return cumulativeRewards Transcoder's cumulative rewards (earned via its active staked rewards and its reward cut)
     * @return cumulativeFees Transcoder's cumulative fees (earned via its active staked rewards and its fee share)
     * @return lastFeeRound Latest round that the transcoder received fees
     */
    function getTranscoder(
        address _transcoder
    )
        public
        view
        returns (uint256 lastRewardRound, uint256 rewardCut, uint256 feeShare, uint256 lastActiveStakeUpdateRound, uint256 activationRound, uint256 deactivationRound, uint256 activeCumulativeRewards, uint256 cumulativeRewards, uint256 cumulativeFees, uint256 lastFeeRound)
    {
        Transcoder storage t = transcoders[_transcoder];

        lastRewardRound = t.lastRewardRound;
        rewardCut = t.rewardCut;
        feeShare = t.feeShare;
        lastActiveStakeUpdateRound = t.lastActiveStakeUpdateRound;
        activationRound = t.activationRound;
        deactivationRound = t.deactivationRound;
        activeCumulativeRewards = t.activeCumulativeRewards;
        cumulativeRewards = t.cumulativeRewards;
        cumulativeFees = t.cumulativeFees;
        lastFeeRound = t.lastFeeRound;
    }

    /**
     * @notice Return transcoder's earnings pool for a given round
     * @param _transcoder Address of transcoder
     * @param _round Round number
     * @return rewardPool Reward pool for delegators (only used before LIP-36)
     * @return feePool Fee pool for delegators (only used before LIP-36)
     * @return totalStake Transcoder's total stake in '_round'
     * @return claimableStake Remaining stake that can be used to claim from the pool (only used before LIP-36)
     * @return transcoderRewardCut Transcoder's reward cut for '_round'
     * @return transcoderFeeShare Transcoder's fee share for '_round'
     * @return transcoderRewardPool Transcoder's rewards for '_round' (only used before LIP-36)
     * @return transcoderFeePool Transcoder's fees for '_round' (only used before LIP-36)
     * @return hasTranscoderRewardFeePool True if there is a split reward/fee pool for the transcoder (only used before LIP-36)
     * @return cumulativeRewardFactor The cumulative reward factor for delegator rewards calculation (only used after LIP-36)
     * @return cumulativeFeeFactor The cumulative fee factor for delegator fees calculation (only used after LIP-36)
     */
    function getTranscoderEarningsPoolForRound(
        address _transcoder,
        uint256 _round
    )
        public
        view
        returns (uint256 rewardPool, uint256 feePool, uint256 totalStake, uint256 claimableStake, uint256 transcoderRewardCut, uint256 transcoderFeeShare, uint256 transcoderRewardPool, uint256 transcoderFeePool, bool hasTranscoderRewardFeePool, uint256 cumulativeRewardFactor, uint256 cumulativeFeeFactor)
    {
        EarningsPool.Data storage earningsPool = transcoders[_transcoder].earningsPoolPerRound[_round];

        rewardPool = earningsPool.rewardPool;
        feePool = earningsPool.feePool;
        totalStake = earningsPool.totalStake;
        claimableStake = earningsPool.claimableStake;
        transcoderRewardCut = earningsPool.transcoderRewardCut;
        transcoderFeeShare = earningsPool.transcoderFeeShare;
        transcoderRewardPool = earningsPool.transcoderRewardPool;
        transcoderFeePool = earningsPool.transcoderFeePool;
        hasTranscoderRewardFeePool = earningsPool.hasTranscoderRewardFeePool;
        cumulativeRewardFactor = earningsPool.cumulativeRewardFactor;
        cumulativeFeeFactor = earningsPool.cumulativeFeeFactor;
    }

    /**
     * @notice Return delegator info
     * @param _delegator Address of delegator
     * @return total amount bonded by '_delegator'
     * @return amount of fees collected by '_delegator'
     * @return address '_delegator' has bonded to
     * @return total amount delegated to '_delegator'
     * @return round in which bond for '_delegator' became effective
     * @return round for which '_delegator' has last claimed earnings
     * @return ID for the next unbonding lock created for '_delegator'
     */
    function getDelegator(
        address _delegator
    )
        public
        view
        returns (uint256 bondedAmount, uint256 fees, address delegateAddress, uint256 delegatedAmount, uint256 startRound, uint256 lastClaimRound, uint256 nextUnbondingLockId)
    {
        Delegator storage del = delegators[_delegator];

        bondedAmount = del.bondedAmount;
        fees = del.fees;
        delegateAddress = del.delegateAddress;
        delegatedAmount = del.delegatedAmount;
        startRound = del.startRound;
        lastClaimRound = del.lastClaimRound;
        nextUnbondingLockId = del.nextUnbondingLockId;
    }

    /**
     * @notice Return delegator's unbonding lock info
     * @param _delegator Address of delegator
     * @param _unbondingLockId ID of unbonding lock
     * @return amount of stake locked up by unbonding lock
     * @return round in which 'amount' becomes available for withdrawal
     */
    function getDelegatorUnbondingLock(
        address _delegator,
        uint256 _unbondingLockId
    )
        public
        view
        returns (uint256 amount, uint256 withdrawRound)
    {
        UnbondingLock storage lock = delegators[_delegator].unbondingLocks[_unbondingLockId];

        return (lock.amount, lock.withdrawRound);
    }

    /**
     * @notice Returns max size of transcoder pool
     * @return transcoder pool max size
     */
    function getTranscoderPoolMaxSize() public view returns (uint256) {
        return transcoderPoolV2.getMaxSize();
    }

    /**
     * @notice Returns size of transcoder pool
     * @return transcoder pool current size
     */
    function getTranscoderPoolSize() public view returns (uint256) {
        return transcoderPoolV2.getSize();
    }

    /**
     * @notice Returns transcoder with most stake in pool
     * @return address for transcoder with highest stake in transcoder pool
     */
    function getFirstTranscoderInPool() public view returns (address) {
        return transcoderPoolV2.getFirst();
    }

    /**
     * @notice Returns next transcoder in pool for a given transcoder
     * @param _transcoder Address of a transcoder in the pool
     * @return address for the transcoder after '_transcoder' in transcoder pool
     */
    function getNextTranscoderInPool(address _transcoder) public view returns (address) {
        return transcoderPoolV2.getNext(_transcoder);
    }

    /**
     * @notice Return total bonded tokens
     * @return total active stake for the current round
     */
    function getTotalBonded() public view returns (uint256) {
        return currentRoundTotalActiveStake;
    }

   /**
     * @notice Return whether a transcoder is active for the current round
     * @param _transcoder Transcoder address
     * @return true if transcoder is active
     */
    function isActiveTranscoder(address _transcoder) public view returns (bool) {
        Transcoder storage t = transcoders[_transcoder];
        uint256 currentRound = roundsManager().currentRound();
        return t.activationRound <= currentRound && currentRound < t.deactivationRound;
    }

    /**
     * @notice Return whether a transcoder is registered
     * @param _transcoder Transcoder address
     * @return true if transcoder is self-bonded
     */
    function isRegisteredTranscoder(address _transcoder) public view returns (bool) {
        Delegator storage d = delegators[_transcoder];
        return d.delegateAddress == _transcoder && d.bondedAmount > 0;
    }

    /**
     * @notice Return whether an unbonding lock for a delegator is valid
     * @param _delegator Address of delegator
     * @param _unbondingLockId ID of unbonding lock
     * @return true if unbondingLock for ID has a non-zero withdraw round
     */
    function isValidUnbondingLock(address _delegator, uint256 _unbondingLockId) public view returns (bool) {
        // A unbonding lock is only valid if it has a non-zero withdraw round (the default value is zero)
        return delegators[_delegator].unbondingLocks[_unbondingLockId].withdrawRound > 0;
    }

    /**
     * @notice Return an EarningsPool.Data struct with the latest cumulative factors for a given round
     * @param _transcoder Storage pointer to a transcoder struct
     * @param _round The round to fetch the latest cumulative factors for
     * @return pool An EarningsPool.Data populated with the latest cumulative factors for _round
     */
    function latestCumulativeFactorsPool(Transcoder storage _transcoder, uint256 _round) internal view returns (EarningsPool.Data memory pool) {
        pool.cumulativeRewardFactor = _transcoder.earningsPoolPerRound[_round].cumulativeRewardFactor;
        pool.cumulativeFeeFactor = _transcoder.earningsPoolPerRound[_round].cumulativeFeeFactor;

        uint256 lastRewardRound = _transcoder.lastRewardRound;
        // Only use the cumulativeRewardFactor for lastRewardRound if lastRewardRound is before _round
        if (pool.cumulativeRewardFactor == 0 && lastRewardRound < _round) {
            pool.cumulativeRewardFactor = _transcoder.earningsPoolPerRound[lastRewardRound].cumulativeRewardFactor;
        }

        uint256 lastFeeRound = _transcoder.lastFeeRound;
        // Only use the cumulativeFeeFactor for lastFeeRound if lastFeeRound is before _round
        if (pool.cumulativeFeeFactor == 0 && lastFeeRound < _round) {
            pool.cumulativeFeeFactor = _transcoder.earningsPoolPerRound[lastFeeRound].cumulativeFeeFactor;
        }

        return pool;
    }

    /**
     * @notice Return a delegator's cumulative stake and fees using the LIP-36 earnings claiming algorithm
     * @param _transcoder Storage pointer to a transcoder struct for a delegator's delegate
     * @param _startRound The round for the start cumulative factors
     * @param _endRound The round for the end cumulative factors
     * @param _stake The delegator's initial stake before including earned rewards
     * @param _fees The delegator's initial fees before including earned fees
     * @return (cStake, cFees) where cStake is the delegator's cumulative stake including earned rewards and cFees is the delegator's cumulative fees including earned fees
     */
    function delegatorCumulativeStakeAndFees(
        Transcoder storage _transcoder,
        uint256 _startRound,
        uint256 _endRound,
        uint256 _stake,
        uint256 _fees
    )
        internal
        view
        returns (uint256 cStake, uint256 cFees)
    {
        uint256 baseRewardFactor = MathUtils.percPoints(1, 1);

        // Fetch start cumulative factors
        EarningsPool.Data memory startPool;
        startPool.cumulativeRewardFactor = _transcoder.earningsPoolPerRound[_startRound].cumulativeRewardFactor;
        startPool.cumulativeFeeFactor = _transcoder.earningsPoolPerRound[_startRound].cumulativeFeeFactor;

        if (startPool.cumulativeRewardFactor == 0) {
            startPool.cumulativeRewardFactor = baseRewardFactor;
        }

        // Fetch end cumulative factors
        EarningsPool.Data memory endPool = latestCumulativeFactorsPool(_transcoder, _endRound);

        if (endPool.cumulativeRewardFactor == 0) {
            endPool.cumulativeRewardFactor = baseRewardFactor;
        }

        cFees = _fees.add(
            MathUtils.percOf(
                _stake,
                endPool.cumulativeFeeFactor.sub(startPool.cumulativeFeeFactor),
                startPool.cumulativeRewardFactor
            )
        );

        cStake = MathUtils.percOf(
            _stake,
            endPool.cumulativeRewardFactor,
            startPool.cumulativeRewardFactor
        );

        return (cStake, cFees);
    }

    /**
     * @notice Return the pending stake and fees for a delegator
     * @param _delegator Address of a delegator
     * @param _endRound The last round to claim earnings for when calculating the pending stake and fees
     * @return (stake, fees) where stake is the delegator's pending stake and fees is the delegator's pending fees
     */
    function pendingStakeAndFees(address _delegator, uint256 _endRound) internal view returns (uint256 stake, uint256 fees) {
        Delegator storage del = delegators[_delegator];
        Transcoder storage t = transcoders[del.delegateAddress];

        fees = del.fees;
        stake = del.bondedAmount;

        uint256 startRound = del.lastClaimRound.add(1);
        address delegateAddr = del.delegateAddress;
        bool isTranscoder = _delegator == delegateAddr;

        uint256 lip36Round = roundsManager().lipUpgradeRound(36);
        while (startRound <= _endRound && startRound <= lip36Round) {
            EarningsPool.Data storage earningsPool = t.earningsPoolPerRound[startRound];

            // If earningsPool.hasTranscoderRewardFeePool is not set during lip36Round then the transcoder did not call
            // reward during lip36Round before the upgrade. In this case, if the transcoder calls reward in lip36Round
            // the delegator can use the LIP-36 earnings claiming algorithm to claim for lip36Round
            if (startRound == lip36Round && !earningsPool.hasTranscoderRewardFeePool) {
                break;
            }

            if (earningsPool.hasClaimableShares()) {
                // Calculate and add fee pool share from this round
                fees = fees.add(earningsPool.feePoolShare(stake, isTranscoder));
                // Calculate new bonded amount with rewards from this round. Updated bonded amount used
                // to calculate fee pool share in next round
                stake = stake.add(earningsPool.rewardPoolShare(stake, isTranscoder));
            }

            startRound = startRound.add(1);
        }

        // If the transcoder called reward during lip36Round the upgrade, then startRound = lip36Round
        // Otherwise, startRound = lip36Round + 1

        // If the start round is greater than the end round, we've already claimed for the end round so we do not
        // need to execute the LIP-36 earnings claiming algorithm. This could be the case if:
        // - _endRound < lip36Round i.e. we are not claiming through the lip36Round
        // - _endRound == lip36Round AND startRound = lip36Round + 1 i.e we already claimed through the lip36Round
        if (startRound > _endRound) {
            return (stake, fees);
        }

        // The LIP-36 earnings claiming algorithm uses the cumulative factors from the delegator's lastClaimRound i.e. startRound - 1
        // and from the specified _endRound
        (
            stake,
            fees
        ) = delegatorCumulativeStakeAndFees(t, startRound.sub(1), _endRound, stake, fees);

        if (isTranscoder) {
            stake = stake.add(t.cumulativeRewards);
            fees = fees.add(t.cumulativeFees);
        }

        return (stake, fees);
    }

    /**
     * @dev Increase the total stake for a delegate and updates its 'lastActiveStakeUpdateRound'
     * @param _delegate The delegate to increase the stake for
     * @param _amount The amount to increase the stake for '_delegate' by
     */
    function increaseTotalStake(address _delegate, uint256 _amount, address _newPosPrev, address _newPosNext) internal {
        if (isRegisteredTranscoder(_delegate)) {
            uint256 currStake = transcoderTotalStake(_delegate);
            uint256 newStake = currStake.add(_amount);
            uint256 currRound = roundsManager().currentRound();
            uint256 nextRound = currRound.add(1);

            // If the transcoder is already in the active set update its stake and return
            if (transcoderPoolV2.contains(_delegate)) {
                transcoderPoolV2.updateKey(_delegate, newStake, _newPosPrev, _newPosNext);
                nextRoundTotalActiveStake = nextRoundTotalActiveStake.add(_amount);
                Transcoder storage t = transcoders[_delegate];

                // currStake (the transcoder's delegatedAmount field) will reflect the transcoder's stake from lastActiveStakeUpdateRound
                // because it is updated every time lastActiveStakeUpdateRound is updated
                // The current active total stake is set to currStake to ensure that the value can be used in updateTranscoderWithRewards()
                // and updateTranscoderWithFees() when lastActiveStakeUpdateRound > currentRound
                if (t.lastActiveStakeUpdateRound < currRound) {
                    t.earningsPoolPerRound[currRound].setStake(currStake);
                }

                t.earningsPoolPerRound[nextRound].setStake(newStake);
                t.lastActiveStakeUpdateRound = nextRound;
            } else {
                // Check if the transcoder is eligible to join the active set in the update round
                tryToJoinActiveSet(_delegate, newStake, nextRound, _newPosPrev, _newPosNext);
            }
        }

        // Increase delegate's delegated amount
        delegators[_delegate].delegatedAmount = delegators[_delegate].delegatedAmount.add(_amount);
    }

    /**
     * @dev Decrease the total stake for a delegate and updates its 'lastActiveStakeUpdateRound'
     * @param _delegate The transcoder to decrease the stake for
     * @param _amount The amount to decrease the stake for '_delegate' by
     */
    function decreaseTotalStake(address _delegate, uint256 _amount, address _newPosPrev, address _newPosNext) internal {
        if (transcoderPoolV2.contains(_delegate)) {
            uint256 currStake = transcoderTotalStake(_delegate);
            uint256 newStake = currStake.sub(_amount);
            uint256 currRound = roundsManager().currentRound();
            uint256 nextRound = currRound.add(1);

            transcoderPoolV2.updateKey(_delegate, newStake, _newPosPrev, _newPosNext);
            nextRoundTotalActiveStake = nextRoundTotalActiveStake.sub(_amount);
            Transcoder storage t = transcoders[_delegate];

            // currStake (the transcoder's delegatedAmount field) will reflect the transcoder's stake from lastActiveStakeUpdateRound
            // because it is updated every time lastActiveStakeUpdateRound is updated
            // The current active total stake is set to currStake to ensure that the value can be used in updateTranscoderWithRewards()
            // and updateTranscoderWithFees() when lastActiveStakeUpdateRound > currentRound
            if (t.lastActiveStakeUpdateRound < currRound) {
                t.earningsPoolPerRound[currRound].setStake(currStake);
            }

            t.lastActiveStakeUpdateRound = nextRound;
            t.earningsPoolPerRound[nextRound].setStake(newStake);
        }

        // Decrease old delegate's delegated amount
        delegators[_delegate].delegatedAmount = delegators[_delegate].delegatedAmount.sub(_amount);
    }

    /**
     * @dev Tries to add a transcoder to active transcoder pool, evicts the active transcoder with the lowest stake if the pool is full
     * @param _transcoder The transcoder to insert into the transcoder pool
     * @param _totalStake The total stake for '_transcoder'
     * @param _activationRound The round in which the transcoder should become active
     */
    function tryToJoinActiveSet(
        address _transcoder,
        uint256 _totalStake,
        uint256 _activationRound,
        address _newPosPrev,
        address _newPosNext
    )
        internal
    {
        uint256 pendingNextRoundTotalActiveStake = nextRoundTotalActiveStake;

        if (transcoderPoolV2.isFull()) {
            address lastTranscoder = transcoderPoolV2.getLast();
            uint256 lastStake = transcoderTotalStake(lastTranscoder);

            // If the pool is full and the transcoder has less stake than the least stake transcoder in the pool
            // then the transcoder is unable to join the active set for the next round
            if (_totalStake <= lastStake) {
                return;
            }

            // Evict the least stake transcoder from the active set for the next round
            // Not zeroing 'Transcoder.lastActiveStakeUpdateRound' saves gas (5k when transcoder is evicted and 20k when transcoder is reinserted)
            // There should be no side-effects as long as the value is properly updated on stake updates
            // Not zeroing the stake on the current round's 'EarningsPool' saves gas and should have no side effects as long as
            // 'EarningsPool.setStake()' is called whenever a transcoder becomes active again.
            transcoderPoolV2.remove(lastTranscoder);
            transcoders[lastTranscoder].deactivationRound = _activationRound;
            pendingNextRoundTotalActiveStake = pendingNextRoundTotalActiveStake.sub(lastStake);

            emit TranscoderDeactivated(lastTranscoder, _activationRound);
        }

        transcoderPoolV2.insert(_transcoder, _totalStake, _newPosPrev, _newPosNext);
        pendingNextRoundTotalActiveStake = pendingNextRoundTotalActiveStake.add(_totalStake);
        Transcoder storage t = transcoders[_transcoder];
        t.lastActiveStakeUpdateRound = _activationRound;
        t.activationRound = _activationRound;
        t.deactivationRound = MAX_FUTURE_ROUND;
        t.earningsPoolPerRound[_activationRound].setStake(_totalStake);
        nextRoundTotalActiveStake = pendingNextRoundTotalActiveStake;
        emit TranscoderActivated(_transcoder, _activationRound);
    }

    /**
     * @dev Remove a transcoder from the pool and deactivate it
     */
    function resignTranscoder(address _transcoder) internal {
        // Not zeroing 'Transcoder.lastActiveStakeUpdateRound' saves gas (5k when transcoder is evicted and 20k when transcoder is reinserted)
        // There should be no side-effects as long as the value is properly updated on stake updates
        // Not zeroing the stake on the current round's 'EarningsPool' saves gas and should have no side effects as long as
        // 'EarningsPool.setStake()' is called whenever a transcoder becomes active again.
        transcoderPoolV2.remove(_transcoder);
        nextRoundTotalActiveStake = nextRoundTotalActiveStake.sub(transcoderTotalStake(_transcoder));
        uint256 deactivationRound = roundsManager().currentRound().add(1);
        transcoders[_transcoder].deactivationRound = deactivationRound;
        emit TranscoderDeactivated(_transcoder, deactivationRound);
    }

    /**
     * @dev Update a transcoder with rewards and update the transcoder pool with an optional list hint if needed.
     * See SortedDoublyLL.sol for details on list hints
     * @param _transcoder Address of transcoder
     * @param _rewards Amount of rewards
     * @param _round Round that transcoder is updated
     * @param _newPosPrev Address of previous transcoder in pool if the transcoder is in the pool
     * @param _newPosNext Address of next transcoder in pool if the transcoder is in the pool
     */
    function updateTranscoderWithRewards(
        address _transcoder,
        uint256 _rewards,
        uint256 _round,
        address _newPosPrev,
        address _newPosNext
    )
        internal
    {
        Transcoder storage t = transcoders[_transcoder];
        EarningsPool.Data storage earningsPool = t.earningsPoolPerRound[_round];
        EarningsPool.Data storage prevEarningsPool = t.earningsPoolPerRound[t.lastRewardRound];

        t.activeCumulativeRewards = t.cumulativeRewards;

        uint256 transcoderCommissionRewards = MathUtils.percOf(_rewards, earningsPool.transcoderRewardCut);
        uint256 delegatorsRewards = _rewards.sub(transcoderCommissionRewards);
        // Calculate the rewards earned by the transcoder's earned rewards
        uint256 transcoderRewardStakeRewards = MathUtils.percOf(delegatorsRewards, t.activeCumulativeRewards, earningsPool.totalStake);
        // Track rewards earned by the transcoder based on its earned rewards and rewardCut
        t.cumulativeRewards = t.cumulativeRewards.add(transcoderRewardStakeRewards).add(transcoderCommissionRewards);
        // Update cumulative reward factor with new rewards
        // The cumulativeRewardFactor is used to calculate rewards for all delegators including the transcoder (self-delegated)
        // Note that delegatorsRewards includes transcoderRewardStakeRewards, but no delegator will claim that amount using
        // the earnings claiming algorithm and instead that amount is accounted for in the transcoder's cumulativeRewards field
        earningsPool.updateCumulativeRewardFactor(prevEarningsPool, delegatorsRewards);
        // Update transcoder's total stake with rewards
        increaseTotalStake(_transcoder, _rewards, _newPosPrev, _newPosNext);
    }

    /**
     * @dev Update a delegator with token pools shares from its lastClaimRound through a given round
     * @param _delegator Delegator address
     * @param _endRound The last round for which to update a delegator's stake with earnings pool shares
     * @param _lastClaimRound The round for which a delegator has last claimed earnings
     */
    function updateDelegatorWithEarnings(address _delegator, uint256 _endRound, uint256 _lastClaimRound) internal {
        Delegator storage del = delegators[_delegator];
        uint256 startRound = _lastClaimRound.add(1);
        uint256 currentBondedAmount = del.bondedAmount;
        uint256 currentFees = del.fees;

        uint256 lip36Round = roundsManager().lipUpgradeRound(36);

        // Only will have earnings to claim if you have a delegate
        // If not delegated, skip the earnings claim process
        if (del.delegateAddress != address(0)) {
            if (startRound <= lip36Round) {
                // Cannot claim earnings for more than maxEarningsClaimsRounds before LIP-36
                // This is a number to cause transactions to fail early if
                // we know they will require too much gas to loop through all the necessary rounds to claim earnings
                // The user should instead manually invoke `claimEarnings` to split up the claiming process
                // across multiple transactions
                uint256 endLoopRound = _endRound <= lip36Round ? _endRound : lip36Round;
                require(endLoopRound.sub(_lastClaimRound) <= maxEarningsClaimsRounds, "too many rounds to claim through");
            }

            (
                currentBondedAmount,
                currentFees
            ) = pendingStakeAndFees(_delegator, _endRound);

            // Check whether the endEarningsPool is initialised
            // If it is not initialised set it's cumulative factors so that they can be used when a delegator
            // next claims earnings as the start cumulative factors (see delegatorCumulativeStakeAndFees())
            Transcoder storage t = transcoders[del.delegateAddress];
            EarningsPool.Data storage endEarningsPool = t.earningsPoolPerRound[_endRound];
            if (endEarningsPool.cumulativeRewardFactor == 0) {
                endEarningsPool.cumulativeRewardFactor = t.earningsPoolPerRound[t.lastRewardRound].cumulativeRewardFactor;
            }
            if (endEarningsPool.cumulativeFeeFactor == 0) {
                endEarningsPool.cumulativeFeeFactor = t.earningsPoolPerRound[t.lastFeeRound].cumulativeFeeFactor;
            }

            if (del.delegateAddress == _delegator) {
                t.cumulativeFees = 0;
                t.cumulativeRewards = 0;
                // activeCumulativeRewards is not cleared here because the next reward() call will set it to cumulativeRewards
            }
        }

        emit EarningsClaimed(
            del.delegateAddress,
            _delegator,
            currentBondedAmount.sub(del.bondedAmount),
            currentFees.sub(del.fees),
            startRound,
            _endRound
        );

        del.lastClaimRound = _endRound;
        // Rewards are bonded by default
        del.bondedAmount = currentBondedAmount;
        del.fees = currentFees;
    }

    /**
     * @dev Update the state of a delegator and its delegate by processing a rebond using an unbonding lock and update the transcoder pool with an optional
     * list hint if needed. See SortedDoublyLL.sol for details on list hints
     * @param _delegator Address of delegator
     * @param _unbondingLockId ID of unbonding lock to rebond with
     * @param _newPosPrev Address of previous transcoder in pool if the delegate is already in or joins the pool
     * @param _newPosNext Address of next transcoder in pool if the delegate is already in or joins the pool
     */
    function processRebond(address _delegator, uint256 _unbondingLockId, address _newPosPrev, address _newPosNext) internal {
        Delegator storage del = delegators[_delegator];
        UnbondingLock storage lock = del.unbondingLocks[_unbondingLockId];

        require(isValidUnbondingLock(_delegator, _unbondingLockId), "invalid unbonding lock ID");

        uint256 amount = lock.amount;
        // Increase delegator's bonded amount
        del.bondedAmount = del.bondedAmount.add(amount);

        // Delete lock
        delete del.unbondingLocks[_unbondingLockId];

        increaseTotalStake(del.delegateAddress, amount, _newPosPrev, _newPosNext);

        emit Rebond(del.delegateAddress, _delegator, _unbondingLockId, amount);
    }

    /**
     * @dev Return LivepeerToken interface
     * @return Livepeer token contract registered with Controller
     */
    function livepeerToken() internal view returns (ILivepeerToken) {
        return ILivepeerToken(controller.getContract(keccak256("LivepeerToken")));
    }

    /**
     * @dev Return Minter interface
     * @return Minter contract registered with Controller
     */
    function minter() internal view returns (IMinter) {
        return IMinter(controller.getContract(keccak256("Minter")));
    }

    /**
     * @dev Return RoundsManager interface
     * @return RoundsManager contract registered with Controller
     */
    function roundsManager() internal view returns (IRoundsManager) {
        return IRoundsManager(controller.getContract(keccak256("RoundsManager")));
    }

    function _onlyTicketBroker() internal view {
        require(
            msg.sender == controller.getContract(keccak256("TicketBroker")),
            "caller must be TicketBroker"
        );
    }

    function _onlyRoundsManager() internal view {
        require(
            msg.sender == controller.getContract(keccak256("RoundsManager")),
            "caller must be RoundsManager"
        );
    }

    function _onlyVerifier() internal view {
        require(msg.sender == controller.getContract(keccak256("Verifier")), "caller must be Verifier");
    }

    function  _currentRoundInitialized() internal view {
        require(roundsManager().currentRoundInitialized(), "current round is not initialized");
    }

    function _autoClaimEarnings() internal {
        uint256 currentRound = roundsManager().currentRound();
        uint256 lastClaimRound = delegators[msg.sender].lastClaimRound;
        if (lastClaimRound < currentRound) {
            updateDelegatorWithEarnings(msg.sender, currentRound, lastClaimRound);
        }
    }
}