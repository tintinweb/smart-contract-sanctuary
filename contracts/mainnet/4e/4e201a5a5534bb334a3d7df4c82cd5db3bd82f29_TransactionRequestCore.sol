pragma solidity 0.4.24;

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}


/**
 * @title SchedulerInterface
 * @dev The base contract that the higher contracts: BaseScheduler, BlockScheduler and TimestampScheduler all inherit from.
 */
contract SchedulerInterface {
    function schedule(address _toAddress, bytes _callData, uint[8] _uintArgs)
        public payable returns (address);
    function computeEndowment(uint _bounty, uint _fee, uint _callGas, uint _callValue, uint _gasPrice)
        public view returns (uint);
}

contract TransactionRequestInterface {
    
    // Primary actions
    function execute() public returns (bool);
    function cancel() public returns (bool);
    function claim() public payable returns (bool);

    // Proxy function
    function proxy(address recipient, bytes callData) public payable returns (bool);

    // Data accessors
    function requestData() public view returns (address[6], bool[3], uint[15], uint8[1]);
    function callData() public view returns (bytes);

    // Pull mechanisms for payments.
    function refundClaimDeposit() public returns (bool);
    function sendFee() public returns (bool);
    function sendBounty() public returns (bool);
    function sendOwnerEther() public returns (bool);
    function sendOwnerEther(address recipient) public returns (bool);
}

contract TransactionRequestCore is TransactionRequestInterface {
    using RequestLib for RequestLib.Request;
    using RequestScheduleLib for RequestScheduleLib.ExecutionWindow;

    RequestLib.Request txnRequest;
    bool private initialized = false;

    /*
     *  addressArgs[0] - meta.createdBy
     *  addressArgs[1] - meta.owner
     *  addressArgs[2] - paymentData.feeRecipient
     *  addressArgs[3] - txnData.toAddress
     *
     *  uintArgs[0]  - paymentData.fee
     *  uintArgs[1]  - paymentData.bounty
     *  uintArgs[2]  - schedule.claimWindowSize
     *  uintArgs[3]  - schedule.freezePeriod
     *  uintArgs[4]  - schedule.reservedWindowSize
     *  uintArgs[5]  - schedule.temporalUnit
     *  uintArgs[6]  - schedule.windowSize
     *  uintArgs[7]  - schedule.windowStart
     *  uintArgs[8]  - txnData.callGas
     *  uintArgs[9]  - txnData.callValue
     *  uintArgs[10] - txnData.gasPrice
     *  uintArgs[11] - claimData.requiredDeposit
     */
    function initialize(
        address[4]  addressArgs,
        uint[12]    uintArgs,
        bytes       callData
    )
        public payable
    {
        require(!initialized);

        txnRequest.initialize(addressArgs, uintArgs, callData);
        initialized = true;
    }

    /*
     *  Allow receiving ether.  This is needed if there is a large increase in
     *  network gas prices.
     */
    function() public payable {}

    /*
     *  Actions
     */
    function execute() public returns (bool) {
        return txnRequest.execute();
    }

    function cancel() public returns (bool) {
        return txnRequest.cancel();
    }

    function claim() public payable returns (bool) {
        return txnRequest.claim();
    }

    /*
     *  Data accessor functions.
     */

    // Declaring this function `view`, although it creates a compiler warning, is
    // necessary to return values from it.
    function requestData()
        public view returns (address[6], bool[3], uint[15], uint8[1])
    {
        return txnRequest.serialize();
    }

    function callData()
        public view returns (bytes data)
    {
        data = txnRequest.txnData.callData;
    }

    /**
     * @dev Proxy a call from this contract to another contract.
     * This function is only callable by the scheduler and can only
     * be called after the execution window ends. One purpose is to
     * provide a way to transfer assets held by this contract somewhere else.
     * For example, if this request was used to buy tokens during an ICO,
     * it would become the owner of the tokens and this function would need
     * to be called with the encoded data to the token contract to transfer
     * the assets somewhere else. */
    function proxy(address _to, bytes _data)
        public payable returns (bool success)
    {
        require(txnRequest.meta.owner == msg.sender && txnRequest.schedule.isAfterWindow());
        
        /* solium-disable-next-line */
        return _to.call.value(msg.value)(_data);
    }

    /*
     *  Pull based payment functions.
     */
    function refundClaimDeposit() public returns (bool) {
        txnRequest.refundClaimDeposit();
    }

    function sendFee() public returns (bool) {
        return txnRequest.sendFee();
    }

    function sendBounty() public returns (bool) {
        return txnRequest.sendBounty();
    }

    function sendOwnerEther() public returns (bool) {
        return txnRequest.sendOwnerEther();
    }

    function sendOwnerEther(address recipient) public returns (bool) {
        return txnRequest.sendOwnerEther(recipient);
    }

    /** Event duplication from RequestLib.sol. This is so
     *  that these events are available on the contracts ABI.*/
    event Aborted(uint8 reason);
    event Cancelled(uint rewardPayment, uint measuredGasConsumption);
    event Claimed();
    event Executed(uint bounty, uint fee, uint measuredGasConsumption);
}

contract RequestFactoryInterface {
    event RequestCreated(address request, address indexed owner, int indexed bucket, uint[12] params);

    function createRequest(address[3] addressArgs, uint[12] uintArgs, bytes callData) public payable returns (address);
    function createValidatedRequest(address[3] addressArgs, uint[12] uintArgs, bytes callData) public payable returns (address);
    function validateRequestParams(address[3] addressArgs, uint[12] uintArgs, uint endowment) public view returns (bool[6]);
    function isKnownRequest(address _address) public view returns (bool);
}

contract TransactionRecorder {
    address owner;

    bool public wasCalled;
    uint public lastCallValue;
    address public lastCaller;
    bytes public lastCallData = "";
    uint public lastCallGas;

    function TransactionRecorder()  public {
        owner = msg.sender;
    }

    function() payable  public {
        lastCallGas = gasleft();
        lastCallData = msg.data;
        lastCaller = msg.sender;
        lastCallValue = msg.value;
        wasCalled = true;
    }

    function __reset__() public {
        lastCallGas = 0;
        lastCallData = "";
        lastCaller = 0x0;
        lastCallValue = 0;
        wasCalled = false;
    }

    function kill() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}

contract Proxy {
    SchedulerInterface public scheduler;
    address public receipient; 
    address public scheduledTransaction;
    address public owner;

    function Proxy(address _scheduler, address _receipient, uint _payout, uint _gasPrice, uint _delay) public payable {
        scheduler = SchedulerInterface(_scheduler);
        receipient = _receipient;
        owner = msg.sender;

        scheduledTransaction = scheduler.schedule.value(msg.value)(
            this,              // toAddress
            "",                     // callData
            [
                2000000,            // The amount of gas to be sent with the transaction.
                _payout,                  // The amount of wei to be sent.
                255,                // The size of the execution window.
                block.number + _delay,        // The start of the execution window.
                _gasPrice,    // The gasprice for the transaction
                12345 wei,          // The fee included in the transaction.
                224455 wei,         // The bounty that awards the executor of the transaction.
                20000 wei           // The required amount of wei the claimer must send as deposit.
            ]
        );
    }

    function () public payable {
        if (msg.value > 0) {
            receipient.transfer(msg.value);
        }
    }

    function sendOwnerEther(address _receipient) public {
        if (msg.sender == owner && _receipient != 0x0) {
            TransactionRequestInterface(scheduledTransaction).sendOwnerEther(_receipient);
        }   
    }
}

