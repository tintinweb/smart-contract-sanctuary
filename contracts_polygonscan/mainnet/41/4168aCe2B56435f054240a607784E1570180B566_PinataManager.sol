// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IPinataPrizePool.sol";
import "../interfaces/IPinataStrategy.sol";
import "../interfaces/IPinataVault.sol";

/**
 * @dev Implementation of a manager for each pool of Pinata Finance protocol.
 * This is the contract that using to managing state, permission.
 * and also managing contract in which is part of each pool.
 */
contract PinataManager {
    using SafeMath for uint256;

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER,
        WINNERS_PENDING,
        READY
    }

    /* ========================== Variables ========================== */
    address public manager; // The current manager.
    address public pendingManager; // The address pending to become the manager once accepted.
    address public timeKeeper; // keeper of pool state.

    uint256 public openTime;
    uint256 public closingTime;
    uint256 public drawingTime;
    bool public allowCloseAnytime;
    bool public allowDrawAnytime;
    LOTTERY_STATE public lotteryState;

    // Contracts
    address public vault;
    address public strategy;
    address public prizePool;
    address public randomNumberGenerator;

    // Fee Receiver
    address public strategist; // Address of the strategy author/deployer where strategist fee will go.
    address public pinataFeeRecipient; // Address where to send pinata's fees (fund of platform).

    /* ========================== Events ========================== */

    /**
     * @dev Emitted when Pool is open ready to deposit.
     */
    event PoolOpen();

    /**
     * @dev Emitted when Pool is closed deposit will not be allowed.
     */
    event PoolClosed();

    /**
     * @dev Emitted when Pool is calculating for lucky winners.
     */
    event PoolCalculatingWinners();

    /**
     * @dev Emitted when Pool is getting numbers from Chainlink and waiting for reward distribution.
     */
    event PoolWinnersPending();

    /**
     * @dev Emitted when Pool is ready to be open.
     */
    event PoolReady();

    /**
     * @dev Emitted when address of vault is setted.
     */
    event VaultSetted(address vault);

    /**
     * @dev Emitted when address of strategy is setted.
     */
    event StrategySetted(address strategy);

    /**
     * @dev Emitted when address of prize pool is setted.
     */
    event PrizePoolSetted(address prizePool);

    /**
     * @dev Emitted when address of random number generator is setted.
     */
    event RandomNumberGeneratorSetted(address randomNumberGenerator);

    /**
     * @dev Emitted when address of strategist (dev) is setted.
     */
    event StrategistSetted(address strategist);

    /**
     * @dev Emitted when address of pinataFeeRecipient (treasury) is setted.
     */
    event PinataFeeRecipientSetted(address pinataFeeRecipient);

    /**
     * @dev Emitted when manager is setted.
     */
    event ManagerSetted(address manager);

    /**
     * @dev Emitted when pending manager is setted.
     */
    event PendingManagerSetted(address pendingManager);

    /**
     * @dev Emitted when time keeper is setted.
     */
    event TimeKeeperSetted(address timeKeeper);

    /**
     * @dev Emitted when changing allowCloseAnytime or allowDrawAnytime.
     */
    event PoolTimerSetted(bool allowCloseAnytime, bool allowDrawAnytime);
    /**

    /* ========================== Modifier ========================== */

    /**
     * @dev Modifier to make a function callable only when called by time keeper.
     *
     * Requirements:
     *
     * - The caller have to be setted as time keeper.
     */
    modifier onlyTimeKeeper() {
        require(
            msg.sender == timeKeeper,
            "PinataManager: Only Timekeeper allowed!"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when called by manager.
     *
     * Requirements:
     *
     * - The caller have to be setted as manager.
     */
    modifier onlyManager() {
        require(msg.sender == manager, "PinataManager: Only Manager allowed!");
        _;
    }

    /* ========================== Functions ========================== */

    /**
     * @dev Setting up contract's state, permission is setted to deployer as default.
     * @param _allowCloseAnytime boolean in which is pool allowed to be closed any time.
     * @param _allowDrawAnytime boolean in which is pool allowed to be able to draw rewards any time.
     */
    constructor(bool _allowCloseAnytime, bool _allowDrawAnytime) public {
        allowCloseAnytime = _allowCloseAnytime;
        allowDrawAnytime = _allowDrawAnytime;
        lotteryState = LOTTERY_STATE.READY;

        manager = msg.sender;
        pendingManager = address(0);
        vault = address(0);
        timeKeeper = msg.sender;
    }

    /**
     * @dev Start new lottery round set lottery state to open. only allow when lottery is in ready state.
     *  only allow by address setted as time keeper.
     * @param _closingTime timestamp of desired closing time.
     * @param _drawingTime timestamp of desired drawing time.
     */
    function startNewLottery(uint256 _closingTime, uint256 _drawingTime)
        public
        onlyTimeKeeper
    {
        require(
            lotteryState == LOTTERY_STATE.READY,
            "PinataManager: can't start a new lottery yet!"
        );
        drawingTime = _drawingTime;
        openTime = block.timestamp;
        closingTime = _closingTime;
        lotteryState = LOTTERY_STATE.OPEN;

        emit PoolOpen();
    }

    /**
     * @dev Closing ongoing lottery set status of pool to closed.
     *  only allow by address setted as time keeper.
     */
    function closePool() public onlyTimeKeeper {
        if (!allowCloseAnytime) {
            require(
                block.timestamp >= closingTime,
                "PinataManager: cannot be closed before closing time!"
            );
        }
        lotteryState = LOTTERY_STATE.CLOSED;

        emit PoolClosed();
    }

    /**
     * @dev Picking winners for this round calling harvest on strategy to ensure reward is updated.
     *  calling drawing number on prize pool to calculating for lucky winners.
     *  only allow by address setted as time keeper.
     */
    function calculateWinners() public onlyTimeKeeper {
        if (!allowDrawAnytime) {
            require(
                block.timestamp >= drawingTime,
                "PinataManager: cannot be calculate winners before drawing time!"
            );
        }

        IPinataStrategy(strategy).harvest();

        IPinataPrizePool(prizePool).drawNumber();
        lotteryState = LOTTERY_STATE.CALCULATING_WINNER;

        emit PoolCalculatingWinners();
    }

    /**
     * @dev Called when winners is calculated only allow to be called from prize pool.
     *  setting the lottery state winners pending since reward need to be distributed.
     * @dev process have to be seperated since Chainlink VRF only allow 200k for gas limit.
     */
    function winnersCalculated() external {
        require(
            msg.sender == prizePool,
            "PinataManager: Caller need to be PrizePool"
        );

        lotteryState = LOTTERY_STATE.WINNERS_PENDING;

        emit PoolWinnersPending();
    }

    /**
     * @dev Called when winners is calculated only allow to be called from prize pool.
     *  setting the lottery state to ready for next round.
     */
    function rewardDistributed() external {
        require(
            msg.sender == prizePool,
            "PinataManager: Caller need to be PrizePool"
        );

        lotteryState = LOTTERY_STATE.READY;

        emit PoolReady();
    }

    /* ========================== Getter Functions ========================== */

    /**
     * @dev getting current state of the pool.
     */
    function getState() public view returns (LOTTERY_STATE) {
        return lotteryState;
    }

    /**
     * @dev getting timeline of current round setted when new lottery started.
     */
    function getTimeline()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (openTime, closingTime, drawingTime);
    }

    /**
     * @dev get address of vault setted.
     */
    function getVault() external view returns (address) {
        return vault;
    }

    /**
     * @dev get address of strategy setted.
     */
    function getStrategy() external view returns (address) {
        return strategy;
    }

    /**
     * @dev get address of prize pool setted.
     */
    function getPrizePool() external view returns (address) {
        return prizePool;
    }

    /**
     * @dev get address of random number generator setted.
     */
    function getRandomNumberGenerator() external view returns (address) {
        return randomNumberGenerator;
    }

    /**
     * @dev get address of strategist (dev) setted.
     */
    function getStrategist() external view returns (address) {
        return strategist;
    }

    /**
     * @dev get address of pinata fee recipient (treasury) setted.
     */
    function getPinataFeeRecipient() external view returns (address) {
        return pinataFeeRecipient;
    }

    /**
     * @dev get manager status of address provided.
     * @param _manager is address want to know status of.
     */
    function getIsManager(address _manager) external view returns (bool) {
        return _manager == manager;
    }

    /**
     * @dev get timekeeper status of address provided.
     * @param _timeKeeper is address want to know status of.
     */
    function getIsTimekeeper(address _timeKeeper) external view returns (bool) {
        return _timeKeeper == timeKeeper;
    }

    /* ========================== Admin Setter Functions ========================== */

    /**
     * @dev setting address of vault.
     * @param _vault is address of vault.
     */
    function setVault(address _vault) external onlyManager {
        require(vault == address(0), "PinataManager: Vault already set!");
        vault = _vault;

        emit VaultSetted(vault);
    }

    /**
     * @dev setting address of strategy. perform retireStrat operation to withdraw the fund from
     *  old strategy to new strategy.
     * @param _strategy is address of strategy.
     */
    function setStrategy(address _strategy) external onlyManager {
        if (strategy != address(0)) {
            IPinataStrategy(strategy).retireStrat();
        }
        strategy = _strategy;

        IPinataVault(vault).earn();

        emit StrategySetted(strategy);
    }

    /**
     * @dev setting address of prize pool. perform retirePrizePool operation to withdraw the fund from
     *  old prizePool to vault. but the allocated reward is remain in the old prize pool.
     *  participant will have to withdraw and deposit again to participate in new prize pool.
     * @param _prizePool is address of new prize pool.
     */
    function setPrizePool(address _prizePool) external onlyManager {
        require(
            lotteryState == LOTTERY_STATE.READY,
            "PinataManager: only allow to set prize pool in ready state!"
        );
        if (prizePool != address(0)) {
            IPinataPrizePool(prizePool).retirePrizePool();
        }
        prizePool = _prizePool;

        emit PrizePoolSetted(prizePool);
    }

    /**
     * @dev setting address of random number generator.
     * @param _randomNumberGenerator is address of random number generator.
     */
    function setRandomNumberGenerator(address _randomNumberGenerator)
        external
        onlyManager
    {
        randomNumberGenerator = _randomNumberGenerator;

        emit RandomNumberGeneratorSetted(randomNumberGenerator);
    }

    /**
     * @dev setting address of strategist.
     * @param _strategist is address of strategist.
     */
    function setStrategist(address _strategist) external onlyManager {
        strategist = _strategist;

        emit StrategistSetted(strategist);
    }

    /**
     * @dev setting address of pinataFeeRecipient.
     * @param _pinataFeeRecipient is address of pinataFeeRecipient.
     */
    function setPinataFeeRecipient(address _pinataFeeRecipient)
        external
        onlyManager
    {
        pinataFeeRecipient = _pinataFeeRecipient;

        emit PinataFeeRecipientSetted(pinataFeeRecipient);
    }

    /**
     * @dev Set the pending manager, which will be the manager once accepted.
     * @param _pendingManager The address to become the pending governor.
     */
    function setPendingManager(address _pendingManager) external onlyManager {
        pendingManager = _pendingManager;

        emit PendingManagerSetted(_pendingManager);
    }

    /**
     * @dev Set the pending manager, which will be the manager once accepted.
     * @param _accept is to accept role as manager or not.
     */
    function acceptManager(bool _accept) external {
        require(
            msg.sender == pendingManager,
            "PinataManager: not the pending manager"
        );
        pendingManager = address(0);
        if (_accept) {
            manager = msg.sender;

            emit ManagerSetted(msg.sender);
        }
    }

    /**
     * @dev setting status of time keeper.
     * @param _timeKeeper is address wish to changing status.
     */
    function setTimeKeeper(address _timeKeeper) external onlyManager {
        timeKeeper = _timeKeeper;

        emit TimeKeeperSetted(_timeKeeper);
    }

    /**
     * @dev setting pool to beable to close or draw anytime or only when past time setted.
     * @param _allowCloseAnytime is address wish to changing status.
     * @param _allowDrawAnytime is address wish to changing status.
     */
    function setPoolAllow(bool _allowCloseAnytime, bool _allowDrawAnytime) external onlyManager {
        allowCloseAnytime = _allowCloseAnytime;
        allowDrawAnytime = _allowDrawAnytime;

        emit PoolTimerSetted(allowCloseAnytime, allowDrawAnytime);
    }
    
    /**
     * @dev use for emergency in case state got stuck.
     *  state of the pool should progress automatically.
     *  this function is provided just in case.
     */
    function setStateToReady() external onlyManager {
        lotteryState = LOTTERY_STATE.READY;

        emit PoolReady();
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

interface IPinataPrizePool {
    struct Entry {
        address addr;
        uint256 chances;
        uint256 lastEnterId;
        uint256 lastDeposit;
        uint256 claimableReward;
    }

    struct History {
        uint256 roundId;
        uint256 rewardNumber;
        address[] winners;
        uint256 roundReward;
    }

    function addChances(address participant, uint256 _chances) external;

    function withdraw(address participant)
        external;
    
    function chancesOf(address participant) external view returns (uint256);

    function ownerOf(uint256 ticketId) external view returns (address);

    function drawNumber() external;

    function numbersDrawn(
        bytes32 requestId,
        uint256 roundId,
        uint256 randomness
    ) external;

    function claimReward(uint256 _amount) external;

    function getEntryInfo(address _entry) external view returns (Entry memory);

    function getNumOfParticipants() external view returns (uint256);

    function getHistory(uint256 _round)
        external
        view
        returns (History memory history);

    function setRandomGenerator(address randomGenerator) external;
    
    function setVault(address vault) external;

    function retirePrizePool() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPinataStrategy {
    function deposit() external;

    function withdraw(uint256 _amount) external;

    function harvest() external;

    function balanceOf() external view returns (uint256);

    function balanceOfLpWant() external view returns (uint256);

    function balanceOfPool() external view returns (uint256);

    function want() external view returns(address);

    function retireStrat() external;

    function panic() external;

    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPinataVault {
    function want() external view returns (IERC20);

    function balance() external view returns (uint256);

    function available() external view returns (uint256);

    function earn() external;

    function deposit(uint256 _amount) external;

    function withdrawAll() external;

    function getPricePerFullShare() external view returns (uint256);
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

