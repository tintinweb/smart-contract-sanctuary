/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


/*

      ___           ___           ___           ___           ___       ___                    ___           ___           ___                       ___     
     /\  \         /\  \         /\__\         /\  \         /\__\     /\  \                  /\  \         /\  \         /\__\          ___        /\  \    
    /::\  \       /::\  \       /::|  |       /::\  \       /:/  /    /::\  \                /::\  \       /::\  \       /::|  |        /\  \      /::\  \   
   /:/\:\  \     /:/\:\  \     /:|:|  |      /:/\:\  \     /:/  /    /:/\:\  \              /:/\:\  \     /:/\:\  \     /:|:|  |        \:\  \    /:/\:\  \  
  /:/  \:\  \   /::\~\:\  \   /:/|:|  |__   /:/  \:\__\   /:/  /    /::\~\:\  \            /:/  \:\  \   /::\~\:\  \   /:/|:|  |__      /::\__\  /::\~\:\  \ 
 /:/__/ \:\__\ /:/\:\ \:\__\ /:/ |:| /\__\ /:/__/ \:|__| /:/__/    /:/\:\ \:\__\          /:/__/_\:\__\ /:/\:\ \:\__\ /:/ |:| /\__\  __/:/\/__/ /:/\:\ \:\__\
 \:\  \  \/__/ \/__\:\/:/  / \/__|:|/:/  / \:\  \ /:/  / \:\  \    \:\~\:\ \/__/          \:\  /\ \/__/ \:\~\:\ \/__/ \/__|:|/:/  / /\/:/  /    \:\~\:\ \/__/
  \:\  \            \::/  /      |:/:/  /   \:\  /:/  /   \:\  \    \:\ \:\__\             \:\ \:\__\    \:\ \:\__\       |:/:/  /  \::/__/      \:\ \:\__\  
   \:\  \           /:/  /       |::/  /     \:\/:/  /     \:\  \    \:\ \/__/              \:\/:/  /     \:\ \/__/       |::/  /    \:\__\       \:\ \/__/  
    \:\__\         /:/  /        /:/  /       \::/__/       \:\__\    \:\__\                 \::/  /       \:\__\         /:/  /      \/__/        \:\__\    
     \/__/         \/__/         \/__/         ~~            \/__/     \/__/                  \/__/         \/__/         \/__/                     \/__/  
     
                                                                              
                                                                              V2
                                                                              
                                                                   https://candlegenie.live


*/


// SAFEMATH
library SafeMath 
{

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }


    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

