pragma solidity ^0.4.23;

/******* USING Registry **************************

Gives the inherting contract access to:
    .addressOf(bytes32): returns current address mapped to the name.
    [modifier] .fromOwner(): requires the sender is owner.

*************************************************/
// Returned by .getRegistry()
interface IRegistry {
    function owner() external view returns (address _addr);
    function addressOf(bytes32 _name) external view returns (address _addr);
}

contract UsingRegistry {
    IRegistry private registry;

    modifier fromOwner(){
        require(msg.sender == getOwner());
        _;
    }

    constructor(address _registry)
        public
    {
        require(_registry != 0);
        registry = IRegistry(_registry);
    }

    function addressOf(bytes32 _name)
        internal
        view
        returns(address _addr)
    {
        return registry.addressOf(_name);
    }

    function getOwner()
        public
        view
        returns (address _addr)
    {
        return registry.owner();
    }

    function getRegistry()
        public
        view
        returns (IRegistry _addr)
    {
        return registry;
    }
}

/******* USING ADMIN ***********************

Gives the inherting contract access to:
    .getAdmin(): returns the current address of the admin
    [modifier] .fromAdmin: requires the sender is the admin

*************************************************/
contract UsingAdmin is
    UsingRegistry
{
    constructor(address _registry)
        UsingRegistry(_registry)
        public
    {}

    modifier fromAdmin(){
        require(msg.sender == getAdmin());
        _;
    }
    
    function getAdmin()
        public
        constant
        returns (address _addr)
    {
        return addressOf("ADMIN");
    }
}


/******* USING MONARCHYCONTROLLER **************************

Gives the inherting contract access to:
    .getMonarchyController(): returns current IMC instance
    [modifier] .fromMonarchyController(): requires the sender is current MC.

*************************************************/
// Returned by .getMonarchyController()
interface IMonarchyController {
    function refreshGames() external returns (uint _numGamesEnded, uint _feesSent);
    function startDefinedGame(uint _index) external payable returns (address _game);
    function getFirstStartableIndex() external view returns (uint _index);
    function getNumEndableGames() external view returns (uint _count);
    function getAvailableFees() external view returns (uint _feesAvailable);
    function getInitialPrize(uint _index) external view returns (uint);
    function getIsStartable(uint _index) external view returns (bool);
}

contract UsingMonarchyController is
    UsingRegistry
{
    constructor(address _registry)
        UsingRegistry(_registry)
        public
    {}

    modifier fromMonarchyController(){
        require(msg.sender == address(getMonarchyController()));
        _;
    }

    function getMonarchyController()
        public
        view
        returns (IMonarchyController)
    {
        return IMonarchyController(addressOf("MONARCHY_CONTROLLER"));
    }
}


/******* USING TREASURY **************************

Gives the inherting contract access to:
    .getTreasury(): returns current ITreasury instance
    [modifier] .fromTreasury(): requires the sender is current Treasury

*************************************************/
// Returned by .getTreasury()
interface ITreasury {
    function issueDividend() external returns (uint _profits);
    function profitsSendable() external view returns (uint _profits);
}

contract UsingTreasury is
    UsingRegistry
{
    constructor(address _registry)
        UsingRegistry(_registry)
        public
    {}

    modifier fromTreasury(){
        require(msg.sender == address(getTreasury()));
        _;
    }
    
    function getTreasury()
        public
        view
        returns (ITreasury)
    {
        return ITreasury(addressOf("TREASURY"));
    }
}

