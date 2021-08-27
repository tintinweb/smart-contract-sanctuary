/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


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
     
                                                                              
                                                                          PREDICTION V2
                                                                              
                                                                   https://candlegenie.live


*/


//CONTEXT
abstract contract Context 
{
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

// REENTRANCY GUARD
abstract contract ReentrancyGuard 
{
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

//ORACLE AGGREGATOR INTERFACE
interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description()external view returns (string memory);
  function version() external view returns (uint256);
  function getRoundData( uint80 _roundId) external view returns ( uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
  function latestRoundData() external view returns ( uint80 roundId,int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

}

//OWNABLE
abstract contract Ownable is Context 
{
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() { address msgSender = _msgSender();
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

    constructor() {
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


//PREDICTIONS
contract CandleGeniePredictionV2 is Ownable, Pausable, ReentrancyGuard 
{

    struct Round 
    {
        uint256 epoch;
        uint256 startTimestamp;
        uint256 lockTimestamp;
        uint256 closeTimestamp;
        int256 lockPrice;
        int256 closePrice;
        uint256 lockOracleId;
        uint256 closeOracleId;
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
    
    mapping(uint256 => Round) public Rounds;
    mapping(uint256 => mapping(address => BetInfo)) public Bets;
    mapping(address => uint256[]) public UserBets;
    mapping(address=>bool) internal Blacklist;
        
    uint256 public currentEpoch;
    uint256 public currentEpochStart;
    uint256 public currentEpochLock;
    uint256 public currentEpochClose;
    uint256 public intervalSeconds;
    uint256 public bufferSeconds;
    address public operatorAddress;

    AggregatorV3Interface public oracle;
    uint256 public oracleLatestRoundId;

    uint256 public rewardRate = 97; // Prize reward rate
    uint256 constant internal minimumRewardRate = 90; // Minimum reward rate 90%
       
    uint256 public minBetAmount;
    uint256 public oracleUpdateAllowance;

    bool public startOnce = false;
    bool public lockOnce = false;

    event BetBear(address indexed sender, uint256 indexed epoch, uint256 amount);
    event BetBull(address indexed sender, uint256 indexed epoch, uint256 amount);
    event HouseBet(address indexed sender, uint256 indexed epoch, uint256 bullAmount, uint256 bearAmount);
    event Claim(address indexed sender, uint256 indexed epoch, uint256 amount);
    event EndRound(uint256 indexed epoch, uint256 indexed roundId, int256 price);
    event LockRound(uint256 indexed epoch, uint256 indexed roundId, int256 price);

    event StartRound(uint256 indexed epoch);
    event CancelRound(uint256 indexed epoch);
    event Pause(uint256 indexed epoch);
    event Unpause(uint256 indexed epoch);
          

    event InjectFunds(address indexed sender);
    event MinBetAmountUpdated(uint256 indexed epoch, uint256 minBetAmount);
    event BufferAndIntervalSecondsUpdated(uint256 bufferSeconds, uint256 intervalSeconds);
    event NewOracle(address oracle);
    
    event RewardsCalculated(
        uint256 indexed epoch,
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount
    );


    constructor(
        AggregatorV3Interface _oracle,
        address _operatorAddress,
        uint256 _intervalSeconds,
        uint256 _bufferSeconds,
        uint256 _minBetAmount,
        uint256 _oracleUpdateAllowance
    ) {
        oracle = _oracle;
        operatorAddress = _operatorAddress;
        intervalSeconds = _intervalSeconds;
        bufferSeconds = _bufferSeconds;
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
    

    function _safeStartRound(uint256 epoch) internal 
    {
        require(startOnce, "Can only run after startRound is triggered");
        require(Rounds[epoch - 2].closeTimestamp != 0, "Can only start round after round n-2 has ended");
        require(block.number >= Rounds[epoch - 2].closeTimestamp, "Can only start new round after round n-2 endBlock");
        _startRound(epoch);
    }

    function _startRound(uint256 epoch) internal 
    {

        Round storage round = Rounds[epoch];
        round.startTimestamp = block.timestamp;
        round.lockTimestamp = block.timestamp + intervalSeconds;
        round.closeTimestamp = block.timestamp + (2 * intervalSeconds);
        round.epoch = epoch;

        currentEpochStart = round.startTimestamp;
        currentEpochLock = round.lockTimestamp;
        currentEpochClose = round.closeTimestamp;
           
        emit StartRound(epoch);
    }

    function _safeCancelRound(uint256 epoch, bool cancelled, bool oracleLock) internal 
    {
        Round storage round = Rounds[epoch];
        round.cancelled = cancelled;
        round.oracleCalled = oracleLock;
        emit CancelRound(epoch);
    }

    function _safeLockRound(uint256 epoch, uint256 roundId, int256 price) internal 
    {
        require(Rounds[epoch].startTimestamp != 0, "Can only lock round after round has started");
        require(block.number >= Rounds[epoch].lockTimestamp, "Can only lock round after lockBlock");
        require(block.number <= Rounds[epoch].closeTimestamp, "Can only lock before end block");
        
        Round storage round = Rounds[epoch];
        round.closeTimestamp = block.timestamp + intervalSeconds;
        round.lockPrice = price;
        round.lockOracleId = roundId;

        emit LockRound(epoch, roundId, round.lockPrice);
    }


    function _safeEndRound(uint256 epoch, uint256 roundId, int256 price) internal 
    {
        require(Rounds[epoch].lockTimestamp != 0, "Can only end round after round has locked");
        require(block.timestamp >= Rounds[epoch].closeTimestamp, "Can only end round after closeTimestamp");
        require( block.timestamp <= Rounds[epoch].closeTimestamp + bufferSeconds, "Can only end round within bufferSeconds");
        Round storage round = Rounds[epoch];
        round.closePrice = price;
        round.closeOracleId = roundId;
        round.oracleCalled = true;

        emit EndRound(epoch, roundId, round.closePrice);
    }

    function _calculateRewards(uint256 epoch) internal 
    {
        
        require(Rounds[epoch].rewardBaseCalAmount == 0 && Rounds[epoch].rewardAmount == 0, "Rewards calculated");
        Round storage round = Rounds[epoch];
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;

        uint256 totalAmount = round.bullAmount + round.bearAmount;
        
        // Bull wins
        if (round.closePrice > round.lockPrice) 
        {
            rewardBaseCalAmount = round.bullAmount;
            rewardAmount = totalAmount * (rewardRate * 10) / 10000;
        }
        // Bear wins
        else if (round.closePrice < round.lockPrice) 
        {
            rewardBaseCalAmount = round.bearAmount;
            rewardAmount = totalAmount * (rewardRate * 10) / 10000;

        }
        // House wins
        else 
        {
            rewardBaseCalAmount = 0;
            rewardAmount = 0;
        }
        round.rewardBaseCalAmount = rewardBaseCalAmount;
        round.rewardAmount = rewardAmount;

        emit RewardsCalculated(epoch, rewardBaseCalAmount, rewardAmount);
    }


    function _getPriceFromOracle() internal view returns (uint80, int256) {
        uint256 leastAllowedTimestamp = block.timestamp + oracleUpdateAllowance;
        (uint80 roundId, int256 price, , uint256 timestamp, ) = oracle.latestRoundData();
        require(timestamp <= leastAllowedTimestamp, "Oracle update exceeded max timestamp allowance");
        require(uint256(roundId) > oracleLatestRoundId, "Oracle update roundId must be larger than oracleLatestRoundId");
        return (roundId, price);
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

    function _bettable(uint256 epoch) internal view returns (bool) 
    {
        return
            Rounds[epoch].startTimestamp != 0 &&
            Rounds[epoch].lockTimestamp != 0 &&
            block.timestamp > Rounds[epoch].startTimestamp &&
            block.timestamp < Rounds[epoch].lockTimestamp;
    }
    
    // EXTERNAL FUNCTIONS ---------------->
    
    function owner_SetOperator(address _operatorAddress) external onlyOwner 
    {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;
    }

    function owner_FundsInject() external payable onlyOwner 
    {
        emit InjectFunds(msg.sender);
    }
    
    function owner_FundsExtract(uint256 value) external onlyOwner 
    {
        _safeTransferBNB(_owner,  value);
    }
    
    function owner_RewardUser(address user, uint256 value) external onlyOwner 
    {
        _safeTransferBNB(user,  value);
    }
    
    function owner_BlackListInsert(address _user) public onlyOwner {
        require(!Blacklist[_user], "Address already blacklisted");
        Blacklist[_user] = true;
    }
    
    function owner_BlackListRemove(address _user) public onlyOwner {
        require(Blacklist[_user], "Address already whitelisted");
        Blacklist[_user] = false;
    }
   
    function owner_HouseBet(uint256 bullAmount, uint256 bearAmount) external onlyOwnerOrOperator whenNotPaused notContract 
    {
        require(_bettable(currentEpoch), "Round not bettable");
        require(address(this).balance >= bullAmount + bearAmount, "Contract balance must be greater than house bet totals");

        // Putting Bull Bet
        if (bullAmount > 0)
        {
            // Update round data
            Round storage round = Rounds[currentEpoch];
            round.bullAmount += bullAmount;
    
            // Update user data
            BetInfo storage betInfo = Bets[currentEpoch][address(this)];
            betInfo.position = Position.Bull;
            betInfo.amount = bullAmount;
            UserBets[address(this)].push(currentEpoch);
        }

        // Putting Bear Bet
        if (bearAmount > 0)
        {
            // Update round data
            Round storage round = Rounds[currentEpoch];
            round.bearAmount += bearAmount;
    
            // Update user data
            BetInfo storage betInfo = Bets[currentEpoch][address(this)];
            betInfo.position = Position.Bear;
            betInfo.amount = bearAmount;
            UserBets[address(this)].push(currentEpoch);
        }
        
        emit HouseBet(address(this), currentEpoch, bullAmount, bearAmount);
    }
    

    function control_Pause() public onlyOwnerOrOperator whenNotPaused 
    {
        _pause();

        emit Pause(currentEpoch);
    }

    function control_Resume() public onlyOwnerOrOperator whenPaused 
    {
        startOnce = false;
        lockOnce = false;
        _unpause();

        emit Unpause(currentEpoch);
    }

    function control_RoundStart() external onlyOwnerOrOperator whenNotPaused 
    {
        require(!startOnce, "Can only run startRound once");

        currentEpoch = currentEpoch + 1;
        _startRound(currentEpoch);
        startOnce = true;
    }


    function control_RoundLock() external onlyOwnerOrOperator whenNotPaused 
    {
        require(startOnce, "Can only run after startRound is triggered");
        require(!lockOnce, "Can only run lockRound once");

        (uint80 currentRoundId, int256 currentPrice) = _getPriceFromOracle();

        oracleLatestRoundId = uint256(currentRoundId);

        _safeLockRound(currentEpoch, currentRoundId, currentPrice);

        currentEpoch = currentEpoch + 1;
        _startRound(currentEpoch);
        lockOnce = true;
        
    }
    
    function control_RoundExecute() external onlyOwnerOrOperator whenNotPaused 
    {
        require(startOnce && lockOnce,"Can only run after startRound and lockRound is triggered");

        (uint80 currentRoundId, int256 currentPrice) = _getPriceFromOracle();

        oracleLatestRoundId = uint256(currentRoundId);

        // CurrentEpoch refers to previous round (n-1)
        _safeLockRound(currentEpoch, currentRoundId, currentPrice);
        _safeEndRound(currentEpoch - 1, currentRoundId, currentPrice);
        _calculateRewards(currentEpoch - 1);

        // Increment currentEpoch to current round (n)
        currentEpoch = currentEpoch + 1;
        _safeStartRound(currentEpoch);
    }


    function control_RoundCancel(uint256 epoch,bool cancelled, bool oracleLock) external onlyOwner 
    {
        _safeCancelRound(epoch, cancelled, oracleLock);
    }


    function setBufferAndIntervalSeconds(uint256 _bufferSeconds, uint256 _intervalSeconds) external onlyOwner
    {
        require(_bufferSeconds < _intervalSeconds, "BufferSeconds must be inferior to intervalSeconds");
        bufferSeconds = _bufferSeconds;
        intervalSeconds = _intervalSeconds;
        emit BufferAndIntervalSecondsUpdated(_bufferSeconds, _intervalSeconds);
    }

    function settings_SetOracle(address _oracle) external onlyOwner 
    {
        require(_oracle != address(0), "Cannot be zero address");
        
        oracleLatestRoundId = 0;
        oracle = AggregatorV3Interface(_oracle);
        oracle.latestRoundData();
        emit NewOracle(_oracle);
    }


    function settings_SetOracleUpdateAllowance(uint256 _oracleUpdateAllowance) external onlyOwner 
    {
        oracleUpdateAllowance = _oracleUpdateAllowance;
    }


    function settings_SetRewardRate(uint256 _rewardRate) external onlyOwner 
    {
        require(_rewardRate >= minimumRewardRate, "Reward rate can't be lower than minimum reward rate");
        rewardRate = _rewardRate;
    }


    function settings_SetMinBetAmount(uint256 _minBetAmount) external onlyOwner 
    {
        minBetAmount = _minBetAmount;

        emit MinBetAmountUpdated(currentEpoch, minBetAmount);
    }


    function user_BetBear() external payable whenNotPaused notContract 
    {
        require(_bettable(currentEpoch), "Round not bettable");
        require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");
        require(Bets[currentEpoch][msg.sender].amount == 0, "Can only bet once per round");
        require(!Blacklist[msg.sender], "Blacklisted! Are you a bot ?");
 
        // Update round data
        uint256 amount = msg.value;
        Round storage round = Rounds[currentEpoch];
        round.bearAmount += amount;

        // Update user data
        BetInfo storage betInfo = Bets[currentEpoch][msg.sender];
        betInfo.position = Position.Bear;
        betInfo.amount = amount;
        UserBets[msg.sender].push(currentEpoch);

        emit BetBear(msg.sender, currentEpoch, amount);
    }


    function user_Claim(uint256[] calldata epochs) external nonReentrant notContract 
    {
            
        uint256 reward; // Initializes reward

        for (uint256 i = 0; i < epochs.length; i++) {
            require(Rounds[epochs[i]].startTimestamp != 0, "Round has not started");
            require(block.timestamp > Rounds[epochs[i]].closeTimestamp, "Round has not ended");

            uint256 addedReward = 0;

            // Round valid, claim rewards
            if (Rounds[epochs[i]].oracleCalled) {
                require(claimable(epochs[i], msg.sender), "Not eligible for claim");
                Round memory round = Rounds[epochs[i]];
                addedReward = (Bets[epochs[i]][msg.sender].amount * round.rewardAmount) / round.rewardBaseCalAmount;
            }
            // Round invalid, refund bet amount
            else {
                require(refundable(epochs[i], msg.sender), "Not eligible for refund");
                addedReward = Bets[epochs[i]][msg.sender].amount;
            }

            Bets[epochs[i]][msg.sender].claimed = true;
            reward += addedReward;

            emit Claim(msg.sender, epochs[i], addedReward);
        }

        if (reward > 0) 
        {
            _safeTransferBNB(address(msg.sender), reward);
        }
        
    }
    

    function user_BetBull() external payable whenNotPaused notContract 
    {
        require(_bettable(currentEpoch), "Round not bettable");
        require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");
        require(Bets[currentEpoch][msg.sender].amount == 0, "Can only bet once per round");
        require(!Blacklist[msg.sender], "Blacklisted! Are you a bot ?");
   
        // Update round data
        uint256 amount = msg.value;
        Round storage round = Rounds[currentEpoch];
        round.bullAmount += amount;

        // Update user data
        BetInfo storage betInfo = Bets[currentEpoch][msg.sender];
        betInfo.position = Position.Bull;
        betInfo.amount = amount;
        UserBets[msg.sender].push(currentEpoch);

        emit BetBull(msg.sender, currentEpoch, amount);
    }
    

    function getUserRounds(address user, uint256 cursor, uint256 size) external view returns (uint256[] memory, uint256) 
    {
        uint256 length = size;
        if (length > UserBets[user].length - cursor) {
            length = UserBets[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = UserBets[user][cursor + i];
        }

        return (values, cursor + length);
    }
    
    function getUserRoundsLength(address user) external view returns (uint256) {
        return UserBets[user].length;
    }


    function claimable(uint256 epoch, address user) public view returns (bool) 
    {
        BetInfo memory betInfo = Bets[epoch][user];
        Round memory round = Rounds[epoch];
        if (round.lockPrice == round.closePrice) {
            return false;
        }
        return
            round.oracleCalled &&
            ((round.closePrice > round.lockPrice && betInfo.position == Position.Bull) ||
                (round.closePrice < round.lockPrice && betInfo.position == Position.Bear));
    }
    
    
    function currentBlockNumber() public view returns (uint256) 
    {
        return block.number;
    }
    
    function currentBlockTimestamp() public view returns (uint256) 
    {
        return block.timestamp;
    }
    
    
    function oracleUpdateLock() public view returns (bool)
    {
        (uint80 roundId, , , , ) = oracle.latestRoundData();
        return roundId > oracleLatestRoundId;
    }
    
    function refundable(uint256 epoch, address user) public view returns (bool) 
    {
        BetInfo memory betInfo = Bets[epoch][user];
        Round memory round = Rounds[epoch];
        
        return !round.oracleCalled && !betInfo.claimed && block.timestamp > round.closeTimestamp + bufferSeconds && betInfo.amount != 0;
    }

   
}