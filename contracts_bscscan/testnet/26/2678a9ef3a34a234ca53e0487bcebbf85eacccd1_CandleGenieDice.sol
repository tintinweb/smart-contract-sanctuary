/**
 *Submitted for verification at BscScan.com on 2021-10-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


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
     
                                                                              
                                                                                DICE
                                                                              
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

//RANDOM GENERATOR INTERFACE
abstract contract CandleGenieDiceRandomSource
{
    function RollWithVRF() external virtual returns (uint256 requestId); 
    function RollWithPSEUDO() external virtual returns (uint256 requestId); 
    function fulfillPSEUDO(uint256 requestId) external virtual;
}


contract CandleGenieDice is Ownable, ReentrancyGuard 
{
    
    enum DiceRoll {None, One, Two, Three, Four, Five, Six}
    enum Status {Idle, Rolling , Drop, Refunded}

    struct Bet 
    {
        address user;
        uint256 Index;
        uint256 rollId;
        uint256 rollTimestamp;
        uint256 dropTimestamp;
        uint256 betAmount;
        uint256 paidAmount;
        uint8 rewardMultiplier;
        DiceRoll guess;
        DiceRoll result;
        Status status;
        bool paid;
        bool vrfUsed;
    }
    
    mapping(uint256 => Bet) public Bets;
    mapping(address => uint256[]) public UserBets;
    mapping(address=>bool) internal Blacklist;
        
    CandleGenieDiceRandomSource public diceRandomSource;
    uint256 public currentBetIndex;
    
    uint8 public houseFee = 5;
    uint8 public rewardMultiplier = 2;
    uint256 public vrfMinimumBetAmount = 10000000000000000;
    uint256 public pseudoMinimumBetAmount = 10000000000000000;
    uint256 public maximumBetAmount = 1000000000000000000;


    event RollEvent(address indexed sender, uint256 indexed rollIndex, uint256 indexed rollId, int guess, uint256 timestamp, uint256 betAmount, uint8 rewardMultiplier, bool vrfUsed);
    event DropEvent(address indexed sender, uint256 indexed rollIndex, uint256 indexed rollId, int guess, int result, uint256 rollTimestamp, uint256 dropTimestamp, uint256 betAmount, uint8 rewardMultiplier, bool paid, uint256 paidAmount, bool vrfUsed);
    event RefundBetEvent(uint256 indexed rollId, address user, bool paid);
    
    event VrfMinimumBetAmountUpdatedEvent(uint256 minimumBetAmount);
    event PseudoMinimumBetAmountUpdatedEvent(uint256 minimumBetAmount);
    
    event MaximumBetAmountUpdatedEvent(uint256 maximumBetAmount);
    event BruteTimeoutUpdatedEvent(uint8 bruteTimeout);
    event DiceRandomSourceUpdated(address diceRandomSource);
      
    event InjectFunds(address indexed sender);

 
    // MODIFIERS
    modifier notContract() 
    {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    modifier onlyRandomContract() 
    {
        require(msg.sender == address(diceRandomSource), "Only random source contract allowed");
        _;
    }
    
    // INTERNAL FUNCTIONS ---------------->
    
    function _safeTransferBNB(address to, uint256 value) internal returns (bool)
    {
        (bool success, ) = to.call{value: value}("");
        return success;
    }
    

    function _isContract(address addr) internal view returns (bool) 
    {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

  
    // EXTERNAL FUNCTIONS ---------------->
    
    function FundsInject() external payable onlyOwner 
    {
        emit InjectFunds(msg.sender);
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
   

    function SetHouseFee(uint8 _houseFee) external onlyOwner 
    {
        houseFee = _houseFee;
    }
    
    function SetRewardMultiplier(uint8 _rewardMultiplier) external onlyOwner 
    {
        rewardMultiplier = _rewardMultiplier;
    }
    
    function SetVRFMinimumBetAmount(uint256 _vrfMinimumBetAmount) external onlyOwner 
    {
        vrfMinimumBetAmount = _vrfMinimumBetAmount;
        emit VrfMinimumBetAmountUpdatedEvent(vrfMinimumBetAmount);
    }
    
    function SetPSEUDOMinimumBetAmount(uint256 _pseudoMinimumBetAmount) external onlyOwner 
    {
        pseudoMinimumBetAmount = _pseudoMinimumBetAmount;
        emit PseudoMinimumBetAmountUpdatedEvent(pseudoMinimumBetAmount);
    }
    
    function SetMaximumBetAmount(uint256 _maximumBetAmount) external onlyOwner 
    {
        maximumBetAmount = _maximumBetAmount;
        emit MaximumBetAmountUpdatedEvent(maximumBetAmount);
    }

    
    function SetDiceRandomSource(address _diceRandomSource) external onlyOwner {
    
        diceRandomSource = CandleGenieDiceRandomSource(_diceRandomSource);
        emit DiceRandomSourceUpdated(_diceRandomSource);
    }

    function RefundBet(address user, uint256 rollId) external onlyOwner
    {
        require(Bets[rollId].betAmount != 0, "Bet not found");  
        require(Bets[rollId].paid == false, "Bet already refunded");  
          
        Bet storage bet = Bets[rollId];
        
        bool payment = _safeTransferBNB(msg.sender, bet.betAmount);
        if (payment)
        {
            bet.paid = true;
            bet.paidAmount = bet.betAmount;
            bet.rewardMultiplier = 0;
            bet.status = Status.Refunded;
        }
  
        emit RefundBetEvent(bet.rollId, user, bet.paid);
   
    }
    
    function Roll(int position, bool useVRF) external payable nonReentrant notContract
    {
        
        require(position <= 6, "Wrong position");
        if (useVRF)require(msg.value >= vrfMinimumBetAmount, "Bet amount must be greater than minimum bet amount");
        if (!useVRF)require(msg.value >= pseudoMinimumBetAmount, "Bet amount must be greater than minimum bet amount");
        require(msg.value <= maximumBetAmount, "Bet amount must be less than maximum bet amount");
        require(!Blacklist[msg.sender], "Blacklisted! Are you a bot ?");
        require(address(this).balance > msg.value * 4, "Wow ! your bet size larger than all we have. Try a small one !");
          
        // Roll
        address user = msg.sender;
        uint256 amount = msg.value;
        
        _safeRoll(user, amount, position, useVRF);
        
    }
    
    
    function _safeRoll(address user, uint256 betAmount, int position, bool useVRF) internal
    {
        
        uint256 rollID;
        if (useVRF)
        {
            // Rolling Dice via Chainlink VRF
            rollID = diceRandomSource.RollWithVRF();
        }
        else
        {
            // Rolling Dice via PSEUDO
            rollID = diceRandomSource.RollWithPSEUDO();
        }

        // Storing Roll
        Bet storage bet = Bets[rollID];
        bet.user = user;
        bet.Index = currentBetIndex;
        bet.rollId =rollID;
        bet.rollTimestamp = block.timestamp;
        bet.guess = getPositionToRoll(position);
        bet.result = DiceRoll.None;
        bet.status = Status.Rolling;
        bet.betAmount = betAmount;
        bet.vrfUsed = useVRF;
        UserBets[user].push(rollID);
            
            
        // Incresing Bet Index
        currentBetIndex++;
        
        // Emit Event
        emit RollEvent(user, bet.Index, bet.rollId, getRollToPosition(bet.guess), bet.rollTimestamp, bet.betAmount, bet.rewardMultiplier, bet.vrfUsed);

        // Execute Pseudo
        if (!useVRF)
        {
           diceRandomSource.fulfillPSEUDO(bet.rollId); 
        }

    }
    
    function Drop(uint256 rollId, int rollResult) external onlyRandomContract
    {
         _safeDrop(rollId, rollResult);
    }
    
    function _safeDrop(uint256 rollId, int rollResult) internal
    {
   
        require(Bets[rollId].betAmount != 0, "Roll not found");

        DiceRoll result = getPositionToRoll(rollResult);
        
        Bet storage bet = Bets[rollId];
        bet.dropTimestamp = block.timestamp;
        bet.status = Status.Drop;
        bet.result = result;
          
        // Payment 
        if (bet.guess == bet.result)
        {
            uint256 paidAmount = ((bet.betAmount - (bet.betAmount / 100 * houseFee)) * rewardMultiplier);
            bool payment = _safeTransferBNB(bet.user, paidAmount);
            if (payment)
            {
                bet.paid = true;
                bet.paidAmount = paidAmount;
                bet.rewardMultiplier = rewardMultiplier;
            }
        }
        
        emit DropEvent(address(this), bet.Index, bet.rollId, getRollToPosition(bet.guess), getRollToPosition(bet.result), bet.rollTimestamp, bet.dropTimestamp, bet.betAmount, bet.rewardMultiplier, bet.paid, bet.paidAmount, bet.vrfUsed);
    }
    


    function getUserBets(address user, uint256 cursor, uint256 size) external view returns (uint256[] memory, Bet[] memory, uint256)
    {
        uint256 length = size;

        if (length > UserBets[user].length - cursor) 
        {
            length = UserBets[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        Bet[] memory userBets = new Bet[](length);

        for (uint256 i = 0; i < length; i++) 
        {
            values[i] = UserBets[user][cursor + i];
            userBets[i] = Bets[values[i]];
        }

        return (values, userBets, cursor + length);
    }
    
   
    function getBet(uint256 rollId) external view returns (Bet memory)
    {
        return Bets[rollId];
    }
    
    function getUserBetsLength(address user) external view returns (uint256) {
        return UserBets[user].length;
    }
    
    function getUserBetId(address user, uint256 position) external view returns (uint256) {
        return UserBets[user][position];
    }


   function getRollToPosition(DiceRoll roll) internal pure returns (int result)
    {
         if (roll == DiceRoll.One) return 1;
         if (roll == DiceRoll.Two) return 2;
         if (roll == DiceRoll.Three) return 3;
         if (roll == DiceRoll.Four) return 4;
         if (roll == DiceRoll.Five) return 5;
         if (roll == DiceRoll.Six) return 6;
         return 0;
    }
    
    function getPositionToRoll(int position) internal pure returns (DiceRoll result)
    {
         if (position == 1) return DiceRoll.One;
         if (position == 2) return DiceRoll.Two;
         if (position == 3) return DiceRoll.Three;
         if (position == 4) return DiceRoll.Four;
         if (position == 5) return DiceRoll.Five;
         if (position == 6) return DiceRoll.Six;
         return  DiceRoll.None;
    }
    
    
}