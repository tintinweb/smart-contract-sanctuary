/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

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
contract BourbonLiveEvents is Ownable 
{

    // STRUTCTURES
    enum Position {None, One, Draw, Two}
    enum Status {None, Open, Finished, Cancelled}
      
    struct LiveEvent 
    {
        uint256 id;
        uint256 startTimestamp;
        uint256 closeTimestamp;
        uint256 endTimestamp;
        string category;
        string data;
        uint256 oneAmount;
        uint256 drawAmount;
        uint256 twoAmount;
        uint256 rewardAmount;
        uint256 rewardBaseAmount;
        uint256 betCount;
        Position position;
        Status status;
        
    }

    struct Bet 
    {
        uint256 eventId;
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
    uint256 public rewardRate = 97; // Prize reward rate %
    uint256 constant internal minimumRewardRate = 90; // Minimum reward rate 90%
    
    uint256 public minAmount;
    uint256 public currentID;
    uint256[] internal openEvents;
    
     
    // EVENTS
    event LiveEventAdd(uint256 indexed id, uint256 blockNumber, uint256 closeTimeStamp, uint256 endTimestamp, string category, string data);
    event LiveEventEdit(uint256 indexed id, uint256 blockNumber, uint256 closeTimeStamp, uint256 endTimestamp, string category, string data);
    event LiveEventStart(uint256 indexed id, uint256 blockNumber, uint256 startTimestamp);
    event LiveEventCancel(uint256 indexed id, uint256 blockNumber);
    event LiveEventEnd(uint256 indexed id, uint256 blockNumber, int position);
    event BetEnter(address indexed sender, uint256 indexed id, uint256 amount, int position);   
    event BetClaim(address indexed sender, uint256 indexed id, uint256 amount);
    event RewardsCalculated(uint256 indexed id, uint256 rewardBaseAmount, uint256 rewardAmount);
    event SetRewardRate(uint256 rewardRate);
    
            
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
        require(_rewardRate >= minimumRewardRate, "Reward rate can't be lower than minimum reward rate");
        rewardRate = _rewardRate;

        emit SetRewardRate(_rewardRate);
    }
    
    function fundsInject() external payable onlyOwner {}
    function fundsExtract(uint256 value) external onlyOwner {transferBNB(owner(),  value);}
    
    function transferBNB(address to, uint256 value) internal 
    {
        (bool success, ) = to.call{gas: 23000, value: value}("");
        require(success, "Transfer Failed");
    }

    function addOpenEvent(uint256 id) internal
    {
        openEvents.push(id);   
    }
    
    function removeOpenEvent(uint256 id) internal
    {
        uint eventOldIndex;
        for (uint i = 0; i < openEvents.length; i++) 
        {
            if (openEvents[i] == id)
            {
               eventOldIndex = i; 
            }
        }
        
        uint eventNewIndex = openEvents.length - 1;
        if (eventNewIndex < 0)
        {
            eventNewIndex = 0;
        }
        openEvents[eventOldIndex] = openEvents[eventNewIndex];
        openEvents.pop();   

    }
    

    function liveEventAdd(uint256 closeTimeStamp, uint256 endTimestamp, string memory category, string memory data) public onlyOwnerOrOperator
    {
        require(closeTimeStamp > 0, "Invalid close timestamp");
        require(endTimestamp > 0, "Invalid end timestamp");
        require(closeTimeStamp < endTimestamp, "Close timestamp must be lower than end timestamp");
        require(bytes(category).length > 0, "category can not be empty");
        require(bytes(data).length > 0, "Data can not be empty");   
           
        LiveEvent storage liveEvent = Events[currentID];
        
        liveEvent.id = currentID;
        liveEvent.closeTimestamp = closeTimeStamp;
        liveEvent.endTimestamp =  endTimestamp;
        liveEvent.category =  category;
        liveEvent.data =  data;
        liveEvent.position = Position.None;
        
        // Increasing current ID
        currentID++;

        emit LiveEventAdd(currentID, block.number, closeTimeStamp, endTimestamp, category, data);

    }
    
    function liveEventEdit(uint256 id, uint256 closeTimeStamp, uint256 endTimestamp, string memory category, string memory data) public onlyOwner
    {
        
        require(closeTimeStamp > 0, "Invalid close timestamp");
        require(endTimestamp > 0, "Invalid end timestamp");
        require(closeTimeStamp < endTimestamp, "Close timestamp must be lower than close timestamp");
        require(bytes(category).length > 0, "category can not be empty");
        require(bytes(data).length > 0, "Data can not be empty");   
           
        LiveEvent storage liveEvent = Events[id];
        
        liveEvent.closeTimestamp = closeTimeStamp;
        liveEvent.endTimestamp =  endTimestamp;
        liveEvent.category =  category;
        liveEvent.data =  data;
     
        emit LiveEventEdit(id, block.number, closeTimeStamp, endTimestamp, category, data);
    }
    
    function liveEventStart(uint256 id) public onlyOwnerOrOperator
    {
        require(Events[id].closeTimestamp > 0, "Event not defined");
        require(Events[id].status != Status.Open, "Event already started");
        require(Events[id].status != Status.Cancelled, "Event cancelled");
        require(Events[id].status != Status.Finished, "Event finished");
        
        LiveEvent storage liveEvent = Events[id];
        liveEvent.startTimestamp = block.timestamp;
        liveEvent.status = Status.Open;
        
         // Add Open Event
        addOpenEvent(id);
        
        emit LiveEventStart(id, block.number, block.timestamp);
    }
    
    function liveEventCancel(uint256 id) public onlyOwnerOrOperator
    {
        LiveEvent storage liveEvent = Events[id];
        liveEvent.status = Status.Cancelled;
        
        if (liveEvent.status == Status.Open)
        {
            // Remove Open Event
            removeOpenEvent(id);
        }

        emit LiveEventCancel(id, block.number);
    }
    
   function liveEventEnd(uint256 id, int position) public onlyOwnerOrOperator 
    {
        require(Events[id].closeTimestamp > 0, "Event not defined");
        require(Events[id].status == Status.Open, "Event not started");
        require(block.timestamp >= Events[id].endTimestamp, "Live event can only end after end timestamp reached");
        
        LiveEvent storage liveEvent = Events[id];
        liveEvent.status = Status.Finished;
       
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
        calculateRewards(id);
        
        // Remove Open Event
        removeOpenEvent(id);
        
        emit LiveEventEnd(id, block.number, position);
    }
    

    function calculateRewards(uint256 id) internal 
    {
        
        require(Events[id].rewardBaseAmount == 0 && Events[id].rewardAmount == 0, "Rewards calculated");
        
        LiveEvent storage liveEvent = Events[id];
          
        uint256 rewardBaseAmount;
        uint256 rewardAmount;
        uint256 totalAmount = liveEvent.oneAmount + liveEvent.drawAmount + liveEvent.twoAmount;
        
        if (liveEvent.position == Position.One) 
        {
            rewardBaseAmount = liveEvent.oneAmount;
            rewardAmount = totalAmount * rewardRate / 100;
        }
        else if (liveEvent.position == Position.Draw) 
        {
            rewardBaseAmount = liveEvent.drawAmount;
            rewardAmount = totalAmount * rewardRate / 100;
        }
        else if (liveEvent.position == Position.Two) 
        {
            rewardBaseAmount = liveEvent.twoAmount;
            rewardAmount = totalAmount * rewardRate / 100;
        }
        
        liveEvent.rewardBaseAmount = rewardBaseAmount;
        liveEvent.rewardAmount = rewardAmount;

        emit RewardsCalculated(id, rewardBaseAmount, rewardAmount);
    }
    

    function bettable(uint256 id) public view returns (bool) 
    {
        LiveEvent storage liveEvent = Events[id];
 
        return
           liveEvent.status == Status.Open &&
           liveEvent.startTimestamp != 0 &&
           liveEvent.closeTimestamp != 0 &&
           liveEvent.startTimestamp < liveEvent.closeTimestamp;
           
    }
    
    function claimable(uint256 id, address user) public view returns (bool) 
    {
        LiveEvent memory liveEvent = Events[id];
        Bet memory bet = Bets[id][user];
        
        return
            (
                (liveEvent.position == Position.One && bet.position == Position.One) ||
                (liveEvent.position == Position.Draw && bet.position == Position.Draw) || 
                (liveEvent.position == Position.Two && bet.position == Position.Two)
            );
    }
    

    function betEnter(uint256 id, int position) external payable notContract 
    {
        require(bettable(id), "Event not bettable, not started yet finished or cancelled");
        require(msg.value >= minAmount, "Bet amount must be greater than minimum bet amount");
        require(Bets[id][msg.sender].amount == 0, "Can only bet once per round");
        require(!Blacklist[msg.sender], "Blacklisted! Are you a bot ?");
   
        // Update round data
        uint256 amount = msg.value;
        
        LiveEvent storage liveEvent = Events[id];
        liveEvent.betCount++;
               
        Bet storage bet = Bets[id][msg.sender];
        bet.amount = amount;
        bet.eventId = id;
 
        
        if (position == 0)
        {
            liveEvent.oneAmount += amount;
            bet.position = Position.One;
        }
        else if (position == 1)
        {
            liveEvent.drawAmount += amount;
            bet.position = Position.Draw;
        }
        else if (position == 2)
        {
            liveEvent.twoAmount += amount;
            bet.position = Position.Two;
        }
        
        UserEnteredEvents[msg.sender].push(id);
        
        emit BetEnter(msg.sender, id, amount, position);
        
    }
    

    function betClaim(uint256 id) external notContract 
    {
        require(Bets[id][msg.sender].amount > 0, "Amount must be greater than zero");
        require(!Bets[id][msg.sender].claimed, "Already claimed");
        require(!Blacklist[msg.sender], "Blacklisted! Are you a bot ?");
 
        LiveEvent storage liveEvent = Events[id];
        Bet storage bet = Bets[id][msg.sender];

        
        uint256 amountToPay;
        
        if (liveEvent.status == Status.Cancelled)
        {
            amountToPay = bet.amount;
        }
        else if (liveEvent.status == Status.Finished)
        {
            require(block.timestamp > Events[id].endTimestamp, "Event has not ended");
            require(liveEvent.position != Position.None, "Event has not resulted");
            require(claimable(id, msg.sender), "Not eligible for claim");
            
            amountToPay = bet.amount * liveEvent.rewardAmount / liveEvent.rewardBaseAmount;
        }
      
        bet.claimed = true;
        transferBNB(address(msg.sender), amountToPay);

        emit BetClaim(msg.sender, id, amountToPay);
    }
    
 

    function getUserEnteredEventsCount(address user) external view returns (uint256) {
        return UserEnteredEvents[user].length;
    }

  
    function getUserEnteredEvents(address user, uint256 cursor, uint256 size) external view returns (uint256[] memory, Bet[] memory, uint256)
    {
        uint256 length = size;

        if (length > UserEnteredEvents[user].length - cursor) 
        {
            length = UserEnteredEvents[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        Bet[] memory userBets = new Bet[](length);

        for (uint256 i = 0; i < length; i++) 
        {
            values[i] = UserEnteredEvents[user][cursor + i];
            userBets[i] = Bets[values[i]][user];
        }

        return (values, userBets, cursor + length);
    }
    
    
    function getOpenEvents() external view returns (uint256[] memory, uint256) 
    {
        uint256 length = openEvents.length;
        uint256[] memory values = new uint256[](length);
        
        for (uint256 i = 0; i < length; i++) {
            values[i] = openEvents[ i];
        }

        return (values, length);
    }

    
}