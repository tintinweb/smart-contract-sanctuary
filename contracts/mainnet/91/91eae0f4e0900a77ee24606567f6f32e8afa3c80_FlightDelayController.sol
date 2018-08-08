// File: contracts/FlightDelayConstants.sol

/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description	Events and Constants
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock
 */

pragma solidity ^0.4.11;


contract FlightDelayConstants {

    /*
    * General events
    */

// --> test-mode
//        event LogUint(string _message, uint _uint);
//        event LogUintEth(string _message, uint ethUint);
//        event LogUintTime(string _message, uint timeUint);
//        event LogInt(string _message, int _int);
//        event LogAddress(string _message, address _address);
//        event LogBytes32(string _message, bytes32 hexBytes32);
//        event LogBytes(string _message, bytes hexBytes);
//        event LogBytes32Str(string _message, bytes32 strBytes32);
//        event LogString(string _message, string _string);
//        event LogBool(string _message, bool _bool);
//        event Log(address);
// <-- test-mode

    event LogPolicyApplied(
        uint _policyId,
        address _customer,
        bytes32 strCarrierFlightNumber,
        uint ethPremium
    );
    event LogPolicyAccepted(
        uint _policyId,
        uint _statistics0,
        uint _statistics1,
        uint _statistics2,
        uint _statistics3,
        uint _statistics4,
        uint _statistics5
    );
    event LogPolicyPaidOut(
        uint _policyId,
        uint ethAmount
    );
    event LogPolicyExpired(
        uint _policyId
    );
    event LogPolicyDeclined(
        uint _policyId,
        bytes32 strReason
    );
    event LogPolicyManualPayout(
        uint _policyId,
        bytes32 strReason
    );
    event LogSendFunds(
        address _recipient,
        uint8 _from,
        uint ethAmount
    );
    event LogReceiveFunds(
        address _sender,
        uint8 _to,
        uint ethAmount
    );
    event LogSendFail(
        uint _policyId,
        bytes32 strReason
    );
    event LogOraclizeCall(
        uint _policyId,
        bytes32 hexQueryId,
        string _oraclizeUrl,
        uint256 _oraclizeTime
    );
    event LogOraclizeCallback(
        uint _policyId,
        bytes32 hexQueryId,
        string _result,
        bytes hexProof
    );
    event LogSetState(
        uint _policyId,
        uint8 _policyState,
        uint _stateTime,
        bytes32 _stateMessage
    );
    event LogExternal(
        uint256 _policyId,
        address _address,
        bytes32 _externalId
    );

    /*
    * General constants
    */
    // contracts release version
    uint public constant MAJOR_VERSION = 1;
    uint public constant MINOR_VERSION = 0;
    uint public constant PATCH_VERSION = 2;

    // minimum observations for valid prediction
    uint constant MIN_OBSERVATIONS = 10;
    // minimum premium to cover costs
    uint constant MIN_PREMIUM = 50 finney;
    // maximum premium
    uint constant MAX_PREMIUM = 1 ether;
    // maximum payout
    uint constant MAX_PAYOUT = 1100 finney;

    uint constant MIN_PREMIUM_EUR = 1500 wei;
    uint constant MAX_PREMIUM_EUR = 29000 wei;
    uint constant MAX_PAYOUT_EUR = 30000 wei;

    uint constant MIN_PREMIUM_USD = 1700 wei;
    uint constant MAX_PREMIUM_USD = 34000 wei;
    uint constant MAX_PAYOUT_USD = 35000 wei;

    uint constant MIN_PREMIUM_GBP = 1300 wei;
    uint constant MAX_PREMIUM_GBP = 25000 wei;
    uint constant MAX_PAYOUT_GBP = 270 wei;

    // maximum cumulated weighted premium per risk
    uint constant MAX_CUMULATED_WEIGHTED_PREMIUM = 60 ether;
    // 1 percent for DAO, 1 percent for maintainer
    uint8 constant REWARD_PERCENT = 2;
    // reserve for tail risks
    uint8 constant RESERVE_PERCENT = 1;
    // the weight pattern; in future versions this may become part of the policy struct.
    // currently can&#39;t be constant because of compiler restrictions
    // WEIGHT_PATTERN[0] is not used, just to be consistent
    uint8[6] WEIGHT_PATTERN = [
        0,
        0,
        0,
        30,
        50,
        50
    ];

// --> prod-mode
    // DEFINITIONS FOR ROPSTEN AND MAINNET
    // minimum time before departure for applying
    uint constant MIN_TIME_BEFORE_DEPARTURE	= 24 hours; // for production
    // check for delay after .. minutes after scheduled arrival
    uint constant CHECK_PAYOUT_OFFSET = 15 minutes; // for production
// <-- prod-mode

// --> test-mode
//        // DEFINITIONS FOR LOCAL TESTNET
//        // minimum time before departure for applying
//        uint constant MIN_TIME_BEFORE_DEPARTURE = 1 seconds; // for testing
//        // check for delay after .. minutes after scheduled arrival
//        uint constant CHECK_PAYOUT_OFFSET = 1 seconds; // for testing
// <-- test-mode

    // maximum duration of flight
    uint constant MAX_FLIGHT_DURATION = 2 days;
    // Deadline for acceptance of policies: 31.12.2030 (Testnet)
    uint constant CONTRACT_DEAD_LINE = 1922396399;

    // gas Constants for oraclize
    uint constant ORACLIZE_GAS = 700000;
    uint constant ORACLIZE_GASPRICE = 4000000000;


    /*
    * URLs and query strings for oraclize
    */

// --> prod-mode
    // DEFINITIONS FOR ROPSTEN AND MAINNET
    string constant ORACLIZE_RATINGS_BASE_URL =
        // ratings api is v1, see https://developer.flightstats.com/api-docs/ratings/v1
        "[URL] json(https://api.flightstats.com/flex/ratings/rest/v1/json/flight/";
    string constant ORACLIZE_RATINGS_QUERY =
        "?${[decrypt] BJoM0BfTe82RtghrzzCbNA7b9E9tQIX8LtM+pRRh22RfQ5QhnVAv6Kk4SyaMwQKczC7YtinJ/Xm6PZMgKnWN7+/pFUfI2YcxaAW0vYuXJF4zCTxPYXa6j4shhce60AMBeKoZZsgn6Og+olgSpgpfi4MwkmmytwdCLHqat3gGUPklBhM1HR0x}).ratings[0][&#39;observations&#39;,&#39;late15&#39;,&#39;late30&#39;,&#39;late45&#39;,&#39;cancelled&#39;,&#39;diverted&#39;,&#39;arrivalAirportFsCode&#39;,&#39;departureAirportFsCode&#39;]";
    string constant ORACLIZE_STATUS_BASE_URL =
        // flight status api is v2, see https://developer.flightstats.com/api-docs/flightstatus/v2/flight
        "[URL] json(https://api.flightstats.com/flex/flightstatus/rest/v2/json/flight/status/";
    string constant ORACLIZE_STATUS_QUERY =
        // pattern:
        "?${[decrypt] BA3YyqF4iMQszBawvgG82bqX3fw7JoWA1thFsboUECR/L8JkBCgvaThg1LcUWbIntosEKs/kvqyzOtvdQfMgjYPV0c6hsq/gKQkmJYILZmLY4SgBebH8g0qbfrrjxF5gEbfCi2qoR6PSxcQzKIjgd4HvAaumlQd4CkJLmY463ymqNN9B8/PL}&utc=true).flightStatuses[0][&#39;status&#39;,&#39;delays&#39;,&#39;operationalTimes&#39;]";
// <-- prod-mode

// --> test-mode
//        // DEFINITIONS FOR LOCAL TESTNET
//        string constant ORACLIZE_RATINGS_BASE_URL =
//            // ratings api is v1, see https://developer.flightstats.com/api-docs/ratings/v1
//            "[URL] json(https://api-test.etherisc.com/flex/ratings/rest/v1/json/flight/";
//        string constant ORACLIZE_RATINGS_QUERY =
//            // for testrpc:
//            ").ratings[0][&#39;observations&#39;,&#39;late15&#39;,&#39;late30&#39;,&#39;late45&#39;,&#39;cancelled&#39;,&#39;diverted&#39;,&#39;arrivalAirportFsCode&#39;,&#39;departureAirportFsCode&#39;]";
//        string constant ORACLIZE_STATUS_BASE_URL =
//            // flight status api is v2, see https://developer.flightstats.com/api-docs/flightstatus/v2/flight
//            "[URL] json(https://api-test.etherisc.com/flex/flightstatus/rest/v2/json/flight/status/";
//        string constant ORACLIZE_STATUS_QUERY =
//            // for testrpc:
//            "?utc=true).flightStatuses[0][&#39;status&#39;,&#39;delays&#39;,&#39;operationalTimes&#39;]";
// <-- test-mode
}