/// Super simple token contract that moves funds into the owner account on creation and
/// only exposes an API to be used for `test/proxy.js`
contract SimpleToken {

    address public owner;

    mapping(address => uint) balances;

    function SimpleToken (uint _initialSupply) public {
        owner = msg.sender;
        balances[owner] = _initialSupply;
    }

    function transfer (address _to, uint _amount)
        public returns (bool success)
    {
        require(balances[msg.sender] > _amount);
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        success = true;
    }

    uint public constant rate = 30;

    function buyTokens()
        public payable returns (bool success)
    {
        require(msg.value > 0);
        balances[msg.sender] += msg.value * rate;
        success = true;
    }

    function balanceOf (address _who)
        public view returns (uint balance)
    {
        balance = balances[_who];
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
  // require(b > 0); // Solidity automatically throws when dividing by 0
  uint256 c = a / b;
  // require(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
  return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
  require(b <= a);
  return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
  uint256 c = a + b;
  require(c >= a);
  return c;
  }
}

/**
 * @title BaseScheduler
 * @dev The foundational contract which provides the API for scheduling future transactions on the Alarm Client.
 */
contract BaseScheduler is SchedulerInterface {
    // The RequestFactory which produces requests for this scheduler.
    address public factoryAddress;

    // The TemporalUnit (Block or Timestamp) for this scheduler.
    RequestScheduleLib.TemporalUnit public temporalUnit;

    // The address which will be sent the fee payments.
    address public feeRecipient;

    /*
     * @dev Fallback function to be able to receive ether. This can occur
     *  legitimately when scheduling fails due to a validation error.
     */
    function() public payable {}

    /// Event that bubbles up the address of new requests made with this scheduler.
    event NewRequest(address request);

    /**
     * @dev Schedules a new TransactionRequest using the &#39;full&#39; parameters.
     * @param _toAddress The address destination of the transaction.
     * @param _callData The bytecode that will be included with the transaction.
     * @param _uintArgs [0] The callGas of the transaction.
     * @param _uintArgs [1] The value of ether to be sent with the transaction.
     * @param _uintArgs [2] The size of the execution window of the transaction.
     * @param _uintArgs [3] The (block or timestamp) of when the execution window starts.
     * @param _uintArgs [4] The gasPrice which will be used to execute this transaction.
     * @param _uintArgs [5] The fee attached to this transaction.
     * @param _uintArgs [6] The bounty attached to this transaction.
     * @param _uintArgs [7] The deposit required to claim this transaction.
     * @return The address of the new TransactionRequest.   
     */ 
    function schedule (
        address   _toAddress,
        bytes     _callData,
        uint[8]   _uintArgs
    )
        public payable returns (address newRequest)
    {
        RequestFactoryInterface factory = RequestFactoryInterface(factoryAddress);

        uint endowment = computeEndowment(
            _uintArgs[6], //bounty
            _uintArgs[5], //fee
            _uintArgs[0], //callGas
            _uintArgs[1], //callValue
            _uintArgs[4]  //gasPrice
        );

        require(msg.value >= endowment);

        if (temporalUnit == RequestScheduleLib.TemporalUnit.Blocks) {
            newRequest = factory.createValidatedRequest.value(msg.value)(
                [
                    msg.sender,                 // meta.owner
                    feeRecipient,               // paymentData.feeRecipient
                    _toAddress                  // txnData.toAddress
                ],
                [
                    _uintArgs[5],               // paymentData.fee
                    _uintArgs[6],               // paymentData.bounty
                    255,                        // scheduler.claimWindowSize
                    10,                         // scheduler.freezePeriod
                    16,                         // scheduler.reservedWindowSize
                    uint(temporalUnit),         // scheduler.temporalUnit (1: block, 2: timestamp)
                    _uintArgs[2],               // scheduler.windowSize
                    _uintArgs[3],               // scheduler.windowStart
                    _uintArgs[0],               // txnData.callGas
                    _uintArgs[1],               // txnData.callValue
                    _uintArgs[4],               // txnData.gasPrice
                    _uintArgs[7]                // claimData.requiredDeposit
                ],
                _callData
            );
        } else if (temporalUnit == RequestScheduleLib.TemporalUnit.Timestamp) {
            newRequest = factory.createValidatedRequest.value(msg.value)(
                [
                    msg.sender,                 // meta.owner
                    feeRecipient,               // paymentData.feeRecipient
                    _toAddress                  // txnData.toAddress
                ],
                [
                    _uintArgs[5],               // paymentData.fee
                    _uintArgs[6],               // paymentData.bounty
                    60 minutes,                 // scheduler.claimWindowSize
                    3 minutes,                  // scheduler.freezePeriod
                    5 minutes,                  // scheduler.reservedWindowSize
                    uint(temporalUnit),         // scheduler.temporalUnit (1: block, 2: timestamp)
                    _uintArgs[2],               // scheduler.windowSize
                    _uintArgs[3],               // scheduler.windowStart
                    _uintArgs[0],               // txnData.callGas
                    _uintArgs[1],               // txnData.callValue
                    _uintArgs[4],               // txnData.gasPrice
                    _uintArgs[7]                // claimData.requiredDeposit
                ],
                _callData
            );
        } else {
            // unsupported temporal unit
            revert();
        }

        require(newRequest != 0x0);
        emit NewRequest(newRequest);
        return newRequest;
    }

    function computeEndowment(
        uint _bounty,
        uint _fee,
        uint _callGas,
        uint _callValue,
        uint _gasPrice
    )
        public view returns (uint)
    {
        return PaymentLib.computeEndowment(
            _bounty,
            _fee,
            _callGas,
            _callValue,
            _gasPrice,
            RequestLib.getEXECUTION_GAS_OVERHEAD()
        );
    }
}

/**
 * @title BlockScheduler
 * @dev Top-level contract that exposes the API to the Ethereum Alarm Clock service and passes in blocks as temporal unit.
 */
contract BlockScheduler is BaseScheduler {

    /**
     * @dev Constructor
     * @param _factoryAddress Address of the RequestFactory which creates requests for this scheduler.
     */
    constructor(address _factoryAddress, address _feeRecipient) public {
        require(_factoryAddress != 0x0);

        // Default temporal unit is block number.
        temporalUnit = RequestScheduleLib.TemporalUnit.Blocks;

        // Sets the factoryAddress variable found in BaseScheduler contract.
        factoryAddress = _factoryAddress;

        // Sets the fee recipient for these schedulers.
        feeRecipient = _feeRecipient;
    }
}

/**
 * @title TimestampScheduler
 * @dev Top-level contract that exposes the API to the Ethereum Alarm Clock service and passes in timestamp as temporal unit.
 */
contract TimestampScheduler is BaseScheduler {

    /**
     * @dev Constructor
     * @param _factoryAddress Address of the RequestFactory which creates requests for this scheduler.
     */
    constructor(address _factoryAddress, address _feeRecipient) public {
        require(_factoryAddress != 0x0);

        // Default temporal unit is timestamp.
        temporalUnit = RequestScheduleLib.TemporalUnit.Timestamp;

        // Sets the factoryAddress variable found in BaseScheduler contract.
        factoryAddress = _factoryAddress;

        // Sets the fee recipient for these schedulers.
        feeRecipient = _feeRecipient;
    }
}

/// Truffle-specific contract (Not a part of the EAC)

contract Migrations {
    address public owner;

    uint public last_completed_migration;

    modifier restricted() {
        if (msg.sender == owner) {
            _;
        }
    }

    function Migrations()  public {
        owner = msg.sender;
    }

    function setCompleted(uint completed) restricted  public {
        last_completed_migration = completed;
    }

    function upgrade(address new_address) restricted  public {
        Migrations upgraded = Migrations(new_address);
        upgraded.setCompleted(last_completed_migration);
    }
}

/**
 * @title ExecutionLib
 * @dev Contains the logic for executing a scheduled transaction.
 */
