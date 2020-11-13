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

// File: contracts/rounds/RoundsManager.sol

pragma solidity 0.5.11;








/**
 * @title RoundsManager
 * @notice Manages round progression and other blockchain time related operations of the Livepeer protocol
 */
contract RoundsManager is ManagerProxyTarget, IRoundsManager {
    using SafeMath for uint256;

    // Round length in blocks
    uint256 public roundLength;
    // Lock period of a round as a % of round length
    // Transcoders cannot join the transcoder pool or change their rates during the lock period at the end of a round
    // The lock period provides delegators time to review transcoder information without changes
    // # of blocks in the lock period = (roundLength * roundLockAmount) / PERC_DIVISOR
    uint256 public roundLockAmount;
    // Last initialized round. After first round, this is the last round during which initializeRound() was called
    uint256 public lastInitializedRound;
    // Round in which roundLength was last updated
    uint256 public lastRoundLengthUpdateRound;
    // Start block of the round in which roundLength was last updated
    uint256 public lastRoundLengthUpdateStartBlock;

    // Mapping round number => block hash for the round
    mapping (uint256 => bytes32) internal _blockHashForRound;

    // LIP Upgrade Rounds
    // These can be used in conditionals to ensure backwards compatibility or skip such backwards compatibility logic
    // in case 'currentRound' > LIP-X upgrade round
    mapping (uint256 => uint256) public lipUpgradeRound; // mapping (LIP-number > round number)

    /**
     * @notice RoundsManager constructor. Only invokes constructor of base Manager contract with provided Controller address
     * @dev This constructor will not initialize any state variables besides `controller`. The following setter functions
     * should be used to initialize state variables post-deployment:
     * - setRoundLength()
     * - setRoundLockAmount()
     * @param _controller Address of Controller that this contract will be registered with
     */
    constructor(address _controller) public Manager(_controller) {}

    /**
     * @notice Set round length. Only callable by the controller owner
     * @param _roundLength Round length in blocks
     */
    function setRoundLength(uint256 _roundLength) external onlyControllerOwner {
        require(_roundLength > 0, "round length cannot be 0");

        if (roundLength == 0) {
            // If first time initializing roundLength, set roundLength before
            // lastRoundLengthUpdateRound and lastRoundLengthUpdateStartBlock
            roundLength = _roundLength;
            lastRoundLengthUpdateRound = currentRound();
            lastRoundLengthUpdateStartBlock = currentRoundStartBlock();
        } else {
            // If updating roundLength, set roundLength after
            // lastRoundLengthUpdateRound and lastRoundLengthUpdateStartBlock
            lastRoundLengthUpdateRound = currentRound();
            lastRoundLengthUpdateStartBlock = currentRoundStartBlock();
            roundLength = _roundLength;
        }

        emit ParameterUpdate("roundLength");
    }

    /**
     * @notice Set round lock amount. Only callable by the controller owner
     * @param _roundLockAmount Round lock amount as a % of the number of blocks in a round
     */
    function setRoundLockAmount(uint256 _roundLockAmount) external onlyControllerOwner {
        require(MathUtils.validPerc(_roundLockAmount), "round lock amount must be a valid percentage");

        roundLockAmount = _roundLockAmount;

        emit ParameterUpdate("roundLockAmount");
    }

    /**
     * @notice Initialize the current round. Called once at the start of any round
     */
    function initializeRound() external whenSystemNotPaused {
        uint256 currRound = currentRound();

        // Check if already called for the current round
        require(lastInitializedRound < currRound, "round already initialized");

        // Set current round as initialized
        lastInitializedRound = currRound;
        // Store block hash for round
        bytes32 roundBlockHash = blockHash(blockNum().sub(1));
        _blockHashForRound[currRound] = roundBlockHash;
        // Set total active stake for the round
        bondingManager().setCurrentRoundTotalActiveStake();
        // Set mintable rewards for the round
        minter().setCurrentRewardTokens();

        emit NewRound(currRound, roundBlockHash);
    }

    /**
    * @notice setLIPUpgradeRound sets the round an LIP upgrade would become active.
    * @param _lip the LIP number.
    * @param _round (optional) the round in which the LIP becomes active
    */
    function setLIPUpgradeRound(uint256 _lip, uint256 _round) external onlyControllerOwner {
        require(lipUpgradeRound[_lip] == 0, "LIP upgrade round already set");
        lipUpgradeRound[_lip] = _round;
    }

    /**
     * @notice Return current block number
     */
    function blockNum() public view returns (uint256) {
        return block.number;
    }

    /**
     * @notice Return blockhash for a block
     */
    function blockHash(uint256 _block) public view returns (bytes32) {
        uint256 currentBlock = blockNum();
        require(_block < currentBlock, "can only retrieve past block hashes");
        require(currentBlock < 256 || _block >= currentBlock - 256, "can only retrieve hashes for last 256 blocks");

        return blockhash(_block);
    }

    /**
     * @notice Return blockhash for a round
     * @param _round Round number
     * @return Blockhash for `_round`
     */
    function blockHashForRound(uint256 _round) public view returns (bytes32) {
        return _blockHashForRound[_round];
    }

    /**
     * @notice Return current round
     */
    function currentRound() public view returns (uint256) {
        // Compute # of rounds since roundLength was last updated
        uint256 roundsSinceUpdate = blockNum().sub(lastRoundLengthUpdateStartBlock).div(roundLength);
        // Current round = round that roundLength was last updated + # of rounds since roundLength was last updated
        return lastRoundLengthUpdateRound.add(roundsSinceUpdate);
    }

    /**
     * @notice Return start block of current round
     */
    function currentRoundStartBlock() public view returns (uint256) {
        // Compute # of rounds since roundLength was last updated
        uint256 roundsSinceUpdate = blockNum().sub(lastRoundLengthUpdateStartBlock).div(roundLength);
        // Current round start block = start block of round that roundLength was last updated + (# of rounds since roundLenght was last updated * roundLength)
        return lastRoundLengthUpdateStartBlock.add(roundsSinceUpdate.mul(roundLength));
    }

    /**
     * @notice Check if current round is initialized
     */
    function currentRoundInitialized() public view returns (bool) {
        return lastInitializedRound == currentRound();
    }

    /**
     * @notice Check if we are in the lock period of the current round
     */
    function currentRoundLocked() public view returns (bool) {
        uint256 lockedBlocks = MathUtils.percOf(roundLength, roundLockAmount);
        return blockNum().sub(currentRoundStartBlock()) >= roundLength.sub(lockedBlocks);
    }

    /**
     * @dev Return BondingManager interface
     */
    function bondingManager() internal view returns (IBondingManager) {
        return IBondingManager(controller.getContract(keccak256("BondingManager")));
    }

    /**
     * @dev Return Minter interface
     */
    function minter() internal view returns (IMinter) {
        return IMinter(controller.getContract(keccak256("Minter")));
    }
}