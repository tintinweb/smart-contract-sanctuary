/**
 *Submitted for verification at BscScan.com on 2021-10-15
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


contract CandleGenieCoinFlip is Ownable, ReentrancyGuard 
{
    
    enum Position {Heads, Tails}

    struct Bet 
    {
        address user;
        uint256 Id;
        uint256 timestamp;
        Position guess;
        Position result;
        uint256 amount;
        bool paid;
    }
    
    mapping(uint256 => Bet) public Bets;
    mapping(address => uint256[]) public UserBets;
    mapping(address=>bool) internal Blacklist;
        
    uint256 public currentId;
    
    uint256 public rewardMultiplier = 2;
    uint256 public minimumBetAmount = 1000000000000000;


    event FlipEvent(address indexed sender, uint256 indexed betId, uint8 guess, uint8 result, uint256 timestamp);
    event RepayBetEvent(uint256 indexed betId, address user, uint256 amount);
    event MinimumBetAmountUpdatedEvent(uint256 minimumBetAmount);
          
    event RewardsCalculated(
        uint256 indexed epoch,
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount
    );

    event InjectFunds(address indexed sender);


    modifier notContract() 
    {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
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
   
  
    function settings_SetMinimumBetAmount(uint256 _minimumBetAmount) external onlyOwner 
    {
        minimumBetAmount = _minimumBetAmount;
        emit MinimumBetAmountUpdatedEvent(minimumBetAmount);
    }

    function settings_SetRewardMultiplier(uint256 _rewardMultiplier) external onlyOwner 
    {
        rewardMultiplier = _rewardMultiplier;
    }

    function RepayBet(address user, uint256 betId) external onlyOwner
    {
        require(Bets[betId].amount != 0, "Bet not found");  
        require(Bets[betId].paid == false, "Bet already paid");  
          
        Bet storage bet = Bets[betId];
        
        // Re-Payment 
        if (bet.result == bet.guess)
        {
            bool Payment = _safeTransferBNB(msg.sender, bet.amount * rewardMultiplier);
            if (Payment)
            {
                bet.paid = true;
            }
        }
        
        emit RepayBetEvent(bet.Id, user, bet.amount);
   
    }
    

    function generateRandomNumber() public view returns(uint256) 
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));
    
        uint256 rand = (seed - ((seed / 1000) * 1000));
        return rand;
    }  

    function Flip(int position) external payable nonReentrant notContract 
    {

        require(msg.value >= minimumBetAmount, "Bet amount must be greater than minBetAmount");
        require(Bets[currentId].amount == 0, "Can only bet after previous bet finished");
        require(!Blacklist[msg.sender], "Blacklisted! Are you a bot ?");
         
        // Bet Amount        
        uint256 amount = msg.value;
    
        // Flipping Coin
        Position result;
        uint256 randomNumber = generateRandomNumber();
        result = randomNumber < 500 ? Position.Heads : Position.Tails;
        
        Position guess;
        if (position == 0)
        {
            guess = Position.Heads;
        }
        else if (position == 1)
        {
            guess = Position.Tails;
        }
        
        // Storing Bet
        Bet storage bet = Bets[currentId];
        bet.user = msg.sender;
        bet.Id = currentId;
        bet.timestamp = block.timestamp;
        bet.result = result;
        bet.guess = guess;
        bet.amount = amount;

        // Payment 
        if (result == guess)
        {
            bool Payment = _safeTransferBNB(msg.sender, amount * rewardMultiplier);
            if (Payment)
            {
                bet.paid = true;
            }
        }
        
        UserBets[msg.sender].push(currentId);
        
        // Incresing Id
        currentId++;

        emit FlipEvent(msg.sender, bet.Id, bet.guess == Position.Heads ? 0 : 1,  bet.result == Position.Heads ? 0 : 1, bet.timestamp);
    }
    


    function getUserRounds(address user, uint256 cursor, uint256 size) external view returns (uint256[] memory, Bet[] memory, uint256)
    {
        uint256 length = size;

        if (length > UserBets[user].length - cursor) 
        {
            length = UserBets[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        Bet[] memory betInfo = new Bet[](length);

        for (uint256 i = 0; i < length; i++) 
        {
            values[i] = UserBets[user][cursor + i];
            betInfo[i] = Bets[values[i]];
        }

        return (values, betInfo, cursor + length);
    }
    
    function getUserRoundsLength(address user) external view returns (uint256) {
        return UserBets[user].length;
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