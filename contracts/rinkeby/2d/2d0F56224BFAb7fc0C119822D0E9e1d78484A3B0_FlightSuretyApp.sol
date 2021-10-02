pragma solidity ^0.4.24;

import "./SafeMath.sol";

interface iFlightSuretyData {
    function registerAirline(address airlineAddress) external;
    function getTotalPayedAirlines() external view returns(uint256 _totalAirlines);
    function getAirlineRegistrationStatus(address airlineAddress) external view returns(bool _status);
    function getAirlinePaymentStatus(address airlineAddress) external view returns(bool _status);
    function getAirlineRegistrationVote(address registeredAirline, address newAirlineAddress) external view returns(bool _status);
    
    function registerFlight(bytes32 key) external;
    function getFlightRegistrationStatus(bytes32 key) external view returns(bool _status);
    function requestFlight(bytes32 key, uint8 index1, uint8 index2, uint8 index3) external;
    function getFlightRequestStatus(bytes32 key) external view returns(bool _stats);
    function getFlightIndexesRequired(bytes32 key) external view returns(uint8 _index1, uint8 _index2, uint8 _index3);
    function flightStatusUpdate(bytes32 key, uint8 code) external;
    function getFlightStatusCode(bytes32 key) external view returns(uint8 _status);
    
    function getInsuranceDeposit(address insureeAddress, bytes32 key) external view returns(uint256 _deposit);
    function getCreditedInsureeStatus(address insureeAddress, bytes32 key) external view returns(bool _status);
    function getTotalAccountCredit(address insureeAddress) external view returns(uint256 _balance);
    function creditInsuree(address insureeAddress, bytes32 key, uint256 totalAccountCredit) external;
    
    function getOracleServerRegistrationStatus(address server) external view returns(bool status);
    function getTotalOracles(address server) external view returns(uint256 _counter);
    function getOraceIndexes(address server, uint256 id) external view returns(uint8 _index1, uint8 _index2, uint8 _index3);
    function getVotesCounter(bytes32 key, uint8 statusCode) external view returns(uint256 _counter);
    function oracleResponseToRequest(bytes32 key, uint8 voteCode) external;
    function oracleServerCleanVotes(bytes32 key, uint8 voteCode) external;
    
    function payAirlineRegistrationFee(address airline) external payable;
    function purchaseInsurance(address insureeAddress, bytes32 key) external payable;
    function registerOracle(address server, uint8 index1, uint8 index2, uint8 index3) external payable;
    function creditWithdraw(address user, uint256 value) external payable;
    
    function checkDataContratBalance() external view returns(uint256 _contractBalance);
    function withdrawAfterProjectEnds(address ownerAddress, uint256 value) external payable;
}

