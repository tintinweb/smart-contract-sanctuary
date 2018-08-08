// File: contracts/FlightDelayAccessControllerInterface.sol

/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description	AccessControllerInterface
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock
 */

pragma solidity ^0.4.11;


contract FlightDelayAccessControllerInterface {

    function setPermissionById(uint8 _perm, bytes32 _id) public;

    function setPermissionById(uint8 _perm, bytes32 _id, bool _access) public;

    function setPermissionByAddress(uint8 _perm, address _addr) public;

    function setPermissionByAddress(uint8 _perm, address _addr, bool _access) public;

    function checkPermission(uint8 _perm, address _addr) public returns (bool _success);
}

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

// File: contracts/FlightDelayDatabaseInterface.sol

/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description Database contract interface
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock, Stephan Karpischek
 */

pragma solidity ^0.4.11;



contract FlightDelayDatabaseInterface is FlightDelayDatabaseModel {

    uint public MIN_DEPARTURE_LIM;

    uint public MAX_DEPARTURE_LIM;

    bytes32[] public validOrigins;

    bytes32[] public validDestinations;

    function countOrigins() public constant returns (uint256 _length);

    function getOriginByIndex(uint256 _i) public constant returns (bytes32 _origin);

    function countDestinations() public constant returns (uint256 _length);

    function getDestinationByIndex(uint256 _i) public constant returns (bytes32 _destination);

    function setAccessControl(address _contract, address _caller, uint8 _perm) public;

    function setAccessControl(
        address _contract,
        address _caller,
        uint8 _perm,
        bool _access
    ) public;

    function getAccessControl(address _contract, address _caller, uint8 _perm) public returns (bool _allowed) ;

    function setLedger(uint8 _index, int _value) public;

    function getLedger(uint8 _index) public returns (int _value) ;

    function getCustomerPremium(uint _policyId) public returns (address _customer, uint _premium) ;

    function getPolicyData(uint _policyId) public returns (address _customer, uint _premium, uint _weight) ;

    function getPolicyState(uint _policyId) public returns (policyState _state) ;

    function getRiskId(uint _policyId) public returns (bytes32 _riskId);

    function createPolicy(address _customer, uint _premium, Currency _currency, bytes32 _customerExternalId, bytes32 _riskId) public returns (uint _policyId) ;

    function setState(
        uint _policyId,
        policyState _state,
        uint _stateTime,
        bytes32 _stateMessage
    ) public;

    function setWeight(uint _policyId, uint _weight, bytes _proof) public;

    function setPayouts(uint _policyId, uint _calculatedPayout, uint _actualPayout) public;

    function setDelay(uint _policyId, uint8 _delay, uint _delayInMinutes) public;

    function getRiskParameters(bytes32 _riskId)
        public returns (bytes32 _carrierFlightNumber, bytes32 _departureYearMonthDay, uint _arrivalTime) ;

    function getPremiumFactors(bytes32 _riskId)
        public returns (uint _cumulatedWeightedPremium, uint _premiumMultiplier);

    function createUpdateRisk(bytes32 _carrierFlightNumber, bytes32 _departureYearMonthDay, uint _arrivalTime)
        public returns (bytes32 _riskId);

    function setPremiumFactors(bytes32 _riskId, uint _cumulatedWeightedPremium, uint _premiumMultiplier) public;

    function getOraclizeCallback(bytes32 _queryId)
        public returns (uint _policyId, uint _oraclizeTime) ;

    function getOraclizePolicyId(bytes32 _queryId)
        public returns (uint _policyId) ;

    function createOraclizeCallback(
        bytes32 _queryId,
        uint _policyId,
        oraclizeState _oraclizeState,
        uint _oraclizeTime
    ) public;

    function checkTime(bytes32 _queryId, bytes32 _riskId, uint _offset)
        public returns (bool _result) ;
}

// File: contracts/FlightDelayLedgerInterface.sol

/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description	Ledger contract interface
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock, Stephan Karpischek
 */

pragma solidity ^0.4.11;



contract FlightDelayLedgerInterface is FlightDelayDatabaseModel {

    function receiveFunds(Acc _to) public payable;

    function sendFunds(address _recipient, Acc _from, uint _amount) public returns (bool _success);

    function bookkeeping(Acc _from, Acc _to, uint amount) public;
}

// File: contracts/FlightDelayUnderwriteInterface.sol

/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description	Underwrite contract interface
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock, Stephan Karpischek
 */

pragma solidity ^0.4.11;


contract FlightDelayUnderwriteInterface {

    function scheduleUnderwriteOraclizeCall(uint _policyId, bytes32 _carrierFlightNumber) public;
}

// File: contracts/convertLib.sol

/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description	Conversions
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock
 */

