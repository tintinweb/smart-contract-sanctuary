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

/******* USING MONARCHYFACTORY **************************

Gives the inherting contract access to:
    .getPaf(): returns current IPaf instance
    [modifier] .fromPaf(): requires the sender is current Paf.

*************************************************/
// Returned by .getMonarchyFactory()
interface IMonarchyFactory {
    function lastCreatedGame() external view returns (address _game);
    function getCollector() external view returns (address _collector);
}

contract UsingMonarchyFactory is
    UsingRegistry
{
    constructor(address _registry)
        UsingRegistry(_registry)
        public
    {}

    modifier fromMonarchyFactory(){ 
        require(msg.sender == address(getMonarchyFactory()));
        _;
    }

    function getMonarchyFactory()
        public
        view
        returns (IMonarchyFactory)
    {
        return IMonarchyFactory(addressOf("MONARCHY_FACTORY"));
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

// An interface to MonarchyGame instances.
interface IMonarchyGame {
    function sendPrize(uint _gasLimit) external returns (bool _success, uint _prizeSent);
    function sendFees() external returns (uint _feesSent);
    function prize() external view returns(uint);
    function numOverthrows() external view returns(uint);
    function fees() external view returns (uint _fees);
    function monarch() external view returns (address _addr);
    function isEnded() external view returns (bool _bool);
    function isPaid() external view returns (bool _bool);
}

/*

  MonarchyController manages a list of PredefinedGames.
  PredefinedGames&#39; parameters are definable by the Admin.
  These gamess can be started, ended, or refreshed by anyone.

  Starting games uses the funds in this contract, unless called via
  .startDefinedGameManually(), in which case it uses the funds sent.

  All revenues of any started games will come back to this contract.

  Since this contract inherits Bankrollable, it is able to be funded
  via the Registry (or by anyone whitelisted). Profits will go to the
  Treasury, and can be triggered by anyone.

*/
contract MonarchyController is
    HasDailyLimit,
    Bankrollable,
    UsingAdmin,
    UsingMonarchyFactory
{
    uint constant public version = 1;

    // just some accounting/stats stuff to keep track of
    uint public totalFees;
    uint public totalPrizes;
    uint public totalOverthrows;
    IMonarchyGame[] public endedGames;

    // An admin-controlled index of available games.
    // Note: Index starts at 1, and is limited to 20.
    uint public numDefinedGames;
    mapping (uint => DefinedGame) public definedGames;
    struct DefinedGame {
        IMonarchyGame game;     // address of ongoing game (or 0)
        bool isEnabled;         // if true, can be started
        string summary;         // definable via editDefinedGame
        uint initialPrize;      // definable via editDefinedGame
        uint fee;               // definable via editDefinedGame
        int prizeIncr;          // definable via editDefinedGame
        uint reignBlocks;       // definable via editDefinedGame
        uint initialBlocks;     // definable via editDefinedGame
    }

    event Created(uint time);
    event DailyLimitChanged(uint time, address indexed owner, uint newValue);
    event Error(uint time, string msg);
    event DefinedGameEdited(uint time, uint index);
    event DefinedGameEnabled(uint time, uint index, bool isEnabled);
    event DefinedGameFailedCreation(uint time, uint index);
    event GameStarted(uint time, uint indexed index, address indexed addr, uint initialPrize);
    event GameEnded(uint time, uint indexed index, address indexed addr, address indexed winner);
    event FeesCollected(uint time, uint amount);


    constructor(address _registry) 
        HasDailyLimit(10 ether)
        Bankrollable(_registry)
        UsingAdmin(_registry)
        UsingMonarchyFactory(_registry)
        public
    {
        emit Created(now);
    }

    /*************************************************************/
    /******** OWNER FUNCTIONS ************************************/
    /*************************************************************/

    function setDailyLimit(uint _amount)
        public
        fromOwner
    {
        _setDailyLimit(_amount);
        emit DailyLimitChanged(now, msg.sender, _amount);
    }


    /*************************************************************/
    /******** ADMIN FUNCTIONS ************************************/
    /*************************************************************/

    // allows admin to edit or add an available game
    function editDefinedGame(
        uint _index,
        string _summary,
        uint _initialPrize,
        uint _fee,
        int _prizeIncr,
        uint _reignBlocks,
        uint _initialBlocks
    )
        public
        fromAdmin
        returns (bool _success)
    {
        if (_index-1 > numDefinedGames || _index > 20) {
            emit Error(now, "Index out of bounds.");
            return;
        }

        if (_index-1 == numDefinedGames) numDefinedGames++;
        definedGames[_index].summary = _summary;
        definedGames[_index].initialPrize = _initialPrize;
        definedGames[_index].fee = _fee;
        definedGames[_index].prizeIncr = _prizeIncr;
        definedGames[_index].reignBlocks = _reignBlocks;
        definedGames[_index].initialBlocks = _initialBlocks;
        emit DefinedGameEdited(now, _index);
        return true;
    }

    function enableDefinedGame(uint _index, bool _bool)
        public
        fromAdmin
        returns (bool _success)
    {
        if (_index-1 >= numDefinedGames) {
            emit Error(now, "Index out of bounds.");
            return;
        }
        definedGames[_index].isEnabled = _bool;
        emit DefinedGameEnabled(now, _index, _bool);
        return true;
    }


    /*************************************************************/
    /******* PUBLIC FUNCTIONS ************************************/
    /*************************************************************/

    function () public payable {
         totalFees += msg.value;
    }

    // This is called by anyone when a new MonarchyGame should be started.
    // In reality will only be called by TaskManager.
    //
    // Errors if:
    //      - isEnabled is false (or doesnt exist)
    //      - game is already started
    //      - not enough funds
    //      - PAF.getCollector() points to another address
    //      - unable to create game
    function startDefinedGame(uint _index)
        public
        returns (address _game)
    {
        DefinedGame memory dGame = definedGames[_index];
        if (_index-1 >= numDefinedGames) {
            _error("Index out of bounds.");
            return;
        }
        if (dGame.isEnabled == false) {
            _error("DefinedGame is not enabled.");
            return;
        }
        if (dGame.game != IMonarchyGame(0)) {
            _error("Game is already started.");
            return;
        }
        if (address(this).balance < dGame.initialPrize) {
            _error("Not enough funds to start this game.");
            return;
        }
        if (getDailyLimitRemaining() < dGame.initialPrize) {
            _error("Starting game would exceed daily limit.");
            return;
        }

        // Ensure that if this game is started, revenue comes back to this contract.
        IMonarchyFactory _mf = getMonarchyFactory();
        if (_mf.getCollector() != address(this)){
            _error("MonarchyFactory.getCollector() points to a different contract.");
            return;
        }

        // Try to create game via factory.
        bool _success = address(_mf).call.value(dGame.initialPrize)(
            bytes4(keccak256("createGame(uint256,uint256,int256,uint256,uint256)")),
            dGame.initialPrize,
            dGame.fee,
            dGame.prizeIncr,
            dGame.reignBlocks,
            dGame.initialBlocks
        );
        if (!_success) {
            emit DefinedGameFailedCreation(now, _index);
            _error("MonarchyFactory could not create game (invalid params?)");
            return;
        }

        // Get the game, add it to definedGames, and return.
        _useFromDailyLimit(dGame.initialPrize);
        _game = _mf.lastCreatedGame();
        definedGames[_index].game = IMonarchyGame(_game);
        emit GameStarted(now, _index, _game, dGame.initialPrize);
        return _game;
    }
        // Emits an error with a given message
        function _error(string _msg)
            private
        {
            emit Error(now, _msg);
        }

    function startDefinedGameManually(uint _index)
        public
        payable
        returns (address _game)
    {
        // refund if invalid value sent.
        DefinedGame memory dGame = definedGames[_index];
        if (msg.value != dGame.initialPrize) {
            _error("Value sent does not match initialPrize.");
            require(msg.sender.call.value(msg.value)());
            return;
        }

        // refund if .startDefinedGame fails
        _game = startDefinedGame(_index);
        if (_game == address(0)) {
            require(msg.sender.call.value(msg.value)());
        }
    }

    // Looks at all active defined games and:
    //  - tells each game to send fees to collector (us)
    //  - if ended: tries to pay winner, moves to endedGames
    function refreshGames()
        public
        returns (uint _numGamesEnded, uint _feesCollected)
    {
        for (uint _i = 1; _i <= numDefinedGames; _i++) {
            IMonarchyGame _game = definedGames[_i].game;
            if (_game == IMonarchyGame(0)) continue;

            // redeem the fees
            uint _fees = _game.sendFees();
            _feesCollected += _fees;

            // attempt to pay winner, update stats, and set game to empty.
            if (_game.isEnded()) {
                // paying the winner can error if the winner uses too much gas
                // in that case, they can call .sendPrize() themselves later.
                if (!_game.isPaid()) _game.sendPrize(2300);
                
                // update stats
                totalPrizes += _game.prize();
                totalOverthrows += _game.numOverthrows();

                // clear game, move to endedGames, update return
                definedGames[_i].game = IMonarchyGame(0);
                endedGames.push(_game);
                _numGamesEnded++;

                emit GameEnded(now, _i, address(_game), _game.monarch());
            }
        }
        if (_feesCollected > 0) emit FeesCollected(now, _feesCollected);
        return (_numGamesEnded, _feesCollected);
    }


    /*************************************************************/
    /*********** PUBLIC VIEWS ************************************/
    /*************************************************************/
    // IMPLEMENTS: Bankrollable.getCollateral()
    function getCollateral() public view returns (uint) { return 0; }
    function getWhitelistOwner() public view returns (address){ return getAdmin(); }

    function numEndedGames()
        public
        view
        returns (uint)
    {
        return endedGames.length;
    }

    function numActiveGames()
        public
        view
        returns (uint _count)
    {
        for (uint _i = 1; _i <= numDefinedGames; _i++) {
            if (definedGames[_i].game != IMonarchyGame(0)) _count++;
        }
    }

    function getNumEndableGames()
        public
        view
        returns (uint _count)
    {
        for (uint _i = 1; _i <= numDefinedGames; _i++) {
            IMonarchyGame _game = definedGames[_i].game;
            if (_game == IMonarchyGame(0)) continue;
            if (_game.isEnded()) _count++;
        }
        return _count;
    }

    function getFirstStartableIndex()
        public
        view
        returns (uint _index)
    {
        for (uint _i = 1; _i <= numDefinedGames; _i++) {
            if (getIsStartable(_i)) return _i;
        }
    }

    // Gets total amount of fees that are redeemable if refreshGames() is called.
    function getAvailableFees()
        public
        view
        returns (uint _feesAvailable)
    {
        for (uint _i = 1; _i <= numDefinedGames; _i++) {
            if (definedGames[_i].game == IMonarchyGame(0)) continue;
            _feesAvailable += definedGames[_i].game.fees();
        }
        return _feesAvailable;
    }

    function recentlyEndedGames(uint _num)
        public
        view
        returns (address[] _addresses)
    {
        // set _num to Min(_num, _len), initialize the array
        uint _len = endedGames.length;
        if (_num > _len) _num = _len;
        _addresses = new address[](_num);

        // Loop _num times, adding from end of endedGames.
        uint _i = 1;
        while (_i <= _num) {
            _addresses[_i - 1] = endedGames[_len - _i];
            _i++;
        }
    }

    /******** Shorthand access to definedGames **************************/
    function getGame(uint _index)
        public
        view
        returns (address)
    {
        return address(definedGames[_index].game);
    }

    function getIsEnabled(uint _index)
        public
        view
        returns (bool)
    {
        return definedGames[_index].isEnabled;
    }

    function getInitialPrize(uint _index)
        public
        view
        returns (uint)
    {
        return definedGames[_index].initialPrize;
    }

    function getIsStartable(uint _index)
        public
        view
        returns (bool _isStartable)
    {
        DefinedGame memory dGame = definedGames[_index];
        if (_index >= numDefinedGames) return;
        if (dGame.isEnabled == false) return;
        if (dGame.game != IMonarchyGame(0)) return;
        if (dGame.initialPrize > address(this).balance) return;
        if (dGame.initialPrize > getDailyLimitRemaining()) return;
        return true;
    }
    /******** Shorthand access to definedGames **************************/
}