/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

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
     
                                                                              
                                                                        LIVE EVENT BETS
                                                                              
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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

//OWNABLE
abstract contract Ownable is Context 
{
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()
    {
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

//CONTRACT
contract CandleGenieLiveEventBets is Ownable {

    using SafeMath for uint256;
    
    // STRUTCTURES
    enum Position {None, One, Draw, Two}
        
    struct LiveEvent 
    {
        uint256 epoch;
        
        uint256 startTimestamp;
        uint256 closeTimestamp;
        uint256 endTimestamp;
        
        string category;
        string data;

        Position position;
        
        uint256 oneAmount;
        uint256 drawAmount;
        uint256 twoAmount;
        
        uint256 rewardAmount;
        uint256 rewardBaseAmount;
        
        bool open;
        bool cancelled;

    }

    struct Bet 
    {
        uint256 epoch;
        Position position;
        uint256 amount;
        bool claimed; 
    }
    
    // MAPPINGS
    mapping(uint256 => LiveEvent) public Events;
    mapping(uint256 => mapping(address => Bet)) public Bets;
    mapping(address => uint256[]) internal UserEnteredEvents;
    mapping(address=>bool) internal Blacklist;
    
    // VARIABLES
    address public operatorAddress;
    uint256 internal rewardRate = 97; // Prize reward rate
    uint256 public minAmount;
    uint256 public currentEpoch;
    
    // EVENTS
    event AddLiveEvent(uint256 indexed epoch, uint256 blockNumber, uint256 closeTimeStamp, uint256 endTimestamp, string category, string data);
    event EditLiveEvent(uint256 indexed epoch, uint256 blockNumber, uint256 closeTimeStamp, uint256 endTimestamp, string category, string data);
    event StartLiveEvent(uint256 indexed epoch, uint256 blockNumber, uint256 startTimestamp);
    event CancelLiveEvent(uint256 indexed epoch, uint256 blockNumber);
    event EndLiveEvent(uint256 indexed epoch, uint256 blockNumber, int position);
    event EnterBet(address indexed sender, uint256 indexed epoch, uint256 amount, int position);   
    event ClaimBet(address indexed sender, uint256 indexed epoch, uint256 amount);
    event RewardsCalculated(uint256 indexed epoch, uint256 rewardBaseAmount, uint256 rewardAmount);
    
            
    // CONSCTRUCTOR
    constructor(address _operatorAddress, uint256 _minAmount)  
    {
        operatorAddress = _operatorAddress;
        minAmount = _minAmount;
    }
    
    // MODIFIERS
    modifier onlyOwnerOrOperator() 
    {
        require(msg.sender == _owner || msg.sender == operatorAddress, "Only owner or operator can call this function");
        _;
    }

    modifier notContract() 
    {
        require(!isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }
    
    // FUNCTIONS
    function isContract(address addr) internal view returns (bool) 
    {
        uint256 size;
        assembly {size := extcodesize(addr)}
        return size > 0;
    }
    
    function setRewardRate(uint256 _rewardRate) external onlyOwner 
    {
        require(_rewardRate <= 100, "rewardRate cannot be more than 100%");
        rewardRate = _rewardRate;
    }
    function fundsInject() external payable onlyOwner {}
    function fundsExtract(uint256 value) external onlyOwner {transferBNB(owner(),  value);}
    
    function transferBNB(address to, uint256 value) internal 
    {
        (bool success, ) = to.call{gas: 23000, value: value}("");
        require(success, "Transfer Failed");
    }
    
    
    function addLiveEvent(uint256 closeTimeStamp, uint256 endTimestamp, string memory category, string memory data) public onlyOwnerOrOperator
    {
        
        require(closeTimeStamp > 0, "Invalid close timestamp");
        require(endTimestamp > 0, "Invalid end timestamp");
        require(closeTimeStamp < endTimestamp, "Close timestamp must be lower than end timestamp");
        require(bytes(category).length > 0, "category can not be empty");
        require(bytes(data).length > 0, "Data can not be empty");   
           
        LiveEvent storage liveEvent = Events[currentEpoch];
        
        liveEvent.epoch = currentEpoch;
        liveEvent.closeTimestamp = closeTimeStamp;
        liveEvent.endTimestamp =  endTimestamp;
        liveEvent.category =  category;
        liveEvent.data =  data;
        liveEvent.position = Position.None;
        
        // Increasing current epoch
        currentEpoch++;
        
         
        emit AddLiveEvent(currentEpoch, block.number, closeTimeStamp, endTimestamp, category, data);
       
     
    }
    
    function editLiveEvent(uint256 epoch, uint256 closeTimeStamp, uint256 endTimestamp, string memory category, string memory data) public onlyOwner
    {
        
        require(closeTimeStamp > 0, "Invalid close timestamp");
        require(endTimestamp > 0, "Invalid end timestamp");
        require(closeTimeStamp < endTimestamp, "Close timestamp must be lower than close timestamp");
        require(bytes(category).length > 0, "category can not be empty");
        require(bytes(data).length > 0, "Data can not be empty");   
           
        LiveEvent storage liveEvent = Events[epoch];
        
        liveEvent.closeTimestamp = closeTimeStamp;
        liveEvent.endTimestamp =  endTimestamp;
        liveEvent.category =  category;
        liveEvent.data =  data;
     
        emit EditLiveEvent(epoch, block.number, closeTimeStamp, endTimestamp, category, data);
    }
    
    function startLiveEvent(uint256 epoch) public onlyOwnerOrOperator
    {
        require(!Events[epoch].open, "Event already started");
         
        LiveEvent storage liveEvent = Events[epoch];
        liveEvent.startTimestamp = block.timestamp;
        liveEvent.open = true;
        emit StartLiveEvent(epoch, block.number, block.timestamp);
    }
    
    function cancelLiveEvent(uint256 epoch) public onlyOwnerOrOperator
    {
        LiveEvent storage liveEvent = Events[epoch];
        liveEvent.cancelled = true;
        emit CancelLiveEvent(epoch, block.number);
    }
    
   function endLiveEvent(uint256 epoch, int position) public onlyOwnerOrOperator 
    {
        require(Events[epoch].open, "Event not started");
        require(Events[epoch].closeTimestamp != 0, "Live event can only end after it has locked");
        require(block.timestamp >= Events[epoch].endTimestamp, "Live event can only end after end timestamp reached");
        
        LiveEvent storage liveEvent = Events[epoch];
       
        if (position == 0)
        {
            liveEvent.position = Position.One;
        }
        else if (position == 1)
        {
            liveEvent.position = Position.Draw;
        }
        else if (position == 2)
        {
            liveEvent.position = Position.Two;
        }
        
        // Calculating Rewards
        calculateRewards(epoch);
        
        emit EndLiveEvent(epoch, block.number, position);
    }
    
    function calculateRewards(uint256 epoch) internal 
    {
        
        require(Events[epoch].rewardBaseAmount == 0 && Events[epoch].rewardAmount == 0, "Rewards calculated");
        
        LiveEvent storage liveEvent = Events[epoch];
          
        uint256 rewardBaseAmount;
        uint256 rewardAmount;
        uint256 totalAmount = liveEvent.oneAmount.add(liveEvent.drawAmount).add(liveEvent.twoAmount);
        
        if (liveEvent.position == Position.One) 
        {
            rewardBaseAmount = liveEvent.oneAmount;
            rewardAmount = totalAmount.mul(rewardRate).div(100);
        }
        else if (liveEvent.position == Position.Draw) 
        {
            rewardBaseAmount = liveEvent.drawAmount;
            rewardAmount = totalAmount.mul(rewardRate).div(100);
        }
        else if (liveEvent.position == Position.Two) 
        {
            rewardBaseAmount = liveEvent.twoAmount;
            rewardAmount = totalAmount.mul(rewardRate).div(100);
        }
        
        liveEvent.rewardBaseAmount = rewardBaseAmount;
        liveEvent.rewardAmount = rewardAmount;

        emit RewardsCalculated(epoch, rewardBaseAmount, rewardAmount);
    }
    

    function bettable(uint256 epoch) public view returns (bool) 
    {
        LiveEvent storage liveEvent = Events[epoch];
 
        return
           liveEvent.open &&
           liveEvent.cancelled == false &&
           liveEvent.startTimestamp != 0 &&
           liveEvent.closeTimestamp != 0 &&
           liveEvent.startTimestamp < liveEvent.closeTimestamp;
           
    }
    
    function claimable(uint256 epoch, address user) public view returns (bool) 
    {
        LiveEvent memory liveEvent = Events[epoch];
        Bet memory bet = Bets[epoch][user];
        
        return
            (
                (liveEvent.position == Position.One && bet.position == Position.One) ||
                (liveEvent.position == Position.Draw && bet.position == Position.Draw) || 
                (liveEvent.position == Position.Two && bet.position == Position.Two)
            );
    }
    

    function enterBet(uint256 epoch, int position) external payable notContract 
    {
        require(bettable(currentEpoch), "Event not bettable");
        require(msg.value >= minAmount, "Bet amount must be greater than minimum bet amount");
        require(Bets[currentEpoch][msg.sender].amount == 0, "Can only bet once per round");
        require(!Blacklist[msg.sender], "Blacklisted! Are you a bot ?");
   
        // Update round data
        uint256 amount = msg.value;
        
        LiveEvent storage liveEvent = Events[epoch];
        Bet storage bet = Bets[epoch][msg.sender];
        bet.amount = amount;
               
        if (position == 0)
        {
            liveEvent.oneAmount = liveEvent.oneAmount.add(amount);
            bet.position = Position.One;
        }
        else if (position == 1)
        {
            liveEvent.drawAmount = liveEvent.drawAmount.add(amount);
            bet.position = Position.Draw;
        }
        else if (position == 2)
        {
            liveEvent.twoAmount = liveEvent.twoAmount.add(amount);
            bet.position = Position.Two;
        }
        
        UserEnteredEvents[msg.sender].push(epoch);
        
        emit EnterBet(msg.sender, currentEpoch, amount, position);
        
    }
    

    function claimBet(uint256 epoch) external notContract 
    {
        require(Bets[epoch][msg.sender].amount > 0, "Amount must be greater than zero");
        require(!Bets[epoch][msg.sender].claimed, "Already claimed");
        require(!Blacklist[msg.sender], "Blacklisted! Are you a bot ?");
 
        LiveEvent storage liveEvent = Events[epoch];
        Bet storage bet = Bets[epoch][msg.sender];
    
        uint256 amountToPay;
        
        if (liveEvent.cancelled)
        {
            amountToPay = bet.amount;
        }
        else
        {
            require(Events[epoch].open, "Event has not started");
            require(block.timestamp > Events[epoch].endTimestamp, "Event has not ended");
            require(liveEvent.position != Position.None, "Event has not resulted");
            require(claimable(epoch, msg.sender), "Not eligible for claim");
            
            amountToPay = bet.amount.mul(liveEvent.rewardAmount).div(liveEvent.rewardBaseAmount);
        }
      
        bet.claimed = true;
        transferBNB(address(msg.sender), amountToPay);

        emit ClaimBet(msg.sender, epoch, amountToPay);
    }
    
    function getUserEnteredEvents(address user, uint256 cursor, uint256 size) external view returns (uint256[] memory, uint256) 
    {
        uint256 length = size;
        if (length > UserEnteredEvents[user].length - cursor) {
            length = UserEnteredEvents[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = UserEnteredEvents[user][cursor + i];
        }

        return (values, cursor + length);
    }


    
}