// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity 0.6.12;

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity 0.6.12;

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
    constructor() internal {
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
}

pragma solidity 0.6.12;

contract BettingPrediction is Ownable {
    using SafeMath for uint256;

    struct Bet {
        uint256 totalAmount;
        uint256 outcomeAAmount;
        uint256 outcomeBAmount;
        uint256 outcomeCAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        int256 eventOutcome;
    }

    enum Position { OutcomeA, OutcomeB, OutcomeC }
    
    struct BetInfo {
        Position position;
        uint256 amount;
        bool claimed;
    }
    
    address public factory;
    mapping(uint256 => Bet) public bets;
    mapping(uint256 => mapping(address => BetInfo)) public ledger;

    uint256 public eventId;
    string public category;
    string public eventName;
    string public eventCategory;
    
    address public operatorAddress=0x2486c562F0B41af2e28d899855980666390C92b2; // 0xd3C1C1c23d9E689832C586D62Bb64620A3D7574f;
    uint256 public treasuryAmount;

    uint256 public constant TOTAL_RATE = 100;     // 100%
    uint256 public rewardRate = 90;        // 90%
    uint256 public treasuryRate = 10;       // 10%
    uint256 public minBetAmount = 10000000000000000;
    int256 public outcomeNumber = 2;
    bool public isBettingLive = false;
    bool public eventFinished = false;

    string public positionAName;
    string public positionBName;
    string public positionCName;

    string public matchStartTime;

    event BetOutcomeA(address indexed sender, uint256 amount);
    event BetOutcomeB(address indexed sender, uint256 amount);
    event BetOutcomeC(address indexed sender, uint256 amount);
    event Claim(address indexed sender, uint256 amount);
    event ClaimTreasury(uint256 amount);
    event RatesUpdated(uint256 rewardRate, uint256 treasuryRate);
    event MinBetAmountUpdated(uint256 minBetAmount);
    event IsBettingLive(bool isBettingLive);
    event IsEventFinished(bool eventFinished);
    event RewardsCalculated(
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount,
        uint256 treasuryAmount
    );
    event ResultReported(uint256 eventId, int256 eventOutcome);
    event OperatorUpdated(address indexed newOperator);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(
        uint256 _eventId,
        string memory _eventName,
        string memory _eventCategory,
        string memory _category
    ) external {
        require(msg.sender == factory, 'TendieBetting: FORBIDDEN'); // sufficient check

        eventId       = _eventId;
        category      = _category;
        eventCategory = _eventCategory;
        eventName     = _eventName;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "operator: wut?");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    /**
     * @dev check if customer able to enter the position
     * callable by operator
     */
    // account address
    function ableToBet(address addr) external view returns (bool) {
        return (ledger[eventId][addr].amount == 0);
    }

    /**
     * @dev set betting properties
     * callable by operator
     */
    function setBettingProperties(
        int256 _outcomeNumber,
        string memory _positionAName,
        string memory _positionBName,
        string memory _positionCName,
        string memory _matchStartTime
    ) external onlyOperator{
        require(_outcomeNumber >= 2 && _outcomeNumber <=3, 'The number of outcome is not valid');

        positionAName = _positionAName;
        positionBName = _positionBName;
        positionCName = _positionCName;        
        matchStartTime = _matchStartTime;
        outcomeNumber = _outcomeNumber;
    }

    function claimAmount(address addr) external view returns (uint256) {
        if(ledger[eventId][addr].claimed) return 0;
        if(bets[eventId].rewardBaseCalAmount == 0) return 0;

        if((bets[eventId].eventOutcome == 1 && ledger[eventId][addr].position == Position.OutcomeA) ||
            (bets[eventId].eventOutcome == 2 && ledger[eventId][addr].position == Position.OutcomeB) ||
            (bets[eventId].eventOutcome == 3 && ledger[eventId][addr].position == Position.OutcomeC)
        ) {
            return ledger[eventId][addr].amount.mul(bets[eventId].rewardAmount).div(bets[eventId].rewardBaseCalAmount);
        } else return 0;
    }

    /**
     * @dev set operator address
     * callable by operator
     */
    function setOperator(address _operatorAddress) external onlyOperator {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;

        emit OperatorUpdated(operatorAddress);
    }

    /**
     * @dev set reward rate
     * callable by operator
     */
    function setRewardRate(uint256 _rewardRate) external onlyOperator {
        require(_rewardRate <= TOTAL_RATE, "rewardRate cannot be more than 100%");
        rewardRate = _rewardRate;
        treasuryRate = TOTAL_RATE.sub(_rewardRate);

        emit RatesUpdated(rewardRate, treasuryRate);
    }

    /**
     * @dev set treasury rate
     * callable by operator
     */
    function setTreasuryRate(uint256 _treasuryRate) external onlyOperator {
        require(_treasuryRate <= TOTAL_RATE, "treasuryRate cannot be more than 100%");
        rewardRate = TOTAL_RATE.sub(_treasuryRate);
        treasuryRate = _treasuryRate;

        emit RatesUpdated(rewardRate, treasuryRate);
    }
    
    /**
     * @dev set minBetAmount
     * callable by operator
     */
    function setMinBetAmount(uint256 _minBetAmount) external onlyOperator {
        minBetAmount = _minBetAmount;

        emit MinBetAmountUpdated(minBetAmount);
    }

    /**
     * @dev set isBettingLive
     * callable by operator
     */
    function setIsBettingLive(bool _isBettingLive) external onlyOperator {
        isBettingLive = _isBettingLive;

        emit IsBettingLive(isBettingLive);
    }
    
    function betOutcomeA() external payable notContract {
        require(isBettingLive == true, "Betting is not open");
        require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");
        require(ledger[eventId][msg.sender].amount == 0, "You have already bet on this contract.");

        // Update bet data
        uint256 amount = msg.value;
        Bet storage bet = bets[eventId];
        bet.totalAmount = bet.totalAmount.add(amount);
        bet.outcomeAAmount = bet.outcomeAAmount.add(amount);

        // Update user data
        BetInfo storage betInfo = ledger[eventId][msg.sender];
        betInfo.position = Position.OutcomeA;
        betInfo.amount = amount;

        emit BetOutcomeA(msg.sender, betInfo.amount);
    }

    function betOutcomeB() external payable notContract {
        require(isBettingLive == true, "Betting is not open");
        require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");
        require(ledger[eventId][msg.sender].amount == 0, "You have already bet on this contract.");

        // Update bet data
        uint256 amount = msg.value;
        Bet storage bet = bets[eventId];
        bet.totalAmount = bet.totalAmount.add(amount);
        bet.outcomeBAmount = bet.outcomeBAmount.add(amount);

        // Update user data
        BetInfo storage betInfo = ledger[eventId][msg.sender];
        betInfo.position = Position.OutcomeB;
        betInfo.amount = amount;

        emit BetOutcomeB(msg.sender, amount);
    }

    function betOutcomeC() external payable notContract {
        require(outcomeNumber == 3, 'You cannot be able to bet on this outcome');
        require(isBettingLive == true, "Betting is not open");
        require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");
        require(ledger[eventId][msg.sender].amount == 0, "You have already bet on this contract.");

        // Update bet data
        uint256 amount = msg.value;
        Bet storage bet = bets[eventId];
        bet.totalAmount = bet.totalAmount.add(amount);
        bet.outcomeCAmount = bet.outcomeCAmount.add(amount);

        // Update user data
        BetInfo storage betInfo = ledger[eventId][msg.sender];
        betInfo.position = Position.OutcomeC;
        betInfo.amount = amount;

        emit BetOutcomeC(msg.sender, amount);
    }

    /**
     * @dev Claim reward
     */
    function claim() external notContract {
        require(eventFinished == true, "fight not finished yet");
        require(!ledger[eventId][msg.sender].claimed, "Rewards claimed");
        require(ledger[eventId][msg.sender].amount > 0, "You are not able to claim");
        
        Bet memory bet = bets[eventId];
        require((bet.eventOutcome == 1 && ledger[eventId][msg.sender].position == Position.OutcomeA) ||
            (bet.eventOutcome == 2 && ledger[eventId][msg.sender].position == Position.OutcomeB) ||
            (bet.eventOutcome == 3 && ledger[eventId][msg.sender].position == Position.OutcomeC), "You are not able to claim"
        );
        
        uint256 reward;
        reward = ledger[eventId][msg.sender].amount.mul(bet.rewardAmount).div(bet.rewardBaseCalAmount);

        BetInfo storage betInfo = ledger[eventId][msg.sender];
        betInfo.claimed = true;
        _safeTransferBNB(address(msg.sender), reward);

        emit Claim(msg.sender, reward);
    }

    /**
     * @dev Claim all rewards in treasury
     */
    function claimTreasury() external onlyOperator {
        require(treasuryAmount > 0, "You are not able to claim");
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        _safeTransferBNB(operatorAddress, currentTreasuryAmount);

        emit ClaimTreasury(currentTreasuryAmount);
    }

    /**
     * @dev Calculate rewards for event
     */
    function _calculateRewards() internal {
        require(rewardRate.add(treasuryRate) == TOTAL_RATE, "rewardRate and treasuryRate must add up to TOTAL_RATE");
        Bet storage bet = bets[eventId];
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        uint256 treasuryAmt;

        // OutcomeA wins
        if (bet.eventOutcome == 1) {
            rewardBaseCalAmount = bet.outcomeAAmount;
            rewardAmount = bet.totalAmount.mul(rewardRate).div(TOTAL_RATE);
            treasuryAmt = bet.totalAmount.mul(treasuryRate).div(TOTAL_RATE);
        }
        // OutcomeB wins
        else if (bet.eventOutcome == 2) {
            rewardBaseCalAmount = bet.outcomeBAmount;
            rewardAmount = bet.totalAmount.mul(rewardRate).div(TOTAL_RATE);
            treasuryAmt = bet.totalAmount.mul(treasuryRate).div(TOTAL_RATE);
        }
        // OutcomeC
        else if (bet.eventOutcome == 3) {
            rewardBaseCalAmount = bet.outcomeCAmount;
            rewardAmount = bet.totalAmount.mul(rewardRate).div(TOTAL_RATE);
            treasuryAmt = bet.totalAmount.mul(treasuryRate).div(TOTAL_RATE);
        }
        bet.rewardBaseCalAmount = rewardBaseCalAmount;
        bet.rewardAmount = rewardAmount;

        // Add to treasury
        treasuryAmount = treasuryAmount.add(treasuryAmt);

        emit RewardsCalculated(rewardBaseCalAmount, rewardAmount, treasuryAmt);
    }

    function _safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{gas: 23000, value: value}("");
        require(success, "TransferHelper: BNB_TRANSFER_FAILED");
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function reportOutcome(int256 _outcomeId) external onlyOperator {
        require(isBettingLive == false, 'Betting is still in live.');
        require(_outcomeId > 0, 'OutcomeId can not be less than zero');
        require(_outcomeId <= outcomeNumber, 'OutcomeId can not be bigger than 3');

        Bet storage bet = bets[eventId];
        bet.eventOutcome = _outcomeId;
        eventFinished = true;
        _calculateRewards();

        emit ResultReported(eventId, bet.eventOutcome);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./BettingPrediction.sol";
import "./IBettingPrediction.sol";


contract Factory{
    
    address public owner;
    address[] public allContracts;
    // top level category
    string[] public allCategories;
    mapping(address=>uint256) public getBettingContract;
    mapping(uint256=>bool)public isUsed;
    mapping(string=>bool) public isCategoryUsed;
    
    event bettingContractCreated(address indexed bettingAddress,uint256 eventId, string eventName, string eventCategory, string _category);
    event OwnerTransfered(address indexed ownerAddress);
    event CategoryCreated(string _categoryName);

    constructor (
        address _owner
    ) public {
        owner = _owner;
    }
    
    // create the parent category in top-level
    function createCategory(
        string memory _categoryName
    ) external {
        require(owner == msg.sender, "You are not right to create a category");
        require(isCategoryUsed[_categoryName] == false, "This category has been already created");
        
        allCategories.push(_categoryName);
        isCategoryUsed[_categoryName] = true;
        
        emit CategoryCreated(_categoryName);
    }

    // create the subcategory and event contract
    function createBettingContract(
        string memory _eventName,
        string memory _eventCategory, // sub category
        string memory _category // top-level category
    ) external returns (address pair) {
        require(owner == msg.sender, "You are not right to create a betting contract");
        require(isCategoryUsed[_category] == true, "This category has not been registered");

        uint256 eventId= allContracts.length;
        require(isUsed[eventId]==false);

        bytes memory bytecode = type(BettingPrediction).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(eventId, _eventName, _eventCategory, _category));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IBettingPrediction(pair).initialize(eventId, _eventName, _eventCategory, _category);
        
        getBettingContract[pair]= eventId;
        allContracts.push(pair);
        
        emit bettingContractCreated(pair, eventId, _eventName, _eventCategory, _category);
    }

    function getCategoriesLength()public view returns(uint256){
        return allCategories.length;
    }
    
    function getAllContractsLength()public view returns(uint256){
        return allContracts.length;
    }

     function transferOwnerShip(address _owner) external {
        require(owner == msg.sender, "You are not right to transfer ownership");
        owner = _owner;

        emit OwnerTransfered(owner);
     }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IBettingPrediction{
    function initialize(
        uint256 _eventId,
        string memory _eventName,
        string memory _eventCategory,
        string memory _category
    ) external ;
}

