pragma solidity 0.4.18;

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

/**
 * @title RoundsManager
 * @dev Manages round progression and other blockchain time related operations of the Livepeer protocol
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

    /**
     * @dev RoundsManager constructor. Only invokes constructor of base Manager contract with provided Controller address
     * @param _controller Address of Controller that this contract will be registered with
     */
    function RoundsManager(address _controller) public Manager(_controller) {}

    /**
     * @dev Set round length. Only callable by the controller owner
     * @param _roundLength Round length in blocks
     */
    function setRoundLength(uint256 _roundLength) external onlyControllerOwner {
        // Round length cannot be 0
        require(_roundLength > 0);

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

        ParameterUpdate("roundLength");
    }

    /**
     * @dev Set round lock amount. Only callable by the controller owner
     * @param _roundLockAmount Round lock amount as a % of the number of blocks in a round
     */
    function setRoundLockAmount(uint256 _roundLockAmount) external onlyControllerOwner {
        // Must be a valid percentage
        require(MathUtils.validPerc(_roundLockAmount));

        roundLockAmount = _roundLockAmount;

        ParameterUpdate("roundLockAmount");
    }

    /**
     * @dev Initialize the current round. Called once at the start of any round
     */
    function initializeRound() external whenSystemNotPaused {
        uint256 currRound = currentRound();

        // Check if already called for the current round
        require(lastInitializedRound < currRound);

        // Set current round as initialized
        lastInitializedRound = currRound;
        // Set active transcoders for the round
        bondingManager().setActiveTranscoders();
        // Set mintable rewards for the round
        minter().setCurrentRewardTokens();

        NewRound(currRound);
    }

    /**
     * @dev Return current block number
     */
    function blockNum() public view returns (uint256) {
        return block.number;
    }

    /**
     * @dev Return blockhash for a block
     */
    function blockHash(uint256 _block) public view returns (bytes32) {
        uint256 currentBlock = blockNum();
        // Can only retrieve past block hashes
        require(_block < currentBlock);
        // Can only retrieve hashes for last 256 blocks
        require(currentBlock < 256 || _block >= currentBlock - 256);

        return block.blockhash(_block);
    }

    /**
     * @dev Return current round
     */
    function currentRound() public view returns (uint256) {
        // Compute # of rounds since roundLength was last updated
        uint256 roundsSinceUpdate = blockNum().sub(lastRoundLengthUpdateStartBlock).div(roundLength);
        // Current round = round that roundLength was last updated + # of rounds since roundLength was last updated
        return lastRoundLengthUpdateRound.add(roundsSinceUpdate);
    }

    /**
     * @dev Return start block of current round
     */
    function currentRoundStartBlock() public view returns (uint256) {
        // Compute # of rounds since roundLength was last updated
        uint256 roundsSinceUpdate = blockNum().sub(lastRoundLengthUpdateStartBlock).div(roundLength);
        // Current round start block = start block of round that roundLength was last updated + (# of rounds since roundLenght was last updated * roundLength)
        return lastRoundLengthUpdateStartBlock.add(roundsSinceUpdate.mul(roundLength));
    }

    /**
     * @dev Check if current round is initialized
     */
    function currentRoundInitialized() public view returns (bool) {
        return lastInitializedRound == currentRound();
    }

    /**
     * @dev Check if we are in the lock period of the current round
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