library ExecutionLib {

    struct ExecutionData {
        address toAddress;                  /// The destination of the transaction.
        bytes callData;                     /// The bytecode that will be sent with the transaction.
        uint callValue;                     /// The wei value that will be sent with the transaction.
        uint callGas;                       /// The amount of gas to be sent with the transaction.
        uint gasPrice;                      /// The gasPrice that should be set for the transaction.
    }

    /**
     * @dev Send the transaction according to the parameters outlined in ExecutionData.
     * @param self The ExecutionData object.
     */
    function sendTransaction(ExecutionData storage self)
        internal returns (bool)
    {
        /// Should never actually reach this require check, but here in case.
        require(self.gasPrice <= tx.gasprice);
        /* solium-disable security/no-call-value */
        return self.toAddress.call.value(self.callValue).gas(self.callGas)(self.callData);
    }


    /**
     * Returns the maximum possible gas consumption that a transaction request
     * may consume.  The EXTRA_GAS value represents the overhead involved in
     * request execution.
     */
    function CALL_GAS_CEILING(uint EXTRA_GAS) 
        internal view returns (uint)
    {
        return block.gaslimit - EXTRA_GAS;
    }

    /*
     * @dev Validation: ensure that the callGas is not above the total possible gas
     * for a call.
     */
    function validateCallGas(uint callGas, uint EXTRA_GAS)
        internal view returns (bool)
    {
        return callGas < CALL_GAS_CEILING(EXTRA_GAS);
    }

    /*
     * @dev Validation: ensure that the toAddress is not set to the empty address.
     */
    function validateToAddress(address toAddress)
        internal pure returns (bool)
    {
        return toAddress != 0x0;
    }
}

