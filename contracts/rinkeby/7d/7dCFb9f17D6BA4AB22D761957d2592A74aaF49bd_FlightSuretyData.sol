pragma solidity ^0.4.24;

import "./SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;
/*
=====================================================================================================================
CONTRACT CONFIGURATION
=====================================================================================================================
*/
    bool operationalStatus;
    address owner;
    address appContract;

    constructor() public {
        operationalStatus = true;
        owner = msg.sender;
        airlines[owner].registrationStatus = true;
    }

    modifier requireOwner() {
        require(msg.sender == owner, "Require contract owner");
        _;
    }

    modifier requireApplication() {
        require(msg.sender == appContract, "Require application");
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
    requireOwner returns(bool _status) {
        return operationalStatus;
    }

    function registerApplicationContract(address application) external
    requireOwner
    requireOperational {
        appContract = application;
    }
/*
=====================================================================================================================
AIRLINES
=====================================================================================================================
*/
    uint256 totalPayedAirlines;
    
    struct airline {
        bool registrationStatus;
        bool paymentStatus;
        mapping(address => bool) registrationVote;
    }
    
    mapping(address => airline) airlines;
    
    function registerAirline(address airlineAddress) external
    requireOperational
    requireApplication {
        airlines[airlineAddress].registrationStatus = true;
    }
    
    function getTotalPayedAirlines() external view
    requireOperational
    requireApplication
    returns(uint256 _totalAirlines) {
        return totalPayedAirlines;
    }
    
    function getAirlineRegistrationStatus(address airlineAddress) external view 
    requireOperational
    requireApplication
    returns(bool _status) {
        return airlines[airlineAddress].registrationStatus;
    }
    
    function getAirlinePaymentStatus(address airlineAddress) external view 
    requireOperational
    requireApplication
    returns(bool _status) {
        return airlines[airlineAddress].paymentStatus;
    }
    
    function getAirlineRegistrationVote(address registeredAirline, address newAirlineAddress) external view
    requireOperational
    requireApplication
    returns(bool _status) {
        return airlines[registeredAirline].registrationVote[newAirlineAddress];
    }
/*
=====================================================================================================================
FLIGHTS
=====================================================================================================================
*/
    struct flight {
        bool registrationStatus;
        bool requestedStatus;
        uint8 stateCode;
        uint8 index1;
        uint8 index2;
        uint8 index3;
    }

    mapping(bytes32 => flight) flights;

    function registerFlight(bytes32 key) external
    requireOperational
    requireApplication {
        flights[key].registrationStatus = true;
    }

    function requestFlight(bytes32 key, uint8 index1, uint8 index2, uint8 index3) external
    requireOperational
    requireApplication {
        flights[key].requestedStatus = true;
        flights[key].index1 = index1;
        flights[key].index2 = index2;
        flights[key].index3 = index3;
    }

    function getFlightRegistrationStatus(bytes32 key) external view
    requireOperational
    requireApplication
    returns(bool _status) {
        return flights[key].registrationStatus;
    }

    function getFlightRequestStatus(bytes32 key) external view
    requireOperational
    requireApplication
    returns(bool _status) {
        return flights[key].requestedStatus;
    }
    
    function getFlightIndexesRequired(bytes32 key) external view
    requireOperational
    requireApplication
    returns(uint8 _index1, uint8 _index2, uint8 _index3) {
        uint8 index1 = flights[key].index1;
        uint8 index2 = flights[key].index2;
        uint8 index3 = flights[key].index3;
        return (index1, index2, index3);
    }
    
    function flightStatusUpdate(bytes32 key, uint8 code) external 
    requireOperational
    requireApplication {
        flights[key].stateCode = code;
        flights[key].requestedStatus = false;
    }
    
    function getFlightStatusCode(bytes32 key) external view
    requireOperational 
    requireApplication
    returns(uint8 _status) {
        return flights[key].stateCode;
    }
/*
=====================================================================================================================
INSUREES
=====================================================================================================================
*/
    struct insurance {
        uint256 deposit;
        bool creditedInsuree;
    }
    
    struct insuree {
        mapping(bytes32 => insurance) insurances;
        uint256 totalAccountCredit;
    }
    
    mapping(address => insuree) insurees;
    
    function getInsuranceDeposit(address insureeAddress, bytes32 key) external view
    requireOperational
    requireApplication
    returns(uint256 _deposit) {
        return insurees[insureeAddress].insurances[key].deposit;
    }
    
    function getCreditedInsureeStatus(address insureeAddress, bytes32 key) external view
    requireOperational 
    requireApplication 
    returns(bool _status) {
        return insurees[insureeAddress].insurances[key].creditedInsuree;
    }
    
    function getTotalAccountCredit(address insureeAddress) external view
    requireOperational
    requireApplication
    returns(uint256 _balance) {
        return insurees[insureeAddress].totalAccountCredit;
    }
    
    function creditInsuree(address insureeAddress, bytes32 key, uint256 totalAccountCredit) external
    requireOperational
    requireApplication {
        insurees[insureeAddress].insurances[key].deposit = 0;
        uint256 currentTotalAccountCredit = insurees[insureeAddress].totalAccountCredit;
        currentTotalAccountCredit = SafeMath.add(currentTotalAccountCredit, totalAccountCredit);
        insurees[insureeAddress].totalAccountCredit = currentTotalAccountCredit;
        insurees[insureeAddress].insurances[key].creditedInsuree = true;
    }
/*
=====================================================================================================================
ORACLES
=====================================================================================================================
*/
    struct oracle {
        uint8 index1;
        uint8 index2;
        uint8 index3;
    }

    struct oracleServer {
        mapping(uint256 => oracle) oracles;
        uint256 numberOfOracles;
        bool registrationStatus;
    }

    mapping(address => oracleServer) private oracleServers;
    mapping(bytes32 => mapping(uint8 => uint256)) private votesCounter;

    function getOracleServerRegistrationStatus(address server) external view 
    requireOperational
    requireApplication
    returns(bool status) {
        return oracleServers[server].registrationStatus;
    }

    function getTotalOracles(address server) external view
    requireOperational
    requireApplication
    returns(uint256 _counter) {
        return oracleServers[server].numberOfOracles;
    }

    function getOraceIndexes(address server, uint256 id) external view
    requireOperational
    requireApplication
    returns(uint8 _index1, uint8 _index2, uint8 _index3) {
        uint8 index1 = oracleServers[server].oracles[id].index1;
        uint8 index2 = oracleServers[server].oracles[id].index2;
        uint8 index3 = oracleServers[server].oracles[id].index3;
        return (index1, index2, index3);
    }
    
    function getVotesCounter(bytes32 key, uint8 statusCode) external view
    requireOperational
    requireApplication
    returns(uint256 _counter) {
        return votesCounter[key][statusCode];
    }
    
    function oracleResponseToRequest(bytes32 key, uint8 voteCode) external
    requireOperational
    requireApplication {
        uint256 counter = votesCounter[key][voteCode];
        counter = SafeMath.add(counter, 1);
        votesCounter[key][voteCode] = counter;
    }
    
    function oracleServerCleanVotes(bytes32 key, uint8 voteCode) external 
    requireOperational
    requireApplication {
        delete votesCounter[key][voteCode];
    }
/*
=====================================================================================================================
FUNDS MOVEMENT FUNCTIONS ----- REGISTER AIRLINE ----- PURCHASE INSURANCE ----- REGISTER ORACLE ----- CREDIT WITHDRAW
=====================================================================================================================
*/
    function payAirlineRegistrationFee(address airlineAddress) external payable
    requireOperational
    requireApplication {
        totalPayedAirlines = SafeMath.add(totalPayedAirlines, 1);
        airlines[airlineAddress].paymentStatus = true;
    }

    function purchaseInsurance(address insureeAddress, bytes32 key) external payable
    requireOperational
    requireApplication {
        insurees[insureeAddress].insurances[key].deposit = msg.value;
    }

    function registerOracle(address server, uint8 index1, uint8 index2, uint8 index3) external payable
    requireOperational
    requireApplication {
        if (oracleServers[server].registrationStatus == false) {
            oracleServers[server].registrationStatus = true;
        }
        uint256 counter = oracleServers[server].numberOfOracles;
        oracleServers[server].oracles[counter].index1 = index1;
        oracleServers[server].oracles[counter].index2 = index2;
        oracleServers[server].oracles[counter].index3 = index3;
        counter = SafeMath.add(counter, 1);
        oracleServers[server].numberOfOracles = counter;
    }

    function creditWithdraw(address user, uint256 value) external payable
    requireOperational
    requireApplication {
        uint256 balance = insurees[user].totalAccountCredit;
        balance = SafeMath.sub(balance, value);
        insurees[user].totalAccountCredit = balance;
        user.transfer(value);
    }
/*
=====================================================================================================================
AFTER PROJECT ENDS
=====================================================================================================================
*/
    function checkDataContratBalance() external view
    requireOperational
    requireApplication
    returns (uint256 _contractBalance) {
        return address(this).balance;
    }
    
    function withdrawAfterProjectEnds(address ownerAddress, uint256 value) external payable
    requireOperational
    requireApplication {
        ownerAddress.transfer(value);
    }
}