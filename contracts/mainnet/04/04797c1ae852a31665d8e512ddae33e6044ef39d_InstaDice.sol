pragma solidity ^0.4.23;

/******* https://www.pennyether.com **************/

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

/*********************************************************
*********************** INSTADICE ************************
**********************************************************

UI: https://www.pennyether.com

This contract allows for users to wager a limited amount on then
outcome of a random roll between [1, 100]. The user may choose
a number, and if the roll is less than or equal to that number,
they will win a payout that is inversely proportional to the
number they chose (lower numbers pay out more).

When a roll is "finalized", it means the result was determined
and the payout paid to the user if they won. Each time somebody 
rolls, their previous roll is finalized. Roll results are based
on blockhash, and since only the last 256 blockhashes are 
available (who knows why it is so limited...), the user must
finalize within 256 blocks or their roll loses.

Note about randomness:
  Although using blockhash for randomness is not advised,
  it is perfectly acceptable if the results of the block
  are not worth an expected value greater than that of:
    (full block reward - uncle block reward) = ~.625 Eth

  In other words, a miner is better of mining honestly and
  getting a full block reward than trying to game this contract,
  unless the maximum bet is increased to about .625, which
  this contract forbids.
*/
contract InstaDice is
    Bankrollable,
    UsingAdmin
{
    struct User {
        uint32 id;
        uint32 r_id;
        uint32 r_block;
        uint8 r_number;
        uint72 r_payout;
    }

    // These stats are updated on each roll.
    struct Stats {
        uint32 numUsers;
        uint32 numRolls;
        uint96 totalWagered;
        uint96 totalWon;
    }
    
    // Admin controlled settings
    struct Settings {
        uint64 minBet;    //
        uint64 maxBet;    // 
        uint8 minNumber;  // they get ~20x their bet
        uint8 maxNumber;  // they get ~1.01x their bet
        uint16 feeBips;   // each bip is .01%, eg: 100 = 1% fee.
    }

    mapping (address => User) public users;
    Stats stats;
    Settings settings;
    uint8 constant public version = 2;
    
    // Admin events
    event Created(uint time);
    event SettingsChanged(uint time, address indexed admin);

    // Events
    event RollWagered(uint time, uint32 indexed id, address indexed user, uint bet, uint8 number, uint payout);
    event RollRefunded(uint time, address indexed user, string msg, uint bet, uint8 number);
    event RollFinalized(uint time, uint32 indexed id, address indexed user, uint8 result, uint payout);
    event PayoutError(uint time, string msg);

    constructor(address _registry)
        Bankrollable(_registry)
        UsingAdmin(_registry)
        public
    {
        // populate with prev contracts&#39; stats
        stats.totalWagered = 3650000000000000000;
        stats.totalWon = 3537855001272912000;
        stats.numRolls = 123;
        stats.numUsers = 19;

        // default settings
        settings.maxBet = .3 ether;
        settings.minBet = .001 ether;
        settings.minNumber = 5;
        settings.maxNumber = 98;
        settings.feeBips = 100;
        emit Created(now);
    }


    ///////////////////////////////////////////////////
    ////// ADMIN FUNCTIONS ////////////////////////////
    ///////////////////////////////////////////////////

    // Changes the settings
    function changeSettings(
        uint64 _minBet,
        uint64 _maxBet,
        uint8 _minNumber,
        uint8 _maxNumber,
        uint16 _feeBips
    )
        public
        fromAdmin
    {
        require(_minBet <= _maxBet);    // makes sense
        require(_maxBet <= .625 ether); // capped at (block reward - uncle reward)
        require(_minNumber >= 1);       // not advisible, but why not
        require(_maxNumber <= 99);      // over 100 makes no sense
        require(_feeBips <= 500);       // max of 5%
        settings.minBet = _minBet;
        settings.maxBet = _maxBet;
        settings.minNumber = _minNumber;
        settings.maxNumber = _maxNumber;
        settings.feeBips = _feeBips;
        emit SettingsChanged(now, msg.sender);
    }
    

    ///////////////////////////////////////////////////
    ////// PUBLIC FUNCTIONS ///////////////////////////
    ///////////////////////////////////////////////////

    // Resolves the last roll for the user.
    // Then creates a new roll.
    // Gas:
    //    Total: 56k (new), or up to 44k (repeat)
    //    Overhead: 36k
    //       22k: tx overhead
    //        2k: SLOAD
    //        3k: execution
    //        2k: curMaxBet()
    //        5k: update stats
    //        2k: RollWagered event
    //    New User: 20k
    //       20k: create user
    //    Repeat User: 8k, 16k
    //        5k: update user
    //        3k: RollFinalized event
    //        8k: pay last roll
    function roll(uint8 _number)
        public
        payable
        returns (bool _success)
    {
        // Ensure bet and number are valid.
        if (!_validateBetOrRefund(_number)) return;

        // Ensure one bet per block.
        User memory _prevUser = users[msg.sender];
        if (_prevUser.r_block == uint32(block.number)){
            _errorAndRefund("Only one bet per block allowed.", msg.value, _number);
            return false;
        }

        // Create and write new user data before finalizing last roll
        Stats memory _stats = stats;
        User memory _newUser = User({
            id: _prevUser.id == 0 ? _stats.numUsers + 1 : _prevUser.id,
            r_id: _stats.numRolls + 1,
            r_block: uint32(block.number),
            r_number: _number,
            r_payout: computePayout(msg.value, _number)
        });
        users[msg.sender] = _newUser;

        // Finalize last roll, if there was one.
        // This will throw if user won, but we couldn&#39;t pay.
        if (_prevUser.r_block != 0) _finalizePreviousRoll(_prevUser, _stats);

        // Increment additional stats data
        _stats.numUsers = _prevUser.id == 0 ? _stats.numUsers + 1 : _stats.numUsers;
        _stats.numRolls = stats.numRolls + 1;
        _stats.totalWagered = stats.totalWagered + uint96(msg.value);
        stats = _stats;

        // Save user in one write.
        emit RollWagered(now, _newUser.r_id, msg.sender, msg.value, _newUser.r_number, _newUser.r_payout);
        return true;
    }

    // Finalizes the previous roll and pays out user if they won.
    // Gas: 45k
    //   21k: tx overhead
    //    1k: SLOADs
    //    2k: execution
    //    8k: send winnings
    //    5k: update user
    //    5k: update stats
    //    3k: RollFinalized event
    function payoutPreviousRoll()
        public
        returns (bool _success)
    {
        // Load last roll in one SLOAD.
        User memory _prevUser = users[msg.sender];
        // Error if on same block.
        if (_prevUser.r_block == uint32(block.number)){
            emit PayoutError(now, "Cannot payout roll on the same block");
            return false;
        }
        // Error if nothing to payout.
        if (_prevUser.r_block == 0){
            emit PayoutError(now, "No roll to pay out.");
            return false;
        }

        // Clear last roll data
        User storage _user = users[msg.sender];
        _user.r_id = 0;
        _user.r_block = 0;
        _user.r_number = 0;
        _user.r_payout = 0;

        // Finalize previous roll and update stats
        Stats memory _stats = stats;
        _finalizePreviousRoll(_prevUser, _stats);
        stats.totalWon = _stats.totalWon;
        return true;
    }


    ////////////////////////////////////////////////////////
    ////// PRIVATE FUNCTIONS ///////////////////////////////
    ////////////////////////////////////////////////////////

    // Validates the bet, or refunds the user.
    function _validateBetOrRefund(uint8 _number)
        private
        returns (bool _isValid)
    {
        Settings memory _settings = settings;
        if (_number < _settings.minNumber) {
            _errorAndRefund("Roll number too small.", msg.value, _number);
            return false;
        }
        if (_number > _settings.maxNumber){
            _errorAndRefund("Roll number too large.", msg.value, _number);
            return false;
        }
        if (msg.value < _settings.minBet){
            _errorAndRefund("Bet too small.", msg.value, _number);
            return false;
        }
        if (msg.value > _settings.maxBet){
            _errorAndRefund("Bet too large.", msg.value, _number);
            return false;
        }
        if (msg.value > curMaxBet()){
            _errorAndRefund("May be unable to payout on a win.", msg.value, _number);
            return false;
        }
        return true;
    }

    // Finalizes the previous roll for the _user.
    // This will modify _stats, but not _user.
    // Throws if unable to pay user on a win.
    function _finalizePreviousRoll(User memory _user, Stats memory _stats)
        private
    {
        assert(_user.r_block != uint32(block.number));
        assert(_user.r_block != 0);
        
        // compute result and isWinner
        uint8 _result = computeResult(_user.r_block, _user.r_id);
        bool _isWinner = _result <= _user.r_number;
        if (_isWinner) {
            require(msg.sender.call.value(_user.r_payout)());
            _stats.totalWon += _user.r_payout;
        }
        // they won and we paid, or they lost. roll is finalized.
        emit RollFinalized(now, _user.r_id, msg.sender, _result, _isWinner ? _user.r_payout : 0);
    }

    // Only called from above.
    // Refunds user the full value, and logs an error
    function _errorAndRefund(string _msg, uint _bet, uint8 _number)
        private
    {
        require(msg.sender.call.value(msg.value)());
        emit RollRefunded(now, msg.sender, _msg, _bet, _number);
    }


    ///////////////////////////////////////////////////
    ////// PUBLIC VIEWS ///////////////////////////////
    ///////////////////////////////////////////////////

    // IMPLEMENTS: Bankrollable.getCollateral()
    // This contract has no collateral, as it pays out in near realtime.
    function getCollateral() public view returns (uint _amount) {
        return 0;
    }

    // IMPLEMENTS: Bankrollable.getWhitelistOwner()
    // Ensures contract always has at least bankroll + totalCredits.
    function getWhitelistOwner() public view returns (address _wlOwner)
    {
        return getAdmin();
    }

    // Returns the largest bet such that we could pay out 10 maximum wins.
    // The likelihood that 10 maximum bets (with highest payouts) are won
    //  within a short period of time are extremely low.
    function curMaxBet() public view returns (uint _amount) {
        // Return largest bet such that 10*bet*payout = bankrollable()
        uint _maxPayout = 10 * 100 / uint(settings.minNumber);
        return bankrollAvailable() / _maxPayout;
    }

    // Return the less of settings.maxBet and curMaxBet()
    function effectiveMaxBet() public view returns (uint _amount) {
        uint _curMax = curMaxBet();
        return _curMax > settings.maxBet ? settings.maxBet : _curMax;
    }

    // Computes the payout amount for the current _feeBips
    function computePayout(uint _bet, uint _number)
        public
        view
        returns (uint72 _wei)
    {
        uint _feeBips = settings.feeBips;   // Cast to uint, makes below math cheaper.
        uint _bigBet = _bet * 1e32;         // Will not overflow unless _bet >> ~1e40
        uint _bigPayout = (_bigBet * 100) / _number;
        uint _bigFee = (_bigPayout * _feeBips) / 10000;
        return uint72( (_bigPayout - _bigFee) / 1e32 );
    }

    // Returns a number between 1 and 100 (inclusive)
    // If blockNumber is too far past, returns 101.
    function computeResult(uint32 _blockNumber, uint32 _id)
        public
        view
        returns (uint8 _result)
    {
        bytes32 _blockHash = blockhash(_blockNumber);
        if (_blockHash == 0) { return 101; }
        return uint8(uint(keccak256(_blockHash, _id)) % 100 + 1);
    }

    // Expose all Stats /////////////////////////////////
    function numUsers() public view returns (uint32) {
        return stats.numUsers;
    }
    function numRolls() public view returns (uint32) {
        return stats.numRolls;
    }
    function totalWagered() public view returns (uint) {
        return stats.totalWagered;
    }
    function totalWon() public view returns (uint) {
        return stats.totalWon;
    }
    //////////////////////////////////////////////////////

    // Expose all Settings ///////////////////////////////
    function minBet() public view returns (uint) {
        return settings.minBet;
    }
    function maxBet() public view returns (uint) {
        return settings.maxBet;
    }
    function minNumber() public view returns (uint8) {
        return settings.minNumber;
    }
    function maxNumber() public view returns (uint8) {
        return settings.maxNumber;
    }
    function feeBips() public view returns (uint16) {
        return settings.feeBips;
    }
    //////////////////////////////////////////////////////

}