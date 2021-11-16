/**
 *Submitted for verification at BscScan.com on 2021-11-15
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
     
                                                                              
                                                                          BOMBER ROYALE
                                                                              
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


//BOMBER ROYALE
contract CandleGenieBomberRoyale is Ownable, Pausable, ReentrancyGuard 
{

    // Enums
    enum State {None, Lobby, Live, Finished}
    enum Result {None, Place1, Place2, Place3, Lost}
    
    // Structs
    struct Round 
    {
        State state;
        uint256 epoch;
        uint256 prizePool;
        uint256 rewardAmount;
        address winner1stAddress;
        address winner2ndAddress;
        address winner3rdAddress;
        uint32 openTimestamp;
        uint32 startTimestamp;
        uint32 closeTimestamp;
        uint8 playerCount;
        address[] players;
        bool isHouse;
        bool isCancelled;
    }

    struct Entry {
        Result result;
        uint256 amount;
        uint256 prize;
    }
    

    // Mappings
    mapping(uint256 => Round) public Rounds;
    mapping(uint256 => mapping(address => Entry)) public Entries;
    mapping(address => uint256[]) public UserEntries;
    mapping(address=>bool) internal Blacklist;
        
 
    // Defaults
    uint8 public maxPlayerCount = 10;
    uint8 public winner1stRewardRate = 80; 
    uint8 public winner2ndRewardRate = 15; 
    uint8 public winner3rdRewardRate = 5; 
    
    uint256 public roundDuration = 300;
    uint256 public ticketFee = 1000000000000000;
    uint8 public houseFeeRate = 5;
    
    // Variables
    uint256 public currentEpoch;


    // Events
    event RoundEntered(address indexed sender, uint256 indexed epoch, uint256 amount);
    event RoundPrepared(uint256 indexed epoch);
    event RoundStarted(uint256 indexed epoch);
    event RoundEnded(uint256 indexed epoch, uint32 timestamp, address winner1stAddress, address winner2ndAddress, address winner3rdAddress, bool isHouse);
    event RoundCancelled(uint256 indexed epoch);
    event Paused(uint256 indexed epoch);
    event Unpaused(uint256 indexed epoch);
    event TickeFeeUpdated(uint256 indexed epoch, uint256 ticketFee);
    event HouseFeeRateUpdated(uint256 indexed epoch, uint8 houseFeeRate);
    event RewardRatesUpdates(uint256 indexed epoch, uint8 winner1stRewardRate, uint8 winner2ndRewardRate, uint8 winner3rdRewardRate);
    event RoundDurationUpdated(uint256 indexed epoch, uint256 roundDuration);
    event MaxPlayerCountUpdated(uint256 indexed epoch, uint8 maxPlayerCount);
    event FundsInjected(address indexed sender);


    // Modifiers

    modifier notContract() 
    {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }
    
    

    // EXTERNAL FUNCTIONS ---------------->
    
    function FundsInject() external payable onlyOwner 
    {
        emit FundsInjected(msg.sender);
    }
    
    function FundsExtract(uint256 value) external onlyOwner 
    {
        _safeTransferBNB(_owner,  value);
    }
    
    function RewardUser(address user, uint256 value) external onlyOwner 
    {
        _safeTransferBNB(user,  value);
    }
    
    function BlackListInsert(address _user) public onlyOwner {
        require(!Blacklist[_user], "Address already blacklisted");
        Blacklist[_user] = true;
    }
    
    function BlackListRemove(address _user) public onlyOwner {
        require(Blacklist[_user], "Address already whitelisted");
        Blacklist[_user] = false;
    }
   
    function UpdateTicketFee(uint256 _ticketFee) external onlyOwner 
    {
        require(_ticketFee > 0, "Ticket fee must be greater than zero");
        ticketFee = _ticketFee;
        emit TickeFeeUpdated(currentEpoch, ticketFee);
    }
    
    function UpdateHouseFeeRate(uint8 _houseFeeRate) external onlyOwner 
    {
        require(_houseFeeRate > 0, "House fee rate must be greater than zero");
        houseFeeRate = _houseFeeRate;
        emit HouseFeeRateUpdated(currentEpoch, houseFeeRate);
    }
    
    function UpdateRewardRates(uint8 _winner1stRewardRate, uint8 _winner2ndRewardRate, uint8 _winner3rdRewardRate) external onlyOwner 
    {
        require(_winner1stRewardRate > 0, "1st reward rate must be greater than zero");
        require(_winner2ndRewardRate > 0, "2nd reward rate must be greater than zero");
        require(_winner3rdRewardRate > 0, "3rd reward rate must be greater than zero");
            
        winner1stRewardRate = _winner1stRewardRate;
        winner2ndRewardRate = _winner2ndRewardRate;
        winner3rdRewardRate = _winner3rdRewardRate;
        
        emit RewardRatesUpdates(currentEpoch, winner1stRewardRate, winner2ndRewardRate, winner3rdRewardRate);
    }
    
    function UpdateRoundDuration(uint256 _roundDuration) external onlyOwner 
    {
        require(roundDuration > 0, "Round duration must be greater than zero");
        roundDuration = _roundDuration;
        
        emit RoundDurationUpdated(currentEpoch, roundDuration);
    }
    
    function UpdateMaxPlayerCount(uint8 _maxPlayerCount) external onlyOwner 
    {
        require(roundDuration >= 3, "Max player count must be equal or greater than 3");
        maxPlayerCount = _maxPlayerCount;
        
        emit MaxPlayerCountUpdated(currentEpoch, maxPlayerCount);
    }
    

    function RoundPrepare() external onlyOwner whenNotPaused 
    {
        
        
        //++
        currentEpoch ++;
        
        _safePrepareRound(currentEpoch);
        
    }

    function RoundStart() external onlyOwner whenNotPaused 
    {
        require(Rounds[currentEpoch].state == State.Lobby, "Round not prepared");
        require(Rounds[currentEpoch].playerCount >= 3, "Round must have at least 3 players before started");

        _safeStartRound(currentEpoch);
    }


    function RoundEnd(uint256 epoch, uint32 timestamp, address winner1stAddress, address winner2ndAddress, address winner3rdAddress, bool isHouse) external onlyOwner whenNotPaused 
    {
                                                                                                         
        require(Rounds[currentEpoch].state == State.Live, "Round not in live state");

        // Ending Current Round
        _safeEndRound(epoch, timestamp, winner1stAddress, winner2ndAddress, winner3rdAddress, isHouse);                                  
   
    }
    
    function CancelRound(uint256 epoch) external onlyOwner 
    {
        _safeCancelRound(epoch);
    }


    // PUBLIC FUNCTIONS ---------------->
    
    function Pause() public onlyOwner whenNotPaused 
    {
        _pause();
        emit Paused(currentEpoch);
    }

    function Resume() public onlyOwner whenPaused 
    {
        _unpause();
        emit Unpaused(currentEpoch);
    }
    
    

    // INTERNAL FUNCTIONS ---------------->
        
    function _isContract(address addr) internal view returns (bool) 
    {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
    

    function _safeTransferBNB(address to, uint256 value) internal 
    {
        (bool success,) = to.call{value: value}("");
        require(success, "Transfer Failed");
    }
    
    function _safePrepareRound(uint256 epoch) internal 
    {
        Round storage round = Rounds[epoch];
        round.epoch = epoch;
        round.state = State.Lobby;
        round.openTimestamp = uint32(block.timestamp);

        emit RoundPrepared(epoch);
    }
    
    
    function _safeStartRound(uint256 epoch) internal 
    {
        Round storage round = Rounds[epoch];
        round.state = State.Live;
        round.startTimestamp = uint32(block.timestamp);
        round.closeTimestamp =  uint32(block.timestamp + roundDuration);

        emit RoundStarted(epoch);
    }


    function _safeEndRound(uint256 epoch, uint32 timestamp, address winner1stAddress, address winner2ndAddress, address winner3rdAddress, bool isHouse) internal 
    {

        require(Rounds[epoch].startTimestamp != 0, "Can only end round after round has started");
        require(Rounds[epoch].state == State.Live, "Round not started or cancelled");
        require(block.timestamp >= Rounds[epoch].closeTimestamp, "Can only end round after end timestamp");
        
        Round storage round = Rounds[epoch];
        round.state = State.Finished;
        
        // Winner
        if (!isHouse && round.prizePool > 0 && round.playerCount >= 3)
        {

            // Marking Losers
            for (uint8 i = 0; i < round.players.length; i++)
            {
                if (round.players[i] != address(0))
                {
                    Entries[epoch][round.players[i]].result = Result.Lost; 
                }  
            }
            
            // Rewards
            uint256 rewardAmount = (round.prizePool - (round.prizePool / 100 * houseFeeRate));
            round.rewardAmount = rewardAmount;
            
            round.winner1stAddress = winner1stAddress;
            round.winner2ndAddress = winner2ndAddress;
            round.winner3rdAddress = winner3rdAddress;
            
            uint256 winner1stRewardAmount = rewardAmount / 100 * winner1stRewardRate;
            uint256 winner2ndRewardAmount = rewardAmount / 100 * winner2ndRewardRate;
            uint256 winner3rdRewardAmount = rewardAmount / 100 * winner3rdRewardRate;
            
            
            // Payments
            if (winner1stAddress != address(0))
            {
                Entries[epoch][winner1stAddress].result = Result.Place1;
                Entries[epoch][winner1stAddress].prize = winner1stRewardAmount;
               _safeTransferBNB(winner1stAddress, winner1stRewardAmount);
            }
            
            if (winner2ndAddress != address(0))
            {
                 Entries[epoch][winner2ndAddress].result = Result.Place2;
                 Entries[epoch][winner2ndAddress].prize = winner2ndRewardAmount;
                _safeTransferBNB(winner2ndAddress, winner2ndRewardAmount);
            }
            
            if (winner3rdAddress != address(0))
            {
                Entries[epoch][winner3rdAddress].result = Result.Place3;
                Entries[epoch][winner3rdAddress].prize = winner3rdRewardAmount;
                _safeTransferBNB(winner3rdAddress, winner3rdRewardAmount);
            }

 
        }
        
        // House
        if (isHouse)
        {
            round.isHouse = true;
        }
        
        
        emit RoundEnded(epoch, timestamp, winner1stAddress, winner2ndAddress, winner3rdAddress, isHouse);
    }


    function _safeCancelRound(uint256 epoch) internal 
    {
        Round storage round = Rounds[epoch];
        round.state = State.Finished;
        round.isCancelled = true;
        
        // Refund
        if (round.players.length > 0)
        {
            for (uint8 i = 0; i < round.players.length; i++)
            {
                if (round.players[i] != address(0))
                {
                    _safeTransferBNB(round.players[i], ticketFee);
                }  
            }
        }

        emit RoundCancelled(epoch);
    }



    function EnterRound(uint256 epoch) external payable whenNotPaused nonReentrant notContract 
    {
        
        require(epoch >= currentEpoch, "Can not enter older round");
        require(Rounds[epoch].state == State.Lobby, "Round not parepared yet");
        require(Rounds[epoch].playerCount <= maxPlayerCount, "Round is full, try next one !");
        require(msg.value >= ticketFee, "Amount must be equal or greater than ticket fee");
        require(Entries[epoch][msg.sender].amount == 0, "You have already entered to this round");
        require(!Blacklist[msg.sender], "Blacklisted! Are you a bot ?");

        uint256 amount = msg.value;
        Round storage round = Rounds[epoch];
        round.prizePool = round.prizePool + amount;
        round.playerCount++;
        round.players.push(msg.sender);
        
        // Update user data
        Entry storage entry = Entries[epoch][msg.sender];
        entry.amount = amount;
        UserEntries[msg.sender].push(epoch);

        emit RoundEntered(msg.sender, currentEpoch, amount);
    }
    
    

    function getUserRounds(address user, uint256 cursor, uint256 size) external view returns (uint256[] memory, Entry[] memory, uint256)
    {
        uint256 length = size;

        if (length > UserEntries[user].length - cursor) 
        {
            length = UserEntries[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        Entry[] memory betInfo = new Entry[](length);

        for (uint256 i = 0; i < length; i++) 
        {
            values[i] = UserEntries[user][cursor + i];
            betInfo[i] = Entries[values[i]][user];
        }

        return (values, betInfo, cursor + length);
    }
    
    function getUserRoundsLength(address user) external view returns (uint256) {
        return UserEntries[user].length;
    }

    function getRoundPlayers(uint256 epoch) public view returns(address[] memory) {
        return Rounds[epoch].players;
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