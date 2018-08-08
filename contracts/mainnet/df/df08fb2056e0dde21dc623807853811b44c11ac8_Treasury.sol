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

/*
    This is an abstract contract, inherited by Treasury, that manages
    creating, cancelling, and executing admin requests that control
    capital. It provides transparency, governence, and security.

    In the future, the Admin account can be set to be a DAO.
    
    A Request:
        - can only be created by Admin
        - can be cancelled by Admin, if not yet executed
        - can be executed after WAITING_TIME (1 week)
        - cannot be executed after TIMEOUT_TIME (2 weeks)
        - contains a type, target, and value
        - when executed, calls corresponding `execute${type}()` method
*/
contract Requestable is
    UsingAdmin 
{
    uint32 public constant WAITING_TIME = 60*60*24*7;   // 1 week
    uint32 public constant TIMEOUT_TIME = 60*60*24*14;  // 2 weeks
    uint32 public constant MAX_PENDING_REQUESTS = 10;

    // Requests.
    enum RequestType {SendCapital, RecallCapital, RaiseCapital, DistributeCapital}
    struct Request {
        // Params to handle state and history.
        uint32 id;
        uint8 typeId;
        uint32 dateCreated;
        uint32 dateCancelled;
        uint32 dateExecuted;
        string createdMsg;
        string cancelledMsg;
        string executedMsg;
        bool executedSuccessfully;
        // Params for execution.
        address target;
        uint value;
    }
    mapping (uint32 => Request) public requests;
    uint32 public curRequestId;
    uint32[] public completedRequestIds;
    uint32[] public cancelledRequestIds;
    uint32[] public pendingRequestIds;

    // Events.
    event RequestCreated(uint time, uint indexed id, uint indexed typeId, address indexed target, uint value, string msg);
    event RequestCancelled(uint time, uint indexed id, uint indexed typeId, address indexed target, string msg);
    event RequestExecuted(uint time, uint indexed id, uint indexed typeId, address indexed target, bool success, string msg);

    constructor(address _registry)
        UsingAdmin(_registry)
        public
    { }

    // Creates a request, assigning it the next ID.
    // Throws if there are already 8 pending requests.
    function createRequest(uint _typeId, address _target, uint _value, string _msg)
        public
        fromAdmin
    {
        uint32 _id = ++curRequestId;
        requests[_id].id = _id;
        requests[_id].typeId = uint8(RequestType(_typeId));
        requests[_id].dateCreated = uint32(now);
        requests[_id].createdMsg = _msg;
        requests[_id].target = _target;
        requests[_id].value = _value;
        _addPendingRequestId(_id);
        emit RequestCreated(now, _id, _typeId, _target, _value, _msg);
    }

    // Cancels a request.
    // Throws if already cancelled or executed.
    function cancelRequest(uint32 _id, string _msg)
        public
        fromAdmin
    {
        // Require Request exists, is not cancelled, is not executed.
        Request storage r = requests[_id];
        require(r.id != 0 && r.dateCancelled == 0 && r.dateExecuted == 0);
        r.dateCancelled = uint32(now);
        r.cancelledMsg = _msg;
        _removePendingRequestId(_id);
        cancelledRequestIds.push(_id);
        emit RequestCancelled(now, r.id, r.typeId, r.target, _msg);
    }

    // Executes (or times out) a request if it is not already cancelled or executed.
    // Note: This may revert if the executeFn() reverts. It&#39;ll time-out eventually.
    function executeRequest(uint32 _id)
        public
    {
        // Require Request exists, is not cancelled, is not executed.
        // Also require is past WAITING_TIME since creation.
        Request storage r = requests[_id];
        require(r.id != 0 && r.dateCancelled == 0 && r.dateExecuted == 0);
        require(uint32(now) > r.dateCreated + WAITING_TIME);
        
        // If request timed out, cancel it.
        if (uint32(now) > r.dateCreated + TIMEOUT_TIME) {
            cancelRequest(_id, "Request timed out.");
            return;
        }
                
        // Execute concrete method after setting as executed.
        r.dateExecuted = uint32(now);
        string memory _msg;
        bool _success;
        RequestType _type = RequestType(r.typeId);
        if (_type == RequestType.SendCapital) {
            (_success, _msg) = executeSendCapital(r.target, r.value);
        } else if (_type == RequestType.RecallCapital) {
            (_success, _msg) = executeRecallCapital(r.target, r.value);
        } else if (_type == RequestType.RaiseCapital) {
            (_success, _msg) = executeRaiseCapital(r.value);
        } else if (_type == RequestType.DistributeCapital) {
            (_success, _msg) = executeDistributeCapital(r.value);
        }

        // Save results, and emit.
        r.executedSuccessfully = _success;
        r.executedMsg = _msg;
        _removePendingRequestId(_id);
        completedRequestIds.push(_id);
        emit RequestExecuted(now, r.id, r.typeId, r.target, _success, _msg);
    }

    // Pushes id onto the array, throws if too many.
    function _addPendingRequestId(uint32 _id)
        private
    {
        require(pendingRequestIds.length != MAX_PENDING_REQUESTS);
        pendingRequestIds.push(_id);
    }

    // Removes id from array, reduces array length by one.
    // Throws if not found.
    function _removePendingRequestId(uint32 _id)
        private
    {
        // Find this id in the array, or throw.
        uint _len = pendingRequestIds.length;
        uint _foundIndex = MAX_PENDING_REQUESTS;
        for (uint _i = 0; _i < _len; _i++) {
            if (pendingRequestIds[_i] == _id) {
                _foundIndex = _i;
                break;
            }
        }
        require(_foundIndex != MAX_PENDING_REQUESTS);

        // Swap last element to this index, then delete last element.
        pendingRequestIds[_foundIndex] = pendingRequestIds[_len-1];
        pendingRequestIds.length--;
    }

    // These methods must be implemented by Treasury /////////////////
    function executeSendCapital(address _target, uint _value)
        internal returns (bool _success, string _msg);

    function executeRecallCapital(address _target, uint _value)
        internal returns (bool _success, string _msg);

    function executeRaiseCapital(uint _value)
        internal returns (bool _success, string _msg);

    function executeDistributeCapital(uint _value)
        internal returns (bool _success, string _msg);
    //////////////////////////////////////////////////////////////////

    // View that returns a Request as a valid tuple.
    // Sorry for the formatting, but it&#39;s a waste of lines otherwise.
    function getRequest(uint32 _requestId) public view returns (
        uint32 _id, uint8 _typeId, address _target, uint _value,
        bool _executedSuccessfully,
        uint32 _dateCreated, uint32 _dateCancelled, uint32 _dateExecuted,
        string _createdMsg, string _cancelledMsg, string _executedMsg       
    ) {
        Request memory r = requests[_requestId];
        return (
            r.id, r.typeId, r.target, r.value,
            r.executedSuccessfully,
            r.dateCreated, r.dateCancelled, r.dateExecuted,
            r.createdMsg, r.cancelledMsg, r.executedMsg
        );
    }

    function isRequestExecutable(uint32 _requestId)
        public
        view
        returns (bool _isExecutable)
    {
        Request memory r = requests[_requestId];
        _isExecutable = (r.id>0 && r.dateCancelled==0 && r.dateExecuted==0);
        _isExecutable = _isExecutable && (uint32(now) > r.dateCreated + WAITING_TIME);
        return _isExecutable;
    }

    // Return the lengths of arrays.
    function numPendingRequests() public view returns (uint _num){
        return pendingRequestIds.length;
    }
    function numCompletedRequests() public view returns (uint _num){
        return completedRequestIds.length;
    }
    function numCancelledRequests() public view returns (uint _num){
        return cancelledRequestIds.length;
    }
}

