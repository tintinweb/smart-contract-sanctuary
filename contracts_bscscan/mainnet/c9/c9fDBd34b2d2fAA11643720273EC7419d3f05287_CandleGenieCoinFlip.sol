/**
 *Submitted for verification at BscScan.com on 2021-09-21
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
     
                                                                              
                                                                             COIN FLIP
                                                                              
                                                                      https://candlegenie.io


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


contract CandleGenieCoinFlip is Ownable, Pausable, ReentrancyGuard 
{

    struct Round 
    {
        uint256 epoch;
        uint256 headsAmount;
        uint256 tailsAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        uint32 startTimestamp;
        uint32 closeTimestamp;
        Position position;
        bool closed;
        bool cancelled;
    }

    enum Position {None, Heads, Tails}

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
    address public operatorAddress;


    // Defaults
    uint256 public rewardRate = 97; // Prize reward rate
    uint256 constant internal minimumRewardRate = 90; // Minimum reward rate 90%
    uint256 public intervalSeconds = 300;
    uint256 public minBetAmount = 1000000000000000;
    uint256 public bufferSeconds = 30;

    bool public startOnce = false;

    event BetHeads(address indexed sender, uint256 indexed epoch, uint256 amount);
    event BetTails(address indexed sender, uint256 indexed epoch, uint256 amount);
    event HouseBet(address indexed sender, uint256 indexed epoch, uint256 headsAmount, uint256 tailsAmount);
    event EndRound(uint256 indexed epoch, Position Position);
    event Claim(address indexed sender, uint256 indexed epoch, uint256 amount);
    
    event StartRound(uint256 indexed epoch);
    event CancelRound(uint256 indexed epoch);
    event Pause(uint256 indexed epoch);
    event Unpause(uint256 indexed epoch);
          
    event RewardsCalculated(
        uint256 indexed epoch,
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount
    );

    event InjectFunds(address indexed sender);
    event MinBetAmountUpdated(uint256 indexed epoch, uint256 minBetAmount);
    event BufferAndIntervalSecondsUpdated(uint256 bufferSeconds, uint256 intervalSeconds);
    event NewPriceSource(string priceSource);

    constructor(address _operatorAddress) 
    {
        operatorAddress = _operatorAddress;
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

        Round storage round = Rounds[epoch];
        round.startTimestamp = uint32(block.timestamp);
        round.closeTimestamp =  uint32(block.timestamp + intervalSeconds);
        round.epoch = epoch;
        round.position = Position.None;
        
        emit StartRound(epoch);
    }



    function _safeEndRound(uint256 epoch) internal 
    {
        require(Rounds[epoch].startTimestamp != 0, "Can only end round after round has started");
        require(block.timestamp >= Rounds[epoch].closeTimestamp, "Can only end round after endBlock");
        
        Round storage round = Rounds[epoch];
        
        bool coinFlipResult = flipACoin();
        Position roundPosition = coinFlipResult ? Position.Heads : Position.Tails;
        round.position = roundPosition;
        round.closed = true;
        
        emit EndRound(epoch, roundPosition);
    }
    
    
    function flipACoin() internal view returns(bool) 
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));
    
        uint256 rand = (seed - ((seed / 1000) * 1000));
        return rand < 500;
    }  


    function _calculateRewards(uint256 epoch) internal 
    {
        
        require(Rounds[epoch].rewardBaseCalAmount == 0 && Rounds[epoch].rewardAmount == 0, "Rewards calculated");
        Round storage round = Rounds[epoch];
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;

        uint256 totalAmount = round.headsAmount + round.tailsAmount;
        
        // Heads wins
        if (round.position == Position.Heads) 
        {
            rewardBaseCalAmount = round.headsAmount;
            rewardAmount = totalAmount * rewardRate / 100;
        }
        // Tails wins
        else if (round.position == Position.Tails) 
        {
            rewardBaseCalAmount = round.tailsAmount;
            rewardAmount = totalAmount * rewardRate / 100;
        }
 
        round.rewardBaseCalAmount = rewardBaseCalAmount;
        round.rewardAmount = rewardAmount;

        emit RewardsCalculated(epoch, rewardBaseCalAmount, rewardAmount);
    }

    function _safeCancelRound(uint256 epoch, bool cancelled, bool closed) internal 
    {
        Round storage round = Rounds[epoch];
        round.cancelled = cancelled;
        round.closed = closed;
        emit CancelRound(epoch);
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
            block.timestamp > Rounds[epoch].startTimestamp &&
            block.timestamp < Rounds[epoch].closeTimestamp;
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
   
   
    function owner_HouseBet(uint256 headsAmount, uint256 tailsAmount) external onlyOwnerOrOperator whenNotPaused notContract 
    {
        require(_bettable(currentEpoch), "Round not bettable");
        require(address(this).balance >= headsAmount + tailsAmount, "Contract balance must be greater than house bet totals");

        // Putting Bull Bet
        if (headsAmount > 0)
        {
            // Update round data
            Round storage round = Rounds[currentEpoch];
            round.headsAmount += headsAmount;
    
            // Update user data
            BetInfo storage betInfo = Bets[currentEpoch][address(this)];
            betInfo.position = Position.Heads;
            betInfo.amount = headsAmount;
            UserBets[address(this)].push(currentEpoch);
        }

        // Putting Bear Bet
        if (tailsAmount > 0)
        {
            // Update round data
            Round storage round = Rounds[currentEpoch];
            round.tailsAmount += tailsAmount;
    
            // Update user data
            BetInfo storage betInfo = Bets[currentEpoch][address(this)];
            betInfo.position = Position.Tails;
            betInfo.amount = tailsAmount;
            UserBets[address(this)].push(currentEpoch);
        }
        
        emit HouseBet(address(this), currentEpoch, headsAmount, tailsAmount);
    }
    

    function control_Pause() public onlyOwnerOrOperator whenNotPaused 
    {
        _pause();

        emit Pause(currentEpoch);
    }

    function control_Resume() public onlyOwnerOrOperator whenPaused 
    {
        startOnce = false;
        _unpause();

        emit Unpause(currentEpoch);
    }

    function control_RoundStart() external onlyOwnerOrOperator whenNotPaused 
    {
        require(!startOnce, "Can only run startRound once");

        currentEpoch = currentEpoch + 1;
        _safeStartRound(currentEpoch);
        startOnce = true;
    }


    function control_RoundExecute() external onlyOwnerOrOperator whenNotPaused 
    {
                                                                                                         
        require(startOnce,"Can only run after startRound is triggered");

        // CurrentEpoch refers to previous round (n-1)
        _safeEndRound(currentEpoch - 1);                                  
        
        _calculateRewards(currentEpoch - 1);                                                            
      
        // Increment currentEpoch to current round (n)
        currentEpoch = currentEpoch + 1;                                                                
      
        _safeStartRound(currentEpoch);                                                                 
           
    }


    function control_RoundCancel(uint256 epoch, bool cancelled, bool closed) external onlyOwner 
    {
        _safeCancelRound(epoch, cancelled, closed);
    }


    function setBufferAndIntervalSeconds(uint256 _bufferSeconds, uint256 _intervalSeconds) external onlyOwner
    {
        require(_bufferSeconds < _intervalSeconds, "BufferSeconds must be inferior to intervalSeconds");
        bufferSeconds = _bufferSeconds;
        intervalSeconds = _intervalSeconds;
        emit BufferAndIntervalSecondsUpdated(_bufferSeconds, _intervalSeconds);
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


    function user_BetHeads(uint256 epoch) external payable whenNotPaused nonReentrant notContract 
    {
        require(epoch == currentEpoch, "Bet is too early/late");
        require(_bettable(epoch), "Round not bettable");
        require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");
        require(Bets[epoch][msg.sender].amount == 0, "Can only bet once per round");
        require(!Blacklist[msg.sender], "Blacklisted! Are you a bot ?");

        uint256 amount = msg.value;
        Round storage round = Rounds[epoch];
        round.headsAmount = round.headsAmount + amount;

        // Update user data
        BetInfo storage betInfo = Bets[epoch][msg.sender];
        betInfo.position = Position.Heads;
        betInfo.amount = amount;
        UserBets[msg.sender].push(epoch);

        emit BetHeads(msg.sender, currentEpoch, amount);
    }
    
    
    function user_BetTails(uint256 epoch) external payable whenNotPaused nonReentrant notContract 
    {
        require(epoch == currentEpoch, "Bet is too early/late");
        require(_bettable(epoch), "Round not bettable");
        require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");
        require(Bets[epoch][msg.sender].amount == 0, "Can only bet once per round");
        require(!Blacklist[msg.sender], "Blacklisted! Are you a bot ?");
 
        uint256 amount = msg.value;
        Round storage round = Rounds[epoch];
        round.tailsAmount = round.tailsAmount + amount;

        // Update user data
        BetInfo storage betInfo = Bets[epoch][msg.sender];
        betInfo.position = Position.Tails;
        betInfo.amount = amount;
        UserBets[msg.sender].push(epoch);

        emit BetTails(msg.sender, epoch, amount);
    }


    function user_Claim(uint256[] calldata epochs) external nonReentrant notContract 
    {
            
        uint256 reward; // Initializes reward

        for (uint256 i = 0; i < epochs.length; i++) {
            require(Rounds[epochs[i]].startTimestamp != 0, "Round has not started");
            require(block.timestamp > Rounds[epochs[i]].closeTimestamp, "Round has not ended");

            uint256 addedReward = 0;

            // Round valid, claim rewards
            if (Rounds[epochs[i]].closed) {
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
    
    function getUserRounds(address user, uint256 cursor, uint256 size) external view returns (uint256[] memory, BetInfo[] memory, uint256)
    {
        uint256 length = size;

        if (length > UserBets[user].length - cursor) 
        {
            length = UserBets[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        BetInfo[] memory betInfo = new BetInfo[](length);

        for (uint256 i = 0; i < length; i++) 
        {
            values[i] = UserBets[user][cursor + i];
            betInfo[i] = Bets[values[i]][user];
        }

        return (values, betInfo, cursor + length);
    }
    
    function getUserRoundsLength(address user) external view returns (uint256) {
        return UserBets[user].length;
    }


    function claimable(uint256 epoch, address user) public view returns (bool) 
    {
        BetInfo memory betInfo = Bets[epoch][user];
        Round memory round = Rounds[epoch];
        
        return round.position != Position.None && round.closed && !betInfo.claimed && 
        ((round.position == Position.Heads && betInfo.position == Position.Heads) || 
        (round.position == Position.Tails && betInfo.position == Position.Tails));
    }
    
    function refundable(uint256 epoch, address user) public view returns (bool) 
    {
        BetInfo memory betInfo = Bets[epoch][user];
        Round memory round = Rounds[epoch];
        
        return !round.closed && !betInfo.claimed && block.timestamp > round.closeTimestamp + bufferSeconds && betInfo.amount != 0;
    }


    function currentBlockNumber() public view returns (uint256) 
    {
        return block.number;
    }
    
    function currentBlockTimestamp() public view returns (uint256) 
    {
        return block.timestamp;
    }
    
    

   
}