/*
    Exposes the following internal methods:
        - _useFromDailyLimit(uint)
        - _setDailyLimit(uint)
        - getDailyLimit()
        - getDailyLimitUsed()
        - getDailyLimitUnused()
*/
contract HasDailyLimit {
    // squeeze all vars into one storage slot.
    struct DailyLimitVars {
        uint112 dailyLimit; // Up to 5e15 * 1e18.
        uint112 usedToday;  // Up to 5e15 * 1e18.
        uint32 lastDay;     // Up to the year 11,000,000 AD
    }
    DailyLimitVars private vars;
    uint constant MAX_ALLOWED = 2**112 - 1;

    constructor(uint _limit) public {
        _setDailyLimit(_limit);
    }

    // Sets the daily limit.
    function _setDailyLimit(uint _limit) internal {
        require(_limit <= MAX_ALLOWED);
        vars.dailyLimit = uint112(_limit);
    }

    // Uses the requested amount if its within limit. Or throws.
    // You should use getDailyLimitRemaining() before calling this.
    function _useFromDailyLimit(uint _amount) internal {
        uint _remaining = updateAndGetRemaining();
        require(_amount <= _remaining);
        vars.usedToday += uint112(_amount);
    }

    // If necessary, resets the day&#39;s usage.
    // Then returns the amount remaining for today.
    function updateAndGetRemaining() private returns (uint _amtRemaining) {
        if (today() > vars.lastDay) {
            vars.usedToday = 0;
            vars.lastDay = today();
        }
        uint112 _usedToday = vars.usedToday;
        uint112 _dailyLimit = vars.dailyLimit;
        // This could be negative if _dailyLimit was reduced.
        return uint(_usedToday >= _dailyLimit ? 0 : _dailyLimit - _usedToday);
    }

    // Returns the current day.
    function today() private view returns (uint32) {
        return uint32(block.timestamp / 1 days);
    }


    /////////////////////////////////////////////////////////////////
    ////////////// PUBLIC VIEWS /////////////////////////////////////
    /////////////////////////////////////////////////////////////////

    function getDailyLimit() public view returns (uint) {
        return uint(vars.dailyLimit);
    }
    function getDailyLimitUsed() public view returns (uint) {
        return uint(today() > vars.lastDay ? 0 : vars.usedToday);
    }
    function getDailyLimitRemaining() public view returns (uint) {
        uint _used = getDailyLimitUsed();
        return uint(_used >= vars.dailyLimit ? 0 : vars.dailyLimit - _used);
    }
}


/**
    This is a simple class that maintains a doubly linked list of
    addresses it has seen. Addresses can be added and removed
    from the set, and a full list of addresses can be obtained.

    Methods:
     - [fromOwner] .add()
     - [fromOwner] .remove()
    Views:
     - .size()
     - .has()
     - .addresses()
*/
contract AddressSet {
    
    struct Entry {  // Doubly linked list
        bool exists;
        address next;
        address prev;
    }
    mapping (address => Entry) public entries;

    address public owner;
    modifier fromOwner() { require(msg.sender==owner); _; }

    // Constructor sets the owner.
    constructor(address _owner)
        public
    {
        owner = _owner;
    }


    /******************************************************/
    /*************** OWNER METHODS ************************/
    /******************************************************/

    function add(address _address)
        fromOwner
        public
        returns (bool _didCreate)
    {
        // Do not allow the adding of HEAD.
        if (_address == address(0)) return;
        Entry storage entry = entries[_address];
        // If already exists, do nothing. Otherwise set it.
        if (entry.exists) return;
        else entry.exists = true;

        // Replace first entry with this one.
        // Before: HEAD <-> X <-> Y
        // After: HEAD <-> THIS <-> X <-> Y
        // do: THIS.NEXT = [0].next; [0].next.prev = THIS; [0].next = THIS; THIS.prev = 0;
        Entry storage HEAD = entries[0x0];
        entry.next = HEAD.next;
        entries[HEAD.next].prev = _address;
        HEAD.next = _address;
        return true;
    }

    function remove(address _address)
        fromOwner
        public
        returns (bool _didExist)
    {
        // Do not allow the removal of HEAD.
        if (_address == address(0)) return;
        Entry storage entry = entries[_address];
        // If it doesn&#39;t exist already, there is nothing to do.
        if (!entry.exists) return;

        // Stitch together next and prev, delete entry.
        // Before: X <-> THIS <-> Y
        // After: X <-> Y
        // do: THIS.next.prev = this.prev; THIS.prev.next = THIS.next;
        entries[entry.prev].next = entry.next;
        entries[entry.next].prev = entry.prev;
        delete entries[_address];
        return true;
    }


    /******************************************************/
    /*************** PUBLIC VIEWS *************************/
    /******************************************************/

    function size()
        public
        view
        returns (uint _size)
    {
        // Loop once to get the total count.
        Entry memory _curEntry = entries[0x0];
        while (_curEntry.next > 0) {
            _curEntry = entries[_curEntry.next];
            _size++;
        }
        return _size;
    }

    function has(address _address)
        public
        view
        returns (bool _exists)
    {
        return entries[_address].exists;
    }

    function addresses()
        public
        view
        returns (address[] _addresses)
    {
        // Populate names and addresses
        uint _size = size();
        _addresses = new address[](_size);
        // Iterate forward through all entries until the end.
        uint _i = 0;
        Entry memory _curEntry = entries[0x0];
        while (_curEntry.next > 0) {
            _addresses[_i] = _curEntry.next;
            _curEntry = entries[_curEntry.next];
            _i++;
        }
        return _addresses;
    }
}