// File: contracts/FlightDelayControllerInterface.sol

/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description Contract interface
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock, Stephan Karpischek
 */

pragma solidity ^0.4.11;


contract FlightDelayControllerInterface {

    function isOwner(address _addr) public returns (bool _isOwner);

    function selfRegister(bytes32 _id) public returns (bool result);

    function getContract(bytes32 _id) public returns (address _addr);
}

// File: contracts/FlightDelayDatabaseModel.sol

/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description Database model
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock, Stephan Karpischek
 */

pragma solidity ^0.4.11;


contract FlightDelayDatabaseModel {

    // Ledger accounts.
    enum Acc {
        Premium,      // 0
        RiskFund,     // 1
        Payout,       // 2
        Balance,      // 3
        Reward,       // 4
        OraclizeCosts // 5
    }

    // policy Status Codes and meaning:
    //
    // 00 = Applied:	  the customer has payed a premium, but the oracle has
    //					        not yet checked and confirmed.
    //					        The customer can still revoke the policy.
    // 01 = Accepted:	  the oracle has checked and confirmed.
    //					        The customer can still revoke the policy.
    // 02 = Revoked:	  The customer has revoked the policy.
    //					        The premium minus cancellation fee is payed back to the
    //					        customer by the oracle.
    // 03 = PaidOut:	  The flight has ended with delay.
    //					        The oracle has checked and payed out.
    // 04 = Expired:	  The flight has endet with <15min. delay.
    //					        No payout.
    // 05 = Declined:	  The application was invalid.
    //					        The premium minus cancellation fee is payed back to the
    //					        customer by the oracle.
    // 06 = SendFailed:	During Revoke, Decline or Payout, sending ether failed
    //					        for unknown reasons.
    //					        The funds remain in the contracts RiskFund.


    //                   00       01        02       03        04      05           06
    enum policyState { Applied, Accepted, Revoked, PaidOut, Expired, Declined, SendFailed }

    // oraclize callback types:
    enum oraclizeState { ForUnderwriting, ForPayout }

    //               00   01   02   03
    enum Currency { ETH, EUR, USD, GBP }

    // the policy structure: this structure keeps track of the individual parameters of a policy.
    // typically customer address, premium and some status information.
    struct Policy {
        // 0 - the customer
        address customer;

        // 1 - premium
        uint premium;
        // risk specific parameters:
        // 2 - pointer to the risk in the risks mapping
        bytes32 riskId;
        // custom payout pattern
        // in future versions, customer will be able to tamper with this array.
        // to keep things simple, we have decided to hard-code the array for all policies.
        // uint8[5] pattern;
        // 3 - probability weight. this is the central parameter
        uint weight;
        // 4 - calculated Payout
        uint calculatedPayout;
        // 5 - actual Payout
        uint actualPayout;

        // status fields:
        // 6 - the state of the policy
        policyState state;
        // 7 - time of last state change
        uint stateTime;
        // 8 - state change message/reason
        bytes32 stateMessage;
        // 9 - TLSNotary Proof
        bytes proof;
        // 10 - Currency
        Currency currency;
        // 10 - External customer id
        bytes32 customerExternalId;
    }

    // the risk structure; this structure keeps track of the risk-
    // specific parameters.
    // several policies can share the same risk structure (typically
    // some people flying with the same plane)
    struct Risk {
        // 0 - Airline Code + FlightNumber
        bytes32 carrierFlightNumber;
        // 1 - scheduled departure and arrival time in the format /dep/YYYY/MM/DD
        bytes32 departureYearMonthDay;
        // 2 - the inital arrival time
        uint arrivalTime;
        // 3 - the final delay in minutes
        uint delayInMinutes;
        // 4 - the determined delay category (0-5)
        uint8 delay;
        // 5 - we limit the cumulated weighted premium to avoid cluster risks
        uint cumulatedWeightedPremium;
        // 6 - max cumulated Payout for this risk
        uint premiumMultiplier;
    }

    // the oraclize callback structure: we use several oraclize calls.
    // all oraclize calls will result in a common callback to __callback(...).
    // to keep track of the different querys we have to introduce this struct.
    struct OraclizeCallback {
        // for which policy have we called?
        uint policyId;
        // for which purpose did we call? {ForUnderwrite | ForPayout}
        oraclizeState oState;
        // time
        uint oraclizeTime;
    }

    struct Customer {
        bytes32 customerExternalId;
        bool identityConfirmed;
    }
}

