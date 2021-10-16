/**
 *Submitted for verification at BscScan.com on 2021-10-16
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
        uint256 betAmount;
        uint256 paidAmount;
        uint8 rewardMultiplier;
        Position guess;
        Position result;
        bool paid;
    }
    
    mapping(uint256 => Bet) public Bets;
    mapping(address => uint256[]) public UserBets;
    mapping(address=>bool) internal Blacklist;
        
    uint256 public currentBetId;
    
    uint8 public houseFee = 3;
    uint8 public rewardMultiplier = 2;
    uint256 public minimumBetAmount = 1000000000000000;


    event FlipEvent(address indexed sender, uint256 indexed betId, uint8 guess, uint8 result, uint256 timestamp, bool paid, uint256 paidAmount, uint8 rewardMultiplier);
    event RepayBetEvent(uint256 indexed betId, address user, bool paid);
    
    event MinimumBetAmountUpdatedEvent(uint256 minimumBetAmount);
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
    
    function SetMinimumBetAmount(uint256 _minimumBetAmount) external onlyOwner 
    {
        minimumBetAmount = _minimumBetAmount;
        emit MinimumBetAmountUpdatedEvent(minimumBetAmount);
    }


    function RepayBet(address user, uint256 betId) external onlyOwner
    {
        require(Bets[betId].betAmount != 0, "Bet not found");  
        require(Bets[betId].paid == false, "Bet already paid");  
          
        Bet storage bet = Bets[betId];
        
        // Re-Payment 
        if (bet.result == bet.guess)
        {
            uint256 paidAmount = ((bet.betAmount - (bet.betAmount / 100 * houseFee)) * rewardMultiplier);
            bool payment = _safeTransferBNB(msg.sender, paidAmount);
            if (payment)
            {
                bet.paid = true;
                bet.paidAmount = paidAmount;
                bet.rewardMultiplier = rewardMultiplier;
            }
        }
        
        emit RepayBetEvent(bet.Id, user, bet.paid);
   
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
        require(Bets[currentBetId].betAmount == 0, "Can only bet after previous bet finished please try again");
        require(!Blacklist[msg.sender], "Blacklisted! Are you a bot ?");
        require(address(this).balance > msg.value * 4, "Wow ! your bet size larger than all we have. Try a small one !");
          
        // Bet Amount        
        uint256 betAmount = msg.value;
    
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
        Bet storage bet = Bets[currentBetId];
        bet.user = msg.sender;
        bet.Id = currentBetId;
        bet.timestamp = block.timestamp;
        bet.result = result;
        bet.guess = guess;
        bet.betAmount = betAmount;

        // Payment 
        if (result == guess)
        {
            uint256 paidAmount = ((betAmount - (betAmount / 100 * houseFee)) * rewardMultiplier);
            bool payment = _safeTransferBNB(msg.sender, paidAmount);
            if (payment)
            {
                bet.paid = true;
                bet.paidAmount = paidAmount;
                bet.rewardMultiplier = rewardMultiplier;
            }
        }
        
        UserBets[msg.sender].push(currentBetId);
        
        // Incresing Id
        currentBetId++;

        emit FlipEvent(msg.sender, bet.Id, bet.guess == Position.Heads ? 0 : 1,  bet.result == Position.Heads ? 0 : 1, bet.timestamp, bet.paid, bet.paidAmount, bet.rewardMultiplier);
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

}