/**
    This is a simple class that maintains a doubly linked list of
    address => uint amounts. Address balances can be added to 
    or removed from via add() and subtract(). All balances can
    be obtain by calling balances(). If an address has a 0 amount,
    it is removed from the Ledger.

    Note: THIS DOES NOT TEST FOR OVERFLOWS, but it&#39;s safe to
          use to track Ether balances.

    Public methods:
      - [fromOwner] add()
      - [fromOwner] subtract()
    Public views:
      - total()
      - size()
      - balanceOf()
      - balances()
      - entries() [to manually iterate]
*/
contract Ledger {
    uint public total;      // Total amount in Ledger

    struct Entry {          // Doubly linked list tracks amount per address
        uint balance;
        address next;
        address prev;
    }
    mapping (address => Entry) public entries;

    address public owner;
    modifier fromOwner() { require(msg.sender==owner); _; }

    // Constructor sets the owner
    constructor(address _owner)
        public
    {
        owner = _owner;
    }


    /******************************************************/
    /*************** OWNER METHODS ************************/
    /******************************************************/

    function add(address _address, uint _amt)
        fromOwner
        public
    {
        if (_address == address(0) || _amt == 0) return;
        Entry storage entry = entries[_address];

        // If new entry, replace first entry with this one.
        if (entry.balance == 0) {
            entry.next = entries[0x0].next;
            entries[entries[0x0].next].prev = _address;
            entries[0x0].next = _address;
        }
        // Update stats.
        total += _amt;
        entry.balance += _amt;
    }

    function subtract(address _address, uint _amt)
        fromOwner
        public
        returns (uint _amtRemoved)
    {
        if (_address == address(0) || _amt == 0) return;
        Entry storage entry = entries[_address];

        uint _maxAmt = entry.balance;
        if (_maxAmt == 0) return;
        
        if (_amt >= _maxAmt) {
            // Subtract the max amount, and delete entry.
            total -= _maxAmt;
            entries[entry.prev].next = entry.next;
            entries[entry.next].prev = entry.prev;
            delete entries[_address];
            return _maxAmt;
        } else {
            // Subtract the amount from entry.
            total -= _amt;
            entry.balance -= _amt;
            return _amt;
        }
    }


    /******************************************************/
    /*************** PUBLIC VIEWS *************************/
    /******************************************************/

    function size()
        public
        view
        returns (uint _size)
    {
        // Loop once to get the total count.
        Entry memory _curEntry = entries[0x0];
        while (_curEntry.next > 0) {
            _curEntry = entries[_curEntry.next];
            _size++;
        }
        return _size;
    }

    function balanceOf(address _address)
        public
        view
        returns (uint _balance)
    {
        return entries[_address].balance;
    }

    function balances()
        public
        view
        returns (address[] _addresses, uint[] _balances)
    {
        // Populate names and addresses
        uint _size = size();
        _addresses = new address[](_size);
        _balances = new uint[](_size);
        uint _i = 0;
        Entry memory _curEntry = entries[0x0];
        while (_curEntry.next > 0) {
            _addresses[_i] = _curEntry.next;
            _balances[_i] = entries[_curEntry.next].balance;
            _curEntry = entries[_curEntry.next];
            _i++;
        }
        return (_addresses, _balances);
    }
}