//CONTEXT
abstract contract Context 
{
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

//OWNABLE
abstract contract Ownable is Context 
{
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function OwnershipRenounce() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function OwnershipTransfer(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//PAUSABLE
abstract contract Pausable is Context 
{

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() internal {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }


    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }


    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

//INTERFACE
interface AggregatorV3Interface 
{
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

//CANDLE GENIE
contract CandleGenieV2 is Ownable, Pausable {
    using SafeMath for uint256;

    struct Round {
        uint256 epoch;
        uint256 startBlock;
        uint256 lockBlock;
        uint256 endBlock;
        int256 lockPrice;
        int256 closePrice;
        uint256 totalAmount;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        bool oracleCalled;
        bool cancelled;
    }

    enum Position {Bull, Bear}

    struct BetInfo {
        Position position;
        uint256 amount;
        bool claimed; // default false
    }
    
    mapping(uint256 => Round) public rounds;
    mapping(uint256 => mapping(address => BetInfo)) public bet;
    mapping(address => uint256[]) public bets;
    mapping(address=>bool) internal blacklist;
        
    uint256 public currentEpoch;
    uint256 public currentEpochStart;
    uint256 public currentEpochLock;
    uint256 public currentEpochEnd;
    uint256 public intervalBlocks;
    uint256 public bufferBlocks;
    address public operatorAddress;

    AggregatorV3Interface internal oracle;
    uint256 public oracleLatestRoundId;

    uint256 internal constant TOTAL_RATE = 100;
    uint256 internal rewardRate = 97; // Prize reward rate
    
    uint256 public minBetAmount;
    uint256 public oracleUpdateAllowance;

    bool public startOnce = false;
    bool public lockOnce = false;

    event StartRound(uint256 indexed epoch, uint256 blockNumber);
    event LockRound(uint256 indexed epoch, uint256 blockNumber, int256 price);
    event EndRound(uint256 indexed epoch, uint256 blockNumber, int256 price);
    event CancelRound(uint256 indexed epoch);
    event BetBull(address indexed sender, uint256 indexed currentEpoch, uint256 amount);
    event BetBear(address indexed sender, uint256 indexed currentEpoch, uint256 amount);
    event HouseBet(address indexed sender, uint256 indexed currentEpoch, uint256 bullAmount, uint256 bearAmount);
    event Claim(address indexed sender, uint256 indexed currentEpoch, uint256 amount);
    event InjectFunds(address indexed sender);
    event MinBetAmountUpdated(uint256 indexed epoch, uint256 minBetAmount);

    
    event RewardsCalculated(
        uint256 indexed epoch,
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount
    );
    
    event Pause(uint256 epoch);
    event Unpause(uint256 epoch);

    constructor(
        AggregatorV3Interface _oracle,
        address _operatorAddress,
        uint256 _intervalBlocks,
        uint256 _bufferBlocks,
        uint256 _minBetAmount,
        uint256 _oracleUpdateAllowance
    ) public {
        oracle = _oracle;
        operatorAddress = _operatorAddress;
        intervalBlocks = _intervalBlocks;
        bufferBlocks = _bufferBlocks;
        minBetAmount = _minBetAmount;
        oracleUpdateAllowance = _oracleUpdateAllowance;
    }


    modifier onlyOwnerOrOperator() 
    {
        require(msg.sender == _owner || msg.sender == operatorAddress, "Only owner or operator can call this function");
        _;
    }


    modifier notContract() 
    {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    // INTERNAL FUNCTIONS ---------------->
    
     /**
     * @dev Start round
     * Previous round n-2 must end
     */
    function _safeStartRound(uint256 epoch) internal 
    {
        require(startOnce, "Can only run after startRound is triggered");
        require(rounds[epoch - 2].endBlock != 0, "Can only start round after round n-2 has ended");
        require(block.number >= rounds[epoch - 2].endBlock, "Can only start new round after round n-2 endBlock");
        _startRound(epoch);
    }

    function _startRound(uint256 epoch) internal 
    {
        Round storage round = rounds[epoch];
        round.startBlock = block.number;
        round.lockBlock = block.number.add(intervalBlocks);
        round.endBlock = block.number.add(intervalBlocks * 2);
        round.epoch = epoch;
        round.totalAmount = 0;

        currentEpochStart = round.startBlock;
        currentEpochLock = round.lockBlock;
        currentEpochEnd = round.endBlock;
           
        emit StartRound(epoch, block.number);
    }
    
    function _cancelRound(uint256 epoch, bool oracleLock) internal 
    {
        Round storage round = rounds[epoch];
        round.cancelled = true;
        round.oracleCalled = oracleLock;
        emit CancelRound(epoch);
    }
    
    function _safeCancelRound(uint256 epoch, bool oracleLock) internal 
    {
        _cancelRound(epoch, oracleLock);
    }

    function _safeLockRound(uint256 epoch, int256 price) internal 
    {
        require(rounds[epoch].startBlock != 0, "Can only lock round after round has started");
        require(block.number >= rounds[epoch].lockBlock, "Can only lock round after lockBlock");
        require(block.number <= rounds[epoch].endBlock, "Can only lock before end block");
        
        _lockRound(epoch, price);
    }

    function _lockRound(uint256 epoch, int256 price) internal 
    {
        Round storage round = rounds[epoch];
        round.lockPrice = price;

        emit LockRound(epoch, block.number, round.lockPrice);
    }

    function _safeEndRound(uint256 epoch, int256 price) internal 
    {
        require(rounds[epoch].lockBlock != 0, "Can only end round after round has locked");
        require(block.number >= rounds[epoch].endBlock, "Can only end round after endBlock");
        _endRound(epoch, price);
    }

    function _endRound(uint256 epoch, int256 price) internal 
    {
        Round storage round = rounds[epoch];
        round.closePrice = price;
        round.oracleCalled = true;

        emit EndRound(epoch, block.number, round.closePrice);
    }

    /**
     * @dev Calculate rewards for round
     */
    function _calculateRewards(uint256 epoch) internal 
    {
        
        require(rounds[epoch].rewardBaseCalAmount == 0 && rounds[epoch].rewardAmount == 0, "Rewards calculated");
        Round storage round = rounds[epoch];
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;

        // Bull wins
        if (round.closePrice > round.lockPrice) {
            rewardBaseCalAmount = round.bullAmount;
            rewardAmount = round.totalAmount.mul(rewardRate).div(TOTAL_RATE);

        }
        // Bear wins
        else if (round.closePrice < round.lockPrice) {
            rewardBaseCalAmount = round.bearAmount;
            rewardAmount = round.totalAmount.mul(rewardRate).div(TOTAL_RATE);

        }
        // House wins
        else {
            rewardBaseCalAmount = 0;
            rewardAmount = 0;
        }
        round.rewardBaseCalAmount = rewardBaseCalAmount;
        round.rewardAmount = rewardAmount;

        emit RewardsCalculated(epoch, rewardBaseCalAmount, rewardAmount);
    }

    /**
     * @dev Get latest recorded price from oracle
     * If it falls below allowed buffer or has not updated, it would be invalid
     */
    function _getPriceFromOracle() internal returns (int256) 
    {
        uint256 leastAllowedTimestamp = block.timestamp.add(oracleUpdateAllowance);
        (uint80 roundId, int256 price, , uint256 timestamp, ) = oracle.latestRoundData();
        require(timestamp <= leastAllowedTimestamp, "Oracle update exceeded max timestamp allowance");
        oracleLatestRoundId = uint256(roundId);
        return price;
    }
    

    function _safeTransferBNB(address to, uint256 value) internal 
    {
        (bool success, ) = to.call{gas: 23000, value: value}("");
        require(success, "Transfer Failed");
    }
    

    function _isContract(address addr) internal view returns (bool) 
    {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /**
     * @dev Determine if a round is valid for receiving bets
     * Round must have started and locked
     * Current block must be within startBlock and endBlock
     */
    function _bettable(uint256 epoch) internal view returns (bool) 
    {
        return
            rounds[epoch].startBlock != 0 &&
            rounds[epoch].lockBlock != 0 &&
            block.number > rounds[epoch].startBlock &&
            block.number < rounds[epoch].lockBlock;
    }
    
    // EXTERNAL FUNCTIONS ---------------->
    

    /**
     * @dev set operator address
     * callable by owner
     */
    function owner_SetOperator(address _operatorAddress) external onlyOwner 
    {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;
    }


    /**
     * @dev Inject any given funds to contract
     * callable by owner
     */
    function owner_FundsInject() external payable onlyOwner 
    {
        emit InjectFunds(msg.sender);
    }
    
    /**
     * @dev Claim requested amounts of reserve
     * callable by owner
     */
    function owner_FundsExtract(uint256 value) external onlyOwner 
    {
        _safeTransferBNB(_owner,  value);
    }
    
     /**
     * @dev Reward any user given amount
     * callable by owner
     */
    function owner_RewardUser(address user, uint256 value) external onlyOwner 
    {
        _safeTransferBNB(user,  value);
    }
    
    /**
     * @dev Blacklist any given address
     * callable by owner
     */
    function owner_BlackListInsert(address _user) public onlyOwner {
        require(!blacklist[_user], "Address already blacklisted");
        blacklist[_user] = true;
    }
    
     /**
     * @dev Remove any given address from blacklist
     * callable by owner
     */
    function owner_BlackListRemove(address _user) public onlyOwner {
        require(blacklist[_user], "Address already whitelisted");
        blacklist[_user] = false;
    }
   
     /**
     * @dev Puts a house bet to the current round
     * callable by owner or operator
     */
    function owner_HouseBet(uint256 bullAmount, uint256 bearAmount) external onlyOwnerOrOperator whenNotPaused notContract 
    {
        require(_bettable(currentEpoch), "Round not bettable");
        require(address(this).balance >= bullAmount + bearAmount, "Contract balance must be greater than bet totals");

        // Putting Bull Bet
        if (bullAmount > 0)
        {
            // Update round data
            Round storage round = rounds[currentEpoch];
            round.totalAmount = round.totalAmount.add(bullAmount);
            round.bullAmount = round.bullAmount.add(bullAmount);
    
            // Update user data
            BetInfo storage betInfo = bet[currentEpoch][address(this)];
            betInfo.position = Position.Bull;
            betInfo.amount = bullAmount;
            bets[address(this)].push(currentEpoch);
        }

        // Putting Bear Bet
        if (bearAmount > 0)
        {
            // Update round data
            Round storage round = rounds[currentEpoch];
            round.totalAmount = round.totalAmount.add(bearAmount);
            round.bullAmount = round.bullAmount.add(bearAmount);
    
            // Update user data
            BetInfo storage betInfo = bet[currentEpoch][address(this)];
            betInfo.position = Position.Bear;
            betInfo.amount = bearAmount;
            bets[address(this)].push(currentEpoch);
        }
        
        emit HouseBet(address(this), currentEpoch, bullAmount, bearAmount);
    }
    

    /**
     * @dev called by the owner or operator to pause, triggers stopped state
     */
    function control_Pause() public onlyOwnerOrOperator whenNotPaused 
    {
        _pause();

        emit Pause(currentEpoch);
    }

    /**
     * @dev called by the owner or operator to unpause, returns to normal state
     * Reset game state. Once paused, the rounds would need to be kickstarted by resume call
     */
    function control_Resume() public onlyOwnerOrOperator whenPaused 
    {
        startOnce = false;
        lockOnce = false;
        _unpause();

        emit Unpause(currentEpoch);
    }

    /**
     * @dev Start round
     */
    function control_RoundStart() external onlyOwnerOrOperator whenNotPaused 
    {
        require(!startOnce, "Can only run startRound once");

        currentEpoch = currentEpoch + 1;
        _startRound(currentEpoch);
        startOnce = true;
    }

    /**
     * @dev Lock round
     */
    function control_RoundLock() external onlyOwnerOrOperator whenNotPaused 
    {
        require(startOnce, "Can only run after startRound is triggered");
        require(!lockOnce, "Can only run lockRound once");
    
        int256 currentPrice = _getPriceFromOracle();
        _safeLockRound(currentEpoch, currentPrice);

        currentEpoch = currentEpoch + 1;
        _startRound(currentEpoch);
        lockOnce = true;
    }
    
     /**
     * @dev Start the next round n, lock price for round n-1, end round n-2
     */
    function control_RoundExecute() external onlyOwnerOrOperator whenNotPaused 
    {
        require(
            startOnce && lockOnce,
            "Can only run after startRound and lockRound is triggered"
        );

        int256 currentPrice = _getPriceFromOracle();
        // CurrentEpoch refers to previous round (n-1)
        _safeLockRound(currentEpoch, currentPrice);
        _safeEndRound(currentEpoch - 1, currentPrice);
        _calculateRewards(currentEpoch - 1);

        // Increment currentEpoch to current round (n)
        currentEpoch = currentEpoch + 1;
        _safeStartRound(currentEpoch);
    }

    /**
     * @dev Cancel round
     */
    function control_RoundCancel(uint256 epoch, bool oracleLock) external onlyOwner 
    {
        _safeCancelRound(epoch, oracleLock);
    }


    /**
     * @dev set interval blocks
     * callable by owner
     */
    function settings_SetIntervalBlocks(uint256 _intervalBlocks) external onlyOwner 
    {
        intervalBlocks = _intervalBlocks;
    }

    /**
     * @dev set buffer blocks
     * callable by owner
     */
    function settings_setBufferBlocks(uint256 _bufferBlocks) external onlyOwner {
        require(_bufferBlocks <= intervalBlocks, "Cannot be more than intervalBlocks");
        bufferBlocks = _bufferBlocks;
    }

    /**
     * @dev set Oracle address
     * callable by owner
     */
    function settings_SetOracle(address _oracle) external onlyOwner 
    {
        require(_oracle != address(0), "Cannot be zero address");
        oracle = AggregatorV3Interface(_oracle);
    }

    /**
     * @dev set oracle update allowance
     * callable by owner
     */
    function settings_SetOracleUpdateAllowance(uint256 _oracleUpdateAllowance) external onlyOwner 
    {
        oracleUpdateAllowance = _oracleUpdateAllowance;
    }

    /**
     * @dev set reward rate
     * callable by owner
     */
    function settings_SetRewardRate(uint256 _rewardRate) external onlyOwner 
    {
        require(_rewardRate <= TOTAL_RATE, "rewardRate cannot be more than 100%");
        rewardRate = _rewardRate;
    }


    /**
     * @dev set minBetAmount
     * callable by owner
     */
    function settings_SetMinBetAmount(uint256 _minBetAmount) external onlyOwner 
    {
        minBetAmount = _minBetAmount;

        emit MinBetAmountUpdated(currentEpoch, minBetAmount);
    }


    /**
     * @dev Bet bear position
     */
    function user_BetBear() external payable whenNotPaused notContract 
    {
        require(_bettable(currentEpoch), "Round not bettable");
        require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");
        require(bet[currentEpoch][msg.sender].amount == 0, "Can only bet once per round");
        require(!blacklist[msg.sender], "Blacklisted! Are you a bot ?");
 
        // Update round data
        uint256 amount = msg.value;
        Round storage round = rounds[currentEpoch];
        round.totalAmount = round.totalAmount.add(amount);
        round.bearAmount = round.bearAmount.add(amount);

        // Update user data
        BetInfo storage betInfo = bet[currentEpoch][msg.sender];
        betInfo.position = Position.Bear;
        betInfo.amount = amount;
        bets[msg.sender].push(currentEpoch);

        emit BetBear(msg.sender, currentEpoch, amount);
    }


    /**
     * @dev Claim reward
     */
    function user_Claim(uint256 epoch) external notContract 
    {
        require(rounds[epoch].startBlock != 0, "Round has not started");
        require(block.number > rounds[epoch].endBlock, "Round has not ended");
        require(!bet[epoch][msg.sender].claimed, "Rewards claimed");
        require(!blacklist[msg.sender], "Blacklisted! Are you a bot ?");
   
        uint256 reward;
        // Round valid, claim rewards
        if (rounds[epoch].oracleCalled) {
            require(claimable(epoch, msg.sender), "Not eligible for claim");
            Round memory round = rounds[epoch];
            reward = bet[epoch][msg.sender].amount.mul(round.rewardAmount).div(round.rewardBaseCalAmount);
        }
        // Round invalid, refund bet amount
        else {
            require(refundable(epoch, msg.sender), "Not eligible for refund");
            reward = bet[epoch][msg.sender].amount;
        }

        BetInfo storage betInfo = bet[epoch][msg.sender];
        betInfo.claimed = true;
        _safeTransferBNB(address(msg.sender), reward);

        emit Claim(msg.sender, epoch, reward);
    }
    
     /**
     * @dev Bet bull position
     */
    function user_BetBull() external payable whenNotPaused notContract 
    {
        require(_bettable(currentEpoch), "Round not bettable");
        require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");
        require(bet[currentEpoch][msg.sender].amount == 0, "Can only bet once per round");
        require(!blacklist[msg.sender], "Blacklisted! Are you a bot ?");
   
        // Update round data
        uint256 amount = msg.value;
        Round storage round = rounds[currentEpoch];
        round.totalAmount = round.totalAmount.add(amount);
        round.bullAmount = round.bullAmount.add(amount);

        // Update user data
        BetInfo storage betInfo = bet[currentEpoch][msg.sender];
        betInfo.position = Position.Bull;
        betInfo.amount = amount;
        bets[msg.sender].push(currentEpoch);

        emit BetBull(msg.sender, currentEpoch, amount);
    }
    



    /**
     * @dev Return round epochs that a user has participated
     */
    function userBets(address user, uint256 cursor, uint256 size) external view returns (uint256[] memory, uint256) 
    {
        uint256 length = size;
        if (length > bets[user].length - cursor) {
            length = bets[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = bets[user][cursor + i];
        }

        return (values, cursor + length);
    }



    /**
     * @dev Get the claimable stats of specific epoch and user account
     */
    function claimable(uint256 epoch, address user) public view returns (bool) 
    {
        BetInfo memory betInfo = bet[epoch][user];
        Round memory round = rounds[epoch];
        if (round.lockPrice == round.closePrice) {
            return false;
        }
        return
            round.oracleCalled &&
            ((round.closePrice > round.lockPrice && betInfo.position == Position.Bull) ||
                (round.closePrice < round.lockPrice && betInfo.position == Position.Bear));
    }
    
    
    /**
     * @dev Get current block number
     */
    function currentBlock() public view returns (uint256) 
    {
        return block.number;
    }
    
    
    /**
     * @dev Check latest oracle round update
     */
    function oracleUpdateLock() public view returns (bool)
    {
        (uint80 roundId, , , , ) = oracle.latestRoundData();
        return roundId > oracleLatestRoundId;
    }
    

    /**
     * @dev Get the refundable stats of specific epoch and user account
     */
    function refundable(uint256 epoch, address user) public view returns (bool) 
    {
        BetInfo memory betInfo = bet[epoch][user];
        Round memory round = rounds[epoch];
        return !round.oracleCalled && block.number > round.endBlock.add(bufferBlocks) && betInfo.amount != 0;
    }

   
}