library MathLib {
    uint constant INT_MAX = 57896044618658097711785492504343953926634992332820282019728792003956564819967;  // 2**255 - 1
    /*
     * Subtracts b from a in a manner such that zero is returned when an
     * underflow condition is met.
     */
    // function flooredSub(uint a, uint b) returns (uint) {
    //     if (b >= a) {
    //         return 0;
    //     } else {
    //         return a - b;
    //     }
    // }

    // /*
    //  * Adds b to a in a manner that throws an exception when overflow
    //  * conditions are met.
    //  */
    // function safeAdd(uint a, uint b) returns (uint) {
    //     if (a + b >= a) {
    //         return a + b;
    //     } else {
    //         throw;
    //     }
    // }

    // /*
    //  * Multiplies a by b in a manner that throws an exception when overflow
    //  * conditions are met.
    //  */
    // function safeMultiply(uint a, uint b) returns (uint) {
    //     var result = a * b;
    //     if (b == 0 || result / b == a) {
    //         return a * b;
    //     } else {
    //         throw;
    //     }
    // }

    /*
     * Return the larger of a or b.  Returns a if a == b.
     */
    function max(uint a, uint b) 
        public pure returns (uint)
    {
        if (a >= b) {
            return a;
        } else {
            return b;
        }
    }

    /*
     * Return the larger of a or b.  Returns a if a == b.
     */
    function min(uint a, uint b) 
        public pure returns (uint)
    {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    /*
     * Returns a represented as a signed integer in a manner that throw an
     * exception if casting to signed integer would result in a negative
     * number.
     */
    function safeCastSigned(uint a) 
        public pure returns (int)
    {
        assert(a <= INT_MAX);
        return int(a);
    }
    
}

/**
 * @title RequestMetaLib
 * @dev Small library holding all the metadata about a TransactionRequest.
 */
library RequestMetaLib {

    struct RequestMeta {
        address owner;              /// The address that created this request.

        address createdBy;          /// The address of the RequestFactory which created this request.

        bool isCancelled;           /// Was the TransactionRequest cancelled?
        
        bool wasCalled;             /// Was the TransactionRequest called?

        bool wasSuccessful;         /// Was the return value from the TransactionRequest execution successful?
    }

}

library RequestLib {
    using ClaimLib for ClaimLib.ClaimData;
    using ExecutionLib for ExecutionLib.ExecutionData;
    using PaymentLib for PaymentLib.PaymentData;
    using RequestMetaLib for RequestMetaLib.RequestMeta;
    using RequestScheduleLib for RequestScheduleLib.ExecutionWindow;
    using SafeMath for uint;

    struct Request {
        ExecutionLib.ExecutionData txnData;
        RequestMetaLib.RequestMeta meta;
        PaymentLib.PaymentData paymentData;
        ClaimLib.ClaimData claimData;
        RequestScheduleLib.ExecutionWindow schedule;
    }

    enum AbortReason {
        WasCancelled,       //0
        AlreadyCalled,      //1
        BeforeCallWindow,   //2
        AfterCallWindow,    //3
        ReservedForClaimer, //4
        InsufficientGas,    //5
        TooLowGasPrice    //6
    }

    event Aborted(uint8 reason);
    event Cancelled(uint rewardPayment, uint measuredGasConsumption);
    event Claimed();
    event Executed(uint bounty, uint fee, uint measuredGasConsumption);

    /**
     * @dev Validate the initialization parameters of a transaction request.
     */
    function validate(
        address[4]  _addressArgs,
        uint[12]    _uintArgs,
        uint        _endowment
    ) 
        public view returns (bool[6] isValid)
    {
        // The order of these errors matters as it determines which
        // ValidationError event codes are logged when validation fails.
        isValid[0] = PaymentLib.validateEndowment(
            _endowment,
            _uintArgs[1],               //bounty
            _uintArgs[0],               //fee
            _uintArgs[8],               //callGas
            _uintArgs[9],               //callValue
            _uintArgs[10],              //gasPrice
            EXECUTION_GAS_OVERHEAD
        );
        isValid[1] = RequestScheduleLib.validateReservedWindowSize(
            _uintArgs[4],               //reservedWindowSize
            _uintArgs[6]                //windowSize
        );
        isValid[2] = RequestScheduleLib.validateTemporalUnit(_uintArgs[5]);
        isValid[3] = RequestScheduleLib.validateWindowStart(
            RequestScheduleLib.TemporalUnit(MathLib.min(_uintArgs[5], 2)),
            _uintArgs[3],               //freezePeriod
            _uintArgs[7]                //windowStart
        );
        isValid[4] = ExecutionLib.validateCallGas(
            _uintArgs[8],               //callGas
            EXECUTION_GAS_OVERHEAD
        );
        isValid[5] = ExecutionLib.validateToAddress(_addressArgs[3]);

        return isValid;
    }

    /**
     * @dev Initialize a new Request.
     */
    function initialize(
        Request storage self,
        address[4]      _addressArgs,
        uint[12]        _uintArgs,
        bytes           _callData
    ) 
        public returns (bool)
    {
        address[6] memory addressValues = [
            0x0,                // self.claimData.claimedBy
            _addressArgs[0],    // self.meta.createdBy
            _addressArgs[1],    // self.meta.owner
            _addressArgs[2],    // self.paymentData.feeRecipient
            0x0,                // self.paymentData.bountyBenefactor
            _addressArgs[3]     // self.txnData.toAddress
        ];

        bool[3] memory boolValues = [false, false, false];

        uint[15] memory uintValues = [
            0,                  // self.claimData.claimDeposit
            _uintArgs[0],       // self.paymentData.fee
            0,                  // self.paymentData.feeOwed
            _uintArgs[1],       // self.paymentData.bounty
            0,                  // self.paymentData.bountyOwed
            _uintArgs[2],       // self.schedule.claimWindowSize
            _uintArgs[3],       // self.schedule.freezePeriod
            _uintArgs[4],       // self.schedule.reservedWindowSize
            _uintArgs[5],       // self.schedule.temporalUnit
            _uintArgs[6],       // self.schedule.windowSize
            _uintArgs[7],       // self.schedule.windowStart
            _uintArgs[8],       // self.txnData.callGas
            _uintArgs[9],       // self.txnData.callValue
            _uintArgs[10],      // self.txnData.gasPrice
            _uintArgs[11]       // self.claimData.requiredDeposit
        ];

        uint8[1] memory uint8Values = [
            0
        ];

        require(deserialize(self, addressValues, boolValues, uintValues, uint8Values, _callData));

        return true;
    }
 
    function serialize(Request storage self)
        internal view returns(address[6], bool[3], uint[15], uint8[1])
    {
        address[6] memory addressValues = [
            self.claimData.claimedBy,
            self.meta.createdBy,
            self.meta.owner,
            self.paymentData.feeRecipient,
            self.paymentData.bountyBenefactor,
            self.txnData.toAddress
        ];

        bool[3] memory boolValues = [
            self.meta.isCancelled,
            self.meta.wasCalled,
            self.meta.wasSuccessful
        ];

        uint[15] memory uintValues = [
            self.claimData.claimDeposit,
            self.paymentData.fee,
            self.paymentData.feeOwed,
            self.paymentData.bounty,
            self.paymentData.bountyOwed,
            self.schedule.claimWindowSize,
            self.schedule.freezePeriod,
            self.schedule.reservedWindowSize,
            uint(self.schedule.temporalUnit),
            self.schedule.windowSize,
            self.schedule.windowStart,
            self.txnData.callGas,
            self.txnData.callValue,
            self.txnData.gasPrice,
            self.claimData.requiredDeposit
        ];

        uint8[1] memory uint8Values = [
            self.claimData.paymentModifier
        ];

        return (addressValues, boolValues, uintValues, uint8Values);
    }

    /**
     * @dev Populates a Request object from the full output of `serialize`.
     *
     *  Parameter order is alphabetical by type, then namespace, then name.
     */
    function deserialize(
        Request storage self,
        address[6]  _addressValues,
        bool[3]     _boolValues,
        uint[15]    _uintValues,
        uint8[1]    _uint8Values,
        bytes       _callData
    )
        internal returns (bool)
    {
        // callData is special.
        self.txnData.callData = _callData;

        // Address values
        self.claimData.claimedBy = _addressValues[0];
        self.meta.createdBy = _addressValues[1];
        self.meta.owner = _addressValues[2];
        self.paymentData.feeRecipient = _addressValues[3];
        self.paymentData.bountyBenefactor = _addressValues[4];
        self.txnData.toAddress = _addressValues[5];

        // Boolean values
        self.meta.isCancelled = _boolValues[0];
        self.meta.wasCalled = _boolValues[1];
        self.meta.wasSuccessful = _boolValues[2];

        // UInt values
        self.claimData.claimDeposit = _uintValues[0];
        self.paymentData.fee = _uintValues[1];
        self.paymentData.feeOwed = _uintValues[2];
        self.paymentData.bounty = _uintValues[3];
        self.paymentData.bountyOwed = _uintValues[4];
        self.schedule.claimWindowSize = _uintValues[5];
        self.schedule.freezePeriod = _uintValues[6];
        self.schedule.reservedWindowSize = _uintValues[7];
        self.schedule.temporalUnit = RequestScheduleLib.TemporalUnit(_uintValues[8]);
        self.schedule.windowSize = _uintValues[9];
        self.schedule.windowStart = _uintValues[10];
        self.txnData.callGas = _uintValues[11];
        self.txnData.callValue = _uintValues[12];
        self.txnData.gasPrice = _uintValues[13];
        self.claimData.requiredDeposit = _uintValues[14];

        // Uint8 values
        self.claimData.paymentModifier = _uint8Values[0];

        return true;
    }

    function execute(Request storage self) 
        internal returns (bool)
    {
        /*
         *  Execute the TransactionRequest
         *
         *  +---------------------+
         *  | Phase 1: Validation |
         *  +---------------------+
         *
         *  Must pass all of the following checks:
         *
         *  1. Not already called.
         *  2. Not cancelled.
         *  3. Not before the execution window.
         *  4. Not after the execution window.
         *  5. if (claimedBy == 0x0 or msg.sender == claimedBy):
         *         - windowStart <= block.number
         *         - block.number <= windowStart + windowSize
         *     else if (msg.sender != claimedBy):
         *         - windowStart + reservedWindowSize <= block.number
         *         - block.number <= windowStart + windowSize
         *     else:
         *         - throw (should be impossible)
         *  
         *  6. gasleft() == callGas
         *  7. tx.gasprice >= txnData.gasPrice
         *
         *  +--------------------+
         *  | Phase 2: Execution |
         *  +--------------------+
         *
         *  1. Mark as called (must be before actual execution to prevent
         *     re-entrance)
         *  2. Send Transaction and record success or failure.
         *
         *  +---------------------+
         *  | Phase 3: Accounting |
         *  +---------------------+
         *
         *  1. Calculate and send fee amount.
         *  2. Calculate and send bounty amount.
         *  3. Send remaining ether back to owner.
         *
         */

        // Record the gas at the beginning of the transaction so we can
        // calculate how much has been used later.
        uint startGas = gasleft();

        // +----------------------+
        // | Begin: Authorization |
        // +----------------------+

        if (gasleft() < requiredExecutionGas(self).sub(PRE_EXECUTION_GAS)) {
            emit Aborted(uint8(AbortReason.InsufficientGas));
            return false;
        } else if (self.meta.wasCalled) {
            emit Aborted(uint8(AbortReason.AlreadyCalled));
            return false;
        } else if (self.meta.isCancelled) {
            emit Aborted(uint8(AbortReason.WasCancelled));
            return false;
        } else if (self.schedule.isBeforeWindow()) {
            emit Aborted(uint8(AbortReason.BeforeCallWindow));
            return false;
        } else if (self.schedule.isAfterWindow()) {
            emit Aborted(uint8(AbortReason.AfterCallWindow));
            return false;
        } else if (self.claimData.isClaimed() && msg.sender != self.claimData.claimedBy && self.schedule.inReservedWindow()) {
            emit Aborted(uint8(AbortReason.ReservedForClaimer));
            return false;
        } else if (self.txnData.gasPrice > tx.gasprice) {
            emit Aborted(uint8(AbortReason.TooLowGasPrice));
            return false;
        }

        // +--------------------+
        // | End: Authorization |
        // +--------------------+
        // +------------------+
        // | Begin: Execution |
        // +------------------+

        // Mark as being called before sending transaction to prevent re-entrance.
        self.meta.wasCalled = true;

        // Send the transaction...
        // The transaction is allowed to fail and the executing agent will still get the bounty.
        // `.sendTransaction()` will return false on a failed exeuction. 
        self.meta.wasSuccessful = self.txnData.sendTransaction();

        // +----------------+
        // | End: Execution |
        // +----------------+
        // +-------------------+
        // | Begin: Accounting |
        // +-------------------+

        // Compute the fee amount
        if (self.paymentData.hasFeeRecipient()) {
            self.paymentData.feeOwed = self.paymentData.getFee()
                .add(self.paymentData.feeOwed);
        }

        // Record this locally so that we can log it later.
        // `.sendFee()` below will change `self.paymentData.feeOwed` to 0 to prevent re-entrance.
        uint totalFeePayment = self.paymentData.feeOwed;

        // Send the fee. This transaction may also fail but can be called again after
        // execution.
        self.paymentData.sendFee();

        // Compute the bounty amount.
        self.paymentData.bountyBenefactor = msg.sender;
        if (self.claimData.isClaimed()) {
            // If the transaction request was claimed, we add the deposit to the bounty whether
            // or not the same agent who claimed is executing.
            self.paymentData.bountyOwed = self.claimData.claimDeposit
                .add(self.paymentData.bountyOwed);
            // To prevent re-entrance we zero out the claim deposit since it is now accounted for
            // in the bounty value.
            self.claimData.claimDeposit = 0;
            // Depending on when the transaction request was claimed, we apply the modifier to the
            // bounty payment and add it to the bounty already owed.
            self.paymentData.bountyOwed = self.paymentData.getBountyWithModifier(self.claimData.paymentModifier)
                .add(self.paymentData.bountyOwed);
        } else {
            // Not claimed. Just add the full bounty.
            self.paymentData.bountyOwed = self.paymentData.getBounty().add(self.paymentData.bountyOwed);
        }

        // Take down the amount of gas used so far in execution to compensate the executing agent.
        uint measuredGasConsumption = startGas.sub(gasleft()).add(EXECUTE_EXTRA_GAS);

        // // +----------------------------------------------------------------------+
        // // | NOTE: All code after this must be accounted for by EXECUTE_EXTRA_GAS |
        // // +----------------------------------------------------------------------+

        // Add the gas reimbursment amount to the bounty.
        self.paymentData.bountyOwed = measuredGasConsumption
            .mul(self.txnData.gasPrice)
            .add(self.paymentData.bountyOwed);

        // Log the bounty and fee. Otherwise it is non-trivial to figure
        // out how much was payed.
        emit Executed(self.paymentData.bountyOwed, totalFeePayment, measuredGasConsumption);
    
        // Attempt to send the bounty. as with `.sendFee()` it may fail and need to be caled after execution.
        self.paymentData.sendBounty();

        // If any ether is left, send it back to the owner of the transaction request.
        _sendOwnerEther(self, self.meta.owner);

        // +-----------------+
        // | End: Accounting |
        // +-----------------+
        // Successful
        return true;
    }


    // This is the amount of gas that it takes to enter from the
    // `TransactionRequest.execute()` contract into the `RequestLib.execute()`
    // method at the point where the gas check happens.
    uint public constant PRE_EXECUTION_GAS = 25000;   // TODO is this number still accurate?
    
    /*
     * The amount of gas needed to complete the execute method after
     * the transaction has been sent.
     */
    uint public constant EXECUTION_GAS_OVERHEAD = 180000; // TODO check accuracy of this number
    /*
     *  The amount of gas used by the portion of the `execute` function
     *  that cannot be accounted for via gas tracking.
     */
    uint public constant  EXECUTE_EXTRA_GAS = 90000; // again, check for accuracy... Doubled this from Piper&#39;s original - Logan

    /*
     *  Constant value to account for the gas usage that cannot be accounted
     *  for using gas-tracking within the `cancel` function.
     */
    uint public constant CANCEL_EXTRA_GAS = 85000; // Check accuracy

    function getEXECUTION_GAS_OVERHEAD()
        public pure returns (uint)
    {
        return EXECUTION_GAS_OVERHEAD;
    }
    
    function requiredExecutionGas(Request storage self) 
        public view returns (uint requiredGas)
    {
        requiredGas = self.txnData.callGas.add(EXECUTION_GAS_OVERHEAD);
    }

    /*
     * @dev Performs the checks to see if a request can be cancelled.
     *  Must satisfy the following conditions.
     *
     *  1. Not Cancelled
     *  2. either:
     *    * not wasCalled && afterExecutionWindow
     *    * not claimed && beforeFreezeWindow && msg.sender == owner
     */
    function isCancellable(Request storage self) 
        public view returns (bool)
    {
        if (self.meta.isCancelled) {
            // already cancelled!
            return false;
        } else if (!self.meta.wasCalled && self.schedule.isAfterWindow()) {
            // not called but after the window
            return true;
        } else if (!self.claimData.isClaimed() && self.schedule.isBeforeFreeze() && msg.sender == self.meta.owner) {
            // not claimed and before freezePeriod and owner is cancelling
            return true;
        } else {
            // otherwise cannot cancel
            return false;
        }
    }

    /*
     *  Cancel the transaction request, attempting to send all appropriate
     *  refunds.  To incentivise cancellation by other parties, a small reward
     *  payment is issued to the party that cancels the request if they are not
     *  the owner.
     */
    function cancel(Request storage self) 
        public returns (bool)
    {
        uint startGas = gasleft();
        uint rewardPayment;
        uint measuredGasConsumption;

        // Checks if this transactionRequest can be cancelled.
        require(isCancellable(self));

        // Set here to prevent re-entrance attacks.
        self.meta.isCancelled = true;

        // Refund the claim deposit (if there is one)
        require(self.claimData.refundDeposit());

        // Send a reward to the cancelling agent if they are not the owner.
        // This is to incentivize the cancelling of expired transaction requests.
        // This also guarantees that it is being cancelled after the call window
        // since the `isCancellable()` function checks this.
        if (msg.sender != self.meta.owner) {
            // Create the rewardBenefactor
            address rewardBenefactor = msg.sender;
            // Create the rewardOwed variable, it is one-hundredth
            // of the bounty.
            uint rewardOwed = self.paymentData.bountyOwed
                .add(self.paymentData.bounty.div(100));

            // Calculate the amount of gas cancelling agent used in this transaction.
            measuredGasConsumption = startGas
                .sub(gasleft())
                .add(CANCEL_EXTRA_GAS);
            // Add their gas fees to the reward.W
            rewardOwed = measuredGasConsumption
                .mul(tx.gasprice)
                .add(rewardOwed);

            // Take note of the rewardPayment to log it.
            rewardPayment = rewardOwed;

            // Transfers the rewardPayment.
            if (rewardOwed > 0) {
                self.paymentData.bountyOwed = 0;
                rewardBenefactor.transfer(rewardOwed);
            }
        }

        // Log it!
        emit Cancelled(rewardPayment, measuredGasConsumption);

        // Send the remaining ether to the owner.
        return sendOwnerEther(self);
    }

    /*
     * @dev Performs some checks to verify that a transaction request is claimable.
     * @param self The Request object.
     */
    function isClaimable(Request storage self) 
        internal view returns (bool)
    {
        // Require not claimed and not cancelled.
        require(!self.claimData.isClaimed());
        require(!self.meta.isCancelled);

        // Require that it&#39;s in the claim window and the value sent is over the required deposit.
        require(self.schedule.inClaimWindow());
        require(msg.value >= self.claimData.requiredDeposit);
        return true;
    }

    /*
     * @dev Claims the request.
     * @param self The Request object.
     * Payable because it requires the sender to send enough ether to cover the claimDeposit.
     */
    function claim(Request storage self) 
        internal returns (bool claimed)
    {
        require(isClaimable(self));
        
        emit Claimed();
        return self.claimData.claim(self.schedule.computePaymentModifier());
    }

    /*
     * @dev Refund claimer deposit.
     */
    function refundClaimDeposit(Request storage self)
        public returns (bool)
    {
        require(self.meta.isCancelled || self.schedule.isAfterWindow());
        return self.claimData.refundDeposit();
    }

    /*
     * Send fee. Wrapper over the real function that perform an extra
     * check to see if it&#39;s after the execution window (and thus the first transaction failed)
     */
    function sendFee(Request storage self) 
        public returns (bool)
    {
        if (self.schedule.isAfterWindow()) {
            return self.paymentData.sendFee();
        }
        return false;
    }

    /*
     * Send bounty. Wrapper over the real function that performs an extra
     * check to see if it&#39;s after execution window (and thus the first transaction failed)
     */
    function sendBounty(Request storage self) 
        public returns (bool)
    {
        /// check wasCalled
        if (self.schedule.isAfterWindow()) {
            return self.paymentData.sendBounty();
        }
        return false;
    }

    function canSendOwnerEther(Request storage self) 
        public view returns(bool) 
    {
        return self.meta.isCancelled || self.schedule.isAfterWindow() || self.meta.wasCalled;
    }

    /**
     * Send owner ether. Wrapper over the real function that performs an extra 
     * check to see if it&#39;s after execution window (and thus the first transaction failed)
     */
    function sendOwnerEther(Request storage self, address recipient)
        public returns (bool)
    {
        require(recipient != 0x0);
        if(canSendOwnerEther(self) && msg.sender == self.meta.owner) {
            return _sendOwnerEther(self, recipient);
        }
        return false;
    }

    /**
     * Send owner ether. Wrapper over the real function that performs an extra 
     * check to see if it&#39;s after execution window (and thus the first transaction failed)
     */
    function sendOwnerEther(Request storage self)
        public returns (bool)
    {
        if(canSendOwnerEther(self)) {
            return _sendOwnerEther(self, self.meta.owner);
        }
        return false;
    }

    function _sendOwnerEther(Request storage self, address recipient) 
        private returns (bool)
    {
        // Note! This does not do any checks since it is used in the execute function.
        // The public version of the function should be used for checks and in the cancel function.
        uint ownerRefund = address(this).balance
            .sub(self.claimData.claimDeposit)
            .sub(self.paymentData.bountyOwed)
            .sub(self.paymentData.feeOwed);
        /* solium-disable security/no-send */
        return recipient.send(ownerRefund);
    }
}

/**
 * @title RequestScheduleLib
 * @dev Library containing the logic for request scheduling.
 */
library RequestScheduleLib {
    using SafeMath for uint;

    /**
     * The manner in which this schedule specifies time.
     *
     * Null: present to require this value be explicitely specified
     * Blocks: execution schedule determined by block.number
     * Timestamp: execution schedule determined by block.timestamp
     */
    enum TemporalUnit {
        Null,           // 0
        Blocks,         // 1
        Timestamp       // 2
    }

    struct ExecutionWindow {

        TemporalUnit temporalUnit;      /// The type of unit used to measure time.

        uint windowStart;               /// The starting point in temporal units from which the transaction can be executed.

        uint windowSize;                /// The length in temporal units of the execution time period.

        uint freezePeriod;              /// The length in temporal units before the windowStart where no activity is allowed.

        uint reservedWindowSize;        /// The length in temporal units at the beginning of the executionWindow in which only the claim address can execute.

        uint claimWindowSize;           /// The length in temporal units before the freezeperiod in which an address can claim the execution.
    }

    /**
     * @dev Get the `now` represented in the temporal units assigned to this request.
     * @param self The ExecutionWindow object.
     * @return The unsigned integer representation of `now` in appropiate temporal units.
     */
    function getNow(ExecutionWindow storage self) 
        public view returns (uint)
    {
        return _getNow(self.temporalUnit);
    }

    /**
     * @dev Internal function to return the `now` based on the appropiate temporal units.
     * @param _temporalUnit The assigned TemporalUnit to this transaction.
     */
    function _getNow(TemporalUnit _temporalUnit) 
        internal view returns (uint)
    {
        if (_temporalUnit == TemporalUnit.Timestamp) {
            return block.timestamp;
        } 
        if (_temporalUnit == TemporalUnit.Blocks) {
            return block.number;
        }
        /// Only reaches here if the unit is unset, unspecified or unsupported.
        revert();
    }

    /**
     * @dev The modifier that will be applied to the bounty value depending
     * on when a call was claimed.
     */
    function computePaymentModifier(ExecutionWindow storage self) 
        internal view returns (uint8)
    {        
        uint paymentModifier = (getNow(self).sub(firstClaimBlock(self)))
            .mul(100)
            .div(self.claimWindowSize); 
        assert(paymentModifier <= 100); 

        return uint8(paymentModifier);
    }

    /*
     *  Helper: computes the end of the execution window.
     */
    function windowEnd(ExecutionWindow storage self)
        internal view returns (uint)
    {
        return self.windowStart.add(self.windowSize);
    }

    /*
     *  Helper: computes the end of the reserved portion of the execution
     *  window.
     */
    function reservedWindowEnd(ExecutionWindow storage self)
        internal view returns (uint)
    {
        return self.windowStart.add(self.reservedWindowSize);
    }

    /*
     *  Helper: computes the time when the request will be frozen until execution.
     */
    function freezeStart(ExecutionWindow storage self) 
        internal view returns (uint)
    {
        return self.windowStart.sub(self.freezePeriod);
    }

    /*
     *  Helper: computes the time when the request will be frozen until execution.
     */
    function firstClaimBlock(ExecutionWindow storage self) 
        internal view returns (uint)
    {
        return freezeStart(self).sub(self.claimWindowSize);
    }

    /*
     *  Helper: Returns boolean if we are before the execution window.
     */
    function isBeforeWindow(ExecutionWindow storage self)
        internal view returns (bool)
    {
        return getNow(self) < self.windowStart;
    }

    /*
     *  Helper: Returns boolean if we are after the execution window.
     */
    function isAfterWindow(ExecutionWindow storage self) 
        internal view returns (bool)
    {
        return getNow(self) > windowEnd(self);
    }

    /*
     *  Helper: Returns boolean if we are inside the execution window.
     */
    function inWindow(ExecutionWindow storage self)
        internal view returns (bool)
    {
        return self.windowStart <= getNow(self) && getNow(self) < windowEnd(self);
    }

    /*
     *  Helper: Returns boolean if we are inside the reserved portion of the
     *  execution window.
     */
    function inReservedWindow(ExecutionWindow storage self)
        internal view returns (bool)
    {
        return self.windowStart <= getNow(self) && getNow(self) < reservedWindowEnd(self);
    }

    /*
     * @dev Helper: Returns boolean if we are inside the claim window.
     */
    function inClaimWindow(ExecutionWindow storage self) 
        internal view returns (bool)
    {
        /// Checks that the firstClaimBlock is in the past or now.
        /// Checks that now is before the start of the freezePeriod.
        return firstClaimBlock(self) <= getNow(self) && getNow(self) < freezeStart(self);
    }

    /*
     *  Helper: Returns boolean if we are before the freeze period.
     */
    function isBeforeFreeze(ExecutionWindow storage self) 
        internal view returns (bool)
    {
        return getNow(self) < freezeStart(self);
    }

    /*
     *  Helper: Returns boolean if we are before the claim window.
     */
    function isBeforeClaimWindow(ExecutionWindow storage self)
        internal view returns (bool)
    {
        return getNow(self) < firstClaimBlock(self);
    }

    ///---------------
    /// VALIDATION
    ///---------------

    /**
     * @dev Validation: Ensure that the reservedWindowSize is less than or equal to the windowSize.
     * @param _reservedWindowSize The size of the reserved window.
     * @param _windowSize The size of the execution window.
     * @return True if the reservedWindowSize is within the windowSize.
     */
    function validateReservedWindowSize(uint _reservedWindowSize, uint _windowSize)
        public pure returns (bool)
    {
        return _reservedWindowSize <= _windowSize;
    }

    /**
     * @dev Validation: Ensure that the startWindow is at least freezePeriod amount of time in the future.
     * @param _temporalUnit The temporalUnit of this request.
     * @param _freezePeriod The freezePeriod in temporal units.
     * @param _windowStart The time in the future which represents the start of the execution window.
     * @return True if the windowStart is at least freezePeriod amount of time in the future.
     */
    function validateWindowStart(TemporalUnit _temporalUnit, uint _freezePeriod, uint _windowStart) 
        public view returns (bool)
    {
        return _getNow(_temporalUnit).add(_freezePeriod) <= _windowStart;
    }

    /*
     *  Validation: ensure that the temporal unit passed in is constrained to 0 or 1
     */
    function validateTemporalUnit(uint _temporalUnitAsUInt) 
        public pure returns (bool)
    {
        return (_temporalUnitAsUInt != uint(TemporalUnit.Null) &&
            (_temporalUnitAsUInt == uint(TemporalUnit.Blocks) ||
            _temporalUnitAsUInt == uint(TemporalUnit.Timestamp))
        );
    }
}

library ClaimLib {

    struct ClaimData {
        address claimedBy;          // The address that has claimed the txRequest.
        uint claimDeposit;          // The deposit amount that was put down by the claimer.
        uint requiredDeposit;       // The required deposit to claim the txRequest.
        uint8 paymentModifier;      // An integer constrained between 0-100 that will be applied to the
                                    // request payment as a percentage.
    }

    /*
     * @dev Mark the request as being claimed.
     * @param self The ClaimData that is being accessed.
     * @param paymentModifier The payment modifier.
     */
    function claim(
        ClaimData storage self, 
        uint8 _paymentModifier
    ) 
        internal returns (bool)
    {
        self.claimedBy = msg.sender;
        self.claimDeposit = msg.value;
        self.paymentModifier = _paymentModifier;
        return true;
    }

    /*
     * Helper: returns whether this request is claimed.
     */
    function isClaimed(ClaimData storage self) 
        internal view returns (bool)
    {
        return self.claimedBy != 0x0;
    }


    /*
     * @dev Refund the claim deposit to claimer.
     * @param self The Request.ClaimData
     * Called in RequestLib&#39;s `cancel()` and `refundClaimDeposit()`
     */
    function refundDeposit(ClaimData storage self) 
        internal returns (bool)
    {
        // Check that the claim deposit is non-zero.
        if (self.claimDeposit > 0) {
            uint depositAmount;
            depositAmount = self.claimDeposit;
            self.claimDeposit = 0;
            /* solium-disable security/no-send */
            return self.claimedBy.send(depositAmount);
        }
        return true;
    }
}


/**
 * Library containing the functionality for the bounty and fee payments.
 * - Bounty payments are the reward paid to the executing agent of transaction
 * requests.
 * - Fee payments are the cost of using a Scheduler to make transactions. It is 
 * a way for developers to monetize their work on the EAC.
 */
library PaymentLib {
    using SafeMath for uint;

    struct PaymentData {
        uint bounty;                /// The amount in wei to be paid to the executing agent of the TransactionRequest.

        address bountyBenefactor;   /// The address that the bounty will be sent to.

        uint bountyOwed;            /// The amount that is owed to the bountyBenefactor.

        uint fee;                   /// The amount in wei that will be paid to the FEE_RECIPIENT address.

        address feeRecipient;       /// The address that the fee will be sent to.

        uint feeOwed;               /// The amount that is owed to the feeRecipient.
    }

    ///---------------
    /// GETTERS
    ///---------------

    /**
     * @dev Getter function that returns true if a request has a benefactor.
     */
    function hasFeeRecipient(PaymentData storage self)
        internal view returns (bool)
    {
        return self.feeRecipient != 0x0;
    }

    /**
     * @dev Computes the amount to send to the feeRecipient. 
     */
    function getFee(PaymentData storage self) 
        internal view returns (uint)
    {
        return self.fee;
    }

    /**
     * @dev Computes the amount to send to the agent that executed the request.
     */
    function getBounty(PaymentData storage self)
        internal view returns (uint)
    {
        return self.bounty;
    }
 
    /**
     * @dev Computes the amount to send to the address that fulfilled the request
     *       with an additional modifier. This is used when the call was claimed.
     */
    function getBountyWithModifier(PaymentData storage self, uint8 _paymentModifier)
        internal view returns (uint)
    {
        return getBounty(self).mul(_paymentModifier).div(100);
    }

    ///---------------
    /// SENDERS
    ///---------------

    /**
     * @dev Send the feeOwed amount to the feeRecipient.
     * Note: The send is allowed to fail.
     */
    function sendFee(PaymentData storage self) 
        internal returns (bool)
    {
        uint feeAmount = self.feeOwed;
        if (feeAmount > 0) {
            // re-entrance protection.
            self.feeOwed = 0;
            /* solium-disable security/no-send */
            return self.feeRecipient.send(feeAmount);
        }
        return true;
    }

    /**
     * @dev Send the bountyOwed amount to the bountyBenefactor.
     * Note: The send is allowed to fail.
     */
    function sendBounty(PaymentData storage self)
        internal returns (bool)
    {
        uint bountyAmount = self.bountyOwed;
        if (bountyAmount > 0) {
            // re-entrance protection.
            self.bountyOwed = 0;
            return self.bountyBenefactor.send(bountyAmount);
        }
        return true;
    }

    ///---------------
    /// Endowment
    ///---------------

    /**
     * @dev Compute the endowment value for the given TransactionRequest parameters.
     * See request_factory.rst in docs folder under Check #1 for more information about
     * this calculation.
     */
    function computeEndowment(
        uint _bounty,
        uint _fee,
        uint _callGas,
        uint _callValue,
        uint _gasPrice,
        uint _gasOverhead
    ) 
        public pure returns (uint)
    {
        return _bounty
            .add(_fee)
            .add(_callGas.mul(_gasPrice))
            .add(_gasOverhead.mul(_gasPrice))
            .add(_callValue);
    }

    /*
     * Validation: ensure that the request endowment is sufficient to cover.
     * - bounty
     * - fee
     * - gasReimbursment
     * - callValue
     */
    function validateEndowment(uint _endowment, uint _bounty, uint _fee, uint _callGas, uint _callValue, uint _gasPrice, uint _gasOverhead)
        public pure returns (bool)
    {
        return _endowment >= computeEndowment(
            _bounty,
            _fee,
            _callGas,
            _callValue,
            _gasPrice,
            _gasOverhead
        );
    }
}

/**
 * @title IterTools
 * @dev Utility library that iterates through a boolean array of length 6.
 */
library IterTools {
    /*
     * @dev Return true if all of the values in the boolean array are true.
     * @param _values A boolean array of length 6.
     * @return True if all values are true, False if _any_ are false.
     */
    function all(bool[6] _values) 
        public pure returns (bool)
    {
        for (uint i = 0; i < _values.length; i++) {
            if (!_values[i]) {
                return false;
            }
        }
        return true;
    }
}

/*
The MIT License (MIT)

Copyright (c) 2018 Murray Software, LLC.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {

  event CloneCreated(address indexed target, address clone);

  function createClone(address target) internal returns (address result) {
    bytes memory clone = hex"600034603b57603080600f833981f36000368180378080368173bebebebebebebebebebebebebebebebebebebebe5af43d82803e15602c573d90f35b3d90fd";
    bytes20 targetBytes = bytes20(target);
    for (uint i = 0; i < 20; i++) {
      clone[26 + i] = targetBytes[i];
    }
    assembly {
      let len := mload(clone)
      let data := add(clone, 0x20)
      result := create(0, data, len)
    }
  }
}

/// Example of using the Scheduler from a smart contract to delay a payment.
contract DelayedPayment {

    SchedulerInterface public scheduler;
    
    address recipient;
    address owner;
    address public payment;

    uint lockedUntil;
    uint value;
    uint twentyGwei = 20000000000 wei;

    constructor(
        address _scheduler,
        uint    _numBlocks,
        address _recipient,
        uint _value
    )  public payable {
        scheduler = SchedulerInterface(_scheduler);
        lockedUntil = block.number + _numBlocks;
        recipient = _recipient;
        owner = msg.sender;
        value = _value;
   
        uint endowment = scheduler.computeEndowment(
            twentyGwei,
            twentyGwei,
            200000,
            0,
            twentyGwei
        );

        payment = scheduler.schedule.value(endowment)( // 0.1 ether is to pay for gas, bounty and fee
            this,                   // send to self
            "",                     // and trigger fallback function
            [
                200000,             // The amount of gas to be sent with the transaction.
                0,                  // The amount of wei to be sent.
                255,                // The size of the execution window.
                lockedUntil,        // The start of the execution window.
                twentyGwei,    // The gasprice for the transaction (aka 20 gwei)
                twentyGwei,    // The fee included in the transaction.
                twentyGwei,         // The bounty that awards the executor of the transaction.
                twentyGwei * 2     // The required amount of wei the claimer must send as deposit.
            ]
        );

        assert(address(this).balance >= value);
    }

    function () public payable {
        if (msg.value > 0) { //this handles recieving remaining funds sent while scheduling (0.1 ether)
            return;
        } else if (address(this).balance > 0) {
            payout();
        } else {
            revert();
        }
    }

    function payout()
        public returns (bool)
    {
        require(block.number >= lockedUntil);
        
        recipient.transfer(value);
        return true;
    }

    function collectRemaining()
        public returns (bool) 
    {
        owner.transfer(address(this).balance);
    }
}

/// Example of using the Scheduler from a smart contract to delay a payment.
contract RecurringPayment {
    SchedulerInterface public scheduler;
    
    uint paymentInterval;
    uint paymentValue;
    uint lockedUntil;

    address recipient;
    address public currentScheduledTransaction;

    event PaymentScheduled(address indexed scheduledTransaction, address recipient, uint value);
    event PaymentExecuted(address indexed scheduledTransaction, address recipient, uint value);

    function RecurringPayment(
        address _scheduler,
        uint _paymentInterval,
        uint _paymentValue,
        address _recipient
    )  public payable {
        scheduler = SchedulerInterface(_scheduler);
        paymentInterval = _paymentInterval;
        recipient = _recipient;
        paymentValue = _paymentValue;

        schedule();
    }

    function ()
        public payable 
    {
        if (msg.value > 0) { //this handles recieving remaining funds sent while scheduling (0.1 ether)
            return;
        } 
        
        process();
    }

    function process() public returns (bool) {
        payout();
        schedule();
    }

    function payout()
        private returns (bool)
    {
        require(block.number >= lockedUntil);
        require(address(this).balance >= paymentValue);
        
        recipient.transfer(paymentValue);

        emit PaymentExecuted(currentScheduledTransaction, recipient, paymentValue);
        return true;
    }

    function schedule() 
        private returns (bool)
    {
        lockedUntil = block.number + paymentInterval;

        currentScheduledTransaction = scheduler.schedule.value(0.1 ether)( // 0.1 ether is to pay for gas, bounty and fee
            this,                   // send to self
            "",                     // and trigger fallback function
            [
                1000000,            // The amount of gas to be sent with the transaction. Accounts for payout + new contract deployment
                0,                  // The amount of wei to be sent.
                255,                // The size of the execution window.
                lockedUntil,        // The start of the execution window.
                20000000000 wei,    // The gasprice for the transaction (aka 20 gwei)
                20000000000 wei,    // The fee included in the transaction.
                20000000000 wei,         // The bounty that awards the executor of the transaction.
                30000000000 wei     // The required amount of wei the claimer must send as deposit.
            ]
        );

        emit PaymentScheduled(currentScheduledTransaction, recipient, paymentValue);
    }
}

/**
 * @title RequestFactory
 * @dev Contract which will produce new TransactionRequests.
 */
contract RequestFactory is RequestFactoryInterface, CloneFactory, Pausable {
    using IterTools for bool[6];

    TransactionRequestCore public transactionRequestCore;

    uint constant public BLOCKS_BUCKET_SIZE = 240; //~1h
    uint constant public TIMESTAMP_BUCKET_SIZE = 3600; //1h

    constructor(
        address _transactionRequestCore
    ) 
        public 
    {
        require(_transactionRequestCore != 0x0);

        transactionRequestCore = TransactionRequestCore(_transactionRequestCore);
    }

    /**
     * @dev The lowest level interface for creating a transaction request.
     *
     * @param _addressArgs [0] -  meta.owner
     * @param _addressArgs [1] -  paymentData.feeRecipient
     * @param _addressArgs [2] -  txnData.toAddress
     * @param _uintArgs [0]    -  paymentData.fee
     * @param _uintArgs [1]    -  paymentData.bounty
     * @param _uintArgs [2]    -  schedule.claimWindowSize
     * @param _uintArgs [3]    -  schedule.freezePeriod
     * @param _uintArgs [4]    -  schedule.reservedWindowSize
     * @param _uintArgs [5]    -  schedule.temporalUnit
     * @param _uintArgs [6]    -  schedule.windowSize
     * @param _uintArgs [7]    -  schedule.windowStart
     * @param _uintArgs [8]    -  txnData.callGas
     * @param _uintArgs [9]    -  txnData.callValue
     * @param _uintArgs [10]   -  txnData.gasPrice
     * @param _uintArgs [11]   -  claimData.requiredDeposit
     * @param _callData        -  The call data
     */
    function createRequest(
        address[3]  _addressArgs,
        uint[12]    _uintArgs,
        bytes       _callData
    )
        whenNotPaused
        public payable returns (address)
    {
        // Create a new transaction request clone from transactionRequestCore.
        address transactionRequest = createClone(transactionRequestCore);

        // Call initialize on the transaction request clone.
        TransactionRequestCore(transactionRequest).initialize.value(msg.value)(
            [
                msg.sender,       // Created by
                _addressArgs[0],  // meta.owner
                _addressArgs[1],  // paymentData.feeRecipient
                _addressArgs[2]   // txnData.toAddress
            ],
            _uintArgs,            //uint[12]
            _callData
        );

        // Track the address locally
        requests[transactionRequest] = true;

        // Log the creation.
        emit RequestCreated(
            transactionRequest,
            _addressArgs[0],
            getBucket(_uintArgs[7], RequestScheduleLib.TemporalUnit(_uintArgs[5])),
            _uintArgs
        );

        return transactionRequest;
    }

    /**
     *  The same as createRequest except that it requires validation prior to
     *  creation.
     *
     *  Parameters are the same as `createRequest`
     */
    function createValidatedRequest(
        address[3]  _addressArgs,
        uint[12]    _uintArgs,
        bytes       _callData
    )
        public payable returns (address)
    {
        bool[6] memory isValid = validateRequestParams(
            _addressArgs,
            _uintArgs,
            msg.value
        );

        if (!isValid.all()) {
            if (!isValid[0]) {
                emit ValidationError(uint8(Errors.InsufficientEndowment));
            }
            if (!isValid[1]) {
                emit ValidationError(uint8(Errors.ReservedWindowBiggerThanExecutionWindow));
            }
            if (!isValid[2]) {
                emit ValidationError(uint8(Errors.InvalidTemporalUnit));
            }
            if (!isValid[3]) {
                emit ValidationError(uint8(Errors.ExecutionWindowTooSoon));
            }
            if (!isValid[4]) {
                emit ValidationError(uint8(Errors.CallGasTooHigh));
            }
            if (!isValid[5]) {
                emit ValidationError(uint8(Errors.EmptyToAddress));
            }

            // Try to return the ether sent with the message
            msg.sender.transfer(msg.value);
            
            return 0x0;
        }

        return createRequest(_addressArgs, _uintArgs, _callData);
    }

    /// ----------------------------
    /// Internal
    /// ----------------------------

    /*
     *  @dev The enum for launching `ValidationError` events and mapping them to an error.
     */
    enum Errors {
        InsufficientEndowment,
        ReservedWindowBiggerThanExecutionWindow,
        InvalidTemporalUnit,
        ExecutionWindowTooSoon,
        CallGasTooHigh,
        EmptyToAddress
    }

    event ValidationError(uint8 error);

    /*
     * @dev Validate the constructor arguments for either `createRequest` or `createValidatedRequest`.
     */
    function validateRequestParams(
        address[3]  _addressArgs,
        uint[12]    _uintArgs,
        uint        _endowment
    )
        public view returns (bool[6])
    {
        return RequestLib.validate(
            [
                msg.sender,      // meta.createdBy
                _addressArgs[0],  // meta.owner
                _addressArgs[1],  // paymentData.feeRecipient
                _addressArgs[2]   // txnData.toAddress
            ],
            _uintArgs,
            _endowment
        );
    }

    /// Mapping to hold known requests.
    mapping (address => bool) requests;

    function isKnownRequest(address _address)
        public view returns (bool isKnown)
    {
        return requests[_address];
    }

    function getBucket(uint windowStart, RequestScheduleLib.TemporalUnit unit)
        public pure returns(int)
    {
        uint bucketSize;
        /* since we want to handle both blocks and timestamps
            and do not want to get into case where buckets overlaps
            block buckets are going to be negative ints
            timestamp buckets are going to be positive ints
            we&#39;ll overflow after 2**255-1 blocks instead of 2**256-1 since we encoding this on int256
        */
        int sign;

        if (unit == RequestScheduleLib.TemporalUnit.Blocks) {
            bucketSize = BLOCKS_BUCKET_SIZE;
            sign = -1;
        } else if (unit == RequestScheduleLib.TemporalUnit.Timestamp) {
            bucketSize = TIMESTAMP_BUCKET_SIZE;
            sign = 1;
        } else {
            revert();
        }
        return sign * int(windowStart - (windowStart % bucketSize));
    }
}