contract FlightSuretyApp {
    using SafeMath for uint256;
/*
=====================================================================================================================
CONTRACT CONFIGURATION
=====================================================================================================================
*/
    bool operationalStatus;
    address owner;
    iFlightSuretyData FlightSecuretyData;
    
    constructor() public {
        operationalStatus = true;
        owner = msg.sender;
    }
    
    modifier requireOwner() {
        require(msg.sender == owner, "Owner is required");
        _;
    }
    
    modifier requireOperational() {
        require(operationalStatus == true, "Contract is not operational");
        _;
    }
    
    function setOperationalStatus(bool status) external
    requireOwner {
        operationalStatus = status;
    }
    
    function getOperationalStatus() external view
    requireOwner
    returns(bool _status) {
        return operationalStatus;
    }
    
    function registerDataContract(address dataContract) external
    requireOwner {
        FlightSecuretyData = iFlightSuretyData(dataContract);
    }
/*
=====================================================================================================================
AIRLINES
=====================================================================================================================
*/
    mapping(address => uint256) private voteCounter;

    modifier requireAirlineRegistrationFeePayed() {
        bool status = FlightSecuretyData.getAirlinePaymentStatus(msg.sender);
        require(status == true, "You haven't paid the registration fee");
        _;
    }
    
    modifier requireTargetAirlineNotRegistered(address newAirlineAddres) {
        bool status = FlightSecuretyData.getAirlineRegistrationStatus(newAirlineAddres);
        require(status == false, "The target airline is already registered");
        _;
    }
    
    function registerAirline(address newAirlineAddress) external 
    requireOperational 
    requireAirlineRegistrationFeePayed 
    requireTargetAirlineNotRegistered(newAirlineAddress) {
        uint256 totalPayedAirlines = FlightSecuretyData.getTotalPayedAirlines();
        if (totalPayedAirlines < 4) {
            FlightSecuretyData.registerAirline(newAirlineAddress);
        } else {
            bool voteStatus = FlightSecuretyData.getAirlineRegistrationVote(msg.sender, newAirlineAddress);
            require(voteStatus == false, "You already voted");
            uint256 requiredVotes = SafeMath.div(totalPayedAirlines, 2);
            requiredVotes = SafeMath.sub(requiredVotes, 1);
            uint256 currentVotes = voteCounter[newAirlineAddress];
            if (currentVotes < requiredVotes) {
                voteCounter[newAirlineAddress] = SafeMath.add(currentVotes, 1);
            } else {
                FlightSecuretyData.registerAirline(newAirlineAddress);
                delete voteCounter[newAirlineAddress];
            }
        }
    }
    
    function getVoteState(address newAirlineAddress) external view
    requireOperational 
    returns(uint256 _currentVotes, uint256 _requiredVotes) {
        uint256 totalPayedAirlines = FlightSecuretyData.getTotalPayedAirlines();
        uint256 requiredVotes = SafeMath.div(totalPayedAirlines, 2);
        return (voteCounter[newAirlineAddress], requiredVotes);
    }
/*
=====================================================================================================================
FLIGHTS
=====================================================================================================================
*/
    modifier requireFlightNotRegistered(string memory flight, uint256 timestamp) {
        bytes32 key = keccak256(abi.encodePacked(flight, timestamp));
        bool status = FlightSecuretyData.getFlightRegistrationStatus(key);
        require(status == false, "Flight is already registered");
        _;
    }
    
    modifier requireFlightRegistered(string memory flight, uint256 timestamp) {
        bytes32 key = keccak256(abi.encodePacked(flight, timestamp));
        bool status = FlightSecuretyData.getFlightRegistrationStatus(key);
        require(status == true, "Flight is not registered");
        _;
    }   
    
    event FLIGHT_REGISTED(string flight, uint256 timestamp);
    
    function registerFlight(string flight, uint256 timestamp) external
    requireOperational
    requireAirlineRegistrationFeePayed
    requireFlightNotRegistered(flight, timestamp) {
        bytes32 key = keccak256(abi.encodePacked(flight, timestamp));
        FlightSecuretyData.registerFlight(key);
        emit FLIGHT_REGISTED(flight, timestamp);
    }
    
    event FLIGHT_REQUESTED(string flight, uint256 timestamp, uint8 index1, uint8 index2, uint8 index3);
    
    function requestFlight(string flight, uint256 timestamp) external
    requireOperational
    requireFlightRegistered(flight, timestamp) {
        bytes32 key = keccak256(abi.encodePacked(flight, timestamp));
        (uint8 index1, uint8 index2, uint8 index3) = indexesThrown();
        FlightSecuretyData.requestFlight(key, index1, index2, index3);
        emit FLIGHT_REQUESTED(flight, timestamp, index1, index2, index3);
    }
    
    modifier requireOracleServer(address server) {
        bool status = FlightSecuretyData.getOracleServerRegistrationStatus(server);
        require(status == true, "Oracle server required");
        _;
    }
    
    event FLIGHT_STATUS_UPDATED(string flight, uint256 timestamp, string status);
    
    function updateFlightStatus(string flight, uint256 timestamp) external 
    requireOperational
    requireOracleServer(msg.sender) {
        bytes32 key = keccak256(abi.encodePacked(flight, timestamp));
        uint8 winnerCode = 0;
        uint256 winnerVoteCount = 0;
        for (uint8 i=0; i<6; i++) {
            uint8 code = i;
            if (code != 0) {
                code = code * 10;
            }
            uint256 codeTotalVotes = FlightSecuretyData.getVotesCounter(key, code);
            if (codeTotalVotes > winnerVoteCount) {
                winnerVoteCount = codeTotalVotes;
                winnerCode = code;
            }
            FlightSecuretyData.oracleServerCleanVotes(key, code);
        }
        string memory status = convertFlightStatusCodeToString(code);
        emit FLIGHT_STATUS_UPDATED(flight, timestamp, status);
        FlightSecuretyData.flightStatusUpdate(key, winnerCode);
    }

    function convertFlightStatusCodeToString(uint8 code) private pure
    returns(string _status) {
        if(code == 0) {
            return "Unknown";
        } else if(code == 10) {
            return "On Time";
        } else if(code == 20) {
            return "Late Airline";
        } else if(code == 30) {
            return "Late Weather";
        } else if(code == 40) {
            return "Late Technical";
        } else if(code == 50) {
            return "Late Other";
        }
    }
/*
=====================================================================================================================
INSUREES
=====================================================================================================================
*/
    function checkInsurance(string flight, uint256 timestamp) external
    requireOperational {
        bytes32 key = keccak256(abi.encodePacked(flight, timestamp));
        bool status = FlightSecuretyData.getCreditedInsureeStatus(msg.sender, key);
        require(status == false, "Insurance has already been covered");
        uint8 code = FlightSecuretyData.getFlightStatusCode(key);
        if (code == 20) {
            uint256 deposit = FlightSecuretyData.getInsuranceDeposit(msg.sender, key);
            deposit = SafeMath.mul(deposit, 3);
            deposit = SafeMath.div(deposit, 2);
            uint256 totalAccountCredit = FlightSecuretyData.getTotalAccountCredit(msg.sender);
            totalAccountCredit = SafeMath.add(totalAccountCredit, deposit);
            FlightSecuretyData.creditInsuree(msg.sender, key, totalAccountCredit);
        }
    }
    
    function getTotalAccountCredit() external view
    requireOperational
    returns(uint256 _balance) {
        return FlightSecuretyData.getTotalAccountCredit(msg.sender);
    }
/*
=====================================================================================================================
ORACLES
=====================================================================================================================
*/
    function getTotalOracles() external view
    requireOperational
    returns(uint256 _counter) {
        return FlightSecuretyData.getTotalOracles(msg.sender);
    }

    function getOraceIndexes(uint256 id) external view
    requireOperational
    returns(uint8 _index1, uint8 _index2, uint8 _index3) {
        return FlightSecuretyData.getOraceIndexes(msg.sender, id);
    }
    
    modifier requireFlightRequested(string flight, uint256 timestamp) {
        bytes32 key = keccak256(abi.encodePacked(flight, timestamp));
        bool status = FlightSecuretyData.getFlightRequestStatus(key);
        require(status == true, "Flight is not requested");
        _;
    }
    
    function oracleResponseToRequest(string flight, uint256 timestamp, uint8 index1, uint8 index2, uint8 index3, uint8 voteCode) external
    requireOperational {
        bytes32 key = keccak256(abi.encodePacked(flight, timestamp));
        bool status = FlightSecuretyData.getFlightRequestStatus(key);
        require(status == true, "Flight is not requested");
        bool registrationStatus = FlightSecuretyData.getOracleServerRegistrationStatus(msg.sender);
        require(registrationStatus == true, "Oracle server required");
        require((voteCode == 0) || (voteCode == 10) || (voteCode == 20) || (voteCode == 30) || (voteCode == 40) || (voteCode == 50), "Code not registered");
        (uint8 _index1, uint8 _index2, uint8 _index3) = FlightSecuretyData.getFlightIndexesRequired(key);
        require((index1 == _index1) || (index2 == _index2) || (index3 == _index3), "Required at least one index to match");
        FlightSecuretyData.oracleResponseToRequest(key, voteCode);
    }
/*
=====================================================================================================================
INDEXES GENERATOR SECTION
=====================================================================================================================
*/
    function indexesThrown() private view returns(uint8 _index1, uint8 _index2, uint8 _index3) {
        uint8 index1 = generateIndex1();
        uint8 index2 = generateIndex2(index1);
        uint8 index3 = generateIndex3(index1, index2);
        return (index1, index2, index3);
    }

    function generateIndex1() private view returns(uint8 _index) {
        uint256 mod = 10;
        uint256 time = block.timestamp;
        uint256 difficulty = block.difficulty;
        uint8 value = uint8(SafeMath.mod(uint256(keccak256(abi.encodePacked(time, difficulty, msg.sender))), mod));
        return value;
    }

    function generateIndex2(uint8 _index1) private view returns(uint8 _index) {
        uint256 mod = 10;
        uint256 time = block.timestamp;
        uint256 difficulty = block.difficulty;
        uint8 value = uint8(SafeMath.mod(uint256(keccak256(abi.encodePacked(time, difficulty, msg.sender))), mod));
        while(value == _index1) {
            time = SafeMath.add(time, 500);
            difficulty = SafeMath.add(difficulty, 700);
            value = uint8(SafeMath.mod(uint256(keccak256(abi.encodePacked(time, difficulty, msg.sender))), mod));
        }
        return value;
    }

    function generateIndex3(uint8 _index1, uint8 _index2) private view returns(uint8 _index) {
        uint256 mod = 10;
        uint256 time = block.timestamp;
        uint256 difficulty = block.difficulty;
        uint8 value = uint8(SafeMath.mod(uint256(keccak256(abi.encodePacked(time, difficulty, msg.sender))), mod));
        while((value == _index1) || (value == _index2)) {
            time = SafeMath.add(time, 500);
            difficulty = SafeMath.add(difficulty, 700);
            value = uint8(SafeMath.mod(uint256(keccak256(abi.encodePacked(time, difficulty, msg.sender))), mod));
        }
        return value;
    }
/*
=====================================================================================================================
FUNDS MOVEMENT FUNCTIONS ----- REGISTER AIRLINE ----- PURCHASE INSURANCE ----- REGISTER ORACLE ----- CREDIT WITHDRAW
=====================================================================================================================
*/
    modifier requireAirlineRegistered() {
        bool status = FlightSecuretyData.getAirlineRegistrationStatus(msg.sender);
        require(status == true, "Airline needs to be registered before payment");
        _;
    }
    
    uint256 constant AIRLINE_REGISTRATION_FEE = 10 ether;
    
    modifier requireAirlineRegistrationFee() {
        require(msg.value == AIRLINE_REGISTRATION_FEE, "Airline Registration Cost 10 ether");
        _;
    }
    
    modifier requireRegistrationNotFeePayed() {
        bool status = FlightSecuretyData.getAirlinePaymentStatus(msg.sender);
        require(status == false, "You already paid the registration fee");
        _;
    }
    
    function payAirlineRegistrationFee() external payable
    requireOperational
    requireAirlineRegistered
    requireRegistrationNotFeePayed
    requireAirlineRegistrationFee {
        FlightSecuretyData.payAirlineRegistrationFee.value(msg.value)(msg.sender);
    }

    uint256 constant INSURANCE_MAXIMUM_PRICE = 1 ether;
    
    modifier requireLessThanMaximumInsurancePrice {
        require(msg.value <= INSURANCE_MAXIMUM_PRICE, "Maximum Insurance Price is 1 ether");
        _;
    }

    function purchaseInsurance(string flight, uint256 timestamp) external payable
    requireOperational
    requireFlightRegistered(flight, timestamp)
    requireLessThanMaximumInsurancePrice {
        bytes32 key = keccak256(abi.encodePacked(flight, timestamp));
        uint256 deposit = FlightSecuretyData.getInsuranceDeposit(msg.sender, key);
        require(deposit == 0, "Insurance already bought");
        FlightSecuretyData.purchaseInsurance.value(msg.value)(msg.sender, key);
    }

    uint256 constant ORACLE_REGISTRATION_FEE = 1 ether;
    
    modifier requireOracleRegistrationFee() {
        require(msg.value == ORACLE_REGISTRATION_FEE, "Oracle Registration Cost 1 ether");
        _;
    }

    function registerOracle() external payable
    requireOperational
    requireOracleRegistrationFee {
        (uint8 index1, uint8 index2, uint8 index3) = indexesThrown();
        FlightSecuretyData.registerOracle.value(msg.value)(msg.sender, index1, index2, index3);
    }

    modifier requireAccountCredit(uint256 amount) {
        uint256 totalAccountCredit = FlightSecuretyData.getTotalAccountCredit(msg.sender);
        require(amount <= totalAccountCredit, "You can not withdraw more than what you have in your account");
        _;
    }

    function creditWithdraw(uint256 amount) external payable
    requireOperational
    requireAccountCredit(amount) {
        FlightSecuretyData.creditWithdraw(msg.sender, amount);
    }
/*
=====================================================================================================================
AFTER PROJECT ENDS
=====================================================================================================================
*/ 
    function checkDataContratBalance() external view
    requireOperational
    requireOwner
    returns(uint256 _contractBalance) {
        return FlightSecuretyData.checkDataContratBalance();
    }
    
    function withdrawAfterProjectEnds(uint256 amount) external payable
    requireOperational
    requireOwner {
        FlightSecuretyData.withdrawAfterProjectEnds(msg.sender, amount);
    }
}