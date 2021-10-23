/**
 *Submitted for verification at BscScan.com on 2021-10-22
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

//RANDOM GENERATOR INTERFACE
abstract contract CandleGenieCoinFlipRandomSource
{
    function FlipWithVRF() external virtual returns (uint256 requestId); 
    
    function FlipWithPSEUDO() external virtual returns (uint256 requestId); 
    function fulfillPSEUDO(uint256 requestId) external virtual;
}


contract CandleGenieCoinFlip is Ownable, ReentrancyGuard 
{
    
    enum Position {None, Heads, Tails}
    enum Status {Idle, Flipping , Drop, Refunded}

    struct Bet 
    {
        address user;
        uint256 Index;
        uint256 flipId;
        uint256 flipTimestamp;
        uint256 dropTimestamp;
        uint256 betAmount;
        uint256 paidAmount;
        uint8 rewardMultiplier;
        Position guess;
        Position result;
        Status status;
        bool paid;
        bool vrfUsed;
    }
    
    mapping(uint256 => Bet) public Bets;
    mapping(address => uint256[]) public UserBets;
    mapping(address=>bool) internal Blacklist;
        
    CandleGenieCoinFlipRandomSource public coinFlipRandomSource;
    uint256 public currentBetIndex;
    
    uint8 public houseFee = 5;
    uint8 public rewardMultiplier = 2;
    uint256 public vrfMinimumBetAmount = 10000000000000000;
    uint256 public pseudoMinimumBetAmount = 10000000000000000;
    
    uint256 public maximumBetAmount = 1000000000000000000;


    event FlipEvent(address indexed sender, uint256 indexed flipIndex, uint256 indexed flipId, uint8 guess, uint256 timestamp, uint256 betAmount, uint8 rewardMultiplier);
    event DropEvent(address indexed sender, uint256 indexed flipIndex, uint256 indexed flipId, uint8 guess, uint8 result, uint256 flipTimestamp, uint256 dropTimestamp, uint256 betAmount, uint8 rewardMultiplier, bool paid, uint256 paidAmount);
    event RefundBetEvent(uint256 indexed flipId, address user, bool paid);
    
    event VrfMinimumBetAmountUpdatedEvent(uint256 minimumBetAmount);
    event PseudoMinimumBetAmountUpdatedEvent(uint256 minimumBetAmount);
    
    event MaximumBetAmountUpdatedEvent(uint256 maximumBetAmount);
    event BruteTimeoutUpdatedEvent(uint8 bruteTimeout);
    event CoinFlipRandomSourceUpdated(address coinFlipRandomSource);
      
    event InjectFunds(address indexed sender);

    uint8 internal randPivot;
  
 
    // MIDIFIERS
    modifier notContract() 
    {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    modifier onlyRandomContract() 
    {
        require(msg.sender == address(coinFlipRandomSource), "Only random source contract allowed");
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

    
    function SetCoinFlipRandomSource(address _coinFlipRandomSource) external onlyOwner {
    
        coinFlipRandomSource = CandleGenieCoinFlipRandomSource(_coinFlipRandomSource);
        emit CoinFlipRandomSourceUpdated(_coinFlipRandomSource);
    }

    function RefundBet(address user, uint256 flipId) external onlyOwner
    {
        require(Bets[flipId].betAmount != 0, "Bet not found");  
        require(Bets[flipId].paid == false, "Bet already refunded");  
          
        Bet storage bet = Bets[flipId];
        
        bool payment = _safeTransferBNB(msg.sender, bet.betAmount);
        if (payment)
        {
            bet.paid = true;
            bet.paidAmount = bet.betAmount;
            bet.rewardMultiplier = 0;
            bet.status = Status.Refunded;
        }
  
        emit RefundBetEvent(bet.flipId, user, bet.paid);
   
    }
    
    function Flip(int position, bool useVRF) external payable
    {

        require(position == 0 || position == 1, "Wrong position");
        if (useVRF)require(msg.value >= vrfMinimumBetAmount, "Bet amount must be greater than minimum bet amount");
        if (!useVRF)require(msg.value >= pseudoMinimumBetAmount, "Bet amount must be greater than minimum bet amount");
        require(msg.value <= maximumBetAmount, "Bet amount must be less than maximum bet amount");
        require(!Blacklist[msg.sender], "Blacklisted! Are you a bot ?");
        require(address(this).balance > msg.value * 4, "Wow ! your bet size larger than all we have. Try a small one !");
          
        // Brute Check
        if (UserBets[msg.sender].length > 0)
        {
            require(Bets[UserBets[msg.sender][UserBets[msg.sender].length - 1]].status != Status.Flipping, "Please wait current flip result to place a new bet. No brute plis");  
        }
            
        // Bet Amount        
        uint256 betAmount = msg.value;
    

        uint256 flipID;
        if (useVRF)
        {
            // Flipping Coin via Chainlink VRF
            flipID = coinFlipRandomSource.FlipWithVRF();
        }
        else
        {
            // Flipping Coin via PSEUDO
            flipID = coinFlipRandomSource.FlipWithPSEUDO();
        }

        // Storing Flip
        Bet storage bet = Bets[flipID];
        bet.user = msg.sender;
        bet.Index = currentBetIndex;
        bet.flipId = flipID;
        bet.flipTimestamp = block.timestamp;
        bet.guess = position == 0 ? Position.Heads : Position.Tails;
        bet.result = Position.None;
        bet.status = Status.Flipping;
        bet.betAmount = betAmount;
        bet.vrfUsed = true;
        UserBets[msg.sender].push(flipID);
            
            
        // Incresing Bet Index
        currentBetIndex++;
        
        // Emit Event
        emit FlipEvent(msg.sender, bet.Index, bet.flipId, bet.guess == Position.Heads ? 0 : 1, bet.flipTimestamp, bet.betAmount, bet.rewardMultiplier);
        
        // Execute psueudo
        if (!useVRF)
        {
           coinFlipRandomSource.fulfillPSEUDO(bet.flipId); 
        }
        
    }
    
    // Called From Random Source
    function Drop(uint256 flipId, int flipResult) external nonReentrant onlyRandomContract
    {
   
        require(Bets[flipId].betAmount != 0, "Flip not found");

        Position result;
        
        if (flipResult == 0)
        {
            result = Position.Heads;
        }
        else if (flipResult == 1)
        {
            result = Position.Tails;
        } 
        
        Bet storage bet = Bets[flipId];
        bet.dropTimestamp = block.timestamp;
        bet.status = Status.Drop;
        bet.result = result;
          
        // Payment 
        if (bet.result == bet.guess)
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
        
        emit DropEvent(address(this), bet.Index, bet.flipId, bet.guess == Position.Heads ? 0 : 1, bet.result == Position.Heads ? 0 : 1, bet.flipTimestamp, bet.dropTimestamp, bet.betAmount, bet.rewardMultiplier, bet.paid, bet.paidAmount);

    }
    
    function getBet(uint256 flipId) external view returns (Bet memory)
    {
        return Bets[flipId];
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
    
    
    function getUserBetsLength(address user) external view returns (uint256) {
        return UserBets[user].length;
    }
    
    function getUserBetId(address user, uint256 position) external view returns (uint256) {
        return UserBets[user][position];
    }

}