/**
  A simple class that manages bankroll, and maintains collateral.
  This class only ever sends profits the Treasury. No exceptions.

  - Anybody can add funding (according to whitelist)
  - Anybody can tell profits (balance - (funding + collateral)) to go to Treasury.
  - Anyone can remove their funding, so long as balance >= collateral.
  - Whitelist is managed by getWhitelistOwner() -- typically Admin.

  Exposes the following:
    Public Methods
     - addBankroll
     - removeBankroll
     - sendProfits
    Public Views
     - getCollateral
     - profits
     - profitsSent
     - profitsTotal
     - bankroll
     - bankrollAvailable
     - bankrolledBy
     - bankrollerTable
*/
contract Bankrollable is
    UsingTreasury
{   
    // How much profits have been sent. 
    uint public profitsSent;
    // Ledger keeps track of who has bankrolled us, and for how much
    Ledger public ledger;
    // This is a copy of ledger.total(), to save gas in .bankrollAvailable()
    uint public bankroll;
    // This is the whitelist of who can call .addBankroll()
    AddressSet public whitelist;

    modifier fromWhitelistOwner(){
        require(msg.sender == getWhitelistOwner());
        _;
    }

    event BankrollAdded(uint time, address indexed bankroller, uint amount, uint bankroll);
    event BankrollRemoved(uint time, address indexed bankroller, uint amount, uint bankroll);
    event ProfitsSent(uint time, address indexed treasury, uint amount);
    event AddedToWhitelist(uint time, address indexed addr, address indexed wlOwner);
    event RemovedFromWhitelist(uint time, address indexed addr, address indexed wlOwner);

    // Constructor creates the ledger and whitelist, with self as owner.
    constructor(address _registry)
        UsingTreasury(_registry)
        public
    {
        ledger = new Ledger(this);
        whitelist = new AddressSet(this);
    }


    /*****************************************************/
    /************** WHITELIST MGMT ***********************/
    /*****************************************************/    

    function addToWhitelist(address _addr)
        fromWhitelistOwner
        public
    {
        bool _didAdd = whitelist.add(_addr);
        if (_didAdd) emit AddedToWhitelist(now, _addr, msg.sender);
    }

    function removeFromWhitelist(address _addr)
        fromWhitelistOwner
        public
    {
        bool _didRemove = whitelist.remove(_addr);
        if (_didRemove) emit RemovedFromWhitelist(now, _addr, msg.sender);
    }

    /*****************************************************/
    /************** PUBLIC FUNCTIONS *********************/
    /*****************************************************/

    // Bankrollable contracts should be payable (to receive revenue)
    function () public payable {}

    // Increase funding by whatever value is sent
    function addBankroll()
        public
        payable 
    {
        require(whitelist.size()==0 || whitelist.has(msg.sender));
        ledger.add(msg.sender, msg.value);
        bankroll = ledger.total();
        emit BankrollAdded(now, msg.sender, msg.value, bankroll);
    }

    // Removes up to _amount from Ledger, and sends it to msg.sender._callbackFn
    function removeBankroll(uint _amount, string _callbackFn)
        public
        returns (uint _recalled)
    {
        // cap amount at the balance minus collateral, or nothing at all.
        address _bankroller = msg.sender;
        uint _collateral = getCollateral();
        uint _balance = address(this).balance;
        uint _available = _balance > _collateral ? _balance - _collateral : 0;
        if (_amount > _available) _amount = _available;

        // Try to remove _amount from ledger, get actual _amount removed.
        _amount = ledger.subtract(_bankroller, _amount);
        bankroll = ledger.total();
        if (_amount == 0) return;

        bytes4 _sig = bytes4(keccak256(_callbackFn));
        require(_bankroller.call.value(_amount)(_sig));
        emit BankrollRemoved(now, _bankroller, _amount, bankroll);
        return _amount;
    }

    // Send any excess profits to treasury.
    function sendProfits()
        public
        returns (uint _profits)
    {
        int _p = profits();
        if (_p <= 0) return;
        _profits = uint(_p);
        profitsSent += _profits;
        // Send profits to Treasury
        address _tr = getTreasury();
        require(_tr.call.value(_profits)());
        emit ProfitsSent(now, _tr, _profits);
    }


    /*****************************************************/
    /************** PUBLIC VIEWS *************************/
    /*****************************************************/

    // Function must be overridden by inheritors to ensure collateral is kept.
    function getCollateral()
        public
        view
        returns (uint _amount);

    // Function must be overridden by inheritors to enable whitelist control.
    function getWhitelistOwner()
        public
        view
        returns (address _addr);

    // Profits are the difference between balance and threshold
    function profits()
        public
        view
        returns (int _profits)
    {
        int _balance = int(address(this).balance);
        int _threshold = int(bankroll + getCollateral());
        return _balance - _threshold;
    }

    // How profitable this contract is, overall
    function profitsTotal()
        public
        view
        returns (int _profits)
    {
        return int(profitsSent) + profits();
    }

    // Returns the amount that can currently be bankrolled.
    //   - 0 if balance < collateral
    //   - If profits: full bankroll
    //   - If no profits: remaning bankroll: balance - collateral
    function bankrollAvailable()
        public
        view
        returns (uint _amount)
    {
        uint _balance = address(this).balance;
        uint _bankroll = bankroll;
        uint _collat = getCollateral();
        // Balance is below collateral!
        if (_balance <= _collat) return 0;
        // No profits, but we have a balance over collateral.
        else if (_balance < _collat + _bankroll) return _balance - _collat;
        // Profits. Return only _bankroll
        else return _bankroll;
    }

    function bankrolledBy(address _addr)
        public
        view
        returns (uint _amount)
    {
        return ledger.balanceOf(_addr);
    }

    function bankrollerTable()
        public
        view
        returns (address[], uint[])
    {
        return ledger.balances();
    }
}

