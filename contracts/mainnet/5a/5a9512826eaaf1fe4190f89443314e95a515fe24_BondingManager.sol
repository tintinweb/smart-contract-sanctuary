pragma solidity 0.4.18;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
  function Ownable() public {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

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
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

library MathUtils {
    using SafeMath for uint256;

    // Divisor used for representing percentages
    uint256 public constant PERC_DIVISOR = 1000000;

    /*
     * @dev Returns whether an amount is a valid percentage out of PERC_DIVISOR
     * @param _amount Amount that is supposed to be a percentage
     */
    function validPerc(uint256 _amount) internal pure returns (bool) {
        return _amount <= PERC_DIVISOR;
    }

    /*
     * @dev Compute percentage of a value with the percentage represented by a fraction
     * @param _amount Amount to take the percentage of
     * @param _fracNum Numerator of fraction representing the percentage
     * @param _fracDenom Denominator of fraction representing the percentage
     */
    function percOf(uint256 _amount, uint256 _fracNum, uint256 _fracDenom) internal pure returns (uint256) {
        return _amount.mul(percPoints(_fracNum, _fracDenom)).div(PERC_DIVISOR);
    }

    /*
     * @dev Compute percentage of a value with the percentage represented by a fraction over PERC_DIVISOR
     * @param _amount Amount to take the percentage of
     * @param _fracNum Numerator of fraction representing the percentage with PERC_DIVISOR as the denominator
     */
    function percOf(uint256 _amount, uint256 _fracNum) internal pure returns (uint256) {
        return _amount.mul(_fracNum).div(PERC_DIVISOR);
    }

    /*
     * @dev Compute percentage representation of a fraction
     * @param _fracNum Numerator of fraction represeting the percentage
     * @param _fracDenom Denominator of fraction represeting the percentage
     */
    function percPoints(uint256 _fracNum, uint256 _fracDenom) internal pure returns (uint256) {
        return _fracNum.mul(PERC_DIVISOR).div(_fracDenom);
    }
}

contract IController is Pausable {
    event SetContractInfo(bytes32 id, address contractAddress, bytes20 gitCommitHash);

    function setContractInfo(bytes32 _id, address _contractAddress, bytes20 _gitCommitHash) external;
    function updateController(bytes32 _id, address _controller) external;
    function getContract(bytes32 _id) public view returns (address);
}

contract IManager {
    event SetController(address controller);
    event ParameterUpdate(string param);

    function setController(address _controller) external;
}

contract Manager is IManager {
    // Controller that contract is registered with
    IController public controller;

    // Check if sender is controller
    modifier onlyController() {
        require(msg.sender == address(controller));
        _;
    }

    // Check if sender is controller owner
    modifier onlyControllerOwner() {
        require(msg.sender == controller.owner());
        _;
    }

    // Check if controller is not paused
    modifier whenSystemNotPaused() {
        require(!controller.paused());
        _;
    }

    // Check if controller is paused
    modifier whenSystemPaused() {
        require(controller.paused());
        _;
    }

    function Manager(address _controller) public {
        controller = IController(_controller);
    }

    /*
     * @dev Set controller. Only callable by current controller
     * @param _controller Controller contract address
     */
    function setController(address _controller) external onlyController {
        controller = IController(_controller);

        SetController(_controller);
    }
}

/**
 * @title ManagerProxyTarget
 * @dev The base contract that target contracts used by a proxy contract should inherit from
 * Note: Both the target contract and the proxy contract (implemented as ManagerProxy) MUST inherit from ManagerProxyTarget in order to guarantee
 * that both contracts have the same storage layout. Differing storage layouts in a proxy contract and target contract can
 * potentially break the delegate proxy upgradeability mechanism
 */
contract ManagerProxyTarget is Manager {
    // Used to look up target contract address in controller&#39;s registry
    bytes32 public targetContractId;
}

/*
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
        uint256 key;                     // Node&#39;s key used for sorting
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

    /*
     * @dev Set the maximum size of the list
     * @param _size Maximum size
     */
    function setMaxSize(Data storage self, uint256 _size) public {
        // New max size must be greater than old max size
        require(_size > self.maxSize);

        self.maxSize = _size;
    }

    /*
     * @dev Add a node to the list
     * @param _id Node&#39;s id
     * @param _key Node&#39;s key
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */
    function insert(Data storage self, address _id, uint256 _key, address _prevId, address _nextId) public {
        // List must not be full
        require(!isFull(self));
        // List must not already contain node
        require(!contains(self, _id));
        // Node id must not be null
        require(_id != address(0));
        // Key must be non-zero
        require(_key > 0);

        address prevId = _prevId;
        address nextId = _nextId;

        if (!validInsertPosition(self, _key, prevId, nextId)) {
            // Sender&#39;s hint was not a valid insert position
            // Use sender&#39;s hint to find a valid insert position
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

    /*
     * @dev Remove a node from the list
     * @param _id Node&#39;s id
     */
    function remove(Data storage self, address _id) public {
        // List must contain the node
        require(contains(self, _id));

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

    /*
     * @dev Update the key of a node in the list
     * @param _id Node&#39;s id
     * @param _newKey Node&#39;s new key
     * @param _prevId Id of previous node for the new insert position
     * @param _nextId Id of next node for the new insert position
     */
    function updateKey(Data storage self, address _id, uint256 _newKey, address _prevId, address _nextId) public {
        // List must contain the node
        require(contains(self, _id));

        // Remove node from the list
        remove(self, _id);

        if (_newKey > 0) {
            // Insert node if it has a non-zero key
            insert(self, _id, _newKey, _prevId, _nextId);
        }
    }

    /*
     * @dev Checks if the list contains a node
     * @param _transcoder Address of transcoder
     */
    function contains(Data storage self, address _id) public view returns (bool) {
        // List only contains non-zero keys, so if key is non-zero the node exists
        return self.nodes[_id].key > 0;
    }

    /*
     * @dev Checks if the list is full
     */
    function isFull(Data storage self) public view returns (bool) {
        return self.size == self.maxSize;
    }

    /*
     * @dev Checks if the list is empty
     */
    function isEmpty(Data storage self) public view returns (bool) {
        return self.size == 0;
    }

    /*
     * @dev Returns the current size of the list
     */
    function getSize(Data storage self) public view returns (uint256) {
        return self.size;
    }

    /*
     * @dev Returns the maximum size of the list
     */
    function getMaxSize(Data storage self) public view returns (uint256) {
        return self.maxSize;
    }

    /*
     * @dev Returns the key of a node in the list
     * @param _id Node&#39;s id
     */
    function getKey(Data storage self, address _id) public view returns (uint256) {
        return self.nodes[_id].key;
    }

    /*
     * @dev Returns the first node in the list (node with the largest key)
     */
    function getFirst(Data storage self) public view returns (address) {
        return self.head;
    }

    /*
     * @dev Returns the last node in the list (node with the smallest key)
     */
    function getLast(Data storage self) public view returns (address) {
        return self.tail;
    }

    /*
     * @dev Returns the next node (with a smaller key) in the list for a given node
     * @param _id Node&#39;s id
     */
    function getNext(Data storage self, address _id) public view returns (address) {
        return self.nodes[_id].nextId;
    }

    /*
     * @dev Returns the previous node (with a larger key) in the list for a given node
     * @param _id Node&#39;s id
     */
    function getPrev(Data storage self, address _id) public view returns (address) {
        return self.nodes[_id].prevId;
    }

    /*
     * @dev Check if a pair of nodes is a valid insertion point for a new node with the given key
     * @param _key Node&#39;s key
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
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
            // `(_prevId, _nextId)` is a valid insert position if they are adjacent nodes and `_key` falls between the two nodes&#39; keys
            return self.nodes[_prevId].nextId == _nextId && self.nodes[_prevId].key >= _key && _key >= self.nodes[_nextId].key;
        }
    }

    /*
     * @dev Descend the list (larger keys to smaller keys) to find a valid insert position
     * @param _key Node&#39;s key
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

    /*
     * @dev Ascend the list (smaller keys to larger keys) to find a valid insert position
     * @param _key Node&#39;s key
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

    /*
     * @dev Find the insert position for a new node with the given key
     * @param _key Node&#39;s key
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

library EarningsPool {
    using SafeMath for uint256;

    // Represents rewards and fees to be distributed to delegators
    struct Data {
        uint256 rewardPool;                // Rewards in the pool
        uint256 feePool;                   // Fees in the pool
        uint256 totalStake;                // Transcoder&#39;s total stake during the pool&#39;s round
        uint256 claimableStake;            // Stake that can be used to claim portions of the fee and reward pool
        uint256 transcoderRewardCut;       // Reward cut for the reward pool
        uint256 transcoderFeeShare;        // Fee share for the fee pool
    }

    function init(EarningsPool.Data storage earningsPool, uint256 _stake, uint256 _rewardCut, uint256 _feeShare) internal {
        earningsPool.totalStake = _stake;
        earningsPool.claimableStake = _stake;
        earningsPool.transcoderRewardCut = _rewardCut;
        earningsPool.transcoderFeeShare = _feeShare;
    }

    function hasClaimableShares(EarningsPool.Data storage earningsPool) internal view returns (bool) {
        return earningsPool.claimableStake > 0;
    }

    function claimShare(EarningsPool.Data storage earningsPool, uint256 _stake, bool _isTranscoder) internal returns (uint256, uint256) {
        uint256 fees = 0;
        uint256 rewards = 0;

        if (earningsPool.feePool > 0) {
            // Compute fee share
            fees = feePoolShare(earningsPool, _stake, _isTranscoder);
            earningsPool.feePool = earningsPool.feePool.sub(fees);
        }

        if (earningsPool.rewardPool > 0) {
            // Compute reward share
            rewards = rewardPoolShare(earningsPool, _stake, _isTranscoder);
            earningsPool.rewardPool = earningsPool.rewardPool.sub(rewards);
        }

        // Update remaning claimable stake for token pools
        earningsPool.claimableStake = earningsPool.claimableStake.sub(_stake);

        return (fees, rewards);
    }

    function feePoolShare(EarningsPool.Data storage earningsPool, uint256 _stake, bool _isTranscoder) internal view returns (uint256) {
        uint256 transcoderFees = 0;
        uint256 delegatorFees = 0;

        if (earningsPool.claimableStake > 0) {
            uint256 delegatorsFees = MathUtils.percOf(earningsPool.feePool, earningsPool.transcoderFeeShare);
            transcoderFees = earningsPool.feePool.sub(delegatorsFees);
            delegatorFees = MathUtils.percOf(delegatorsFees, _stake, earningsPool.claimableStake);
        }

        if (_isTranscoder) {
            return delegatorFees.add(transcoderFees);
        } else {
            return delegatorFees;
        }
    }

    function rewardPoolShare(EarningsPool.Data storage earningsPool, uint256 _stake, bool _isTranscoder) internal view returns (uint256) {
        uint256 transcoderRewards = 0;
        uint256 delegatorRewards = 0;

        if (earningsPool.claimableStake > 0) {
            transcoderRewards = MathUtils.percOf(earningsPool.rewardPool, earningsPool.transcoderRewardCut);
            delegatorRewards = MathUtils.percOf(earningsPool.rewardPool.sub(transcoderRewards), _stake, earningsPool.claimableStake);
        }

        if (_isTranscoder) {
            return delegatorRewards.add(transcoderRewards);
        } else {
            return delegatorRewards;
        }
    }
}

contract ILivepeerToken is ERC20, Ownable {
    function mint(address _to, uint256 _amount) public returns (bool);
    function burn(uint256 _amount) public;
}

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
    function trustedWithdrawETH(address _to, uint256 _amount) external;
    function depositETH() external payable returns (bool);
    function setCurrentRewardTokens() external;

    // Public functions
    function getController() public view returns (IController);
}

/**
 * @title RoundsManager interface
 */
contract IRoundsManager {
    // Events
    event NewRound(uint256 round);

    // External functions
    function initializeRound() external;

    // Public functions
    function blockNum() public view returns (uint256);
    function blockHash(uint256 _block) public view returns (bytes32);
    function currentRound() public view returns (uint256);
    function currentRoundStartBlock() public view returns (uint256);
    function currentRoundInitialized() public view returns (bool);
    function currentRoundLocked() public view returns (bool);
}

/*
 * @title Interface for BondingManager
 */
contract IBondingManager {
    event TranscoderUpdate(address indexed transcoder, uint256 pendingRewardCut, uint256 pendingFeeShare, uint256 pendingPricePerSegment, bool registered);
    event TranscoderEvicted(address indexed transcoder);
    event TranscoderResigned(address indexed transcoder);
    event TranscoderSlashed(address indexed transcoder, address finder, uint256 penalty, uint256 finderReward);
    event Reward(address indexed transcoder, uint256 amount);
    event Bond(address indexed delegate, address indexed delegator);
    event Unbond(address indexed delegate, address indexed delegator);
    event WithdrawStake(address indexed delegator);
    event WithdrawFees(address indexed delegator);

    // External functions
    function setActiveTranscoders() external;
    function updateTranscoderWithFees(address _transcoder, uint256 _fees, uint256 _round) external;
    function slashTranscoder(address _transcoder, address _finder, uint256 _slashAmount, uint256 _finderFee) external;
    function electActiveTranscoder(uint256 _maxPricePerSegment, bytes32 _blockHash, uint256 _round) external view returns (address);

    // Public functions
    function transcoderTotalStake(address _transcoder) public view returns (uint256);
    function activeTranscoderTotalStake(address _transcoder, uint256 _round) public view returns (uint256);
    function isRegisteredTranscoder(address _transcoder) public view returns (bool);
    function getTotalBonded() public view returns (uint256);
}

/**
 * @title BondingManager
 * @dev Manages bonding, transcoder and rewards/fee accounting related operations of the Livepeer protocol
 */
contract BondingManager is ManagerProxyTarget, IBondingManager {
    using SafeMath for uint256;
    using SortedDoublyLL for SortedDoublyLL.Data;
    using EarningsPool for EarningsPool.Data;

    // Time between unbonding and possible withdrawl in rounds
    uint64 public unbondingPeriod;
    // Number of active transcoders
    uint256 public numActiveTranscoders;
    // Max number of rounds that a caller can claim earnings for at once
    uint256 public maxEarningsClaimsRounds;

    // Represents a transcoder&#39;s current state
    struct Transcoder {
        uint256 lastRewardRound;                             // Last round that the transcoder called reward
        uint256 rewardCut;                                   // % of reward paid to transcoder by a delegator
        uint256 feeShare;                                    // % of fees paid to delegators by transcoder
        uint256 pricePerSegment;                             // Price per segment (denominated in LPT units) for a stream
        uint256 pendingRewardCut;                            // Pending reward cut for next round if the transcoder is active
        uint256 pendingFeeShare;                             // Pending fee share for next round if the transcoder is active
        uint256 pendingPricePerSegment;                      // Pending price per segment for next round if the transcoder is active
        mapping (uint256 => EarningsPool.Data) earningsPoolPerRound;  // Mapping of round => earnings pool for the round
    }

    // The various states a transcoder can be in
    enum TranscoderStatus { NotRegistered, Registered }

    // Represents a delegator&#39;s current state
    struct Delegator {
        uint256 bondedAmount;                    // The amount of bonded tokens
        uint256 fees;                            // The amount of fees collected
        address delegateAddress;                 // The address delegated to
        uint256 delegatedAmount;                 // The amount of tokens delegated to the delegator
        uint256 startRound;                      // The round the delegator transitions to bonded phase and is delegated to someone
        uint256 withdrawRound;                   // The round at which a delegator can withdraw
        uint256 lastClaimRound;                  // The last round during which the delegator claimed its earnings
    }

    // The various states a delegator can be in
    enum DelegatorStatus { Pending, Bonded, Unbonding, Unbonded }

    // Keep track of the known transcoders and delegators
    mapping (address => Delegator) private delegators;
    mapping (address => Transcoder) private transcoders;

    // Keep track of total bonded tokens
    uint256 private totalBonded;

    // Candidate and reserve transcoders
    SortedDoublyLL.Data private transcoderPool;

    // Represents the active transcoder set
    struct ActiveTranscoderSet {
        address[] transcoders;
        mapping (address => bool) isActive;
        uint256 totalStake;
    }

    // Keep track of active transcoder set for each round
    mapping (uint256 => ActiveTranscoderSet) public activeTranscoderSet;

    // Check if sender is JobsManager
    modifier onlyJobsManager() {
        require(msg.sender == controller.getContract(keccak256("JobsManager")));
        _;
    }

    // Check if sender is RoundsManager
    modifier onlyRoundsManager() {
        require(msg.sender == controller.getContract(keccak256("RoundsManager")));
        _;
    }

    // Check if current round is initialized
    modifier currentRoundInitialized() {
        require(roundsManager().currentRoundInitialized());
        _;
    }

    // Automatically claim earnings from lastClaimRound through the current round
    modifier autoClaimEarnings() {
        updateDelegatorWithEarnings(msg.sender, roundsManager().currentRound());
        _;
    }

    /**
     * @dev BondingManager constructor. Only invokes constructor of base Manager contract with provided Controller address
     * @param _controller Address of Controller that this contract will be registered with
     */
    function BondingManager(address _controller) public Manager(_controller) {}

    /**
     * @dev Set unbonding period. Only callable by Controller owner
     * @param _unbondingPeriod Rounds between unbonding and possible withdrawal
     */
    function setUnbondingPeriod(uint64 _unbondingPeriod) external onlyControllerOwner {
        unbondingPeriod = _unbondingPeriod;

        ParameterUpdate("unbondingPeriod");
    }

    /**
     * @dev Set max number of registered transcoders. Only callable by Controller owner
     * @param _numTranscoders Max number of registered transcoders
     */
    function setNumTranscoders(uint256 _numTranscoders) external onlyControllerOwner {
        // Max number of transcoders must be greater than or equal to number of active transcoders
        require(_numTranscoders >= numActiveTranscoders);

        transcoderPool.setMaxSize(_numTranscoders);

        ParameterUpdate("numTranscoders");
    }

    /**
     * @dev Set number of active transcoders. Only callable by Controller owner
     * @param _numActiveTranscoders Number of active transcoders
     */
    function setNumActiveTranscoders(uint256 _numActiveTranscoders) external onlyControllerOwner {
        // Number of active transcoders cannot exceed max number of transcoders
        require(_numActiveTranscoders <= transcoderPool.getMaxSize());

        numActiveTranscoders = _numActiveTranscoders;

        ParameterUpdate("numActiveTranscoders");
    }

    /**
     * @dev Set max number of rounds a caller can claim earnings for at once. Only callable by Controller owner
     * @param _maxEarningsClaimsRounds Max number of rounds a caller can claim earnings for at once
     */
    function setMaxEarningsClaimsRounds(uint256 _maxEarningsClaimsRounds) external onlyControllerOwner {
        maxEarningsClaimsRounds = _maxEarningsClaimsRounds;

        ParameterUpdate("maxEarningsClaimsRounds");
    }

    /**
     * @dev The sender is declaring themselves as a candidate for active transcoding.
     * @param _rewardCut % of reward paid to transcoder by a delegator
     * @param _feeShare % of fees paid to delegators by a transcoder
     * @param _pricePerSegment Price per segment (denominated in Wei) for a stream
     */
    function transcoder(uint256 _rewardCut, uint256 _feeShare, uint256 _pricePerSegment)
        external
        whenSystemNotPaused
        currentRoundInitialized
    {
        Transcoder storage t = transcoders[msg.sender];
        Delegator storage del = delegators[msg.sender];

        if (roundsManager().currentRoundLocked()) {
            // If it is the lock period of the current round
            // the lowest price previously set by any transcoder
            // becomes the price floor and the caller can lower its
            // own price to a point greater than or equal to the price floor

            // Caller must already be a registered transcoder
            require(transcoderStatus(msg.sender) == TranscoderStatus.Registered);
            // Provided rewardCut value must equal the current pendingRewardCut value
            // This value cannot change during the lock period
            require(_rewardCut == t.pendingRewardCut);
            // Provided feeShare value must equal the current pendingFeeShare value
            // This value cannot change during the lock period
            require(_feeShare == t.pendingFeeShare);

            // Iterate through the transcoder pool to find the price floor
            // Since the caller must be a registered transcoder, the transcoder pool size will always at least be 1
            // Thus, we can safely set the initial price floor to be the pendingPricePerSegment of the first
            // transcoder in the pool
            address currentTranscoder = transcoderPool.getFirst();
            uint256 priceFloor = transcoders[currentTranscoder].pendingPricePerSegment;
            for (uint256 i = 0; i < transcoderPool.getSize(); i++) {
                if (transcoders[currentTranscoder].pendingPricePerSegment < priceFloor) {
                    priceFloor = transcoders[currentTranscoder].pendingPricePerSegment;
                }

                currentTranscoder = transcoderPool.getNext(currentTranscoder);
            }

            // Provided pricePerSegment must be greater than or equal to the price floor and
            // less than or equal to the previously set pricePerSegment by the caller
            require(_pricePerSegment >= priceFloor && _pricePerSegment <= t.pendingPricePerSegment);

            t.pendingPricePerSegment = _pricePerSegment;

            TranscoderUpdate(msg.sender, t.pendingRewardCut, t.pendingFeeShare, _pricePerSegment, true);
        } else {
            // It is not the lock period of the current round
            // Caller is free to change rewardCut, feeShare, pricePerSegment as it pleases
            // If caller is not a registered transcoder, it can also register and join the transcoder pool
            // if it has sufficient delegated stake
            // If caller is not a registered transcoder and does not have sufficient delegated stake
            // to join the transcoder pool, it can change rewardCut, feeShare, pricePerSegment
            // as information signals to delegators in an effort to camapaign and accumulate
            // more delegated stake

            // Reward cut must be a valid percentage
            require(MathUtils.validPerc(_rewardCut));
            // Fee share must be a valid percentage
            require(MathUtils.validPerc(_feeShare));

            // Must have a non-zero amount bonded to self
            require(del.delegateAddress == msg.sender && del.bondedAmount > 0);

            t.pendingRewardCut = _rewardCut;
            t.pendingFeeShare = _feeShare;
            t.pendingPricePerSegment = _pricePerSegment;

            uint256 delegatedAmount = del.delegatedAmount;

            // Check if transcoder is not already registered
            if (transcoderStatus(msg.sender) == TranscoderStatus.NotRegistered) {
                if (!transcoderPool.isFull()) {
                    // If pool is not full add new transcoder
                    transcoderPool.insert(msg.sender, delegatedAmount, address(0), address(0));
                } else {
                    address lastTranscoder = transcoderPool.getLast();

                    if (delegatedAmount > transcoderPool.getKey(lastTranscoder)) {
                        // If pool is full and caller has more delegated stake than the transcoder in the pool with the least delegated stake:
                        // - Evict transcoder in pool with least delegated stake
                        // - Add caller to pool
                        transcoderPool.remove(lastTranscoder);
                        transcoderPool.insert(msg.sender, delegatedAmount, address(0), address(0));

                        TranscoderEvicted(lastTranscoder);
                    }
                }
            }

            TranscoderUpdate(msg.sender, _rewardCut, _feeShare, _pricePerSegment, transcoderPool.contains(msg.sender));
        }
    }

    /**
     * @dev Delegate stake towards a specific address.
     * @param _amount The amount of LPT to stake.
     * @param _to The address of the transcoder to stake towards.
     */
    function bond(
        uint256 _amount,
        address _to
    )
        external
        whenSystemNotPaused
        currentRoundInitialized
        autoClaimEarnings
    {
        Delegator storage del = delegators[msg.sender];

        uint256 currentRound = roundsManager().currentRound();
        // Amount to delegate
        uint256 delegationAmount = _amount;

        if (delegatorStatus(msg.sender) == DelegatorStatus.Unbonded || delegatorStatus(msg.sender) == DelegatorStatus.Unbonding) {
            // New delegate
            // Set start round
            // Don&#39;t set start round if delegator is in pending state because the start round would not change
            del.startRound = currentRound.add(1);
            // If transitioning from unbonding or unbonded state
            // make sure to zero out withdraw round
            del.withdrawRound = 0;
            // Unbonded or unbonding state = no existing delegate
            // Thus, delegation amount = bonded stake + provided amount
            // If caller is bonding for the first time or withdrew previously bonded stake, delegation amount = provided amount
            delegationAmount = delegationAmount.add(del.bondedAmount);
        } else if (del.delegateAddress != address(0) && _to != del.delegateAddress) {
            // A registered transcoder cannot delegate its bonded stake toward another address
            // because it can only be delegated toward itself
            // In the future, if delegation towards another registered transcoder as an already
            // registered transcoder becomes useful (i.e. for transitive delegation), this restriction
            // could be removed
            require(transcoderStatus(msg.sender) == TranscoderStatus.NotRegistered);
            // Changing delegate
            // Set start round
            del.startRound = currentRound.add(1);
            // Update amount to delegate with previous delegation amount
            delegationAmount = delegationAmount.add(del.bondedAmount);
            // Decrease old delegate&#39;s delegated amount
            delegators[del.delegateAddress].delegatedAmount = delegators[del.delegateAddress].delegatedAmount.sub(del.bondedAmount);

            if (transcoderStatus(del.delegateAddress) == TranscoderStatus.Registered) {
                // Previously delegated to a transcoder
                // Decrease old transcoder&#39;s total stake
                transcoderPool.updateKey(del.delegateAddress, transcoderPool.getKey(del.delegateAddress).sub(del.bondedAmount), address(0), address(0));
            }
        }

        // Delegation amount must be > 0 - cannot delegate to someone without having bonded stake
        require(delegationAmount > 0);
        // Update delegate
        del.delegateAddress = _to;
        // Update current delegate&#39;s delegated amount with delegation amount
        delegators[_to].delegatedAmount = delegators[_to].delegatedAmount.add(delegationAmount);

        if (transcoderStatus(_to) == TranscoderStatus.Registered) {
            // Delegated to a transcoder
            // Increase transcoder&#39;s total stake
            transcoderPool.updateKey(_to, transcoderPool.getKey(del.delegateAddress).add(delegationAmount), address(0), address(0));
        }

        if (_amount > 0) {
            // Update bonded amount
            del.bondedAmount = del.bondedAmount.add(_amount);
            // Update total bonded tokens
            totalBonded = totalBonded.add(_amount);
            // Transfer the LPT to the Minter
            livepeerToken().transferFrom(msg.sender, minter(), _amount);
        }

        Bond(_to, msg.sender);
    }

    /**
     * @dev Unbond delegator&#39;s current stake. Delegator enters unbonding state
     */
    function unbond()
        external
        whenSystemNotPaused
        currentRoundInitialized
        autoClaimEarnings
    {
        // Sender must be in bonded state
        require(delegatorStatus(msg.sender) == DelegatorStatus.Bonded);

        Delegator storage del = delegators[msg.sender];

        uint256 currentRound = roundsManager().currentRound();

        // Transition to unbonding phase
        del.withdrawRound = currentRound.add(unbondingPeriod);
        // Decrease delegate&#39;s delegated amount
        delegators[del.delegateAddress].delegatedAmount = delegators[del.delegateAddress].delegatedAmount.sub(del.bondedAmount);
        // Update total bonded tokens
        totalBonded = totalBonded.sub(del.bondedAmount);

        if (transcoderStatus(msg.sender) == TranscoderStatus.Registered) {
            // If caller is a registered transcoder, resign
            // In the future, with partial unbonding there would be a check for 0 bonded stake as well
            resignTranscoder(msg.sender);
        }

        if (del.delegateAddress != msg.sender && transcoderStatus(del.delegateAddress) == TranscoderStatus.Registered) {
            // If delegate is not self and is a registered transcoder, decrease its delegated stake
            // We do not need to decrease delegated stake if delegate is self because we would have already removed self
            // from the transcoder pool
            transcoderPool.updateKey(del.delegateAddress, transcoderPool.getKey(del.delegateAddress).sub(del.bondedAmount), address(0), address(0));
        }

        // Delegator no longer bonded to anyone
        del.delegateAddress = address(0);
        // Unbonding delegator does not have a start round
        del.startRound = 0;

        Unbond(del.delegateAddress, msg.sender);
    }

    /**
     * @dev Withdraws bonded stake to the caller after unbonding period.
     */
    function withdrawStake()
        external
        whenSystemNotPaused
        currentRoundInitialized
    {
        // Delegator must be in the unbonded state
        require(delegatorStatus(msg.sender) == DelegatorStatus.Unbonded);

        uint256 amount = delegators[msg.sender].bondedAmount;
        delegators[msg.sender].bondedAmount = 0;
        delegators[msg.sender].withdrawRound = 0;

        // Tell Minter to transfer stake (LPT) to the delegator
        minter().trustedTransferTokens(msg.sender, amount);

        WithdrawStake(msg.sender);
    }

    /**
     * @dev Withdraws fees to the caller
     */
    function withdrawFees()
        external
        whenSystemNotPaused
        currentRoundInitialized
        autoClaimEarnings
    {
        // Delegator must have fees
        require(delegators[msg.sender].fees > 0);

        uint256 amount = delegators[msg.sender].fees;
        delegators[msg.sender].fees = 0;

        // Tell Minter to transfer fees (ETH) to the delegator
        minter().trustedWithdrawETH(msg.sender, amount);

        WithdrawFees(msg.sender);
    }

    /**
     * @dev Set active transcoder set for the current round
     */
    function setActiveTranscoders() external whenSystemNotPaused onlyRoundsManager {
        uint256 currentRound = roundsManager().currentRound();
        uint256 activeSetSize = Math.min256(numActiveTranscoders, transcoderPool.getSize());

        uint256 totalStake = 0;
        address currentTranscoder = transcoderPool.getFirst();

        for (uint256 i = 0; i < activeSetSize; i++) {
            activeTranscoderSet[currentRound].transcoders.push(currentTranscoder);
            activeTranscoderSet[currentRound].isActive[currentTranscoder] = true;

            uint256 stake = transcoderPool.getKey(currentTranscoder);
            uint256 rewardCut = transcoders[currentTranscoder].pendingRewardCut;
            uint256 feeShare = transcoders[currentTranscoder].pendingFeeShare;
            uint256 pricePerSegment = transcoders[currentTranscoder].pendingPricePerSegment;

            Transcoder storage t = transcoders[currentTranscoder];
            // Set pending rates as current rates
            t.rewardCut = rewardCut;
            t.feeShare = feeShare;
            t.pricePerSegment = pricePerSegment;
            // Initialize token pool
            t.earningsPoolPerRound[currentRound].init(stake, rewardCut, feeShare);

            totalStake = totalStake.add(stake);

            // Get next transcoder in the pool
            currentTranscoder = transcoderPool.getNext(currentTranscoder);
        }

        // Update total stake of all active transcoders
        activeTranscoderSet[currentRound].totalStake = totalStake;
    }

    /**
     * @dev Distribute the token rewards to transcoder and delegates.
     * Active transcoders call this once per cycle when it is their turn.
     */
    function reward() external whenSystemNotPaused currentRoundInitialized {
        uint256 currentRound = roundsManager().currentRound();

        // Sender must be an active transcoder
        require(activeTranscoderSet[currentRound].isActive[msg.sender]);

        // Transcoder must not have called reward for this round already
        require(transcoders[msg.sender].lastRewardRound != currentRound);
        // Set last round that transcoder called reward
        transcoders[msg.sender].lastRewardRound = currentRound;

        // Create reward based on active transcoder&#39;s stake relative to the total active stake
        // rewardTokens = (current mintable tokens for the round * active transcoder stake) / total active stake
        uint256 rewardTokens = minter().createReward(activeTranscoderTotalStake(msg.sender, currentRound), activeTranscoderSet[currentRound].totalStake);

        updateTranscoderWithRewards(msg.sender, rewardTokens, currentRound);

        Reward(msg.sender, rewardTokens);
    }

    /**
     * @dev Update transcoder&#39;s fee pool
     * @param _transcoder Transcoder address
     * @param _fees Fees from verified job claims
     */
    function updateTranscoderWithFees(
        address _transcoder,
        uint256 _fees,
        uint256 _round
    )
        external
        whenSystemNotPaused
        onlyJobsManager
    {
        // Transcoder must be registered
        require(transcoderStatus(_transcoder) == TranscoderStatus.Registered);

        Transcoder storage t = transcoders[_transcoder];

        EarningsPool.Data storage earningsPool = t.earningsPoolPerRound[_round];
        // Add fees to fee pool
        earningsPool.feePool = earningsPool.feePool.add(_fees);
    }

    /**
     * @dev Slash a transcoder. Slashing can be invoked by the protocol or a finder.
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
        onlyJobsManager
    {
        Delegator storage del = delegators[_transcoder];

        if (del.bondedAmount > 0) {
            uint256 penalty = MathUtils.percOf(delegators[_transcoder].bondedAmount, _slashAmount);

            // Decrease bonded stake
            del.bondedAmount = del.bondedAmount.sub(penalty);

            // If still bonded
            // - Decrease delegate&#39;s delegated amount
            // - Decrease total bonded tokens
            if (delegatorStatus(_transcoder) == DelegatorStatus.Bonded) {
                delegators[del.delegateAddress].delegatedAmount = delegators[del.delegateAddress].delegatedAmount.sub(penalty);
                totalBonded = totalBonded.sub(penalty);
            }

            // If registered transcoder, resign it
            if (transcoderStatus(_transcoder) == TranscoderStatus.Registered) {
                resignTranscoder(_transcoder);
            }

            // Account for penalty
            uint256 burnAmount = penalty;

            // Award finder fee if there is a finder address
            if (_finder != address(0)) {
                uint256 finderAmount = MathUtils.percOf(penalty, _finderFee);
                minter().trustedTransferTokens(_finder, finderAmount);

                // Minter burns the slashed funds - finder reward
                minter().trustedBurnTokens(burnAmount.sub(finderAmount));

                TranscoderSlashed(_transcoder, _finder, penalty, finderAmount);
            } else {
                // Minter burns the slashed funds
                minter().trustedBurnTokens(burnAmount);

                TranscoderSlashed(_transcoder, address(0), penalty, 0);
            }
        } else {
            TranscoderSlashed(_transcoder, _finder, 0, 0);
        }
    }

    /**
     * @dev Pseudorandomly elect a currently active transcoder that charges a price per segment less than or equal to the max price per segment for a job
     * Returns address of elected active transcoder and its price per segment
     * @param _maxPricePerSegment Max price (in LPT base units) per segment of a stream
     * @param _blockHash Job creation block hash used as a pseudorandom seed for assigning an active transcoder
     * @param _round Job creation round
     */
    function electActiveTranscoder(uint256 _maxPricePerSegment, bytes32 _blockHash, uint256 _round) external view returns (address) {
        uint256 activeSetSize = activeTranscoderSet[_round].transcoders.length;
        // Create array to store available transcoders charging an acceptable price per segment
        address[] memory availableTranscoders = new address[](activeSetSize);
        // Keep track of the actual number of available transcoders
        uint256 numAvailableTranscoders = 0;
        // Keep track of total stake of available transcoders
        uint256 totalAvailableTranscoderStake = 0;

        for (uint256 i = 0; i < activeSetSize; i++) {
            address activeTranscoder = activeTranscoderSet[_round].transcoders[i];
            // If a transcoder is active and charges an acceptable price per segment add it to the array of available transcoders
            if (activeTranscoderSet[_round].isActive[activeTranscoder] && transcoders[activeTranscoder].pricePerSegment <= _maxPricePerSegment) {
                availableTranscoders[numAvailableTranscoders] = activeTranscoder;
                numAvailableTranscoders++;
                totalAvailableTranscoderStake = totalAvailableTranscoderStake.add(activeTranscoderTotalStake(activeTranscoder, _round));
            }
        }

        if (numAvailableTranscoders == 0) {
            // There is no currently available transcoder that charges a price per segment less than or equal to the max price per segment for a job
            return address(0);
        } else {
            // Pseudorandomly pick an available transcoder weighted by its stake relative to the total stake of all available transcoders
            uint256 r = uint256(_blockHash) % totalAvailableTranscoderStake;
            uint256 s = 0;
            uint256 j = 0;

            while (s <= r && j < numAvailableTranscoders) {
                s = s.add(activeTranscoderTotalStake(availableTranscoders[j], _round));
                j++;
            }

            return availableTranscoders[j - 1];
        }
    }

    /**
     * @dev Claim token pools shares for a delegator from its lastClaimRound through the end round
     * @param _endRound The last round for which to claim token pools shares for a delegator
     */
    function claimEarnings(uint256 _endRound) external whenSystemNotPaused currentRoundInitialized {
        // End round must be after the last claim round
        require(delegators[msg.sender].lastClaimRound < _endRound);
        // End round must not be after the current round
        require(_endRound <= roundsManager().currentRound());

        updateDelegatorWithEarnings(msg.sender, _endRound);
    }

    /**
     * @dev Returns pending bonded stake for a delegator from its lastClaimRound through an end round
     * @param _delegator Address of delegator
     * @param _endRound The last round to compute pending stake from
     */
    function pendingStake(address _delegator, uint256 _endRound) public view returns (uint256) {
        uint256 currentRound = roundsManager().currentRound();
        Delegator storage del = delegators[_delegator];
        // End round must be before or equal to current round and after lastClaimRound
        require(_endRound <= currentRound && _endRound > del.lastClaimRound);

        uint256 currentBondedAmount = del.bondedAmount;

        for (uint256 i = del.lastClaimRound + 1; i <= _endRound; i++) {
            EarningsPool.Data storage earningsPool = transcoders[del.delegateAddress].earningsPoolPerRound[i];

            bool isTranscoder = _delegator == del.delegateAddress;
            if (earningsPool.hasClaimableShares()) {
                // Calculate and add reward pool share from this round
                currentBondedAmount = currentBondedAmount.add(earningsPool.rewardPoolShare(currentBondedAmount, isTranscoder));
            }
        }

        return currentBondedAmount;
    }

    /**
     * @dev Returns pending fees for a delegator from its lastClaimRound through an end round
     * @param _delegator Address of delegator
     * @param _endRound The last round to compute pending fees from
     */
    function pendingFees(address _delegator, uint256 _endRound) public view returns (uint256) {
        uint256 currentRound = roundsManager().currentRound();
        Delegator storage del = delegators[_delegator];
        // End round must be before or equal to current round and after lastClaimRound
        require(_endRound <= currentRound && _endRound > del.lastClaimRound);

        uint256 currentFees = del.fees;
        uint256 currentBondedAmount = del.bondedAmount;

        for (uint256 i = del.lastClaimRound + 1; i <= _endRound; i++) {
            EarningsPool.Data storage earningsPool = transcoders[del.delegateAddress].earningsPoolPerRound[i];

            if (earningsPool.hasClaimableShares()) {
                bool isTranscoder = _delegator == del.delegateAddress;
                // Calculate and add fee pool share from this round
                currentFees = currentFees.add(earningsPool.feePoolShare(currentBondedAmount, isTranscoder));
                // Calculate new bonded amount with rewards from this round. Updated bonded amount used
                // to calculate fee pool share in next round
                currentBondedAmount = currentBondedAmount.add(earningsPool.rewardPoolShare(currentBondedAmount, isTranscoder));
            }
        }

        return currentFees;
    }

    /**
     * @dev Returns total bonded stake for an active transcoder
     * @param _transcoder Address of a transcoder
     */
    function activeTranscoderTotalStake(address _transcoder, uint256 _round) public view returns (uint256) {
        // Must be active transcoder
        require(activeTranscoderSet[_round].isActive[_transcoder]);

        return transcoders[_transcoder].earningsPoolPerRound[_round].totalStake;
    }

    /**
     * @dev Returns total bonded stake for a transcoder
     * @param _transcoder Address of transcoder
     */
    function transcoderTotalStake(address _transcoder) public view returns (uint256) {
        return transcoderPool.getKey(_transcoder);
    }

    /*
     * @dev Computes transcoder status
     * @param _transcoder Address of transcoder
     */
    function transcoderStatus(address _transcoder) public view returns (TranscoderStatus) {
        if (transcoderPool.contains(_transcoder)) {
            return TranscoderStatus.Registered;
        } else {
            return TranscoderStatus.NotRegistered;
        }
    }

    /**
     * @dev Computes delegator status
     * @param _delegator Address of delegator
     */
    function delegatorStatus(address _delegator) public view returns (DelegatorStatus) {
        Delegator storage del = delegators[_delegator];

        if (del.withdrawRound > 0) {
            // Delegator called unbond
            if (roundsManager().currentRound() >= del.withdrawRound) {
                return DelegatorStatus.Unbonded;
            } else {
                return DelegatorStatus.Unbonding;
            }
        } else if (del.startRound > roundsManager().currentRound()) {
            // Delegator round start is in the future
            return DelegatorStatus.Pending;
        } else if (del.startRound > 0 && del.startRound <= roundsManager().currentRound()) {
            // Delegator round start is now or in the past
            return DelegatorStatus.Bonded;
        } else {
            // Default to unbonded
            return DelegatorStatus.Unbonded;
        }
    }

    /**
     * @dev Return transcoder information
     * @param _transcoder Address of transcoder
     */
    function getTranscoder(
        address _transcoder
    )
        public
        view
        returns (uint256 lastRewardRound, uint256 rewardCut, uint256 feeShare, uint256 pricePerSegment, uint256 pendingRewardCut, uint256 pendingFeeShare, uint256 pendingPricePerSegment)
    {
        Transcoder storage t = transcoders[_transcoder];

        lastRewardRound = t.lastRewardRound;
        rewardCut = t.rewardCut;
        feeShare = t.feeShare;
        pricePerSegment = t.pricePerSegment;
        pendingRewardCut = t.pendingRewardCut;
        pendingFeeShare = t.pendingFeeShare;
        pendingPricePerSegment = t.pendingPricePerSegment;
    }

    /**
     * @dev Return transcoder&#39;s token pools for a given round
     * @param _transcoder Address of transcoder
     * @param _round Round number
     */
    function getTranscoderEarningsPoolForRound(
        address _transcoder,
        uint256 _round
    )
        public
        view
        returns (uint256 rewardPool, uint256 feePool, uint256 totalStake, uint256 claimableStake)
    {
        EarningsPool.Data storage earningsPool = transcoders[_transcoder].earningsPoolPerRound[_round];

        rewardPool = earningsPool.rewardPool;
        feePool = earningsPool.feePool;
        totalStake = earningsPool.totalStake;
        claimableStake = earningsPool.claimableStake;
    }

    /**
     * @dev Return delegator info
     * @param _delegator Address of delegator
     */
    function getDelegator(
        address _delegator
    )
        public
        view
        returns (uint256 bondedAmount, uint256 fees, address delegateAddress, uint256 delegatedAmount, uint256 startRound, uint256 withdrawRound, uint256 lastClaimRound)
    {
        Delegator storage del = delegators[_delegator];

        bondedAmount = del.bondedAmount;
        fees = del.fees;
        delegateAddress = del.delegateAddress;
        delegatedAmount = del.delegatedAmount;
        startRound = del.startRound;
        withdrawRound = del.withdrawRound;
        lastClaimRound = del.lastClaimRound;
    }

    /**
     * @dev Returns max size of transcoder pool
     */
    function getTranscoderPoolMaxSize() public view returns (uint256) {
        return transcoderPool.getMaxSize();
    }

    /**
     * @dev Returns size of transcoder pool
     */
    function getTranscoderPoolSize() public view returns (uint256) {
        return transcoderPool.getSize();
    }

    /**
     * @dev Returns transcoder with most stake in pool
     */
    function getFirstTranscoderInPool() public view returns (address) {
        return transcoderPool.getFirst();
    }

    /**
     * @dev Returns next transcoder in pool for a given transcoder
     * @param _transcoder Address of a transcoder in the pool
     */
    function getNextTranscoderInPool(address _transcoder) public view returns (address) {
        return transcoderPool.getNext(_transcoder);
    }

    /**
     * @dev Return total bonded tokens
     */
    function getTotalBonded() public view returns (uint256) {
        return totalBonded;
    }

    /**
     * @dev Return total active stake for a round
     * @param _round Round number
     */
    function getTotalActiveStake(uint256 _round) public view returns (uint256) {
        return activeTranscoderSet[_round].totalStake;
    }

    /**
     * @dev Return whether a transcoder was active during a round
     * @param _transcoder Transcoder address
     * @param _round Round number
     */
    function isActiveTranscoder(address _transcoder, uint256 _round) public view returns (bool) {
        return activeTranscoderSet[_round].isActive[_transcoder];
    }

    /**
     * @dev Return whether a transcoder is registered
     * @param _transcoder Transcoder address
     */
    function isRegisteredTranscoder(address _transcoder) public view returns (bool) {
        return transcoderStatus(_transcoder) == TranscoderStatus.Registered;
    }

    /**
     * @dev Remove transcoder
     */
    function resignTranscoder(address _transcoder) internal {
        uint256 currentRound = roundsManager().currentRound();
        if (activeTranscoderSet[currentRound].isActive[_transcoder]) {
            // Decrease total active stake for the round
            activeTranscoderSet[currentRound].totalStake = activeTranscoderSet[currentRound].totalStake.sub(activeTranscoderTotalStake(_transcoder, currentRound));
            // Set transcoder as inactive
            activeTranscoderSet[currentRound].isActive[_transcoder] = false;
        }

        // Remove transcoder from pools
        transcoderPool.remove(_transcoder);

        TranscoderResigned(_transcoder);
    }

    /**
     * @dev Update a transcoder with rewards
     * @param _transcoder Address of transcoder
     * @param _rewards Amount of rewards
     * @param _round Round that transcoder is updated
     */
    function updateTranscoderWithRewards(address _transcoder, uint256 _rewards, uint256 _round) internal {
        Transcoder storage t = transcoders[_transcoder];
        Delegator storage del = delegators[_transcoder];

        EarningsPool.Data storage earningsPool = t.earningsPoolPerRound[_round];
        // Add rewards to reward pool
        earningsPool.rewardPool = earningsPool.rewardPool.add(_rewards);
        // Update transcoder&#39;s delegated amount with rewards
        del.delegatedAmount = del.delegatedAmount.add(_rewards);
        // Update transcoder&#39;s total stake with rewards
        uint256 newStake = transcoderPool.getKey(_transcoder).add(_rewards);
        transcoderPool.updateKey(_transcoder, newStake, address(0), address(0));
        // Update total bonded tokens with claimable rewards
        totalBonded = totalBonded.add(_rewards);
    }

    /**
     * @dev Update a delegator with token pools shares from its lastClaimRound through a given round
     * @param _delegator Delegator address
     * @param _endRound The last round for which to update a delegator&#39;s stake with token pools shares
     */
    function updateDelegatorWithEarnings(address _delegator, uint256 _endRound) internal {
        Delegator storage del = delegators[_delegator];

        // Only will have earnings to claim if you have a delegate
        // If not delegated, skip the earnings claim process
        if (del.delegateAddress != address(0)) {
            // Cannot claim earnings for more than maxEarningsClaimsRounds
            // This is a number to cause transactions to fail early if
            // we know they will require too much gas to loop through all the necessary rounds to claim earnings
            // The user should instead manually invoke `claimEarnings` to split up the claiming process
            // across multiple transactions
            require(_endRound.sub(del.lastClaimRound) <= maxEarningsClaimsRounds);

            uint256 currentBondedAmount = del.bondedAmount;
            uint256 currentFees = del.fees;

            for (uint256 i = del.lastClaimRound + 1; i <= _endRound; i++) {
                EarningsPool.Data storage earningsPool = transcoders[del.delegateAddress].earningsPoolPerRound[i];

                if (earningsPool.hasClaimableShares()) {
                    bool isTranscoder = _delegator == del.delegateAddress;

                    var (fees, rewards) = earningsPool.claimShare(currentBondedAmount, isTranscoder);

                    currentFees = currentFees.add(fees);
                    currentBondedAmount = currentBondedAmount.add(rewards);
                }
            }

            // Rewards are bonded by default
            del.bondedAmount = currentBondedAmount;
            del.fees = currentFees;
        }

        del.lastClaimRound = _endRound;
    }

    /**
     * @dev Return LivepeerToken interface
     */
    function livepeerToken() internal view returns (ILivepeerToken) {
        return ILivepeerToken(controller.getContract(keccak256("LivepeerToken")));
    }

    /**
     * @dev Return Minter interface
     */
    function minter() internal view returns (IMinter) {
        return IMinter(controller.getContract(keccak256("Minter")));
    }

    /**
     * @dev Return RoundsManager interface
     */
    function roundsManager() internal view returns (IRoundsManager) {
        return IRoundsManager(controller.getContract(keccak256("RoundsManager")));
    }
}