// File: contracts/FlightDelayControlledContract.sol

/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description Controlled contract Interface
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock
 */

pragma solidity ^0.4.11;




contract FlightDelayControlledContract is FlightDelayDatabaseModel {

    address public controller;
    FlightDelayControllerInterface FD_CI;

    modifier onlyController() {
        require(msg.sender == controller);
        _;
    }

    function setController(address _controller) internal returns (bool _result) {
        controller = _controller;
        FD_CI = FlightDelayControllerInterface(_controller);
        _result = true;
    }

    function destruct() public onlyController {
        selfdestruct(controller);
    }

    function setContracts() public onlyController {}

    function getContract(bytes32 _id) internal returns (address _addr) {
        _addr = FD_CI.getContract(_id);
    }
}

// File: contracts/Owned.sol

/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description	Owned pattern
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock, Stephan Karpischek
 */

pragma solidity ^0.4.11;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Owned {

    address public owner;

    /**
     * @dev The Owned constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Owned() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
}

// File: contracts/FlightDelayController.sol

/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description Controller contract
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock
 */

pragma solidity ^0.4.11;




contract FlightDelayController is Owned, FlightDelayConstants {

    struct Controller {
        address addr;
        bool isControlled;
        bool isInitialized;
    }

    mapping (bytes32 => Controller) public contracts;
    bytes32[] public contractIds;

    /**
    * Constructor.
    */
    function FlightDelayController() public {
        registerContract(owner, "FD.Owner", false);
        registerContract(address(this), "FD.Controller", false);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
        setContract(_newOwner, "FD.Owner", false);
    }

    /**
    * Store address of one contract in mapping.
    * @param _addr       Address of contract
    * @param _id         ID of contract
    */
    function setContract(address _addr, bytes32 _id, bool _isControlled) internal {
        contracts[_id].addr = _addr;
        contracts[_id].isControlled = _isControlled;
    }

    /**
    * Get contract address from ID. This function is called by the
    * contract&#39;s setContracts function.
    * @param _id         ID of contract
    * @return The address of the contract.
    */
    function getContract(bytes32 _id) public returns (address _addr) {
        _addr = contracts[_id].addr;
    }

    /**
    * Registration of contracts.
    * It will only accept calls of deployments initiated by the owner.
    * @param _id         ID of contract
    * @return  bool        success
    */
    function registerContract(address _addr, bytes32 _id, bool _isControlled) public onlyOwner returns (bool _result) {
        setContract(_addr, _id, _isControlled);
        contractIds.push(_id);
        _result = true;
    }

    /**
    * Deregister a contract.
    * In future, contracts should be exchangeable.
    * @param _id         ID of contract
    * @return  bool        success
    */
    function deregister(bytes32 _id) public onlyOwner returns (bool _result) {
        if (getContract(_id) == 0x0) {
            return false;
        }
        setContract(0x0, _id, false);
        _result = true;
    }

    /**
    * After deploying all contracts, this function is called and calls
    * setContracts() for every registered contract.
    * This call pulls the addresses of the needed contracts in the respective contract.
    * We assume that contractIds.length is small, so this won&#39;t run out of gas.
    */
    function setAllContracts() public onlyOwner {
        FlightDelayControlledContract controlledContract;
        // TODO: Check for upper bound for i
        // i = 0 is FD.Owner, we skip this. // check!
        for (uint i = 0; i < contractIds.length; i++) {
            if (contracts[contractIds[i]].isControlled == true) {
                controlledContract = FlightDelayControlledContract(contracts[contractIds[i]].addr);
                controlledContract.setContracts();
            }
        }
    }

    function setOneContract(uint i) public onlyOwner {
        FlightDelayControlledContract controlledContract;
        // TODO: Check for upper bound for i
        controlledContract = FlightDelayControlledContract(contracts[contractIds[i]].addr);
        controlledContract.setContracts();
    }

    /**
    * Destruct one contract.
    * @param _id         ID of contract to destroy.
    */
    function destructOne(bytes32 _id) public onlyOwner {
        address addr = getContract(_id);
        if (addr != 0x0) {
            FlightDelayControlledContract(addr).destruct();
        }
    }

    /**
    * Destruct all contracts.
    * We assume that contractIds.length is small, so this won&#39;t run out of gas.
    * Otherwise, you can still destroy one contract after the other with destructOne.
    */
    function destructAll() public onlyOwner {
        // TODO: Check for upper bound for i
        for (uint i = 0; i < contractIds.length; i++) {
            if (contracts[contractIds[i]].isControlled == true) {
                destructOne(contractIds[i]);
            }
        }

        selfdestruct(owner);
    }
}