/*
  This is a simple class that pays anybody to execute methods on
  other contracts. The reward amounts are configurable by the Admin,
  with some hard limits to prevent the Admin from pilfering. The
  contract has a DailyLimit, so even if the Admin is compromised,
  the contract cannot be drained.

  TaskManager is Bankrollable, meaning it can accept bankroll from 
  the Treasury (and have it recalled).  However, it will never generate
  profits. On rare occasion, new funds will need to be added to ensure
  rewards can be paid.

  This class is divided into sections that pay rewards for a specific
  contract or set of contracts. Any time a new contract is added to
  the system that requires Tasks, this file will be updated and 
  redeployed.
*/
interface _IBankrollable {
    function sendProfits() external returns (uint _profits);
    function profits() external view returns (int _profits);
}
contract TaskManager is
    HasDailyLimit,
    Bankrollable,
    UsingAdmin,
    UsingMonarchyController
{
    uint constant public version = 1;
    uint public totalRewarded;

    // Number of basis points to reward caller.
    // 1 = .01%, 10 = .1%, 100 = 1%. Capped at .1%.
    uint public issueDividendRewardBips;
    // Number of basis points to reward caller.
    // 1 = .01%, 10 = .1%, 100 = 1%. Capped at 1%.
    uint public sendProfitsRewardBips;
    // How much to pay for games to start and end.
    // These values are capped at 1 Ether.
    uint public monarchyStartReward;
    uint public monarchyEndReward;
    
    event Created(uint time);
    event DailyLimitChanged(uint time, address indexed owner, uint newValue);
    // admin events
    event IssueDividendRewardChanged(uint time, address indexed admin, uint newValue);
    event SendProfitsRewardChanged(uint time, address indexed admin, uint newValue);
    event MonarchyRewardsChanged(uint time, address indexed admin, uint startReward, uint endReward);
    // base events
    event TaskError(uint time, address indexed caller, string msg);
    event RewardSuccess(uint time, address indexed caller, uint reward);
    event RewardFailure(uint time, address indexed caller, uint reward, string msg);
    // task events
    event IssueDividendSuccess(uint time, address indexed treasury, uint profitsSent);
    event SendProfitsSuccess(uint time, address indexed bankrollable, uint profitsSent);
    event MonarchyGameStarted(uint time, address indexed addr, uint initialPrize);
    event MonarchyGamesRefreshed(uint time, uint numEnded, uint feesCollected);

    // Construct sets the registry and instantiates inherited classes.
    constructor(address _registry)
        public
        HasDailyLimit(1 ether)
        Bankrollable(_registry)
        UsingAdmin(_registry)
        UsingMonarchyController(_registry)
    {
        emit Created(now);
    }


    ///////////////////////////////////////////////////////////////////
    ////////// OWNER FUNCTIONS ////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////

    function setDailyLimit(uint _amount)
        public
        fromOwner
    {
        _setDailyLimit(_amount);
        emit DailyLimitChanged(now, msg.sender, _amount);
    }


    ///////////////////////////////////////////////////////////////////
    ////////// ADMIN FUNCTIONS ////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////

    function setIssueDividendReward(uint _bips)
        public
        fromAdmin
    {
        require(_bips <= 10);
        issueDividendRewardBips = _bips;
        emit IssueDividendRewardChanged(now, msg.sender, _bips);
    }

    function setSendProfitsReward(uint _bips)
        public
        fromAdmin
    {
        require(_bips <= 100);
        sendProfitsRewardBips = _bips;
        emit SendProfitsRewardChanged(now, msg.sender, _bips);
    }

    function setMonarchyRewards(uint _startReward, uint _endReward)
        public
        fromAdmin
    {
        require(_startReward <= 1 ether);
        require(_endReward <= 1 ether);
        monarchyStartReward = _startReward;
        monarchyEndReward = _endReward;
        emit MonarchyRewardsChanged(now, msg.sender, _startReward, _endReward);
    }


    ///////////////////////////////////////////////////////////////////
    ////////// ISSUE DIVIDEND TASK ////////////////////////////////////
    ///////////////////////////////////////////////////////////////////

    function doIssueDividend()
        public
        returns (uint _reward, uint _profits)
    {
        // get amount of profits
        ITreasury _tr = getTreasury();
        _profits = _tr.profitsSendable();
        // quit if no profits to send.
        if (_profits == 0) {
            _taskError("No profits to send.");
            return;
        }
        // call .issueDividend(), use return value to compute _reward
        _profits = _tr.issueDividend();
        if (_profits == 0) {
            _taskError("No profits were sent.");
            return;
        } else {
            emit IssueDividendSuccess(now, address(_tr), _profits);
        }
        // send reward
        _reward = (_profits * issueDividendRewardBips) / 10000;
        _sendReward(_reward);
    }

    // Returns reward and profits
    function issueDividendReward()
        public
        view
        returns (uint _reward, uint _profits)
    {
        _profits = getTreasury().profitsSendable();
        _reward = _cappedReward((_profits * issueDividendRewardBips) / 10000);
    }


    ///////////////////////////////////////////////////////////////////
    ////////// SEND PROFITS TASKS /////////////////////////////////////
    ///////////////////////////////////////////////////////////////////

    function doSendProfits(address _bankrollable)
        public
        returns (uint _reward, uint _profits)
    {
        // Call .sendProfits(). Look for Treasury balance to change.
        ITreasury _tr = getTreasury();
        uint _oldTrBalance = address(_tr).balance;
        _IBankrollable(_bankrollable).sendProfits();
        uint _newTrBalance = address(_tr).balance;

        // Quit if no profits. Otherwise compute profits.
        if (_newTrBalance <= _oldTrBalance) {
            _taskError("No profits were sent.");
            return;
        } else {
            _profits = _newTrBalance - _oldTrBalance;
            emit SendProfitsSuccess(now, _bankrollable, _profits);
        }
        
        // Cap reward to current balance (or send will fail)
        _reward = (_profits * sendProfitsRewardBips) / 10000;
        _sendReward(_reward);
    }

    // Returns an estimate of profits to send, and reward.
    function sendProfitsReward(address _bankrollable)
        public
        view
        returns (uint _reward, uint _profits)
    {
        int _p = _IBankrollable(_bankrollable).profits();
        if (_p <= 0) return;
        _profits = uint(_p);
        _reward = _cappedReward((_profits * sendProfitsRewardBips) / 10000);
    }


    ///////////////////////////////////////////////////////////////////
    ////////// MONARCHY TASKS /////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////

    // Try to start monarchy game, reward upon success.
    function startMonarchyGame(uint _index)
        public
    {
        // Don&#39;t bother trying if it&#39;s not startable
        IMonarchyController _mc = getMonarchyController();
        if (!_mc.getIsStartable(_index)){
            _taskError("Game is not currently startable.");
            return;
        }

        // Try to start the game. This may fail.
        address _game = _mc.startDefinedGame(_index);
        if (_game == address(0)) {
            _taskError("MonarchyConroller.startDefinedGame() failed.");
            return;
        } else {
            emit MonarchyGameStarted(now, _game, _mc.getInitialPrize(_index));   
        }

        // Reward
        _sendReward(monarchyStartReward);
    }

    // Return the _reward and _index of the first startable MonarchyGame
    function startMonarchyGameReward()
        public
        view
        returns (uint _reward, uint _index)
    {
        IMonarchyController _mc = getMonarchyController();
        _index = _mc.getFirstStartableIndex();
        if (_index > 0) _reward = _cappedReward(monarchyStartReward);
    }


    // Invoke .refreshGames() and pay reward on number of games ended.
    function refreshMonarchyGames()
        public
    {
        // do the call
        uint _numGamesEnded;
        uint _feesCollected;
        (_numGamesEnded, _feesCollected) = getMonarchyController().refreshGames();
        emit MonarchyGamesRefreshed(now, _numGamesEnded, _feesCollected);

        if (_numGamesEnded == 0) {
            _taskError("No games ended.");
        } else {
            _sendReward(_numGamesEnded * monarchyEndReward);   
        }
    }
    
    // Return a reward for each MonarchyGame that will end
    function refreshMonarchyGamesReward()
        public
        view
        returns (uint _reward, uint _numEndable)
    {
        IMonarchyController _mc = getMonarchyController();
        _numEndable = _mc.getNumEndableGames();
        _reward = _cappedReward(_numEndable * monarchyEndReward);
    }


    ///////////////////////////////////////////////////////////////////////
    /////////////////// PRIVATE FUNCTIONS /////////////////////////////////
    ///////////////////////////////////////////////////////////////////////

    // Called when task is unable to execute.
    function _taskError(string _msg) private {
        emit TaskError(now, msg.sender, _msg);
    }

    // Sends a capped amount of _reward to the msg.sender, and emits proper event.
    function _sendReward(uint _reward) private {
        // Limit the reward to balance or dailyLimitRemaining
        uint _amount = _cappedReward(_reward);
        if (_reward > 0 && _amount == 0) {
            emit RewardFailure(now, msg.sender, _amount, "Not enough funds, or daily limit reached.");
            return;
        }

        // Attempt to send it (even if _reward was 0)
        if (msg.sender.call.value(_amount)()) {
            _useFromDailyLimit(_amount);
            totalRewarded += _amount;
            emit RewardSuccess(now, msg.sender, _amount);
        } else {
            emit RewardFailure(now, msg.sender, _amount, "Reward rejected by recipient (out of gas, or revert).");
        }
    }

    // This caps the reward amount to the minimum of (reward, balance, dailyLimitRemaining)
    function _cappedReward(uint _reward) private view returns (uint) {
        uint _balance = address(this).balance;
        uint _remaining = getDailyLimitRemaining();
        if (_reward > _balance) _reward = _balance;
        if (_reward > _remaining) _reward = _remaining;
        return _reward;
    }

    // IMPLEMENT BANKROLLABLE FUNCTIONS
    function getCollateral() public view returns (uint) {}
    function getWhitelistOwner() public view returns (address){ return getAdmin(); }
}