/*

UI: https://www.pennyether.com/status/treasury

The Treasury manages 2 balances:

    * capital: Ether that can be sent to bankrollable contracts.
        - Is controlled via `Requester` governance, by the Admin (which is mutable)
            - Capital received by Comptroller is considered "capitalRaised".
            - A target amount can be set: "capitalRaisedTarget".
            - Comptroller will sell Tokens to reach capitalRaisedTarget.
        - Can be sent to Bankrollable contracts.
        - Can be recalled from Bankrollable contracts.
        - Allocation in-total and per-contract is available.

    * profits: Ether received via fallback fn. Can be sent to Token at any time.
        - Are received via fallback function, typically by bankrolled contracts.
        - Can be sent to Token at any time, by anyone, via .issueDividend()

All Ether entering and leaving Treasury is allocated to one of the three balances.
Thus, the balance of Treasury will always equal: capital + profits.

Roles:
    Owner:       can set Comptroller and Token addresses, once.
    Comptroller: can add and remove "raised" capital
    Admin:       can trigger requests.
    Token:       receives profits via .issueDividend().
    Anybody:     can call .issueDividend()
                 can call .addCapital()

*/
// Allows Treasury to add/remove capital to/from Bankrollable instances.
interface _ITrBankrollable {
    function removeBankroll(uint _amount, string _callbackFn) external;
    function addBankroll() external payable;
}
interface _ITrComptroller {
    function treasury() external view returns (address);
    function token() external view returns (address);
    function wasSaleEnded() external view returns (bool);
}