pragma solidity ^0.4.11;


contract ConvertLib {

    // .. since beginning of the year
    uint16[12] days_since = [
        11,
        42,
        70,
        101,
        131,
        162,
        192,
        223,
        254,
        284,
        315,
        345
    ];

    function b32toString(bytes32 x) internal returns (string) {
        // gas usage: about 1K gas per char.
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;

        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }

        bytes memory bytesStringTrimmed = new bytes(charCount);

        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }

        return string(bytesStringTrimmed);
    }

    function b32toHexString(bytes32 x) returns (string) {
        bytes memory b = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            uint8 by = uint8(uint(x) / (2**(8*(31 - i))));
            uint8 high = by/16;
            uint8 low = by - 16*high;
            if (high > 9) {
                high += 39;
            }
            if (low > 9) {
                low += 39;
            }
            b[2*i] = byte(high+48);
            b[2*i+1] = byte(low+48);
        }

        return string(b);
    }

    function parseInt(string _a) internal returns (uint) {
        return parseInt(_a, 0);
    }

    // parseInt(parseFloat*10^_b)
    function parseInt(string _a, uint _b) internal returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i<bresult.length; i++) {
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)) {
                if (decimals) {
                    if (_b == 0) {
                        break;
                    } else {
                        _b--;
                    }
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) {
                decimals = true;
            }
        }
        if (_b > 0) {
            mint *= 10**_b;
        }
        return mint;
    }

    // the following function yields correct results in the time between 1.3.2016 and 28.02.2020,
    // so within the validity of the contract its correct.
    function toUnixtime(bytes32 _dayMonthYear) constant returns (uint unixtime) {
        // _day_month_year = /dep/2016/09/10
        bytes memory bDmy = bytes(b32toString(_dayMonthYear));
        bytes memory temp2 = bytes(new string(2));
        bytes memory temp4 = bytes(new string(4));

        temp4[0] = bDmy[5];
        temp4[1] = bDmy[6];
        temp4[2] = bDmy[7];
        temp4[3] = bDmy[8];
        uint year = parseInt(string(temp4));

        temp2[0] = bDmy[10];
        temp2[1] = bDmy[11];
        uint month = parseInt(string(temp2));

        temp2[0] = bDmy[13];
        temp2[1] = bDmy[14];
        uint day = parseInt(string(temp2));

        unixtime = ((year - 1970) * 365 + days_since[month-1] + day) * 86400;
    }
}

// File: contracts/FlightDelayNewPolicy.sol

/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description NewPolicy contract.
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock
 */

pragma solidity ^0.4.11;









contract FlightDelayNewPolicy is FlightDelayControlledContract, FlightDelayConstants, ConvertLib {

    FlightDelayAccessControllerInterface FD_AC;
    FlightDelayDatabaseInterface FD_DB;
    FlightDelayLedgerInterface FD_LG;
    FlightDelayUnderwriteInterface FD_UW;

    function FlightDelayNewPolicy(address _controller) public {
        setController(_controller);
    }

    function setContracts() public onlyController {
        FD_AC = FlightDelayAccessControllerInterface(getContract("FD.AccessController"));
        FD_DB = FlightDelayDatabaseInterface(getContract("FD.Database"));
        FD_LG = FlightDelayLedgerInterface(getContract("FD.Ledger"));
        FD_UW = FlightDelayUnderwriteInterface(getContract("FD.Underwrite"));

        FD_AC.setPermissionByAddress(101, 0x0);
        FD_AC.setPermissionById(102, "FD.Controller");
        FD_AC.setPermissionById(103, "FD.Owner");
    }

    function bookAndCalcRemainingPremium() internal returns (uint) {
        uint v = msg.value;
        uint reserve = v * RESERVE_PERCENT / 100;
        uint remain = v - reserve;
        uint reward = remain * REWARD_PERCENT / 100;

        // FD_LG.bookkeeping(Acc.Balance, Acc.Premium, v);
        FD_LG.bookkeeping(Acc.Premium, Acc.RiskFund, reserve);
        FD_LG.bookkeeping(Acc.Premium, Acc.Reward, reward);

        return (uint(remain - reward));
    }

    function maintenanceMode(bool _on) public {
        if (FD_AC.checkPermission(103, msg.sender)) {
            FD_AC.setPermissionByAddress(101, 0x0, !_on);
        }
    }

    // create new policy
    function newPolicy(
        bytes32 _carrierFlightNumber,
        bytes32 _departureYearMonthDay,
        uint256 _departureTime,
        uint256 _arrivalTime,
        Currency _currency,
        bytes32 _customerExternalId) public payable
    {
        // here we can switch it off.
        require(FD_AC.checkPermission(101, 0x0));

        // solidity checks for valid _currency parameter
        if (_currency == Currency.ETH) {
            // ETH
            if (msg.value < MIN_PREMIUM || msg.value > MAX_PREMIUM) {
                LogPolicyDeclined(0, "Invalid premium value ETH");
                FD_LG.sendFunds(msg.sender, Acc.Premium, msg.value);
                return;
            }
        } else {
            require(msg.sender == getContract("FD.CustomersAdmin"));

            if (_currency == Currency.EUR) {
                // EUR
                if (msg.value < MIN_PREMIUM_EUR || msg.value > MAX_PREMIUM_EUR) {
                    LogPolicyDeclined(0, "Invalid premium value EUR");
                    FD_LG.sendFunds(msg.sender, Acc.Premium, msg.value);
                    return;
                }
            }

            if (_currency == Currency.USD) {
                // USD
                if (msg.value < MIN_PREMIUM_USD || msg.value > MAX_PREMIUM_USD) {
                    LogPolicyDeclined(0, "Invalid premium value USD");
                    FD_LG.sendFunds(msg.sender, Acc.Premium, msg.value);
                    return;
                }
            }

            if (_currency == Currency.GBP) {
                // GBP
                if (msg.value < MIN_PREMIUM_GBP || msg.value > MAX_PREMIUM_GBP) {
                    LogPolicyDeclined(0, "Invalid premium value GBP");
                    FD_LG.sendFunds(msg.sender, Acc.Premium, msg.value);
                    return;
                }
            }
        }

        // forward premium
        FD_LG.receiveFunds.value(msg.value)(Acc.Premium);


        // don&#39;t Accept flights with departure time earlier than in 24 hours,
        // or arrivalTime before departureTime,
        // or departureTime after Mon, 26 Sep 2016 12:00:00 GMT
        uint dmy = toUnixtime(_departureYearMonthDay);

// --> debug-mode
//            LogUintTime("NewPolicy: dmy: ", dmy);
//            LogUintTime("NewPolicy: _departureTime: ", _departureTime);
// <-- debug-mode

        if (
            _arrivalTime < _departureTime ||
            _arrivalTime > _departureTime + MAX_FLIGHT_DURATION ||
            _departureTime < now + MIN_TIME_BEFORE_DEPARTURE ||
            _departureTime > CONTRACT_DEAD_LINE ||
            _departureTime < dmy ||
            _departureTime > dmy + 24 hours ||
            _departureTime < FD_DB.MIN_DEPARTURE_LIM() ||
            _departureTime > FD_DB.MAX_DEPARTURE_LIM()
        ) {
            LogPolicyDeclined(0, "Invalid arrival/departure time");
            FD_LG.sendFunds(msg.sender, Acc.Premium, msg.value);
            return;
        }

        bytes32 riskId = FD_DB.createUpdateRisk(_carrierFlightNumber, _departureYearMonthDay, _arrivalTime);

        var (cumulatedWeightedPremium, premiumMultiplier) = FD_DB.getPremiumFactors(riskId);

        // roughly check, whether MAX_CUMULATED_WEIGHTED_PREMIUM will be exceeded
        // (we Accept the inAccuracy that the real remaining premium is 3% lower),
        // but we are conservative;
        // if this is the first policy, the left side will be 0
        if (msg.value * premiumMultiplier + cumulatedWeightedPremium >= MAX_CUMULATED_WEIGHTED_PREMIUM) {
            LogPolicyDeclined(0, "Cluster risk");
            FD_LG.sendFunds(msg.sender, Acc.Premium, msg.value);
            return;
        } else if (cumulatedWeightedPremium == 0) {
            // at the first police, we set r.cumulatedWeightedPremium to the max.
            // this prevents further polices to be Accepted, until the correct
            // value is calculated after the first callback from the oracle.
            FD_DB.setPremiumFactors(riskId, MAX_CUMULATED_WEIGHTED_PREMIUM, premiumMultiplier);
        }

        uint premium = bookAndCalcRemainingPremium();
        uint policyId = FD_DB.createPolicy(msg.sender, premium, _currency, _customerExternalId, riskId);

        if (premiumMultiplier > 0) {
            FD_DB.setPremiumFactors(
                riskId,
                cumulatedWeightedPremium + premium * premiumMultiplier,
                premiumMultiplier
            );
        }

        // now we have successfully applied
        FD_DB.setState(
            policyId,
            policyState.Applied,
            now,
            "Policy applied by customer"
        );

        LogPolicyApplied(
            policyId,
            msg.sender,
            _carrierFlightNumber,
            premium
        );

        LogExternal(
            policyId,
            msg.sender,
            _customerExternalId
        );

        FD_UW.scheduleUnderwriteOraclizeCall(policyId, _carrierFlightNumber);
    }
}