contract Treasury is
    Requestable
{
    // Address that can initComptroller
    address public owner;
    // Capital sent from this address is considered "capitalRaised"
    // This also contains the token that dividends will be sent to.
    _ITrComptroller public comptroller;

    // Balances
    uint public capital;  // Ether held as capital. Sendable/Recallable via Requests
    uint public profits;  // Ether received via fallback fn. Distributable only to Token.
    
    // Capital Management
    uint public capitalRaised;        // The amount of capital raised from Comptroller.
    uint public capitalRaisedTarget;  // The target amount of capitalRaised.
    Ledger public capitalLedger;      // Tracks capital allocated per address

    // Stats
    uint public profitsSent;          // Total profits ever sent.
    uint public profitsTotal;         // Total profits ever received.

    // EVENTS
    event Created(uint time);
    // Admin triggered events
    event ComptrollerSet(uint time, address comptroller, address token);
    // capital-related events
    event CapitalAdded(uint time, address indexed sender, uint amount);
    event CapitalRemoved(uint time, address indexed recipient, uint amount);
    event CapitalRaised(uint time, uint amount);
    // profit-related events
    event ProfitsReceived(uint time, address indexed sender, uint amount);
    // request-related events
    event ExecutedSendCapital(uint time, address indexed bankrollable, uint amount);
    event ExecutedRecallCapital(uint time, address indexed bankrollable, uint amount);
    event ExecutedRaiseCapital(uint time, uint amount);
    event ExecutedDistributeCapital(uint time, uint amount);
    // dividend events
    event DividendSuccess(uint time, address token, uint amount);
    event DividendFailure(uint time, string msg);

    // `Requester` provides .fromAdmin() and requires implementation of:
    //   - executeSendCapital
    //   - executeRecallCapital
    //   - executeRaiseCapital
    constructor(address _registry, address _owner)
        Requestable(_registry)
        public
    {
        owner = _owner;
        capitalLedger = new Ledger(this);
        emit Created(now);
    }


    /*************************************************************/
    /*************** OWNER FUNCTIONS *****************************/
    /*************************************************************/

    // Callable once to set the Comptroller address
    function initComptroller(_ITrComptroller _comptroller)
        public
    {
        // only owner can call this.
        require(msg.sender == owner);
        // comptroller must not already be set.
        require(address(comptroller) == address(0));
        // comptroller&#39;s treasury must point to this.
        require(_comptroller.treasury() == address(this));
        comptroller = _comptroller;
        emit ComptrollerSet(now, _comptroller, comptroller.token());
    }


    /*************************************************************/
    /******* PROFITS AND DIVIDENDS *******************************/
    /*************************************************************/

    // Can receive Ether from anyone. Typically Bankrollable contracts&#39; profits.
    function () public payable {
        profits += msg.value;
        profitsTotal += msg.value;
        emit ProfitsReceived(now, msg.sender, msg.value);
    }

    // Sends profits to Token
    function issueDividend()
        public
        returns (uint _profits)
    {
        // Ensure token is set.
        if (address(comptroller) == address(0)) {
            emit DividendFailure(now, "Comptroller not yet set.");
            return;
        }
        // Ensure the CrowdSale is completed
        if (comptroller.wasSaleEnded() == false) {
            emit DividendFailure(now, "CrowdSale not yet completed.");
            return;
        }
        // Load _profits to memory (saves gas), and ensure there are profits.
        _profits = profits;
        if (_profits <= 0) {
            emit DividendFailure(now, "No profits to send.");
            return;
        }

        // Set profits to 0, and send to Token
        address _token = comptroller.token();
        profits = 0;
        profitsSent += _profits;
        require(_token.call.value(_profits)());
        emit DividendSuccess(now, _token, _profits);
    }


    /*************************************************************/
    /*************** ADDING CAPITAL ******************************/
    /*************************************************************/ 

    // Anyone can add capital at any time.
    // If it comes from Comptroller, it counts as capitalRaised.
    function addCapital()
        public
        payable
    {
        capital += msg.value;
        if (msg.sender == address(comptroller)) {
            capitalRaised += msg.value;
            emit CapitalRaised(now, msg.value);
        }
        emit CapitalAdded(now, msg.sender, msg.value);
    }


    /*************************************************************/
    /*************** REQUESTER IMPLEMENTATION ********************/
    /*************************************************************/

    // Removes from capital, sends it to Bankrollable target.
    function executeSendCapital(address _bankrollable, uint _value)
        internal
        returns (bool _success, string _result)
    {
        // Fail if we do not have the capital available.
        if (_value > capital)
            return (false, "Not enough capital.");
        // Fail if target is not Bankrollable
        if (!_hasCorrectTreasury(_bankrollable))
            return (false, "Bankrollable does not have correct Treasury.");

        // Decrease capital, increase bankrolled
        capital -= _value;
        capitalLedger.add(_bankrollable, _value);

        // Send it (this throws on failure). Then emit events.
        _ITrBankrollable(_bankrollable).addBankroll.value(_value)();
        emit CapitalRemoved(now, _bankrollable, _value);
        emit ExecutedSendCapital(now, _bankrollable, _value);
        return (true, "Sent bankroll to target.");
    }

    // Calls ".removeBankroll()" on Bankrollable target.
    function executeRecallCapital(address _bankrollable, uint _value)
        internal
        returns (bool _success, string _result)
    {
        // This should call .addCapital(), incrementing capital.
        uint _prevCapital = capital;
        _ITrBankrollable(_bankrollable).removeBankroll(_value, "addCapital()");
        uint _recalled = capital - _prevCapital;
        capitalLedger.subtract(_bankrollable, _recalled);
        
        // Emit and return
        emit ExecutedRecallCapital(now, _bankrollable, _recalled);
        return (true, "Received bankoll back from target.");
    }

    // Increases capitalRaisedTarget
    function executeRaiseCapital(uint _value)
        internal
        returns (bool _success, string _result)
    {
        // Increase target amount.
        capitalRaisedTarget += _value;
        emit ExecutedRaiseCapital(now, _value);
        return (true, "Capital target raised.");
    }

    // Moves capital to profits
    function executeDistributeCapital(uint _value)
        internal
        returns (bool _success, string _result)
    {
        if (_value > capital)
            return (false, "Not enough capital.");
        capital -= _value;
        profits += _value;
        profitsTotal += _value;
        emit CapitalRemoved(now, this, _value);
        emit ProfitsReceived(now, this, _value);
        emit ExecutedDistributeCapital(now, _value);
        return (true, "Capital moved to profits.");
    }


    /*************************************************************/
    /*************** PUBLIC VIEWS ********************************/
    /*************************************************************/

    function profitsTotal()
        public
        view
        returns (uint _amount)
    {
        return profitsSent + profits;
    }

    function profitsSendable()
        public
        view
        returns (uint _amount)
    {
        if (address(comptroller)==0) return 0;
        if (!comptroller.wasSaleEnded()) return 0;
        return profits;
    }

    // Returns the amount of capital needed to reach capitalRaisedTarget.
    function capitalNeeded()
        public
        view
        returns (uint _amount)
    {
        return capitalRaisedTarget > capitalRaised
            ? capitalRaisedTarget - capitalRaised
            : 0;
    }

    // Returns the total amount of capital allocated
    function capitalAllocated()
        public
        view
        returns (uint _amount)
    {
        return capitalLedger.total();
    }

    // Returns amount of capital allocated to an address
    function capitalAllocatedTo(address _addr)
        public
        view
        returns (uint _amount)
    {
        return capitalLedger.balanceOf(_addr);
    }

    // Returns the full capital allocation table
    function capitalAllocation()
        public
        view
        returns (address[] _addresses, uint[] _amounts)
    {
        return capitalLedger.balances();
    }

    // Returns if _addr.getTreasury() returns this address.
    // This is not fool-proof, but should prevent accidentally
    //  sending capital to non-bankrollable addresses.
    function _hasCorrectTreasury(address _addr)
        private
        returns (bool)
    {
        bytes32 _sig = bytes4(keccak256("getTreasury()"));
        bool _success;
        address _response;
        assembly {
            let x := mload(0x40)    // get free memory
            mstore(x, _sig)         // store signature into it
            // store if call was successful
            _success := call(
                10000,  // 10k gas
                _addr,  // to _addr
                0,      // 0 value
                x,      // input is x
                4,      // input length is 4
                x,      // store output to x
                32      // store first return value
            )
            // store first return value to _response
            _response := mload(x)
        }
        return _success ? _response == address(this) : false;
    }
}